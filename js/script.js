import {
  onAuthStateChanged,
  signOut,
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";
import {
  doc,
  getDoc,
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";
// Import the initialized auth from your local config file
import { auth, db } from "./firebase-config.js";

document.addEventListener("DOMContentLoaded", () => {
  const themeToggleBtn = document.getElementById("theme-toggle");
  const mobileMenuBtn = document.getElementById("mobile-menu-btn");
  const closeSidebarBtn = document.getElementById("close-sidebar-btn");
  const sidebar = document.getElementById("sidebar");
  const headerLogo = document.getElementById("header-logo");
  const profileTrigger = document.getElementById("profile-trigger");

  // --- Hero Carousel Logic ---
  const carousel = document.getElementById("hero-carousel"); // Ensure this ID exists in HTML
  const prevBtn = document.getElementById("prev-slide"); // Ensure this ID exists in HTML
  const nextBtn = document.getElementById("next-slide"); // Ensure this ID exists in HTML
  const dots = document.querySelectorAll(".hero-dot"); // Ensure this class exists in HTML

  const updateDots = () => {
    const index = Math.round(carousel.scrollLeft / carousel.offsetWidth);
    dots.forEach((dot, i) => {
      if (i === index) {
        dot.classList.replace("bg-gray-600", "bg-brand-green");
      } else {
        dot.classList.replace("bg-brand-green", "bg-gray-600");
      }
    });
  };

  if (carousel) {
    carousel.addEventListener("scroll", updateDots);
  }

  if (carousel && prevBtn && nextBtn) {
    nextBtn.addEventListener("click", () => {
      if (
        carousel.scrollLeft + carousel.offsetWidth >=
        carousel.scrollWidth - 10
      ) {
        carousel.scrollTo({ left: 0, behavior: "smooth" });
      } else {
        carousel.scrollBy({ left: carousel.offsetWidth, behavior: "smooth" });
      }
    });

    prevBtn.addEventListener("click", () => {
      if (carousel.scrollLeft <= 10) {
        carousel.scrollTo({ left: carousel.scrollWidth, behavior: "smooth" });
      } else {
        carousel.scrollBy({ left: -carousel.offsetWidth, behavior: "smooth" });
      }
    });
  }

  let currentUser = null;

  // Monitor Real Auth State
  onAuthStateChanged(auth, async (user) => {
    currentUser = user;

    // Redirect guests from protected pages
    if (!user) {
      const path = window.location.pathname;
      const page = path.split("/").pop();
      // Pages guests are allowed to see
      const guestAllowedPages = [
        "berforeloginindex.html",
        "login.html",
        "signup.html",
        "news.html",
        "news&update.html",
      ];

      // Default landing page for unauthenticated users visiting root, dashboard or protected pages
      if (
        page === "index.html" ||
        page === "" ||
        !guestAllowedPages.includes(page)
      ) {
        window.location.href = "berforeloginindex.html";
        return;
      }
    } else if (user) {
      // User is logged in. Redirect away from landing and auth pages to dashboard.
      const page = window.location.pathname.split("/").pop();
      if (
        page === "berforeloginindex.html" ||
        page === "login.html"
      ) {
        // Check Firestore emailVerified for OTP-verified users
        // Missing field = legacy user = allow; false = block
        let emailVerified = true;
        try {
          const userSnap = await getDoc(doc(db, "users", user.uid));
          if (userSnap.exists() && userSnap.data().emailVerified === false) {
            emailVerified = false;
          }
        } catch (_) {}
        if (!emailVerified) {
          await signOut(auth);
          return;
        }
        window.location.href = "index.html";
        return;
      }
    }

    const userNameElem = document.getElementById("user-name-display");
    const userAvatarElem = document.getElementById("user-profile-img");
    const userLevelElem = document.getElementById("user-level-display");
    const welcomeElem = document.getElementById("welcome-message");

    if (user) {
      const emailPrefix = user.email.split("@")[0].toLowerCase().replace(/[^a-z0-9]/g, "");
      let displayIdentity = emailPrefix || "user";
      const photo =
        user.photoURL ||
        `https://ui-avatars.com/api/?name=${encodeURIComponent(displayIdentity)}&background=10b981&color=fff`;

      // Show Auth data immediately to prevent flicker
      if (userNameElem)
        userNameElem.textContent = `@${displayIdentity}`;
      if (welcomeElem)
        welcomeElem.innerHTML = `Welcome back, ${displayIdentity}! <span class="ml-2 text-2xl">👋</span>`;
      if (userAvatarElem) userAvatarElem.src = photo;

      // Fetch extra Firestore details in the background
      try {
        const userDoc = await getDoc(doc(db, "users", user.uid));
        if (userDoc.exists()) {
          const data = userDoc.data();
          if (data.username) displayIdentity = `@${data.username}`;
          if (data.frame && userAvatarElem) {
            // Clear existing frames
            userAvatarElem.classList.remove(
              "frame-gold",
              "frame-emerald",
              "frame-diamond",
            );
            if (data.frame && data.frame !== "none")
              userAvatarElem.classList.add(`frame-${data.frame}`);
            if (data.frame && data.frame !== "none")
              userAvatarElem.style.borderWidth = "3px";
          }
          if (userLevelElem)
            userLevelElem.textContent = `Level ${data.level || 1}`;

          if (data.username && userNameElem)
            userNameElem.textContent = `@${data.username}`;
          if (data.photoURL && userAvatarElem) {
            userAvatarElem.src = data.photoURL;
          }
          if (welcomeElem) {
            const name = data.fullName || data.username || displayIdentity;
            welcomeElem.textContent = `Welcome back, ${name}!`;
          }
        }
      } catch (error) {
        console.error("Error fetching user data from Firestore:", error);
      }
    } else {
      // Default Guest State
      if (userNameElem) userNameElem.textContent = "Guest";
      if (welcomeElem)
        welcomeElem.innerHTML = `Welcome, Guest! <span class="ml-2 text-2xl">👋</span>`;
      if (userAvatarElem)
        userAvatarElem.src =
          "https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y";
    }
  });

  // Initialize Sidebar State (Desktop)
  if (window.innerWidth >= 1024) {
    const isCollapsed = localStorage.getItem("sidebar-collapsed") === "true";
    if (isCollapsed) {
      sidebar?.classList.add("sidebar-collapsed");
      headerLogo?.classList.remove("lg:hidden");
    } else {
      headerLogo?.classList.add("lg:hidden");
    }
  }

  // --- Active Link Highlighting ---
  const path = window.location.pathname.split("/").pop() || "index.html";
  document.querySelectorAll("nav a, aside a").forEach((link) => {
    if (link.getAttribute("href") === path) {
      link.classList.add("nav-link-active");
    }
  });

  // --- Language Selection Logic ---
  const translations = {
    en: {
      "nav-home": "Home",
      "nav-live": "Live Matches",
      "welcome-guest": "Welcome, Guest!",
      "login-title": "Welcome Back! 👋",
      "login-email-label": "Email or Username",
      "login-email-placeholder": "Enter your email or username",
      "login-password-label": "Password",
      "login-password-placeholder": "Enter your password",
      "login-submit": "Login",
    },
    hi: {
      "nav-home": "होम",
      "nav-live": "लाइव मैच",
      "welcome-guest": "स्वागत है, अतिथि!",
      "login-title": "वापसी पर स्वागत है! 👋",
      "login-email-label": "ईमेल या उपयोगकर्ता नाम",
      "login-email-placeholder": "अपना ईमेल या उपयोगकर्ता नाम दर्ज करें",
      "login-password-label": "पासवर्ड",
      "login-password-placeholder": "अपना पासवर्ड दर्ज करें",
      "login-submit": "लॉगिन करें",
    },
  };

  function applyLanguage(lang) {
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (translations[lang] && translations[lang][key]) {
        if (el.tagName === "INPUT") {
          el.placeholder = translations[lang][key];
        } else {
          el.textContent = translations[lang][key];
        }
      }
    });
    localStorage.setItem("fanconnect-lang", lang);
    document.documentElement.lang = lang;
  }

  // Load saved language
  const savedLang = localStorage.getItem("fanconnect-lang") || "en";
  applyLanguage(savedLang);
  window.applyLanguage = applyLanguage; // Export for login.html

  // 1. Initial Icon Sync
  const syncIcons = () => {
    const darkIcon = document.getElementById("theme-toggle-dark-icon");
    const lightIcon = document.getElementById("theme-toggle-light-icon");
    const isDark = document.documentElement.classList.contains("dark");

    if (isDark) {
      document.documentElement.classList.remove("light");
      darkIcon?.classList.add("hidden");
      lightIcon?.classList.remove("hidden");
    } else {
      document.documentElement.classList.add("light");
      darkIcon?.classList.remove("hidden");
      lightIcon?.classList.add("hidden");
    }
  };
  syncIcons();

  // 2. Theme handled by theme.js — only sync icons on load

  // 2.1 Listen for changes from other tabs
  window.addEventListener("storage", (e) => {
    if (e.key === "color-theme") {
      const isDark = e.newValue === "dark";
      document.documentElement.classList.toggle("dark", isDark);
      document.documentElement.classList.toggle("light", !isDark);
      syncIcons();
    }
  });

  // 3. Mobile Sidebar Toggle
  mobileMenuBtn?.addEventListener("click", () => {
    if (window.innerWidth < 1024) {
      sidebar?.classList.toggle("-translate-x-full");
      // Hide header logo if sidebar is visible on mobile
      const isSidebarOpen = !sidebar?.classList.contains("-translate-x-full");
      headerLogo?.classList.toggle("hidden", isSidebarOpen);
    } else {
      // Desktop: Toggle and persist full sidebar collapse
      const isCollapsed = sidebar?.classList.toggle("sidebar-collapsed");
      localStorage.setItem("sidebar-collapsed", isCollapsed);
      // Toggle whole logo in header on desktop (show when sidebar is collapsed)
      headerLogo?.classList.toggle("lg:hidden", !isCollapsed);
    }
  });

  // Sidebar Close Button (Mobile)
  closeSidebarBtn?.addEventListener("click", () => {
    sidebar?.classList.add("-translate-x-full");
    headerLogo?.classList.remove("hidden");
  });

  // 4. Navigation Interceptor & Mobile Sidebar Close
  const navLinks = document.querySelectorAll(
    "nav a, .nav-link, aside a, .fixed.bottom-0 a",
  );
  navLinks?.forEach((link) => {
    link.addEventListener("click", (e) => {
      const navTextElement = link.querySelector(".nav-text");
      const linkText = (
        navTextElement ? navTextElement.textContent : link.textContent
      ).trim();
      const href = link.getAttribute("href");

      if (link.tagName === "BUTTON") return; // Don't intercept button clicks

      // Define which tabs are accessible without login
      const allowedTabs = ["Home", "News", "News & Updates"];
      const isHomeOrNews =
        allowedTabs.some((t) => linkText.includes(t)) || href === "index.html";

      // Define sport-related pages that require login.
      // This array should include all sport-specific pages and general match pages.
      // The `includes` check is broad, so ensure unique names if needed.
      // For example, "Matches" could be a general page, while "Cricket" is specific.
      // The current setup assumes "Matches" in the top nav and sidebar refers to livematches.html
      // and individual sport names refer to their respective pages.
      const sportPagesRequiringLogin = [
        "Live Matches",
        "Matches", // For the top header "Matches" link
        "Match Center",
        "Football",
        "Basketball",
        "Tennis",
        "Baseball",
        "Cricket", // Assuming cricket.html is also a sport page
        "Hockey",
        "All Games",
      ];

      // Check if the clicked link is a sport-related page (or general match page)
      // and requires login. If the user is not logged in, redirect to login.
      // Otherwise, proceed with navigation.
      if (sportPagesRequiringLogin.some((sport) => linkText.includes(sport))) {
        if (!currentUser) {
          e.preventDefault();
          window.location.href = "berforeloginindex.html";
        }
        return;
      }

      // If guest clicks a link to index.html, redirect to guest landing page instead
      if (!currentUser && href === "index.html") {
        e.preventDefault();
        if (window.innerWidth < 1024) {
          sidebar?.classList.add("-translate-x-full");
          headerLogo?.classList.remove("hidden");
        }
        window.location.href = "berforeloginindex.html";
        return;
      }

      // Check if the clicked tab is restricted AND user is not logged in
      if (
        linkText &&
        !currentUser &&
        !isHomeOrNews &&
        href !== "login.html" &&
        href !== "signup.html"
      ) {
        e.preventDefault();
        window.location.href = "berforeloginindex.html";
        return;
      }

      if (window.innerWidth < 1024) {
        sidebar?.classList.add("-translate-x-full");
        headerLogo?.classList.remove("hidden");
      }
    });
  });

  // 6. Profile Page Redirect
  profileTrigger?.addEventListener("click", () => {
    window.location.href = "profile.html";
  });

  // 7. Notification Page Redirect
  document.querySelectorAll(".notification-trigger").forEach((trigger) => {
    trigger.addEventListener("click", () => {
      window.location.href = "notification.html";
    });
  });

  // Close sidebar when clicking outside on mobile
  document.addEventListener("click", (e) => {
    if (
      window.innerWidth < 1024 &&
      sidebar &&
      !sidebar.contains(e.target) &&
      mobileMenuBtn &&
      !mobileMenuBtn.contains(e.target)
    ) {
      sidebar.classList.add("-translate-x-full");
      headerLogo?.classList.remove("hidden");
    }
  });
});
