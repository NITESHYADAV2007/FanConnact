import { auth, db } from "./firebase-config.js";

import {
    onAuthStateChanged,
    signOut
} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-auth.js";

import {
    doc,
    getDoc
} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore.js";

onAuthStateChanged(auth, async(user) => {

    if (!user) {
        window.location.href = "login.html";
        return;
    }

    try {

        const docRef = doc(
            db,
            "users",
            user.uid
        );

        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {

            const userData = docSnap.data();

            const welcomeUser =
                document.getElementById("welcomeUser");

            const coinBalance =
                document.getElementById("coinBalance");

            if (welcomeUser) {
                welcomeUser.innerHTML =
                    `Welcome back, ${userData.name} 👋`;
            }

            if (coinBalance) {
                coinBalance.textContent =
                    userData.coins || 0;
            }
        }

    } catch (error) {
        console.error(error);
        alert(error.message);
    }
});

// LOGOUT
const logoutBtn =
    document.getElementById("logoutBtn");

if (logoutBtn) {

    logoutBtn.addEventListener(
        "click",
        async() => {

            try {

                await signOut(auth);

                alert("Logged out successfully!");

                window.location.href =
                    "login.html";

            } catch (error) {

                alert(error.message);

            }
        }
    );
}