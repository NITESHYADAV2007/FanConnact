// Full leaderboard data — real registered users from Firestore (users collection),
// sorted by XP desc, Level desc, then name. Falls back to generated data if
// Firebase is unavailable (e.g. opened via file:// or offline).
var leaderboardData = null;
var leaderboardLoaded = false;

// Fallback generator (used only when Firestore can't be reached)
function generateAllUsers() {
  var firstNames = ["Arjun","Rahul","Virat","Rohit","Sachin","Dhoni","Kohli","Sharma","Amit","Sunil",
    "Raj","Ankit","Vikram","Deepak","Manish","Karan","Nitin","Pradeep","Gaurav","Harsh",
    "Siddharth","Akash","Ravi","Mohan","Kunal","Yash","Aditya","Tushar","Om","Dev",
    "Krishna","Sameer","Abhishek","Tarun","Uday","Varun","Chirag","Farhan","Hitesh","Jatin",
    "Lalit","Manoj","Nilesh","Pankaj","Rakesh","Sandeep","Tanmay","Umesh","Vijay","Yogesh",
    "Aryan","Bhuvan","Chandan","Dinesh","Eshan","Fahad","Girish","Harish","Ishaan","Jivan"];
  var suffixes = ["_Fan","_Army","_King","_Star","_Pro","_Legend","_Master","_Champ","_Warrior","_Hero"];
  var fixedNames = ["MI_Army","CricketKing","Virat18","CSK_Rider","BlueArmy","RohitFan_45"];
  var fixedLevels = [18, 16, 16, 15, 14, 14];
  var fixedXP = [12560, 9870, 8930, 7450, 6980, 6250];
  var fixedImgs = ["https://i.pravatar.cc/100?img=10","https://i.pravatar.cc/100?img=12","https://i.pravatar.cc/100?img=15","https://i.pravatar.cc/100?img=12","https://i.pravatar.cc/100?img=20","https://i.pravatar.cc/100?img=15"];
  var data = [];
  for (var i = 0; i < 6; i++) {
    data.push({ name: fixedNames[i], level: fixedLevels[i], xp: fixedXP[i], coins: 0, img: fixedImgs[i] });
  }
  for (var i = 7; i <= 56; i++) {
    var idx = (i - 7) % firstNames.length;
    var name = firstNames[idx] + suffixes[Math.floor(Math.random() * suffixes.length)] + Math.floor(Math.random() * 99);
    var xp = Math.max(500, Math.floor(12560 - i * 200 + (Math.random() * 400 - 200)));
    var level = Math.max(1, Math.min(20, Math.floor(xp / 700) + 1));
    data.push({ name: name, level: level, xp: xp, coins: 0, img: "https://i.pravatar.cc/100?img=" + ((i % 70) + 1) });
  }
  data.sort(function(a, b) {
    if (a.xp !== b.xp) return b.xp - a.xp;
    if (a.coins !== b.coins) return b.coins - a.coins;
    if (a.level !== b.level) return b.level - a.level;
    return a.name.localeCompare(b.name);
  });
  for (var i = 0; i < data.length; i++) {
    data[i].rank = i + 1;
  }
  return data;
}

// Load real registered users from Firestore (users collection)
async function loadRealUsers() {
  try {
    if (!window.__FB__ || !window.__FB__.db) throw new Error("Firebase not ready");
    const { collection, getDocs, query, orderBy, limit } = await import(
      "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js"
    );
    const q = query(collection(window.__FB__.db, "users"), orderBy("xp", "desc"), limit(200));
    const snap = await getDocs(q);
    var users = [];
    snap.forEach(function (doc) {
      var d = doc.data();
      var xp = parseInt(d.xp, 10) || 0;
      var level = parseInt(d.level, 10) || 1;
      var coins = parseInt(d.coins, 10) || 0;
      var name = d.username || d.fullName || d.email || "Fan";
      var img = d.photoURL || (d.email ? ("https://i.pravatar.cc/100?u=" + encodeURIComponent(d.email)) : "assets/images/default-avatar.png?w=150");
      users.push({ name: name, level: level, xp: xp, coins: coins, img: img, uid: d.uid });
    });
    if (!users.length) throw new Error("No users");
    users.sort(function (a, b) {
      if (a.xp !== b.xp) return b.xp - a.xp;
      if (a.coins !== b.coins) return b.coins - a.coins;
      if (a.level !== b.level) return b.level - a.level;
      return a.name.localeCompare(b.name);
    });
    for (var i = 0; i < users.length; i++) users[i].rank = i + 1;
    return users;
  } catch (e) {
    console.warn("[leaderboard] falling back to generated users:", e.message);
    return null;
  }
}

async function getData() {
  if (leaderboardData) return leaderboardData;
  if (!leaderboardLoaded) {
    leaderboardLoaded = true;
    var real = await loadRealUsers();
    leaderboardData = real || generateAllUsers();
  }
  return leaderboardData;
}

function goToPlayer(u, sport) {
  if (!sport) {
    // Try active game filter button on leaderboard page
    var activeGameBtn = document.querySelector('.game-filter-btn.active-filter');
    if (activeGameBtn) {
      sport = activeGameBtn.getAttribute('data-game') || "Cricket";
    } else {
      sport = "Cricket";
    }
    sport = sport.charAt(0).toUpperCase() + sport.slice(1).toLowerCase();
    if (sport === "Esports") sport = "E-Sports";
  }
  sessionStorage.setItem("playerSport", sport || "Cricket");
  sessionStorage.setItem("playerView", JSON.stringify({ player: { name: u.name, rank: u.rank, xp: u.xp, level: u.level, imgUrl: u.img }, sport: sport || "Cricket" }));
  window.location.href = "player.html";
}

async function renderPodium() {
  var data = await getData();
  var cards = [
    document.getElementById("card-rank1"),
    document.getElementById("card-rank2"),
    document.getElementById("card-rank3")
  ];
  var users = [data[0], data[1], data[2]];
  cards.forEach(function(el, idx) {
    if (!el || !users[idx]) return;
    var u = users[idx];
    var nameEl = el.querySelector("h2, h3");
    var imgEl = el.querySelector("img");
    var levelEl = el.querySelector("[class*='Level']");
    var xpEl = el.querySelector(".font-black");
    if (nameEl) nameEl.textContent = u.name;
    if (imgEl) imgEl.src = u.img;
    if (levelEl) levelEl.textContent = "Level " + u.level;
    if (xpEl) xpEl.textContent = u.xp.toLocaleString() + " XP";
    el.classList.add("cursor-pointer");
    el.addEventListener("click", function() { goToPlayer(u); });
  });
}

async function renderRows4to6() {
  var container = document.getElementById("leaderboard-rows-4-6");
  if (!container) return;
  var data = await getData();
  var rows = data.slice(3, 6);
  container.innerHTML = "";
  rows.forEach(function(u) {
    var d = document.createElement("div");
    d.className = "hidden md:grid grid-cols-12 items-center px-6 py-4 hover:bg-[#091321] transition border-b border-[#0f1d30] cursor-pointer";
    d.innerHTML = '<div class="col-span-1 text-white font-semibold">' + u.rank + '</div>' +
      '<div class="col-span-5 flex items-center gap-3"><img src="' + u.img + '" class="w-10 h-10 rounded-full"><span class="text-white">' + u.name + '</span></div>' +
      '<div class="col-span-3"><span class="bg-[#23153e] text-purple-300 px-3 py-1 rounded-lg text-sm">Level ' + u.level + '</span></div>' +
      '<div class="col-span-3 text-right text-white font-semibold">' + u.xp.toLocaleString() + ' XP</div>';
    d.addEventListener("click", function() { goToPlayer(u); });
    container.appendChild(d);
    var m = document.createElement("div");
    m.className = "md:hidden p-4 border-b border-[#0f1d30] cursor-pointer";
    m.innerHTML = '<div class="flex items-center gap-3"><div class="text-white font-bold">#' + u.rank + '</div>' +
      '<img src="' + u.img + '" class="w-10 h-10 rounded-full">' +
      '<div class="flex-1"><div class="text-white font-medium">' + u.name + '</div>' +
      '<div class="flex justify-between mt-1"><span class="bg-[#23153e] text-purple-300 px-2 py-1 rounded text-xs">Level ' + u.level + '</span>' +
      '<span class="text-white font-semibold">' + u.xp.toLocaleString() + ' XP</span></div></div></div>';
    m.addEventListener("click", function() { goToPlayer(u); });
    container.appendChild(m);
  });
}

async function renderTopEarners() {
  var container = document.getElementById("topEarnersList");
  if (!container) return;
  var data = await getData();
  var top5 = data.slice(0, 5);
  container.innerHTML = "";
  top5.forEach(function(u, idx) {
    var div = document.createElement("div");
    div.className = "flex items-center justify-between cursor-pointer hover:bg-[#0a1628] p-2 rounded-lg transition";
    div.innerHTML = '<div class="flex items-center gap-3"><span class="text-slate-400 w-4">' + (idx + 1) + '</span>' +
      '<img src="' + u.img + '" class="w-10 h-10 rounded-full">' +
      '<span class="text-white">' + u.name + '</span></div>' +
      '<span class="text-[#f7c948] font-semibold">' + u.xp.toLocaleString() + ' XP</span>';
    div.addEventListener("click", function() { goToPlayer(u); });
    container.appendChild(div);
  });
}

var fullLBExpanded = false;

async function toggleFullLeaderboard() {
  var container = document.getElementById("full-leaderboard-container");
  var btn = document.getElementById("full-lb-btn");
  if (!container) return;
  if (fullLBExpanded) {
    container.classList.add("hidden");
    btn.innerHTML = "View Full Leaderboard →";
    fullLBExpanded = false;
    return;
  }
  var data = await getData();
  var rows = data.slice(6);
  container.classList.remove("hidden");
  container.innerHTML = "";
  var header = document.createElement("div");
  header.className = "hidden md:grid grid-cols-12 px-6 py-3 text-slate-400 text-xs font-semibold border-b border-[#12263f] sticky top-0 bg-[#060d18]";
  header.innerHTML = '<div class="col-span-1">Rank</div><div class="col-span-4">User</div><div class="col-span-2">Level</div><div class="col-span-2 text-right">XP</div><div class="col-span-3 text-right">Coins</div>';
  container.appendChild(header);
  rows.forEach(function(f) {
    var row = document.createElement("div");
    row.className = "border-b border-[#0f1d30] hover:bg-[#0a1628] transition cursor-pointer";
    row.addEventListener("click", function() { goToPlayer(f); });
    var rc = f.rank <= 10 ? "text-yellow-400" : "text-white";
    var coins = (f.coins != null ? f.coins : 0).toLocaleString();
    var desk = document.createElement("div");
    desk.className = "hidden md:grid grid-cols-12 items-center px-6 py-3";
    desk.innerHTML = '<div class="col-span-1 ' + rc + ' font-semibold">#' + f.rank + '</div>' +
      '<div class="col-span-4 flex items-center gap-3"><img src="' + f.img + '" class="w-8 h-8 rounded-full"><span class="text-white text-sm">' + f.name + '</span></div>' +
      '<div class="col-span-2"><span class="bg-[#23153e] text-purple-300 px-2 py-1 rounded text-xs">Level ' + f.level + '</span></div>' +
      '<div class="col-span-2 text-right text-white font-semibold text-sm">' + f.xp.toLocaleString() + ' XP</div>' +
      '<div class="col-span-3 text-right text-[#f7c948] font-semibold text-sm">' + coins + ' 🪙</div>';
    row.appendChild(desk);
    var mob = document.createElement("div");
    mob.className = "md:hidden p-3";
    mob.innerHTML = '<div class="flex items-center gap-3"><div class="' + rc + ' font-bold text-sm">#' + f.rank + '</div>' +
      '<img src="' + f.img + '" class="w-8 h-8 rounded-full">' +
      '<div class="flex-1"><div class="text-white text-sm font-medium">' + f.name + '</div>' +
      '<div class="flex justify-between mt-1"><span class="bg-[#23153e] text-purple-300 px-2 py-0.5 rounded text-xs">Level ' + f.level + '</span>' +
      '<span class="text-white font-semibold text-xs">' + f.xp.toLocaleString() + ' XP · ' + coins + ' 🪙</span></div></div></div>';
    row.appendChild(mob);
    container.appendChild(row);
  });
  btn.innerHTML = "Hide Full Leaderboard ↑";
  fullLBExpanded = true;
}

document.addEventListener("DOMContentLoaded", async function() {
  await getData(); // load real registered users (or fallback)
  await renderPodium();
  await renderRows4to6();
  await renderTopEarners();
});

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
