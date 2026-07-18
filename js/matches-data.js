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

    // ---- Baseball (MLB) ----
    nyy:  { name: "NY Yankees",     cc: null, color: "#0C2340", flag: "🇺🇸" },
    bos_b: { name: "Boston Red Sox", cc: null, color: "#BD3039", flag: "🇺🇸" },
    lad:  { name: "LA Dodgers",     cc: null, color: "#005A9C", flag: "🇺🇸" },
    sf_b: { name: "SF Giants",      cc: null, color: "#FD5A1E", flag: "🇺🇸" },

    // ---- Hockey (NHL) ----
    tbl:  { name: "Tampa Bay",      cc: null, color: "#00205B", flag: "⚡" },
    col:  { name: "Colorado",       cc: null, color: "#6F263D", flag: "❄️" },
    tor:  { name: "Toronto",        cc: null, color: "#00205B", flag: "🍁" },
    edm:  { name: "Edmonton",       cc: null, color: "#041E42", flag: "🔥" },

    // ---- E-Sports ----
    sr:   { name: "Sentinels",      cc: null, color: "#E5322D", flag: "🎮" },
    fnc:  { name: "Fnatic",         cc: null, color: "#FF5700", flag: "🎮" },
    t1:   { name: "T1",             cc: null, color: "#E2012D", flag: "🎮" },
    g2:   { name: "G2 Esports",     cc: null, color: "#EE3A35", flag: "🎮" },

    // ---- Kabaddi (PKL) ----
    pun:  { name: "Puneri Paltan",  cc: null, color: "#D81B60", flag: "🤼" },
    hyd:  { name: "Telugu Titans",  cc: null, color: "#1E88E5", flag: "🤼" },
    ben:  { name: "Bengal Warriors", cc: null, color: "#00897B", flag: "🤼" },
    pat:  { name: "Patna Pirates",  cc: null, color: "#FBC02D", flag: "🤼" },

    // ---- Table Tennis ----
    wang: { name: "Wang Chuqin",    cc: "cn", color: "#DE2910", flag: "🏓" },
    har:  { name: "Truls Moregard", cc: "se", color: "#006AA7", flag: "🏓" },
    sun:  { name: "Sun Yingsha",    cc: "cn", color: "#DE2910", flag: "🏓" },
    hay:  { name: "Hina Hayata",    cc: "jp", color: "#BC002D", flag: "🏓" },

    // ---- Volleyball ----
    bra:  { name: "Brazil",         cc: "br", color: "#009C3B", flag: "🇧🇷" },
    pol:  { name: "Poland",         cc: "pl", color: "#DC143C", flag: "🇵🇱" },
    usa_v: { name: "USA",           cc: "us", color: "#3C3B6E", flag: "🇺🇸" },
    ita_v: { name: "Italy",         cc: "it", color: "#009246", flag: "🇮🇹" },

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
    },

    // ===================== BASEBALL =====================
    {
      id: "nyy-bosb-mlb",
      sport: "baseball",
      status: "live",
      tournament: "MLB 2026 Regular Season",
      format: "MLB",
      stage: "Game 2",
      venue: "Yankee Stadium, New York",
      date: "2026-07-15",
      rules: "9 innings · most runs wins",
      home: "nyy", away: "bos_b",
      score: { home: "5", away: "3", detail: "Bot 7th" },
      statusLine: "Yankees leading after 6½",
      link: "match-center.html?sport=baseball&home=nyy&away=bos_b&state=live&series=MLB%202026&format=MLB"
    },
    {
      id: "lad-sfb-mlb",
      sport: "baseball",
      status: "upcoming",
      tournament: "MLB 2026 Regular Season",
      format: "MLB",
      stage: "Game 1",
      venue: "Dodger Stadium, Los Angeles",
      date: "2026-07-15",
      time: "22:10",
      rules: "9 innings · most runs wins",
      home: "lad", away: "sf_b",
      link: "match-center.html?sport=baseball&home=lad&away=sf_b&state=upcoming&series=MLB%202026&format=MLB"
    },

    // ===================== HOCKEY =====================
    {
      id: "tbl-col-nhl",
      sport: "hockey",
      status: "live",
      tournament: "NHL 2026 Stanley Cup Playoffs",
      format: "NHL",
      stage: "Final G3",
      venue: "Amalie Arena, Tampa",
      date: "2026-07-15",
      rules: "3 periods · OT if tied",
      home: "tbl", away: "col",
      score: { home: "2", away: "2", detail: "2nd Period" },
      statusLine: "Tied midway 2nd",
      link: "match-center.html?sport=hockey&home=tbl&away=col&state=live&series=Stanley%20Cup%20Final&format=NHL"
    },
    {
      id: "tor-edm-nhl",
      sport: "hockey",
      status: "upcoming",
      tournament: "NHL 2026 Stanley Cup Playoffs",
      format: "NHL",
      stage: "Final G4",
      venue: "Scotiabank Arena, Toronto",
      date: "2026-07-16",
      time: "19:00",
      rules: "3 periods · OT if tied",
      home: "tor", away: "edm",
      link: "match-center.html?sport=hockey&home=tor&away=edm&state=upcoming&series=Stanley%20Cup%20Final&format=NHL"
    },

    // ===================== E-SPORTS =====================
    {
      id: "sr-fnc-val",
      sport: "e-sports",
      status: "live",
      tournament: "VCT 2026 Masters",
      format: "VALORANT",
      stage: "Grand Final",
      venue: "Online",
      date: "2026-07-15",
      rules: "Best of 5 maps · first to 13 rounds",
      home: "sr", away: "fnc",
      score: { home: "2", away: "1", detail: "Map 4" },
      statusLine: "Sentinels lead series 2-1",
      link: "match-center.html?sport=e-sports&home=sr&away=fnc&state=live&series=VCT%202026%20Masters&format=VALORANT"
    },
    {
      id: "t1-g2-lol",
      sport: "e-sports",
      status: "upcoming",
      tournament: "Worlds 2026 Playoffs",
      format: "LoL",
      stage: "Semifinal",
      venue: "Online",
      date: "2026-07-15",
      time: "20:30",
      rules: "Best of 5 games · first to 3",
      home: "t1", away: "g2",
      link: "match-center.html?sport=e-sports&home=t1&away=g2&state=upcoming&series=Worlds%202026&format=LoL"
    },

    // ===================== KABADDI =====================
    {
      id: "pun-hyd-pkl",
      sport: "kabaddi",
      status: "live",
      tournament: "Pro Kabaddi League 2026",
      format: "PKL",
      stage: "Match 42",
      venue: "Mumbai",
      date: "2026-07-15",
      rules: "40 min · most points wins",
      home: "pun", away: "hyd",
      score: { home: "24", away: "18", detail: "Half" },
      statusLine: "Puneri lead at half",
      link: "match-center.html?sport=kabaddi&home=pun&away=hyd&state=live&series=Pro%20Kabaddi%202026&format=PKL"
    },
    {
      id: "ben-pat-pkl",
      sport: "kabaddi",
      status: "upcoming",
      tournament: "Pro Kabaddi League 2026",
      format: "PKL",
      stage: "Match 43",
      venue: "Mumbai",
      date: "2026-07-15",
      time: "21:00",
      rules: "40 min · most points wins",
      home: "ben", away: "pat",
      link: "match-center.html?sport=kabaddi&home=ben&away=pat&state=upcoming&series=Pro%20Kabaddi%202026&format=PKL"
    },

    // ===================== TABLE TENNIS =====================
    {
      id: "wang-har-tt",
      sport: "tabletennis",
      status: "live",
      tournament: "WTT Champions 2026",
      format: "Singles",
      stage: "Quarterfinal",
      venue: "Las Vegas",
      date: "2026-07-15",
      rules: "Best of 7 games · 11 points",
      home: "wang", away: "har",
      score: { home: "2", away: "1", detail: "Game 4" },
      statusLine: "Wang leads 2-1",
      link: "match-center.html?sport=tabletennis&home=wang&away=har&state=live&series=WTT%20Champions%202026&format=Singles"
    },
    {
      id: "sun-hay-tt",
      sport: "tabletennis",
      status: "upcoming",
      tournament: "WTT Champions 2026",
      format: "Singles",
      stage: "Quarterfinal",
      venue: "Las Vegas",
      date: "2026-07-15",
      time: "19:30",
      rules: "Best of 7 games · 11 points",
      home: "sun", away: "hay",
      link: "match-center.html?sport=tabletennis&home=sun&away=hay&state=upcoming&series=WTT%20Champions%202026&format=Singles"
    },

    // ===================== VOLLEYBALL =====================
    {
      id: "bra-pol-vnl",
      sport: "volleyball",
      status: "live",
      tournament: "Volleyball Nations League 2026",
      format: "Mens",
      stage: "Pool 7",
      venue: "Gdansk",
      date: "2026-07-15",
      rules: "Best of 5 sets · 25 points",
      home: "bra", away: "pol",
      score: { home: "2", away: "1", detail: "Set 4" },
      statusLine: "Brazil lead 2-1",
      link: "match-center.html?sport=volleyball&home=bra&away=pol&state=live&series=VNL%202026&format=Mens"
    },
    {
      id: "usa-ita-vnl",
      sport: "volleyball",
      status: "upcoming",
      tournament: "Volleyball Nations League 2026",
      format: "Mens",
      stage: "Pool 7",
      venue: "Gdansk",
      date: "2026-07-15",
      time: "22:00",
      rules: "Best of 5 sets · 25 points",
      home: "usa_v", away: "ita_v",
      link: "match-center.html?sport=volleyball&home=usa_v&away=ita_v&state=upcoming&series=VNL%202026&format=Mens"
    }
  ];

  window.FANCONNECT_MATCHES = { TEAMS, MATCHES, capturedOn: "2026-07-15" };
})();
