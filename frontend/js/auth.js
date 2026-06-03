import { auth } from "./firebase-config.js";

import {
    signInWithEmailAndPassword,
    sendPasswordResetEmail,
    GoogleAuthProvider,
    signInWithPopup
} from "https://www.gstatic.com/firebasejs/10.12.5/firebase-auth.js";

// LOGIN
const loginForm = document.getElementById("loginForm");

if (loginForm) {
    loginForm.addEventListener("submit", async(e) => {
        e.preventDefault();

        const email = document.getElementById("email").value;
        const password = document.getElementById("password").value;

        try {
            await signInWithEmailAndPassword(
                auth,
                email,
                password
            );

            alert("Login Successful!");
            window.location.href = "index.html";

        } catch (error) {
            alert(error.message);
        }
    });
}

// FORGOT PASSWORD
const forgotPassword =
    document.getElementById("forgotPassword");

if (forgotPassword) {

    forgotPassword.addEventListener(
        "click",
        async() => {

            const email =
                document.getElementById("email").value;

            if (!email) {
                alert("Enter your email first");
                return;
            }

            try {

                await sendPasswordResetEmail(
                    auth,
                    email
                );

                alert(
                    "Password reset email sent!"
                );

            } catch (error) {
                alert(error.message);
            }
        }
    );
}

// GOOGLE LOGIN
const googleBtn =
    document.getElementById("googleLogin");

if (googleBtn) {

    googleBtn.addEventListener(
        "click",
        async() => {

            try {

                const provider =
                    new GoogleAuthProvider();

                await signInWithPopup(
                    auth,
                    provider
                );

                window.location.href =
                    "index.html";

            } catch (error) {

                alert(error.message);

            }
        }
    );
}