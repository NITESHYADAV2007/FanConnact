const topThreeUsers = {
  firstPlace: {
    username: "MI_Army",
    level: 18,
    xp: "12,560",
    avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
  },
  secondPlace: {
    username: "CricketKing",
    level: 16,
    xp: "9,870",
    avatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
  },
  thirdPlace: {
    username: "Virat18",
    level: 16,
    xp: "8,930",
    avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
  },
};

function renderTopThree() {
  const r1 = document.getElementById("card-rank1");
  const r2 = document.getElementById("card-rank2");
  const r3 = document.getElementById("card-rank3");
  if (r1) {
    const h2 = r1.querySelector("h2");
    const img = r1.querySelector("img");
    if (h2) h2.textContent = topThreeUsers.firstPlace.username;
    if (img) img.src = topThreeUsers.firstPlace.avatar;
  }
  if (r2) {
    const h3 = r2.querySelector("h3");
    const img = r2.querySelector("img");
    if (h3) h3.textContent = topThreeUsers.secondPlace.username;
    if (img) img.src = topThreeUsers.secondPlace.avatar;
  }
  if (r3) {
    const h3 = r3.querySelector("h3");
    const img = r3.querySelector("img");
    if (h3) h3.textContent = topThreeUsers.thirdPlace.username;
    if (img) img.src = topThreeUsers.thirdPlace.avatar;
  }
}

document.addEventListener("DOMContentLoaded", renderTopThree);

const userData = {
  xp: 2850,
  currentLevel: 12,
  nextLevelXP: 4000,
};

const xpEl = document.getElementById("userXP");
if (xpEl) xpEl.textContent = userData.xp.toLocaleString() + " XP";

const nextEl = document.getElementById("nextLevel");
if (nextEl) nextEl.textContent = `Next Level ${userData.currentLevel + 1}`;

const remainEl = document.getElementById("xpRemaining");
if (remainEl) remainEl.textContent = `${(userData.nextLevelXP - userData.xp).toLocaleString()} XP to go`;

const progEl = document.getElementById("xpProgress");
if (progEl) progEl.style.width = `${(userData.xp / userData.nextLevelXP) * 100}%`;
