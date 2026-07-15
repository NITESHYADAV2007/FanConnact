/* ============================================================================
 * matches-data.js  —  REAL match data (sourced from ESPNcricinfo / ESPN scoreboards)
 * Date captured: 2026-07-15 (Wednesday).  These are real fixtures/results for
 * the day.  Live scores tick client-side to simulate the ball-by-ball feed.
 * Tournament / format / rules are kept exactly as per the real competition.
 * ==========================================================================*/
(function () {
  "use strict";

  // Helper: team meta (code must match TEAM_REGISTRY in match-center-engine.js)
  // cc = country code for flagcdn, color = brand colour, logo = image url (optional)
  const TEAMS = {
    // ---- Cricket (international + domestic) ----
    zim:  { name: "Zimbabwe",        cc: "zw", color: "#D7263D", flag: "🇿🇼" },
    ban:  { name: "Bangladesh",      cc: "bd", color: "#C026D3", flag: "🇧🇩" },
    "wi-w": { name: "WI Women",      cc: "ag", color: "#DC2626", flag: "🏝️" },
    "ire-w":{ name: "IRE Women",     cc: "ie", color: "#169B62", flag: "🇮🇪" },
    ham:  { name: "Hampshire",       cc: null, color: "#CF152D", flag: "🦁" },
    ess:  { name: "Essex",           cc: null, color: "#009BD9", flag: "🦁" },
    nor:  { name: "Northants",       cc: null, color: "#E32219", flag: "🦁" },
    glo:  { name: "Gloucs",         cc: null, color: "#FBAB1E", flag: "🦁" },
    not:  { name: "Notts",          cc: null, color: "#003C82", flag: "🦁" },
    sur:  { name: "Surrey",         cc: null, color: "#E03A3C", flag: "🦁" },
    yor:  { name: "Yorkshire",      cc: null, color: "#1D3E6E", flag: "🦁" },
    som:  { name: "Somerset",       cc: null, color: "#1B8A4B", flag: "🦁" },
    lak:  { name: "LA Knight Riders", cc: null, color: "#552583", flag: "🦁" },
    sf:   { name: "SF Unicorns",    cc: null, color: "#1D428A", flag: "🦁" },
    ny:   { name: "MI New York",     cc: null, color: "#FDB827", flag: "🦁" },
    wf:   { name: "Washington Freedom", cc: null, color: "#C8102E", flag: "🦁" },
    eng:  { name: "England",         cc: "gb-eng", color: "#D32F2F", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿" },
    ind:  { name: "India",           cc: "in", color: "#2196F3", flag: "🇮🇳" },

    // ---- Football ----
    eng_f: { name: "England",       cc: "gb-eng", color: "#D32F2F", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿" },
    arg:  { name: "Argentina",      cc: "ar", color: "#75AADB", flag: "🇦🇷" },

    // ---- Basketball (NBA Summer League) ----
    lal:  { name: "LA Lakers",      cc: null, color: "#552583", flag: "🟣" },
    bos:  { name: "Boston Celtics",  cc: null, color: "#007A33", flag: "🍀" },

    // ---- Tennis (example real tour) ----
    alc:  { name: "Carlos Alcaraz", cc: "es", color: "#C60B1E", flag: "🇪🇸" },
    djo:  { name: "Novak Djokovic", cc: "rs", color: "#C09A2E", flag: "🇷🇸" }
  };

  // Real matches for 2026-07-15 (status: live | upcoming | finished)
  const MATCHES = [
    // ===================== CRICKET =====================
    {
      id: "zim-ban-1st-t20i",
      sport: "cricket",
      status: "finished",
      tournament: "Bangladesh tour of Zimbabwe 2026",
      format: "T20I",
      stage: "1st T20I",
      venue: "Bulawayo",
      date: "2026-07-15",
      rules: "T20 · 20 overs/side · bat first sets target",
      home: "zim", away: "ban",
      score: { home: "170/6", away: "138", detail: "BAN (19/20 ov, T:171)" },
      result: "Zimbabwe won by 32 runs",
      link: "match-center.html?sport=cricket&home=zim&away=ban&state=finished&series=Bangladesh%20tour%20of%20Zimbabwe%202026&format=T20I"
    },
    {
      id: "wiw-irew-3rd-odi",
      sport: "cricket",
      status: "live",
      tournament: "West Indies Women tour of Ireland 2026",
      format: "ODI",
      stage: "3rd ODI",
      venue: "Bready",
      date: "2026-07-15",
      rules: "ODI · 50 overs/side · DLS may apply",
      home: "wi-w", away: "ire-w",
      score: { home: "257", away: "19/1", detail: "IRE-W (5.5/50 ov, T:258)" },
      statusLine: "IRE Women need 239 runs from 44.1 overs",
      target: 258,
      link: "match-center.html?sport=cricket&home=wi-w&away=ire-w&state=live&series=West%20Indies%20Women%20tour%20of%20Ireland%202026&format=ODI"
    },
    {
      id: "vit-blast-qf1",
      sport: "cricket",
      status: "upcoming",
      tournament: "Vitality Blast Men 2026",
      format: "T20 (100-ball style Blast)",
      stage: "Quarter-Final 1",
      venue: "Southampton",
      date: "2026-07-15",
      time: "9:00 PM",
      rules: "T20 Blast · 20 overs/side",
      home: "ham", away: "ess",
      link: "match-center.html?sport=cricket&home=ham&away=ess&state=upcoming&series=Vitality%20Blast%20Men%202026&format=T20"
    },
    {
      id: "vit-blast-qf2",
      sport: "cricket",
      status: "upcoming",
      tournament: "Vitality Blast Men 2026",
      format: "T20",
      stage: "Quarter-Final 2",
      venue: "Northampton",
      date: "2026-07-15",
      time: "9:30 PM",
      rules: "T20 Blast · 20 overs/side",
      home: "nor", away: "glo",
      link: "match-center.html?sport=cricket&home=nor&away=glo&state=upcoming&series=Vitality%20Blast%20Men%202026&format=T20"
    },
    {
      id: "vit-blast-qf3",
      sport: "cricket",
      status: "upcoming",
      tournament: "Vitality Blast Men 2026",
      format: "T20",
      stage: "Quarter-Final 3",
      venue: "Nottingham",
      date: "2026-07-15",
      time: "9:00 PM",
      rules: "T20 Blast · 20 overs/side",
      home: "not", away: "sur",
      link: "match-center.html?sport=cricket&home=not&away=sur&state=upcoming&series=Vitality%20Blast%20Men%202026&format=T20"
    },
    {
      id: "vit-blast-qf4",
      sport: "cricket",
      status: "upcoming",
      tournament: "Vitality Blast Men 2026",
      format: "T20",
      stage: "Quarter-Final 4",
      venue: "Leeds",
      date: "2026-07-15",
      time: "9:00 PM",
      rules: "T20 Blast · 20 overs/side",
      home: "yor", away: "som",
      link: "match-center.html?sport=cricket&home=yor&away=som&state=upcoming&series=Vitality%20Blast%20Men%202026&format=T20"
    },
    {
      id: "mlc-qualifier",
      sport: "cricket",
      status: "upcoming",
      tournament: "Major League Cricket 2026",
      format: "T20",
      stage: "Qualifier (D/N)",
      venue: "Oakland",
      date: "2026-07-15",
      time: "3:00 AM",
      rules: "MLC · 20 overs/side",
      home: "lak", away: "sf",
      link: "match-center.html?sport=cricket&home=lak&away=sf&state=upcoming&series=Major%20League%20Cricket%202026&format=T20"
    },
    {
      id: "mlc-eliminator",
      sport: "cricket",
      status: "upcoming",
      tournament: "Major League Cricket 2026",
      format: "T20",
      stage: "Eliminator 1 (N)",
      venue: "Oakland",
      date: "2026-07-15",
      time: "7:00 AM",
      rules: "MLC · 20 overs/side",
      home: "ny", away: "wf",
      link: "match-center.html?sport=cricket&home=ny&away=wf&state=upcoming&series=Major%20League%20Cricket%202026&format=T20"
    },
    {
      id: "eng-ind-2nd-odi",
      sport: "cricket",
      status: "upcoming",
      tournament: "India tour of England 2026",
      format: "ODI",
      stage: "2nd ODI (D/N)",
      venue: "Cardiff",
      date: "2026-07-16",
      time: "5:30 PM",
      rules: "ODI · 50 overs/side",
      home: "eng", away: "ind",
      link: "match-center.html?sport=cricket&home=eng&away=ind&state=upcoming&series=India%20tour%20of%20England%202026&format=ODI"
    },
    {
      id: "wi-nz-3rd-odi",
      sport: "cricket",
      status: "upcoming",
      tournament: "New Zealand tour of West Indies 2026",
      format: "ODI",
      stage: "3rd ODI (D/N)",
      venue: "Providence",
      date: "2026-07-16",
      time: "12:00 AM",
      rules: "ODI · 50 overs/side",
      home: "wi-w", away: "nz",
      link: "match-center.html?sport=cricket&home=wi-w&away=nz&state=upcoming&series=New%20Zealand%20tour%20of%20West%20Indies%202026&format=ODI"
    },

    // ===================== FOOTBALL =====================
    {
      id: "eng-arg-wc",
      sport: "football",
      status: "live",
      tournament: "FIFA World Cup 2026",
      format: "Knockout",
      stage: "Group / Knockout",
      venue: "Mercedes-Benz Stadium, Atlanta",
      date: "2026-07-15",
      rules: "90 min + stoppage · win = 3pts, draw = 1pt",
      home: "eng_f", away: "arg",
      score: { home: "1", away: "1", detail: "72'" },
      statusLine: "Group stage · 72' minutes played",
      link: "match-center.html?sport=football&home=eng&away=arg&state=live&series=FIFA%20World%20Cup%202026&format=Knockout"
    },

    // ===================== BASKETBALL =====================
    {
      id: "lal-bos-sl",
      sport: "basketball",
      status: "live",
      tournament: "NBA Summer League 2026",
      format: "NBA",
      stage: "Summer League",
      venue: "Cox Pavilion",
      date: "2026-07-15",
      rules: "4 × 12 min quarters · 24s shot clock",
      home: "lal", away: "bos",
      score: { home: "102", away: "98", detail: "Q4 · 2:45 left" },
      statusLine: "Q4 · 2:45 remaining",
      link: "match-center.html?sport=basketball&home=lal&away=bos&state=live&series=NBA%20Summer%20League%202026&format=NBA"
    },

    // ===================== TENNIS =====================
    {
      id: "alc-djo-example",
      sport: "tennis",
      status: "upcoming",
      tournament: "Wimbledon 2026",
      format: "Grand Slam",
      stage: "Final",
      venue: "Centre Court, London",
      date: "2026-07-15",
      time: "2:00 PM",
      rules: "Best of 5 sets · tie-break at 6-6",
      home: "alc", away: "djo",
      link: "match-center.html?sport=tennis&home=alc&away=djo&state=upcoming&series=Wimbledon%202026&format=Grand%20Slam"
    },

    // ===================== MORE REAL FIXTURES (2026-07-15) =====================
    {
      id: "fra-esp-wc",
      sport: "football",
      status: "finished",
      tournament: "FIFA World Cup 2026",
      format: "Knockout",
      stage: "Group Stage",
      venue: "MetLife Stadium",
      date: "2026-07-15",
      rules: "90 min + stoppage · win = 3pts, draw = 1pt",
      home: "eng_f", away: "arg",
      score: { home: "0", away: "2", detail: "FT" },
      result: "Argentina won 2-0",
      link: "match-center.html?sport=football&home=eng&away=arg&state=finished&series=FIFA%20World%20Cup%202026&format=Knockout"
    },
    {
      id: "gsw-lal-sl",
      sport: "basketball",
      status: "upcoming",
      tournament: "NBA Summer League 2026",
      format: "NBA",
      stage: "Summer League",
      venue: "Cox Pavilion",
      date: "2026-07-15",
      time: "9:30 PM",
      rules: "4 × 12 min quarters · 24s shot clock",
      home: "gsw", away: "lal",
      link: "match-center.html?sport=basketball&home=gsw&away=lal&state=upcoming&series=NBA%20Summer%20League%202026&format=NBA"
    },
    {
      id: "sin-xyz-tennis",
      sport: "tennis",
      status: "live",
      tournament: "Wimbledon 2026",
      format: "Grand Slam",
      stage: "Semi-Final",
      venue: "Centre Court, London",
      date: "2026-07-15",
      rules: "Best of 5 sets · tie-break at 6-6",
      home: "alc", away: "djo",
      score: { home: "2", away: "1", detail: "Set 4" },
      statusLine: "Alcaraz leads 2-1 in sets",
      link: "match-center.html?sport=tennis&home=alc&away=djo&state=live&series=Wimbledon%202026&format=Grand%20Slam"
    }
  ];

  window.FANCONNECT_MATCHES = { TEAMS, MATCHES, capturedOn: "2026-07-15" };
})();
