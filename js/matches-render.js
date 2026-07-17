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
  // Per-sport hero backgrounds (each slide reflects its own sport) — local assets
  const SPORT_BG = {
    cricket:     "assets/cricket bg.jpg",
    football:    "assets/fotball bg.jpeg",
    basketball:  "assets/background.jpg",
    tennis:      "assets/tennis bg.jpg",
    baseball:    "assets/baseball bg.jpg",
    hockey:      "assets/hockey bg.jpg",
    kabaddi:     "assets/kabbadi bg.avif",
    "e-sports":  "assets/esports bg.jpg",
    tabletennis: "assets/table tennis bg.jpg",
    volleyball:  "assets/volleyball bg.jpg"
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
  // NOTE: all colors are theme-aware (bg-card-bg / text-on-surface / etc.)
  // so the card is readable in light, dark and every named theme.
  function cardHTML(m, horizontal, compact) {
    const h = team(m.home), a = team(m.away);
    const col = SPORT_COLOR[m.sport] || "blue";
    const label = SPORT_LABEL[m.sport] || m.sport;
    // In a horizontal-scroll carousel, cards need a fixed width so they
    // don't stretch to full container width and break the scroll on mobile.
    // In a vertical list (game pages / live matches) cards must be full width.
    const widthCls = horizontal ? "w-[260px] sm:w-[280px] md:w-[300px] shrink-0 snap-start" : "w-full";
    // Compact cards (horizontal scrollers) are smaller so several fit on screen.
    const pad = compact ? "p-4" : "p-6";
    const headMb = compact ? "mb-4" : "mb-6";
    const logoSize = compact ? "w-9 h-9 sm:w-11 sm:h-11" : "w-12 h-12 sm:w-14 sm:h-14";
    const scoreSize = compact ? "text-base sm:text-lg" : "text-2xl sm:text-3xl md:text-4xl";

    let statusBadge, midBlock, footer;
    if (m.status === "live") {
      statusBadge =
        '<span class="bg-red-500/15 text-red-500 text-[10px] font-bold px-2 py-0.5 rounded flex items-center">' +
        '<span class="w-1.5 h-1.5 bg-red-500 rounded-full mr-1.5 animate-pulse"></span>LIVE</span>';
      const hs = m.score && m.score.home != null ? m.score.home : "0";
      const as = m.score && m.score.away != null ? m.score.away : "0";
      const detail = (m.score && m.score.detail) ? esc(m.score.detail) : "";
      const line = m.statusLine ? esc(m.statusLine) : "";
      midBlock =
        '<div class="grid grid-cols-3 items-center gap-2 mb-8">' +
          '<div class="flex items-center justify-start space-x-2 sm:space-x-3 min-w-0">' +
            '<img alt="' + esc(h.name) + '" class="' + logoSize + ' object-contain shrink-0" src="' + logo(h) + '">' +
            '<div class="min-w-0 text-left"><h2 class="text-on-surface ' + scoreSize + ' font-bold score-home truncate leading-tight">' + esc(hs) + '</h2>' +
            (detail ? '<p class="text-[10px] sm:text-xs text-on-surface-variant font-medium score-detail truncate">' + detail + '</p>' : '') + '</div>' +
          '</div>' +
          '<div class="text-center min-w-0"><span class="text-on-surface-variant font-bold text-sm sm:text-lg md:text-xl">VS</span>' +
            (line ? '<p class="text-emerald-accent text-[10px] sm:text-[11px] font-semibold mt-1 uppercase tracking-wide status-line truncate">' + line + '</p>' : '') + '</div>' +
          '<div class="flex items-center justify-end space-x-2 sm:space-x-3 min-w-0">' +
            '<img alt="' + esc(a.name) + '" class="' + logoSize + ' object-contain shrink-0" src="' + logo(a) + '">' +
            '<div class="min-w-0 text-right"><h2 class="text-on-surface ' + scoreSize + ' font-bold score-away truncate leading-tight">' + esc(as) + '</h2></div>' +
          '</div>' +
        '</div>';
      footer =
        '<div class="flex flex-wrap items-center justify-between gap-3 pt-6 border-t border-border-subtle">' +
          '<div class="flex items-center min-w-0"><span class="text-[11px] text-on-surface-variant font-medium truncate">Real-time · ' + esc(m.rules) + '</span></div>' +
          '<div class="flex flex-wrap gap-2 shrink-0">' +
            '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="bg-emerald-accent/15 border border-emerald-accent/40 text-emerald-accent px-3 py-1.5 rounded-lg text-xs font-bold flex items-center space-x-2 hover:bg-emerald-accent hover:text-black transition-all"><span class="">Live Chat</span></button>' +
            '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="bg-surface-container-low text-on-surface border border-border-subtle px-3 py-1.5 rounded-lg text-xs font-bold flex items-center space-x-2 hover:bg-surface-container-high transition-all"><span class="">Scorecard</span></button>' +
          '</div>' +
        '</div>';
    } else if (m.status === "upcoming") {
      statusBadge = '<span class="bg-yellow-500/15 text-yellow-600 dark:text-yellow-400 text-[10px] font-bold px-2 py-0.5 rounded uppercase">Upcoming</span>';
      const when = (m.date ? esc(m.date) : "") + (m.time ? " · " + esc(m.time) : "");
      midBlock =
        '<div class="grid grid-cols-3 items-center gap-2 mb-8">' +
          '<div class="flex items-center justify-start space-x-1 sm:space-x-2 min-w-0"><img alt="' + esc(h.name) + '" class="' + logoSize + ' object-contain shrink-0" src="' + logo(h) + '"><span class="font-bold text-on-surface text-[11px] sm:text-sm truncate">' + esc(h.name) + '</span></div>' +
          '<div class="text-center min-w-0 px-1"><p class="text-xs sm:text-sm font-bold text-on-surface truncate">' + when + '</p><p class="text-on-surface-variant text-[10px] sm:text-xs truncate">' + esc(m.rules) + '</p></div>' +
          '<div class="flex items-center justify-end space-x-1 sm:space-x-2 min-w-0"><span class="font-bold text-on-surface text-[11px] sm:text-sm truncate">' + esc(a.name) + '</span><img alt="' + esc(a.name) + '" class="' + logoSize + ' object-contain shrink-0" src="' + logo(a) + '"></div>' +
        '</div>';
      footer =
        '<div class="flex flex-wrap items-center justify-between gap-3 pt-6 border-t border-border-subtle">' +
          '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="bg-emerald-accent/15 border border-emerald-accent/40 text-emerald-accent px-3 py-1.5 rounded-lg text-xs font-bold flex items-center space-x-2 hover:bg-emerald-accent hover:text-black transition-all"><span class="">View Details</span></button>' +
          '<button onclick="window.location.href=\'livematches.html\'" class="text-on-surface-variant text-xs font-bold flex items-center space-x-1 hover:text-on-surface"><span class="">View All</span></button>' +
        '</div>';
    } else { // finished
      statusBadge = '<span class="bg-on-surface-variant/15 text-on-surface-variant text-[10px] font-bold px-2 py-0.5 rounded uppercase">Finished</span>';
      const hs = m.score && m.score.home != null ? m.score.home : "—";
      const as = m.score && m.score.away != null ? m.score.away : "—";
      const detail = (m.score && m.score.detail) ? esc(m.score.detail) : "";
      const res = m.result ? esc(m.result) : "";
      midBlock =
        '<div class="grid grid-cols-3 items-center gap-2 mb-8">' +
          '<div class="flex items-center justify-start space-x-2 sm:space-x-3 min-w-0">' +
            '<img alt="' + esc(h.name) + '" class="' + logoSize + ' object-contain shrink-0" src="' + logo(h) + '">' +
            '<div class="min-w-0 text-left"><h2 class="text-on-surface ' + scoreSize + ' font-bold truncate leading-tight">' + esc(hs) + '</h2>' + (detail ? '<p class="text-[10px] sm:text-xs text-on-surface-variant font-medium truncate">' + detail + '</p>' : '') + '</div>' +
          '</div>' +
          '<div class="text-center min-w-0"><span class="text-on-surface-variant font-bold text-sm sm:text-lg md:text-xl">VS</span>' +
            (res ? '<p class="text-emerald-accent text-[10px] sm:text-[11px] font-semibold mt-1 uppercase tracking-wide truncate">' + res + '</p>' : '') + '</div>' +
          '<div class="flex items-center justify-end space-x-2 sm:space-x-3 min-w-0">' +
            '<img alt="' + esc(a.name) + '" class="' + logoSize + ' object-contain shrink-0" src="' + logo(a) + '">' +
            '<div class="min-w-0 text-right"><h2 class="text-on-surface ' + scoreSize + ' font-bold truncate leading-tight">' + esc(as) + '</h2></div>' +
          '</div>' +
        '</div>';
      footer =
        '<div class="flex flex-wrap items-center justify-between gap-3 pt-6 border-t border-border-subtle">' +
          '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="bg-surface-container-low text-on-surface border border-border-subtle px-3 py-1.5 rounded-lg text-xs font-bold flex items-center space-x-2 hover:bg-surface-container-high transition-all"><span class="">Highlights</span></button>' +
          '<button onclick="window.location.href=\'' + linkFor(m) + '\'" class="text-on-surface-variant text-xs font-bold flex items-center space-x-1 hover:text-on-surface"><span class="">View Details</span></button>' +
        '</div>';
    }

    const sub = esc(m.tournament) + (m.stage ? " • " + esc(m.stage) : "") + (m.venue ? " • " + esc(m.venue) : "");
    return (
      '<div class="bg-card-bg rounded-2xl ' + pad + ' border border-border-subtle hover:border-primary transition-all cursor-pointer group h-full ' + widthCls + ' min-w-0 overflow-hidden flex flex-col" ' +
        'data-match-id="' + esc(m.id) + '" data-sport="' + esc(m.sport) + '" data-status="' + esc(m.status) + '" data-tournament="' + esc(m.tournament || m.sport) + '">' +
        '<div class="flex items-center justify-between ' + headMb + '">' +
          '<div class="flex items-center space-x-3">' + statusBadge +
            '<span class="text-xs font-semibold text-on-surface-variant truncate max-w-[140px] sm:max-w-[240px]">' + sub + '</span>' +
          '</div>' +
          '<span class="text-[10px] font-bold uppercase px-2 py-0.5 rounded bg-' + col + '-900/40 text-' + col + '-400">' + esc(label) + '</span>' +
        '</div>' +
        midBlock +
        '<div class="mt-auto">' + footer + '</div>' +
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
        'style="background-image: url(\'' + (SPORT_BG[m.sport] || SPORT_BG.cricket) + '\'); background-size: cover; background-position: center;">' +
        '<div class="absolute inset-0 bg-gradient-to-t from-black/85 via-black/55 to-black/45"></div>' +
        '<div class="relative z-10 flex flex-col h-full">' +
        '<div class="flex justify-between items-start mb-8 md:mb-10">' +
          '<div class="flex items-center space-x-3">' + badge +
            '<span class="text-xs font-medium text-white/90">' + sub + '</span>' +
          '</div>' +
          '<div class="flex items-center space-x-2 backdrop-blur-md px-3 py-1.5 rounded-full border dark:bg-black/40 dark:border-white/10 light:bg-white/40 light:border-slate-200">' +
            '<span class="material-symbols-outlined text-brand-green text-sm">visibility</span>' +
            '<span class="text-xs font-bold text-white">' + (isLive ? 'Live now' : esc(m.status)) + '</span>' +
          '</div>' +
        '</div>' +
        '<div class="flex items-center justify-between px-2 md:px-8 relative">' +
          '<div class="text-center">' +
            '<img alt="' + esc(h.name) + '" class="w-16 h-16 md:w-24 md:h-24 mx-auto drop-shadow-2xl" src="' + logo(h) + '">' +
            '<div class="mt-4"><p class="text-[10px] md:text-sm font-bold text-white/90">' + esc(h.name) + '</p>' +
            '<h3 class="text-2xl md:text-4xl font-black font-headline text-white">' + esc(hs) + '</h3>' +
            (detail ? '<p class="text-[10px] md:text-xs font-medium text-white/70">' + detail + '</p>' : '') + '</div>' +
          '</div>' +
          '<div class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 font-black text-xl md:text-2xl font-headline text-white/70">VS</div>' +
          '<div class="text-center">' +
            '<img alt="' + esc(a.name) + '" class="w-16 h-16 md:w-24 md:h-24 mx-auto drop-shadow-2xl" src="' + logo(a) + '">' +
            '<div class="mt-4"><p class="text-[10px] md:text-sm font-bold text-white/90">' + esc(a.name) + '</p>' +
            '<h3 class="text-2xl md:text-4xl font-black font-headline text-white">' + esc(as) + '</h3></div>' +
          '</div>' +
        '</div>' +
        '<div class="mt-8 md:mt-10 flex flex-col sm:flex-row justify-between items-center space-y-4 sm:space-y-0">' +
          '<div class="space-y-3 text-center sm:text-left"><p class="font-bold text-sm text-emerald-400">' + statusText + '</p></div>' +
          '<a href="' + linkFor(m) + '" class="w-full sm:w-auto bg-brand-green text-black font-bold px-6 py-3 rounded-xl flex items-center justify-center space-x-3 glow-green hover:scale-105 transition-transform shadow-lg shadow-emerald-500/20">' +
            '<span class="font-headline text-sm uppercase tracking-wider">View Match Center</span>' +
            '<span class="material-symbols-outlined text-lg">arrow_forward</span>' +
          '</a>' +
        '</div>' +
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
  // horizontal=true => fixed-width cards for horizontal scrollers (dashboard)
  // horizontal=false => full-width cards for vertical lists (game pages, live matches)
  function renderInto(container, filter, horizontal, compact) {
    let list = MATCHES.slice();
    if (filter === "live") list = list.filter(m => m.status === "live");
    else if (filter === "upcoming") list = list.filter(m => m.status === "upcoming");
    else if (filter === "finished") list = list.filter(m => m.status === "finished");
    else if (filter && filter !== "all") list = list.filter(m => m.sport === filter);

    if (!list.length) {
      container.innerHTML = '<div class="text-center text-gray-500 py-10 text-sm">No matches found.</div>';
      return;
    }
    container.innerHTML = list.map(c => cardHTML(c, horizontal, compact)).join("");
  }

  function init() {
    // 0) dashboard hero carousel (top live match)
    renderDashboardHero();
    // 1) index.html hero carousel grid
    const hero = document.querySelector('[data-purpose="match-card-grid"]');
    if (hero) {
      // keep first 5 as a responsive grid (matches original layout)
      hero.innerHTML = MATCHES.slice(0, 5).map(m => cardHTML(m, false)).join("");
    }
    // 2) every matches-list container (vertical list -> full-width cards)
    document.querySelectorAll('[data-purpose="matches-list"]').forEach(c => {
      const f = c.getAttribute("data-filter") || "all";
      renderInto(c, f, false, false);
    });
    // 3) containers that only want a specific status (horizontal scrollers)
    document.querySelectorAll('[data-purpose="matches-live"]').forEach(c => renderInto(c, "live", true, true));
    document.querySelectorAll('[data-purpose="matches-upcoming"]').forEach(c => renderInto(c, "upcoming", true, true));
    document.querySelectorAll('[data-purpose="matches-finished"]').forEach(c => renderInto(c, "finished", true, true));

    startLiveTicker();
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();

  window.FANCONNECT_renderMatches = { renderInto, cardHTML };
})();

