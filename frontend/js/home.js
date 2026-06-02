// ==========================
// MOBILE SIDEBAR
// ==========================

const menuBtn = document.getElementById("menuBtn");
const sidebar = document.getElementById("sidebar");
const slides = document.querySelectorAll(".live-slide");
const dots = document.querySelectorAll(".dot");

let currentSlide = 0;

function showSlide(index) {

    slides.forEach(slide => {
        slide.classList.remove("active-slide");
    });

    dots.forEach(dot => {
        dot.classList.remove("active");
    });

    slides[index].classList.add("active-slide");
    dots[index].classList.add("active");

    currentSlide = index;
}

function nextSlide() {

    let next = currentSlide + 1;

    if (next >= slides.length) {
        next = 0;
    }

    showSlide(next);
}

function prevSlide() {

    let prev = currentSlide - 1;

    if (prev < 0) {
        prev = slides.length - 1;
    }

    showSlide(prev);
}

/* keyboard arrows */

document.addEventListener("keydown", (e) => {

    if (e.key === "ArrowRight") {
        nextSlide();
    }

    if (e.key === "ArrowLeft") {
        prevSlide();
    }

});

/* dots click */

dots.forEach((dot, index) => {

    dot.addEventListener("click", () => {

        showSlide(index);

    });

});

menuBtn.addEventListener("click", () => {

    if (window.innerWidth <= 768) {
        sidebar.classList.toggle("show-sidebar");
    }

});

// close when click outside
document.addEventListener("click", (e) => {

    if (
        window.innerWidth <= 768 &&
        !sidebar.contains(e.target) &&
        !menuBtn.contains(e.target)
    ) {
        sidebar.classList.remove("show-sidebar");
    }

});


// ==========================
// DARK / LIGHT MODE
// ==========================

const themeBtn = document.getElementById("themeBtn");
const body = document.body;

themeBtn.addEventListener("click", () => {

    body.classList.toggle("light-mode");

    const icon = themeBtn.querySelector("i");

    if (body.classList.contains("light-mode")) {
        icon.className = "fa-solid fa-sun";
    } else {
        icon.className = "fa-solid fa-moon";
    }

});

const liveCard = document.querySelector(".live-match-slider");

let startX = 0;
let endX = 0;

/* MOBILE TOUCH */

liveCard.addEventListener("touchstart",(e)=>{

    startX = e.touches[0].clientX;

});

liveCard.addEventListener("touchend",(e)=>{

    endX = e.changedTouches[0].clientX;

    handleSwipe();

});

/* DESKTOP DRAG */

liveCard.addEventListener("mousedown",(e)=>{

    startX = e.clientX;

});

liveCard.addEventListener("mouseup",(e)=>{

    endX = e.clientX;

    handleSwipe();

});

function handleSwipe(){

    const distance = startX - endX;

    if(distance > 50){

        nextSlide();

    }

    if(distance < -50){

        prevSlide();

    }

}