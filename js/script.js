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
  const darkIcon = document.getElementById("theme-toggle-dark-icon");
  const lightIcon = document.getElementById("theme-toggle-light-icon");
  const mobileMenuBtn = document.getElementById("mobile-menu-btn");
  const closeSidebarBtn = document.getElementById("close-sidebar-btn");
  const sidebar = document.getElementById("sidebar");
  const profileTrigger = document.getElementById("profile-trigger");

  let currentUser = null;

  // Monitor Real Auth State
  onAuthStateChanged(auth, async (user) => {
    currentUser = user;

    const userNameElem = document.getElementById("user-name-display");
    const userAvatarElem = document.getElementById("user-profile-img");
    const userLevelElem = document.getElementById("user-level-display");
    const welcomeElem = document.getElementById("welcome-message");

    if (user) {
      let displayIdentity = user.displayName || user.email.split("@")[0];
      const photo =
        user.photoURL ||
        `https://ui-avatars.com/api/?name=${encodeURIComponent(displayIdentity)}&background=10b981&color=fff`;

      // Show Auth data immediately to prevent flicker
      if (userNameElem)
        userNameElem.textContent = displayIdentity.startsWith("@")
          ? displayIdentity
          : `@${displayIdentity}`;
      if (welcomeElem)
        welcomeElem.innerHTML = `Welcome back, ${displayIdentity.replace("@", "")}! <span class="ml-2 text-2xl">👋</span>`;
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

  // 1. Initial Theme State Check
  const isDarkMode =
    localStorage.getItem("color-theme") === "dark" ||
    (!("color-theme" in localStorage) &&
      window.matchMedia("(prefers-color-scheme: dark)").matches);

  if (isDarkMode) {
    document.documentElement.classList.add("dark");
    lightIcon?.classList.remove("hidden");
    darkIcon?.classList.add("hidden");
  } else {
    document.documentElement.classList.remove("dark");
    darkIcon?.classList.remove("hidden");
    lightIcon?.classList.add("hidden");
  }

  // 2. Theme Click Handler
  themeToggleBtn?.addEventListener("click", () => {
    darkIcon.classList.toggle("hidden");
    lightIcon.classList.toggle("hidden");

    if (document.documentElement.classList.contains("dark")) {
      document.documentElement.classList.remove("dark");
      localStorage.setItem("color-theme", "light");
    } else {
      document.documentElement.classList.add("dark");
      localStorage.setItem("color-theme", "dark");
    }
  });

  // 3. Mobile Sidebar Toggle
  mobileMenuBtn?.addEventListener("click", () => {
    if (window.innerWidth < 1024) {
      sidebar?.classList.toggle("-translate-x-full");
    } else {
      sidebar?.classList.toggle("sidebar-collapsed");
      // Toggle header logo visibility on desktop when sidebar is slim
      const headerLogo = document.getElementById("header-logo");
      const isCollapsed = sidebar?.classList.contains("sidebar-collapsed");
      headerLogo?.classList.toggle("lg:hidden", !isCollapsed);
      headerLogo?.classList.toggle("lg:flex", isCollapsed);
    }
  });

  // Sidebar Close Button (Mobile)
  closeSidebarBtn?.addEventListener("click", () => {
    sidebar?.classList.add("-translate-x-full");
  });

  // 4. Navigation Interceptor & Mobile Sidebar Close
  const navLinks = sidebar?.querySelectorAll("nav a, .nav-link");
  navLinks?.forEach((link) => {
    link.addEventListener("click", (e) => {
      const navTextElement = link.querySelector(".nav-text");
      // Fallback to searching all text if .nav-text isn't found
      const linkText = (
        navTextElement ? navTextElement.textContent : link.textContent
      ).trim();

      // Define which tabs are accessible without login
      const allowedTabs = ["Home", "News & Updates"];

      // Check if the clicked tab is restricted AND user is not logged in
      if (
        linkText &&
        !allowedTabs.some((tab) => linkText.includes(tab)) &&
        !currentUser
      ) {
        e.preventDefault();
        window.location.href = "login.html"; // Points to your new login page
      } else if (window.innerWidth < 1024) {
        sidebar?.classList.add("-translate-x-full");
      }
    });
  });

  // 6. Profile Page Redirect
  profileTrigger?.addEventListener("click", () => {
    window.location.href = "profile.html";
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
    }
  });
});
