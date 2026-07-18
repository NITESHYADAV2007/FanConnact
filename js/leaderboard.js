// Full leaderboard data — REAL registered users from Firestore (users collection) ONLY.
// No static/fake players are ever shown. If Firestore can't be reached, the
// leaderboard renders empty (never fake names).
var leaderboardData = null;
var leaderboardLoaded = false;

// Wait until Firebase handles are exposed on window.__FB__ (set asynchronously
// by js/script.js -> js/firebase-config.js). Returns true once ready.
async function waitForFirebase(timeoutMs) {
  timeoutMs = timeoutMs || 4000;
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (window.__FB__ && window.__FB__.db && window.__FB__.auth) return true;
    await new Promise((r) => setTimeout(r, 100));
  }
  return !!(window.__FB__ && window.__FB__.db);
}

// Load real registered users from Firestore (users collection)
async function loadRealUsers() {
  try {
    const ready = await waitForFirebase();
    if (!ready) throw new Error("Firebase not ready");
    const { collection, getDocs, query, orderBy, limit } = await import(
      "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js"
    );
    const q = query(collection(window.__FB__.db, "users"), orderBy("xp", "desc"), limit(200));
    const snap = await getDocs(q);
    var users = [];
    snap.forEach(function (doc) {
      var d = doc.data();
      var xp = parseInt(d.xp, 10) || 0;
      var level = (window.LevelSystem && window.LevelSystem.levelFromXP)
        ? window.LevelSystem.levelFromXP(xp)
        : (parseInt(d.level, 10) || 1);
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
    // REAL-ONLY: only ever show registered Firestore users. No fake/fallback names.
    var real = await loadRealUsers();
    leaderboardData = real || [];
  }
  return leaderboardData;
}

// Expose a helper so profile.html can show the user's rank vs ALL registered users.
window.FANCONNECT_leaderboard = {
  loadRealUsers: loadRealUsers,
  getData: getData
};

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
    if (!el) return;
    if (!users[idx]) {
      // No real user for this podium slot — clear placeholder content.
      var nameEl = el.querySelector("h2, h3");
      var imgEl = el.querySelector("img");
      var levelEl = el.querySelector("[class*='Level']");
      var xpEl = el.querySelector(".font-black");
      if (nameEl) nameEl.textContent = "—";
      if (imgEl) imgEl.src = "assets/images/default-avatar.png?w=150";
      if (levelEl) levelEl.textContent = "Level 1";
      if (xpEl) xpEl.textContent = "0 XP";
      return;
    }
    var u = users[idx];
    var nameEl2 = el.querySelector("h2, h3");
    var imgEl2 = el.querySelector("img");
    var levelEl2 = el.querySelector("[class*='Level']");
    var xpEl2 = el.querySelector(".font-black");
    if (nameEl2) nameEl2.textContent = u.name;
    if (imgEl2) imgEl2.src = u.img;
    if (levelEl2) levelEl2.textContent = "Level " + u.level;
    if (xpEl2) xpEl2.textContent = u.xp.toLocaleString() + " XP";
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
  if (!rows.length) {
    container.innerHTML = '<div class="px-6 py-8 text-center text-slate-400 text-sm">No fans ranked yet.</div>';
    return;
  }
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
  if (!top5.length) {
    container.innerHTML = '<div class="text-center text-slate-400 text-sm py-4">No fans yet.</div>';
    return;
  }
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
  if (!rows.length) {
    container.innerHTML = '<div class="px-6 py-8 text-center text-slate-400 text-sm">No more fans to show.</div>';
    btn.innerHTML = "Hide Full Leaderboard ↑";
    fullLBExpanded = true;
    return;
  }
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
  await getData(); // load real registered users (real-only)
  await renderPodium();
  await renderRows4to6();
  await renderTopEarners();
  await renderYourRank();
});

// Populate the "Your Rank" sidebar + "Your Row" with the REAL logged-in user.
async function renderYourRank() {
  // Wait for the real profile (set by js/script.js onAuthStateChanged).
  let profile = null;
  for (var i = 0; i < 40; i++) {
    if (window.currentUserProfile && window.currentUserProfile.name) { profile = window.currentUserProfile; break; }
    await new Promise(function(r){ setTimeout(r, 100); });
  }
  if (!profile) profile = { name: "You", username: "", photoURL: "assets/images/default-avatar.png?w=150", level: 1, xp: 0 };

  // Derive XP + level from the real profile (prefer Firestore xp if present).
  var xp = parseInt(profile.xp, 10) || 0;
  var level = (window.LevelSystem && window.LevelSystem.levelFromXP)
    ? window.LevelSystem.levelFromXP(xp)
    : (parseInt(profile.level, 10) || 1);

  // Find this user's rank within the real leaderboard data.
  var data = await getData();
  var rank = data.findIndex(function(u){ return u.uid && profile.uid && u.uid === profile.uid; });
  if (rank < 0) {
    // Match by name as a fallback.
    rank = data.findIndex(function(u){ return u.name === profile.name; });
  }
  rank = rank >= 0 ? rank + 1 : (data.length ? data.length + 1 : 1);
  var total = data.length || 1;

  // Compute next-level progress via LevelSystem.
  var nextXP = (window.LevelSystem && window.LevelSystem.nextLevelXP) ? window.LevelSystem.nextLevelXP(xp) : (xp + 1000);
  var toGo = (window.LevelSystem && window.LevelSystem.xpToNextLevel) ? window.LevelSystem.xpToNextLevel(xp) : 1000;
  var pct = (window.LevelSystem && window.LevelSystem.xpProgress) ? Math.round(window.LevelSystem.xpProgress(xp) * 100) : 0;

  // Sidebar: Your Rank
  var curRank = document.getElementById("currentRank");
  if (curRank) curRank.textContent = rank;
  var totalLabel = document.getElementById("totalUsersLabel");
  if (totalLabel) totalLabel.textContent = "/ " + total.toLocaleString();
  var totalXPEl = document.getElementById("totalXP");
  if (totalXPEl) totalXPEl.textContent = xp.toLocaleString() + " XP";
  var sProg = document.getElementById("sidebar-xpProgress");
  if (sProg) sProg.style.width = pct + "%";
  var sNext = document.getElementById("sidebar-nextLevel");
  if (sNext) sNext.textContent = "Next Level " + (level + 1);
  var sRemain = document.getElementById("sidebar-xpRemaining");
  if (sRemain) sRemain.textContent = toGo.toLocaleString() + " XP to go";

  // Your Row (desktop)
  var rowRank = document.getElementById("yourRowRank");
  if (rowRank) rowRank.textContent = rank;
  var rowName = document.getElementById("yourRowName");
  if (rowName) rowName.textContent = profile.name + (profile.username ? " (@" + profile.username + ")" : "");
  var rowLevel = document.getElementById("yourRowLevel");
  if (rowLevel) rowLevel.textContent = "Level " + level;
  var rowXP = document.getElementById("yourRowXP");
  if (rowXP) rowXP.textContent = xp.toLocaleString() + " XP";
  var rowImg = document.getElementById("yourRowImg");
  if (rowImg) rowImg.src = profile.photoURL || "assets/images/default-avatar.png?w=150";

  // Your Row (mobile)
  var rowRankM = document.getElementById("yourRowRankM");
  if (rowRankM) rowRankM.textContent = "#" + rank;
  var rowNameM = document.getElementById("yourRowNameM");
  if (rowNameM) rowNameM.textContent = profile.name + (profile.username ? " (@" + profile.username + ")" : "");
  var rowLevelM = document.getElementById("yourRowLevelM");
  if (rowLevelM) rowLevelM.textContent = "Level " + level;
  var rowImgM = document.getElementById("yourRowImgM");
  if (rowImgM) rowImgM.src = profile.photoURL || "assets/images/default-avatar.png?w=150";

  var mProg = document.getElementById("xpProgress");
  if (mProg) mProg.style.width = pct + "%";
  var mNext = document.getElementById("nextLevel");
  if (mNext) mNext.textContent = "Next Level " + (level + 1);
  var mRemain = document.getElementById("xpRemaining");
  if (mRemain) mRemain.textContent = toGo.toLocaleString() + " XP to go";
  var mXP = document.getElementById("userXP");
  if (mXP) mXP.textContent = xp.toLocaleString() + " XP";
}
