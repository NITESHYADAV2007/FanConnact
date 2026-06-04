import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  updateProfile,
  GoogleAuthProvider,
  FacebookAuthProvider,
  TwitterAuthProvider,
  signInWithPopup,
  onAuthStateChanged,
  signOut,
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-analytics.js";
import {
  getStorage,
  ref,
  uploadBytes,
  getDownloadURL,
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-storage.js";
import {
  getFirestore,
  doc,
  getDoc,
  setDoc,
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyCkDa6v1vM3vMUxc0tAmCv6rx6y_-0TNcQ",
  authDomain: "fanconnect-82e17.firebaseapp.com",
  projectId: "fanconnect-82e17",
  storageBucket: "fanconnect-82e17.firebasestorage.app",
  messagingSenderId: "559813632216",
  appId: "1:559813632216:web:88f70426dd6727b4fdb7ad",
  measurementId: "G-4YHH1LBFJW",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const storage = getStorage(app);
const db = getFirestore(app);
const analytics = getAnalytics(app);

// Providers
const googleProvider = new GoogleAuthProvider();
const facebookProvider = new FacebookAuthProvider();
const twitterProvider = new TwitterAuthProvider();

// Theme Sync Logic (Moved from login.html for cleanliness)
const syncTheme = () => {
  const isDarkMode =
    localStorage.getItem("color-theme") === "dark" ||
    (!("color-theme" in localStorage) &&
      window.matchMedia("(prefers-color-scheme: dark)").matches);
  document.documentElement.classList.toggle("dark", isDarkMode);
};
syncTheme();

document.getElementById("theme-toggle-login")?.addEventListener("click", () => {
  const isDark = document.documentElement.classList.toggle("dark");
  localStorage.setItem("color-theme", isDark ? "dark" : "light");
});

// Social Login Handlers
const handleSocialLogin = async (provider) => {
  if (window.location.protocol === "file:") {
    alert(
      "Firebase Auth does not work on local files (file://). Please use a local server like 'Live Server' in VS Code.",
    );
    return;
  }

  try {
    const result = await signInWithPopup(auth, provider);
    const user = result.user;

    // Ensure social user has a record in Firestore so their profile isn't empty
    const userRef = doc(db, "users", user.uid);
    const userSnap = await getDoc(userRef);

    if (!userSnap.exists()) {
      await setDoc(userRef, {
        fullName: user.displayName,
        email: user.email,
        username: user.email.split("@")[0] + Math.floor(Math.random() * 1000),
        coins: 4250,
        level: 1,
        createdAt: new Date().toISOString(),
      });
    }

    window.location.href = "index.html";
  } catch (error) {
    console.error("Auth Error Code:", error.code);
    if (error.code === "auth/unauthorized-domain") {
      alert(
        "This domain is not authorized in Firebase Console. Add '" +
          window.location.hostname +
          "' to Authorized Domains in Authentication settings.",
      );
    } else if (error.code === "auth/operation-not-allowed") {
      alert("This sign-in provider is not enabled in your Firebase Console.");
    } else {
      alert("Login failed: " + error.message);
    }
  }
};

document
  .getElementById("google-login")
  ?.addEventListener("click", () => handleSocialLogin(googleProvider));
document
  .getElementById("facebook-login")
  ?.addEventListener("click", () => handleSocialLogin(facebookProvider));
document
  .getElementById("twitter-login")
  ?.addEventListener("click", () => handleSocialLogin(twitterProvider));

// Email/Password Login
const loginForm = document.querySelector("form");
loginForm?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("username").value;
  const password = document.getElementById("password").value;

  try {
    await signInWithEmailAndPassword(auth, email, password);
    window.location.href = "index.html";
  } catch (error) {
    // If user doesn't exist, we could offer to sign them up here
    // For now, alert the error
    alert(
      "Email login failed. Make sure you have signed up in Firebase Console first.",
    );
  }
});

// Sign Up Handler
const signupForm = document.getElementById("signup-form");
signupForm?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const fullName = document.getElementById("full-name").value;
  const username = document
    .getElementById("signup-username")
    .value.trim()
    .toLowerCase();
  const email = document.getElementById("email").value;
  const mobile = document.getElementById("mobile").value;
  const dob = document.getElementById("dob").value;
  const gender =
    document.querySelector('input[name="gender"]:checked')?.value || "Other";
  const password = document.getElementById("password").value;
  const defaultAvatar = document.getElementById(
    "selected-default-avatar",
  )?.value;
  const selectedFrame =
    document.getElementById("selected-frame")?.value || "none";
  const terms = document.getElementById("terms").checked;
  const croppedBlob = window.croppedProfileBlob; // Access via global state set by signup script

  if (!terms) {
    alert("Please agree to the Terms of Service.");
    return;
  }

  try {
    // 1. Check if username exists in Firestore
    const usernameRef = doc(db, "usernames", username);
    const usernameSnap = await getDoc(usernameRef);

    if (usernameSnap.exists()) {
      throw new Error("Username is already taken. Please choose another one.");
    }

    const userCredential = await createUserWithEmailAndPassword(
      auth,
      email,
      password,
    );

    console.log("User created, starting upload...");

    let photoURL = defaultAvatar || null;

    if (croppedBlob) {
      const storageRef = ref(storage, `profiles/${userCredential.user.uid}`);
      const snapshot = await uploadBytes(storageRef, croppedBlob);
      photoURL = await getDownloadURL(snapshot.ref);
      console.log("Photo uploaded successfully:", photoURL);
    }

    await updateProfile(userCredential.user, {
      displayName: fullName,
      photoURL: photoURL,
    });

    // 3. Store user data and reserve username in Firestore
    await setDoc(doc(db, "users", userCredential.user.uid), {
      fullName,
      username,
      email,
      mobile,
      dob,
      gender,
      frame: selectedFrame,
      coins: 4250, // Initial default coins
      level: 12, // Initial default level
      createdAt: new Date().toISOString(),
    });

    await setDoc(usernameRef, { uid: userCredential.user.uid });

    // Prevent auto-login redirect so the user sees the success alert
    await signOut(auth);

    alert("Sign up successfully!");
    window.location.href = "login.html";
  } catch (error) {
    alert("Registration failed: " + error.message);
  }
});

// Monitor Auth State
onAuthStateChanged(auth, (user) => {
  if (user && window.location.pathname.includes("login.html")) {
    window.location.href = "index.html";
  }
});

export { auth, db, storage };
