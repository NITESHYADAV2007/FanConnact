// =========================
// SIDEBAR COLLAPSE
// =========================

const menuBtn =
document.getElementById(
  "menu-btn"
);

const sidebar =
document.getElementById(
  "sidebar"
);

menuBtn.addEventListener(
  "click",
  () => {

    sidebar.classList.toggle(
      "collapsed"
    );
  }
);


// =========================
// LIVE MATCH DATA
// =========================

const matches = [

  {
    team1: "MI",
    team2: "CSK",

    team1Logo:
      "./assets/teams/mi.png",

    team2Logo:
      "./assets/teams/csk.png",

    score1: "185/4",
    overs1: "(18.2)",

    score2: "165/7",
    overs2: "(20)",

    status:
      "MI need 20 runs in 10 balls"
  },

  {
    team1: "IND",
    team2: "AUS",

    team1Logo:
      "./assets/teams/india.png",

    team2Logo:
      "./assets/teams/australia.png",

    score1: "287/6",
    overs1: "(48.2)",

    score2: "Yet to bat",
    overs2: "",

    status:
      "IND chose to bat"
  },

  {
    team1: "RCB",
    team2: "KKR",

    team1Logo:
      "./assets/teams/rcb.png",

    team2Logo:
      "./assets/teams/kkr.png",

    score1: "142/3",
    overs1: "(15.4)",

    score2: "141/7",
    overs2: "(18.1)",

    status:
      "RCB need 2 runs in 11 balls"
  }

];


// =========================
// MATCH SLIDER
// =========================

let currentMatch = 0;

function updateMatch() {

  const match =
    matches[currentMatch];


  // TEAM 1
  document.querySelector(
    ".team:first-child img"
  ).src =
    match.team1Logo;

  document.querySelector(
    ".team:first-child h3"
  ).innerText =
    match.team1;


  // TEAM 2
  document.querySelector(
    ".team:last-child img"
  ).src =
    match.team2Logo;

  document.querySelector(
    ".team:last-child h3"
  ).innerText =
    match.team2;


  // SCORE
  document.querySelectorAll(
    ".score-row h2"
  )[0].innerText =
    match.score1;

  document.querySelectorAll(
    ".score-row span"
  )[0].innerText =
    match.overs1;

  document.querySelectorAll(
    ".score-row h2"
  )[1].innerText =
    match.score2;

  document.querySelectorAll(
    ".score-row span"
  )[1].innerText =
    match.overs2;


  // STATUS
  document.querySelector(
    ".match-status"
  ).innerText =
    match.status;
}


// =========================
// NEXT BUTTON
// =========================

document
.getElementById(
  "nextBtn"
)
.addEventListener(
  "click",
  (e) => {

    e.stopPropagation();

    currentMatch++;

    if (
      currentMatch >=
      matches.length
    ) {
      currentMatch = 0;
    }

    updateMatch();
  }
);


// =========================
// PREVIOUS BUTTON
// =========================

document
.getElementById(
  "prevBtn"
)
.addEventListener(
  "click",
  (e) => {

    e.stopPropagation();

    currentMatch--;

    if (
      currentMatch < 0
    ) {
      currentMatch =
        matches.length - 1;
    }

    updateMatch();
  }
);


// =========================
// HERO CARD CLICK
// =========================

document
.getElementById(
  "liveCard"
)
.addEventListener(
  "click",
  (e) => {

    // Ignore arrow button click
    if (
      e.target.closest(
        ".slider-btn"
      )
    ) {
      return;
    }

    // Open match page
    window.location.href =
      "./match.html";
  }
);


// =========================
// INITIAL LOAD
// =========================

updateMatch();