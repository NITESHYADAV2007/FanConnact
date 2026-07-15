/* ============================================================================
 * matches-render.js  —  Renders REAL match cards (live / upcoming / finished)
 * into every page from window.FANCONNECT_MATCHES (js/matches-data.js).
 * - Live matches tick their score + clock client-side (simulated ball-by-ball).
 * - Tournament / format / rules are shown exactly as in the real data.
 * - Works for any container marked data-purpose="matches-list" (and the
 *   index.html hero carousel marked data-purpose="match-card-grid").
 * ==========================================================================*/
(function () {
  "use strict";
  const DATA = window.FANCONNECT_MATCHES;
  if (!DATA) { console.warn("[matches] no data"); return; }
  const { TEAMS, MATCHES } = DATA;

  const SPORT_LABEL = {
    cricket: "Cricket", football: "Football", basketball: "Basketball",
    tennis: "Tennis", baseball: "Baseball", hockey: "Hockey",
    kabaddi: "Kabaddi", "e-sports": "E-Sports", tabletennis: "Table Tennis",
    volleyball: "Volleyball"
  };
  const SPORT_COLOR = {
    cricket: "blue", football: "green", basketball: "indigo",
    tennis: "lime", baseball: "amber", hockey: "cyan",
    kabaddi: "orange", "e-sports": "fuchsia", tabletennis: "teal",
    volleyball: "rose"
  };

  function team(code) {
    return TEAMS[code] || { name: code.toUpperCase(), cc: null, color: "#6B7280", flag: "🏳️" };
  }
  // Append real scores to the match-center link so card score == center score
  function linkFor(m) {
    let u = m.link || '';
    if (m.score && m.score.home != null) u += '&hs=' + encodeURIComponent(String(m.score.home));
    if (m.score && m.score.away != null) u += '&as=' + encodeURIComponent(String(m.score.away));
    return u;
  }
  function logo(t) {
    if (t.cc) return "https://flagcdn.com/w80/" + t.cc + ".png";
    return "https://ui-avatars.com/api/?name=" + encodeURIComponent(t.name.replace(/\s+/g, "+")) +
      "&background=" + (t.color || "#6B7280").replace("#", "") + "&color=ffffff&size=64&bold=true";
  }
  function esc(s) { return String(s == null ? "" : s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c])); }

  // ---- build a single card ----
  function cardHTML(m) {
    const h = team(m.home), a = team(m.away);
    const col = SPORT_COLOR[m.sport] || "blue";
    const label = SPORT_LABEL[m.sport] || m.sport;

    let statusBadge, midBlock, footer;
    if (m.status === "live") {
      statusBadge =
        '<span class="bg-red-500/20 text-red-500 text-[10px] font-bold px-2 py-0.5 rounded flex items-center">' +
        '<span class="w-1.5 h-1.5 bg-red-500 rounded-full mr-1.5 animate-pulse"></span>LIVE</span>';
      const hs = m.score && m.score.home != null ? m.score.home : "0";
      const as = m.score && m.score.away != null ? m.score.away : "0";
      const detail = (m.score && m.score.detail) ? esc(m.score.detail) : "";
      const line = m.statusLine ? esc(m.statusLine) : "";
      midBlock =
        '<div class="flex items-center justify-between px-1 sm:px-4 lg:px-12 mb-8">' +
          '<div class="flex items-center space-x-1 sm:space-x-6">' +
            '<img alt="' + esc(h.name) + '" class="w-12 h-12 sm:w-16 sm:h-16 lg:w-20 lg:h-20 object-contain" src="' + logo(h) + '">' +
            '<div><h2 class="text-xl sm:text-2xl font-bold score-home">' + esc(hs) + '</h2>' +
            (detail ? '<p class="text-xs sm:text-sm text-gray-500 font-medium score-detail">' + detail + '</p>' : '') + '</div>' +
          '</div>' +
          '<div class="text-center shrink-0"><span class="text-gray-600 font-bold text-lg sm:text-xl">VS</span>' +
            (line ? '<p class="text-emerald-accent text-[11px] font-semibold mt-2 uppercase tracking-wide status-line">' + line + '</p>' : '') + '</div>' +
          '<div class="flex items-center space-x-1 sm:space-x-6 flex-row-reverse">' +
            '<img alt="' + esc(a.name) + '" class="w-12 h-12 sm:w-16 sm:h-16 lg:w-20 lg:h-20 object-contain ml-2 sm:ml-6" src="' + logo(a) + '">' +
            '<div class="text-right"><h2 class="text-xl sm:text-2xl font-bold score-away">' + esc(as) + '</h2></div>' +
          '</div>' +
        '</div>';
      footer =
        '<div class="flex items-center justify-between pt-6 border-t border-gray-800/50">' +
          '<div class="flex items-center space-x-3"><span class="text-[11px] text-gray-400 font-medium">Real-time · ' + esc(m.rules) + '</span></div>' +
          '<div class="flex space-x-3">' +
            '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="bg-[#161d2b] border border-emerald-accent/50 text-emerald-accent px-4 py-1.5 rounded-lg text-xs font-bold flex items-center space-x-2 hover:bg-emerald-accent hover:text-black transition-all"><span class="">Live Chat</span></button>' +
            '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="bg-gray-800/50 text-white px-4 py-1.5 rounded-lg text-xs font-bold flex items-center space-x-2 hover:bg-gray-700 transition-all"><span class="">Scorecard</span></button>' +
          '</div>' +
        '</div>';
    } else if (m.status === "upcoming") {
      statusBadge = '<span class="bg-yellow-500/20 text-yellow-500 text-[10px] font-bold px-2 py-0.5 rounded uppercase">Upcoming</span>';
      const when = (m.date ? esc(m.date) : "") + (m.time ? " · " + esc(m.time) : "");
      midBlock =
        '<div class="flex items-center justify-between px-1 sm:px-12 mb-8">' +
          '<div class="flex flex-col items-center space-y-1 sm:space-y-3"><img alt="' + esc(h.name) + '" class="w-12 h-12 sm:w-16 sm:h-16 object-contain" src="' + logo(h) + '"><span class="font-bold">' + esc(h.name) + '</span></div>' +
          '<div class="text-center"><p class="text-lg font-bold">' + when + '</p><p class="text-gray-400 text-sm">' + esc(m.rules) + '</p></div>' +
          '<div class="flex flex-col items-center space-y-1 sm:space-y-3"><img alt="' + esc(a.name) + '" class="w-12 h-12 sm:w-16 sm:h-16 object-contain" src="' + logo(a) + '"><span class="font-bold">' + esc(a.name) + '</span></div>' +
        '</div>';
      footer =
        '<div class="flex items-center justify-between pt-6 border-t border-gray-800/50">' +
          '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="bg-[#161d2b] border border-emerald-accent/50 text-emerald-accent px-4 py-1.5 rounded-lg text-xs font-bold flex items-center space-x-2 hover:bg-emerald-accent hover:text-black transition-all"><span class="">View Details</span></button>' +
          '<button onclick="window.location.href=\'livematches.html\'" class="text-gray-400 text-xs font-bold flex items-center space-x-1 hover:text-white"><span class="">View All</span></button>' +
        '</div>';
    } else { // finished
      statusBadge = '<span class="bg-gray-600/20 text-gray-400 text-[10px] font-bold px-2 py-0.5 rounded uppercase">Finished</span>';
      const hs = m.score && m.score.home != null ? m.score.home : "—";
      const as = m.score && m.score.away != null ? m.score.away : "—";
      const detail = (m.score && m.score.detail) ? esc(m.score.detail) : "";
      const res = m.result ? esc(m.result) : "";
      midBlock =
        '<div class="flex items-center justify-between px-1 sm:px-4 lg:px-12 mb-8">' +
          '<div class="flex items-center space-x-1 sm:space-x-6">' +
            '<img alt="' + esc(h.name) + '" class="w-12 h-12 sm:w-16 sm:h-16 lg:w-20 lg:h-20 object-contain" src="' + logo(h) + '">' +
            '<div><h2 class="text-xl sm:text-2xl font-bold">' + esc(hs) + '</h2>' + (detail ? '<p class="text-xs sm:text-sm text-gray-500 font-medium">' + detail + '</p>' : '') + '</div>' +
          '</div>' +
          '<div class="text-center shrink-0"><span class="text-gray-600 font-bold text-lg sm:text-xl">VS</span>' +
            (res ? '<p class="text-emerald-accent text-[11px] font-semibold mt-2 uppercase tracking-wide">' + res + '</p>' : '') + '</div>' +
          '<div class="flex items-center space-x-1 sm:space-x-6 flex-row-reverse">' +
            '<img alt="' + esc(a.name) + '" class="w-12 h-12 sm:w-16 sm:h-16 lg:w-20 lg:h-20 object-contain ml-2 sm:ml-6" src="' + logo(a) + '">' +
            '<div class="text-right"><h2 class="text-xl sm:text-2xl font-bold">' + esc(as) + '</h2></div>' +
          '</div>' +
        '</div>';
      footer =
        '<div class="flex items-center justify-between pt-6 border-t border-gray-800/50">' +
          '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="bg-[#161d2b] border border-gray-700 text-gray-300 px-4 py-1.5 rounded-lg text-xs font-bold flex items-center space-x-2 hover:bg-gray-800 transition-all"><span class="">Highlights</span></button>' +
          '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="text-gray-400 text-xs font-bold flex items-center space-x-1 hover:text-white"><span class="">View Details</span></button>' +
        '</div>';
    }

    const sub = esc(m.tournament) + (m.stage ? " • " + esc(m.stage) : "") + (m.venue ? " • " + esc(m.venue) : "");
    return (
      '<div class="bg-card-bg rounded-2xl p-6 border border-border-subtle hover:border-gray-600 transition-all cursor-pointer group" ' +
        'data-match-id="' + esc(m.id) + '" data-sport="' + esc(m.sport) + '" data-status="' + esc(m.status) + '" data-tournament="' + esc(m.tournament || m.sport) + '">' +
        '<div class="flex items-center justify-between mb-8">' +
          '<div class="flex items-center space-x-3">' + statusBadge +
            '<span class="text-xs font-semibold text-gray-400 truncate max-w-[140px] sm:max-w-[240px]">' + sub + '</span>' +
          '</div>' +
          '<span class="text-[10px] font-bold uppercase px-2 py-0.5 rounded bg-' + col + '-900/50 text-' + col + '-400">' + esc(label) + '</span>' +
        '</div>' +
        midBlock +
        footer +
      '</div>'
    );
  }

  // ---- dashboard hero carousel slide (top live match, else first match) ----
  function heroSlideHTML(m) {
    const h = team(m.home), a = team(m.away);
    const hs = m.score && m.score.home != null ? m.score.home : "0";
    const as = m.score && m.score.away != null ? m.score.away : "0";
    const detail = (m.score && m.score.detail) ? esc(m.score.detail) : "";
    const line = m.statusLine ? esc(m.statusLine) : (m.result ? esc(m.result) : "");
    const isLive = m.status === "live";
    const badge = isLive
      ? '<span class="bg-red-600 text-[10px] font-bold px-2 py-1 rounded uppercase tracking-wider flex items-center text-white"><span class="w-1.5 h-1.5 bg-white rounded-full mr-1.5 animate-pulse"></span> LIVE NOW</span>'
      : '<span class="bg-yellow-500/20 text-yellow-400 text-[10px] font-bold px-2 py-1 rounded uppercase">' + esc(m.status) + '</span>';
    const sub = esc(m.tournament) + (m.format ? ' • ' + esc(m.format) : '') + (m.stage ? ' • ' + esc(m.stage) : '');
    const statusText = isLive ? (line || 'Live') : (m.status === 'upcoming' ? (m.date + (m.time ? ' · ' + m.time : '')) : (line || 'Full Time'));
    return (
      '<div class="hero-gradient min-w-full rounded-3xl p-6 md:p-8 relative overflow-hidden border dark:border-white/5 light:border-gray-200 light:shadow-soft transition-all duration-300 snap-center" ' +
        'style="background-image: linear-gradient(rgba(11,14,17,0.3), rgba(11,14,17,0.6)), url(\'https://images.unsplash.com/photo-1531415074968-036ba1b575da?auto=format&fit=crop&q=80&w=1536\');">' +
        '<div class="flex justify-between items-start mb-8 md:mb-10">' +
          '<div class="flex items-center space-x-3">' + badge +
            '<span class="text-xs font-medium dark:text-gray-300 light:text-slate-500">' + sub + '</span>' +
          '</div>' +
          '<div class="flex items-center space-x-2 backdrop-blur-md px-3 py-1.5 rounded-full border dark:bg-black/40 dark:border-white/10 light:bg-white/40 light:border-slate-200">' +
            '<span class="material-symbols-outlined text-brand-green text-sm">visibility</span>' +
            '<span class="text-xs font-bold dark:text-white light:text-slate-700">' + (isLive ? 'Live now' : esc(m.status)) + '</span>' +
          '</div>' +
        '</div>' +
        '<div class="flex items-center justify-between px-2 md:px-8 relative">' +
          '<div class="text-center">' +
            '<img alt="' + esc(h.name) + '" class="w-16 h-16 md:w-24 md:h-24 mx-auto drop-shadow-2xl" src="' + logo(h) + '">' +
            '<div class="mt-4"><p class="text-[10px] md:text-sm font-bold dark:text-gray-300 light:text-slate-500">' + esc(h.name) + '</p>' +
            '<h3 class="text-2xl md:text-4xl font-black font-headline dark:text-white light:text-slate-900">' + esc(hs) + '</h3>' +
            (detail ? '<p class="text-[10px] md:text-xs font-medium dark:text-gray-400 light:text-slate-400">' + detail + '</p>' : '') + '</div>' +
          '</div>' +
          '<div class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 font-black text-xl md:text-2xl font-headline dark:text-gray-600/50 light:text-slate-300">VS</div>' +
          '<div class="text-center">' +
            '<img alt="' + esc(a.name) + '" class="w-16 h-16 md:w-24 md:h-24 mx-auto drop-shadow-2xl" src="' + logo(a) + '">' +
            '<div class="mt-4"><p class="text-[10px] md:text-sm font-bold dark:text-gray-300 light:text-slate-500">' + esc(a.name) + '</p>' +
            '<h3 class="text-2xl md:text-4xl font-black font-headline dark:text-white light:text-slate-900">' + esc(as) + '</h3></div>' +
          '</div>' +
        '</div>' +
        '<div class="mt-8 md:mt-10 flex flex-col sm:flex-row justify-between items-center space-y-4 sm:space-y-0">' +
          '<div class="space-y-3 text-center sm:text-left"><p class="font-bold text-sm dark:text-brand-green light:text-emerald-600">' + statusText + '</p></div>' +
          '<a href="' + linkFor(m) + '" class="w-full sm:w-auto bg-brand-green text-black font-bold px-6 py-3 rounded-xl flex items-center justify-center space-x-3 glow-green hover:scale-105 transition-transform shadow-lg shadow-emerald-500/20">' +
            '<span class="font-headline text-sm uppercase tracking-wider">View Match Center</span>' +
            '<span class="material-symbols-outlined text-lg">arrow_forward</span>' +
          '</a>' +
        '</div>' +
      '</div>'
    );
  }

  function renderDashboardHero() {
    const car = document.querySelector('[data-purpose="hero-carousel"]');
    if (!car) return;
    // pick top live match; if none, pick first upcoming; else first match
    const live = MATCHES.filter(m => m.status === "live");
    const up = MATCHES.filter(m => m.status === "upcoming");
    const pick = live.length ? live : (up.length ? up : MATCHES);
    if (!pick.length) { car.innerHTML = '<div class="p-8 text-center text-gray-400">No live matches right now.</div>'; return; }
    car.innerHTML = pick.map(heroSlideHTML).join("");
  }

  // ---- live ticking simulation (cricket overs / football minutes) ----
  function startLiveTicker() {
    const lives = MATCHES.filter(m => m.status === "live");
    if (!lives.length) return;
    setInterval(() => {
      lives.forEach(m => {
        const el = document.querySelector('[data-match-id="' + m.id + '"]');
        if (!el) return;
        if (m.sport === "cricket") {
          // bump away (chasing) score a little + advance over
          const sc = m.score;
          if (sc && sc.away != null && /^\d/.test(String(sc.away))) {
            let parts = String(sc.away).split("/");
            let runs = parseInt(parts[0], 10) || 0;
            let wkts = parts[1] != null ? parseInt(parts[1], 10) : 0;
            runs += Math.floor(Math.random() * 3); // 0-2 runs
            if (Math.random() < 0.08) wkts += 1; // occasional wicket
            sc.away = runs + (wkts ? "/" + wkts : "");
            const awayEl = el.querySelector(".score-away");
            if (awayEl) awayEl.textContent = sc.away;
          }
          // advance over in detail like "5.5/50 ov"
          if (sc && sc.detail) {
            const ov = sc.detail.match(/([\d.]+)\/(\d+)/);
            if (ov) {
              let o = parseFloat(ov[1]) + 0.1;
              const max = parseInt(ov[2], 10);
              if (o > max) o = max;
              sc.detail = sc.detail.replace(/[\d.]+\/\d+/, o.toFixed(1) + "/" + max);
              const d = el.querySelector(".score-detail");
              if (d) d.textContent = sc.detail;
            }
          }
          // update need-line
          if (m.target) {
            const cur = parseInt(String(sc.away).split("/")[0], 10) || 0;
            const need = m.target - cur;
            const line = el.querySelector(".status-line");
            if (line && need > 0) line.textContent = "Need " + need + " runs";
          }
        } else if (m.sport === "football" || m.sport === "basketball") {
          const sc = m.score;
          if (sc && sc.detail) {
            const min = sc.detail.match(/(\d+)'/);
            if (min) {
              let mm = parseInt(min[1], 10) + 1;
              sc.detail = sc.detail.replace(/\d+'/, mm + "'");
              const d = el.querySelector(".score-detail");
              if (d) d.textContent = sc.detail;
              const line = el.querySelector(".status-line");
              if (line) line.textContent = "Group stage · " + mm + "' minutes played";
            }
          }
          // occasional goal
          if (Math.random() < 0.05) {
            const who = Math.random() < 0.5 ? "home" : "away";
            const key = who === "home" ? ".score-home" : ".score-away";
            const el2 = el.querySelector(key);
            if (el2) { let v = parseInt(el2.textContent, 10) || 0; el2.textContent = (v + 1); }
          }
        }
      });
    }, 4000);
  }

  // ---- render into a container, optionally filtered ----
  function renderInto(container, filter) {
    let list = MATCHES.slice();
    if (filter === "live") list = list.filter(m => m.status === "live");
    else if (filter === "upcoming") list = list.filter(m => m.status === "upcoming");
    else if (filter === "finished") list = list.filter(m => m.status === "finished");
    else if (filter && filter !== "all") list = list.filter(m => m.sport === filter);

    if (!list.length) {
      container.innerHTML = '<div class="text-center text-gray-500 py-10 text-sm">No matches found.</div>';
      return;
    }
    container.innerHTML = list.map(cardHTML).join("");
  }

  function init() {
    // 0) dashboard hero carousel (top live match)
    renderDashboardHero();
    // 1) index.html hero carousel grid
    const hero = document.querySelector('[data-purpose="match-card-grid"]');
    if (hero) {
      // keep first 5 as a responsive grid (matches original layout)
      hero.innerHTML = MATCHES.slice(0, 5).map(cardHTML).join("");
    }
    // 2) every matches-list container
    document.querySelectorAll('[data-purpose="matches-list"]').forEach(c => {
      const f = c.getAttribute("data-filter") || "all";
      renderInto(c, f);
    });
    // 3) containers that only want a specific status
    document.querySelectorAll('[data-purpose="matches-live"]').forEach(c => renderInto(c, "live"));
    document.querySelectorAll('[data-purpose="matches-upcoming"]').forEach(c => renderInto(c, "upcoming"));
    document.querySelectorAll('[data-purpose="matches-finished"]').forEach(c => renderInto(c, "finished"));

    startLiveTicker();
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();

  window.FANCONNECT_renderMatches = { renderInto, cardHTML };
})();
