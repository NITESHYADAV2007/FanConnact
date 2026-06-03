import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.5/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.12.5/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore.js";
const firebaseConfig = {
    apiKey: "AIzaSyCkDa6v1vM3vMUxc0tAmCv6rx6y_-0TNcQ",
    authDomain: "fanconnect-82e17.firebaseapp.com",
    projectId: "fanconnect-82e17",
    storageBucket: "fanconnect-82e17.firebasestorage.app",
    messagingSenderId: "559813632216",
    appId: "1:559813632216:web:88f70426dd6727b4fdb7ad"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);