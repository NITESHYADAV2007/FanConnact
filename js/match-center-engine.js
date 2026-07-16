// ============================================================================
//  match-center-engine.js
//  Data-driven Match Center. Reads URL params (sport, home, away, state, match)
//  and renders ALL panels (score header, match info, summary, scorecard,
//  commentary, squads, graph, news) for ANY sport / match / state.
//  State: upcoming | live | finished
// ============================================================================
(function () {
  'use strict';
  window.__MC_ENGINE__ = true;

  // ------------------------------------------------------------------ params
  const params = new URLSearchParams(location.search);
  const SPORT = (params.get('sport') || 'cricket').toLowerCase();
  const HOME = (params.get('home') || (SPORT === 'cricket' ? 'ind' : 'home')).toLowerCase();
  const AWAY = (params.get('away') || (SPORT === 'cricket' ? 'eng' : 'away')).toLowerCase();
  const STATE = (params.get('state') || 'finished').toLowerCase();
  // Real scores passed from match cards (e.g. hs=185%2F4&as=165%2F7) — keep card & center consistent
  const HS_PARAM = params.get('hs');
  const AS_PARAM = params.get('as');
  function parseScore(raw) {
    if (!raw) return null;
    const s = decodeURIComponent(raw);
    // cricket "185/4", football "2", tennis "2"
    const m = s.match(/^(\d+)(?:\/(\d+))?/);
    if (!m) return null;
    return { score: m[1], wkts: m[2] != null ? parseInt(m[2], 10) : null };
  }
  const HS = parseScore(HS_PARAM);
  const AS = parseScore(AS_PARAM);
  const MATCHID = params.get('match') || (SPORT + '-' + HOME + '-' + AWAY);
  window.__MC_MATCH_ID__ = MATCHID;
  const SERIES_PARAM = params.get('series') || params.get('tournament') || '';
  const FORMAT_PARAM = params.get('format') || '';

  // ------------------------------------------------------------------ helpers
  function $(id) { return document.getElementById(id); }
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c])); }

  // seeded RNG so a given match always renders the same data
  function rngFrom(str) {
    let h = 2166136261;
    for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619); }
    return function () {
      h += 0x6D2B79F5; let t = h;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  const rng = rngFrom(MATCHID + STATE);
  const ri = (a, b) => Math.floor(rng() * (b - a + 1)) + a;
  const pick = arr => arr[Math.floor(rng() * arr.length)];

  // ------------------------------------------------------------------ teams
  const TEAM_REGISTRY = {
    ind: { name: 'India', flag: '🇮🇳', cc: 'in', color: '#2196F3' },
    eng: { name: 'England', flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', cc: 'gb-eng', color: '#D32F2F' },
    aus: { name: 'Australia', flag: '🇦🇺', cc: 'au', color: '#1B5E20' },
    sa: { name: 'South Africa', flag: '🇿🇦', cc: 'za', color: '#0E7490' },
    nz: { name: 'New Zealand', flag: '🇳🇿', cc: 'nz', color: '#1D4ED8' },
    pak: { name: 'Pakistan', flag: '🇵🇰', cc: 'pk', color: '#16A34A' },
    sl: { name: 'Sri Lanka', flag: '🇱🇰', cc: 'lk', color: '#9333EA' },
    ban: { name: 'Bangladesh', flag: '🇧🇩', cc: 'bd', color: '#C026D3' },
    wi: { name: 'West Indies', flag: '🏝️', cc: 'ag', color: '#DC2626' },
    afg: { name: 'Afghanistan', flag: '🇦🇫', cc: 'af', color: '#2563EB' },
    mi: { name: 'Mumbai Indians', flag: '🦁', cc: null, color: '#045093' },
    csk: { name: 'Chennai Super Kings', flag: '🦁', cc: null, color: '#F9CD05' },
    rcb: { name: 'Royal Challengers Bengaluru', flag: '🦁', cc: null, color: '#EC1C24' },
    kkr: { name: 'Kolkata Knight Riders', flag: '🦁', cc: null, color: '#3B2A7E' },
    liv: { name: 'Liverpool', flag: '🔴', cc: null, color: '#C8102E' },
    mci: { name: 'Manchester City', flag: '🔵', cc: null, color: '#6CABDD' },
    mun: { name: 'Manchester United', flag: '🔴', cc: null, color: '#DA291C' },
    che: { name: 'Chelsea', flag: '🔵', cc: null, color: '#034694' },
    ars: { name: 'Arsenal', flag: '🔴', cc: null, color: '#EF0107' },
    real: { name: 'Real Madrid', flag: '👑', cc: null, color: '#FEBE10' },
    bar: { name: 'Barcelona', flag: '🔵', cc: null, color: '#A50044' },
    lal: { name: 'Los Angeles Lakers', flag: '🟣', cc: null, color: '#552583' },
    gsw: { name: 'Golden State Warriors', flag: '🌉', cc: null, color: '#1D428A' },
    bos: { name: 'Boston Celtics', flag: '🍀', cc: null, color: '#007A33' },
    alc: { name: 'Carlos Alcaraz', flag: '🇪🇸', cc: 'es', color: '#C60B1E' },
    djo: { name: 'Novak Djokovic', flag: '🇷🇸', cc: 'rs', color: '#C09A2E' },
    lad: { name: 'LA Dodgers', flag: '🔵', cc: null, color: '#005A9C' },
    nyy: { name: 'NY Yankees', flag: '🔹', cc: null, color: '#0C2340' },
    wsh: { name: 'Washington Capitals', flag: '🔴', cc: null, color: '#C8102E' },
    vgk: { name: 'Vegas Golden Knights', flag: '⚔️', cc: null, color: '#B4975A' }
  };

  // Real player rosters per team (used for squads, scorecard, commentary, live)
  const REAL_PLAYERS = {
    ind: ['Rohit Sharma','Shubman Gill','Virat Kohli','Shreyas Iyer','KL Rahul','Hardik Pandya','Ravindra Jadeja','Axar Patel','Washington Sundar','Jasprit Bumrah','Mohammed Siraj','Kuldeep Yadav','Rishabh Pant','Yuzvendra Chahal','Shivam Dube'],
    eng: ['Ben Duckett','Jamie Smith','Joe Root','Harry Brook','Jos Buttler','Liam Livingstone','Jacob Bethell','Will Jacks','Adil Rashid','Jofra Archer','Josh Tongue','Sam Curran','Ben Stokes','Mark Wood','Gus Atkinson'],
    aus: ['Travis Head','David Warner','Steve Smith','Marnus Labuschagne','Glenn Maxwell','Mitchell Marsh','Alex Carey','Pat Cummins','Mitchell Starc','Adam Zampa','Josh Hazlewood','Cameron Green'],
    sa: ['Temba Bavuma','Quinton de Kock','Aiden Markram','Heinrich Klaasen','David Miller','Kagiso Rabada','Anrich Nortje','Keshav Maharaj','Lungi Ngidi','Rassie van der Dussen'],
    nz: ['Kane Williamson','Devon Conway','Daryl Mitchell','Tom Latham','Glenn Phillips','Mitchell Santner','Trent Boult','Lockie Ferguson','Tim Southee','Matt Henry'],
    pak: ['Babar Azam','Mohammad Rizwan','Fakhar Zaman','Imam-ul-Haq','Shaheen Afridi','Haris Rauf','Shadab Khan','Naseem Shah','Mohammad Nawaz','Iftikhar Ahmed'],
    sl: ['Pathum Nissanka','Kusal Perera','Kusal Mendis','Charith Asalanka','Wanindu Hasaranga','Maheesh Theekshana','Dhananjaya de Silva','Dimuth Karunaratne'],
    ban: ['Litton Das','Najmul Hossain','Shakib Al Hasan','Mushfiqur Rahim','Towhid Hridoy','Taskin Ahmed','Mustafizur Rahman','Mehidy Hasan'],
    wi: ['Brandon King','Shai Hope','Nicholas Pooran','Rovman Powell','Shimron Hetmyer','Andre Russell','Jason Holder','Alzarri Joseph','Akeal Hosein','Shamar Joseph'],
    afg: ['Rahmanullah Gurbaz','Ibrahim Zadran','Hashmatullah Shahidi','Azmatullah Omarzai','Mohammad Nabi','Rashid Khan','Mujeeb Ur Rahman','Fazalhaq Farooqi','Naveen-ul-Haq'],
    mi: ['Rohit Sharma','Ishan Kishan','Suryakumar Yadav','Tilak Varma','Hardik Pandya','Tim David','Jasprit Bumrah','Trent Boult','Piyush Chawla','Gerald Coetzee','Dewald Brevis','Nehal Wadhera'],
    csk: ['Ruturaj Gaikwad','Devon Conway','Ajinkya Rahane','Shivam Dube','MS Dhoni','Ravindra Jadeja','Sam Curran','Deepak Chahar','Matheesha Pathirana','Maheesh Theekshana','Ambati Rayudu'],
    rcb: ['Virat Kohli','Faf du Plessis','Glenn Maxwell','Cameron Green','Dinesh Karthik','Mohammed Siraj','Yuzvendra Chahal','Wanindu Hasaranga','Josh Hazlewood','Rajat Patidar'],
    kkr: ['Shreyas Iyer','Nitish Rana','Rinku Singh','Andre Russell','Sunil Narine','Venkatesh Iyer','Varun Chakravarthy','Harshit Rana','Phil Salt','Ramandeep Singh'],
    liv: ['Mohamed Salah','Virgil van Dijk','Trent Alexander-Arnold','Alisson','Darwin Nunez','Cody Gakpo','Alexis Mac Allister','Dominik Szoboszlai','Luis Diaz','Andrew Robertson'],
    mci: ['Erling Haaland','Kevin De Bruyne','Phil Foden','Rodri','Bernardo Silva','Kyle Walker','Ederson','Julian Alvarez','Jack Grealish','Ruben Dias'],
    mun: ['Bruno Fernandes','Marcus Rashford','Casemiro','Lisandro Martinez','Alejandro Garnacho','Kobbie Mainoo','Raphael Varane','Andre Onana'],
    che: ['Enzo Fernandez','Cole Palmer','Reece James','Thiago Silva','Raheem Sterling','Nicolas Jackson','Moises Caicedo','Marc Cucurella'],
    ars: ['Bukayo Saka','Martin Odegaard','Declan Rice','Gabriel Jesus','William Saliba','Kai Havertz','Leandro Trossard','Aaron Ramsdale'],
    real: ['Vinicius Jr','Jude Bellingham','Kylian Mbappe','Luka Modric','Toni Kroos','Rodrygo','Antonio Rudiger','Federico Valverde','Eduardo Camavinga'],
    bar: ['Robert Lewandowski','Lamine Yamal','Pedri','Gavi','Frenkie de Jong','Raphinha','Jules Kounde','Marc-Andre ter Stegen','Fermin Lopez'],
    lal: ['LeBron James','Anthony Davis','Luka Doncic','Austin Reaves','D\'Angelo Russell','Rui Hachimura','Jarred Vanderbilt','Gabe Vincent'],
    gsw: ['Stephen Curry','Klay Thompson','Draymond Green','Jimmy Butler','Brandin Podziemski','Jonathan Kuminga','Moses Moody','Buddy Hield'],
    bos: ['Jayson Tatum','Jaylen Brown','Derrick White','Kristaps Porzingis','Jrue Holiday','Al Horford','Payton Pritchard'],
    alc: ['Carlos Alcaraz'],
    djo: ['Novak Djokovic'],
    lad: ['Shohei Ohtani','Mookie Betts','Freddie Freeman','Will Smith','Teoscar Hernandez','Tyler Glasnow','Yoshinobu Yamamoto','Max Muncy'],
    nyy: ['Aaron Judge','Giancarlo Stanton','Juan Soto','Anthony Volpe','Gerrit Cole','Anthony Rizzo','Gleyber Torres','DJ LeMahieu'],
    wsh: ['Alex Ovechkin','Nicklas Backstrom','Tom Wilson','John Carlson','Dylan Strome','Connor McMichael','T.J. Oshie','Martin Fehervary'],
    vgk: ['Jack Eichel','Mark Stone','William Karlsson','Jonathan Marchessault','Shea Theodore','Adin Hill','Tomas Hertl','Pavel Dorofeyev']
  };

  // Build a squad (XI + bench) from real players when available
  function squadFor(code, sport) {
    const real = REAL_PLAYERS[code];
    const names = (real && real.length) ? real.slice() : Array.from({ length: 11 }, () => genName());
    if (sport === 'tennis') {
      const n = names[0] || genName();
      return { xi: [{ n: n, r: 'Player', c: true, wk: false }], bench: [] };
    }
    const n = Math.min(names.length, 11);
    const out = [];
    for (let i = 0; i < n; i++) {
      let r;
      if (i === 0) r = 'Captain';
      else if (i === 1 && sport === 'cricket') r = 'WK-Batter';
      else r = sport === 'cricket' ? pick(['Batter','Batter','All-rounder','Bowler','Bowler']) : 'Player';
      out.push({ n: names[i], r: r, c: i === 0, wk: r === 'WK-Batter' });
    }
    const bench = names.slice(n, n + Math.max(0, names.length - n));
    return { xi: out, bench: bench };
  }

  function teamMeta(code) {
    const t = TEAM_REGISTRY[code];
    if (t) {
      const img = t.cc ? ('https://flagcdn.com/w80/' + t.cc + '.png') :
        ('https://ui-avatars.com/api/?name=' + encodeURIComponent(code.toUpperCase()) + '&background=' + t.color.replace('#', '') + '&color=ffffff&size=64&bold=true');
      return { code: code, name: t.name, flag: t.flag, color: t.color, img: img };
    }
    const name = code.toUpperCase();
    const color = '#6B7280';
    return { code: code, name: name, flag: '🏳️', color: color, img: 'https://ui-avatars.com/api/?name=' + encodeURIComponent(name) + '&background=6B7280&color=ffffff&size=64&bold=true' };
  }

  const HOME_T = teamMeta(HOME);
  const AWAY_T = teamMeta(AWAY);

  // ------------------------------------------------------------------ sport config
  const SPORTS = {
    cricket: { label: 'Cricket', xUnit: 'Overs', xMax: 50, icon: '🏏', isCricket: true },
    football: { label: 'Football', xUnit: 'Min', xMax: 90, icon: '⚽', isBall: false },
    basketball: { label: 'Basketball', xUnit: 'Min', xMax: 48, icon: '🏀', isBall: false },
    tennis: { label: 'Tennis', xUnit: 'Games', xMax: 40, icon: '🎾', isBall: false },
    baseball: { label: 'Baseball', xUnit: 'Inn', xMax: 9, icon: '⚾', isBall: false },
    hockey: { label: 'Hockey', xUnit: 'Min', xMax: 60, icon: '🏒', isBall: false },
    kabaddi: { label: 'Kabaddi', xUnit: 'Min', xMax: 40, icon: '🤼', isKabaddi: true },
    'e-sports': { label: 'E-Sports', xUnit: 'Min', xMax: 60, icon: '🎮', isKabaddi: true },
    tabletennis: { label: 'Table Tennis', xUnit: 'Games', xMax: 11, icon: '🏓', isBall: false },
    volleyball: { label: 'Volleyball', xUnit: 'Sets', xMax: 5, icon: '🏐', isBall: false }
  };
  const SC = SPORTS[SPORT] || SPORTS.cricket;

  // ------------------------------------------------------------------ rules & regulations (sport-aware, proper for ALL games)
  const RULES = {
    cricket: {
      title: 'Cricket — Rules & Regulations',
      points: [
        'Two teams of 11 players; the side batting tries to score runs while the other bowls and fields.',
        'A match is split into innings; each innings ends when 10 batters are out or the allotted overs are bowled.',
        'Runs are scored by running between the wickets (1 per run) or by hitting boundaries (4 for ground, 6 over the rope).',
        'The bowling side dismisses batters via bowled, caught, LBW, run-out, stumped or hit-wicket.',
        'Overs = 6 legal deliveries. No-balls and wides concede extra runs and a free hit may apply.',
        'Limited-overs (ODI/T20): most runs wins. Test: win by runs or wickets; a draw is possible.'
      ]
    },
    football: {
      title: 'Football — Rules & Regulations',
      points: [
        'Two teams of 11 players aim to score by putting the ball into the opponent’s goal.',
        'A standard match is 90 minutes (two 45-minute halves) plus stoppage time.',
        'Goals scored with any part of the body except the hands/arms (goalkeepers excluded in their box).',
        'Fouls and handballs are penalised with free-kicks; serious offences earn yellow/red cards.',
        'Offside: an attacker ahead of the ball and second-last defender when the ball is played.',
        'Most goals at full time wins; draws stand in league play, extra time/penalties in knockouts.'
      ]
    },
    basketball: {
      title: 'Basketball — Rules & Regulations',
      points: [
        'Two teams of five score by shooting the ball through the opponent’s hoop (2 or 3 points).',
        'NBA games are 48 minutes (four 12-minute quarters); FIBA uses four 10-minute quarters.',
        'A shot inside the arc is worth 2, beyond the three-point line is worth 3; free throws are 1 each.',
        'Players may dribble, pass or shoot; travelling and double-dribble are violations.',
        'Personal fouls (5–6) send opponents to the free-throw line; team fouls trigger bonus shots.',
        'The team with the most points when time expires wins; ties go to overtime.'
      ]
    },
    tennis: {
      title: 'Tennis — Rules & Regulations',
      points: [
        'Singles or doubles; players score points to win games, games to win sets, sets to win the match.',
        'Points run 0 (love), 15, 30, 40; deuce at 40–40 needs two clear points to win the game.',
        'A set is won by the first player to 6 games (with a 2-game margin) or via a tiebreak at 6–6.',
        'Serve must land in the diagonal service box; two faults concede the point (double fault).',
        'Ball may bounce once before a return; touching the net or out-of-bounds loses the point.',
        'Best-of-3 (WTA/most ATP) or best-of-5 (Grand Slam men) sets decides the winner.'
      ]
    },
    baseball: {
      title: 'Baseball — Rules & Regulations',
      points: [
        'Two teams of nine; the batting side scores runs by circling the four bases without being out.',
        'A game is nine innings; the home team bats in the bottom half and wins if ahead after the top of the 9th.',
        'Three outs end a half-inning via strikeout, fly-out or force/tag out on the bases.',
        'A batter gets three strikes (a walk on four balls); a home run scores all runners on base.',
        'Pitchers must deliver from the rubber; balks and illegal pitches advance runners.',
        'If tied after nine innings, extra innings are played until a winner emerges.'
      ]
    },
    hockey: {
      title: 'Ice Hockey — Rules & Regulations',
      points: [
        'Two teams of six (including a goalie) score by putting the puck in the opponent’s net with a stick.',
        'NHL games are 60 minutes (three 20-minute periods); ties go to overtime then a shootout.',
        'Goals count only if struck with the stick below the crossbar and inside the posts.',
        'Body-checking, high-sticking and tripping draw penalties (2, 4 or 5 minutes in the box).',
        'Offside and icing stop play; the offending team faces a face-off in their zone.',
        'Power plays award a man-advantage when a player is serving a penalty.'
      ]
    },
    tabletennis: {
      title: 'Table Tennis — Rules & Regulations',
      points: [
        'Singles or doubles rally using paddles; the ball must bounce once on each side.',
        'A game is won at 11 points (by 2); matches are best-of-5 or best-of-7 games.',
        'Serve alternates every 2 points; the ball must be tossed at least 16 cm straight up.',
        'A let is called if the serve clips the net but still lands in play.',
        'Double hits, failure to return, or hitting the ball off the table loses the point.',
        'In doubles, partners must alternate hits and serve diagonally.'
      ]
    },
    volleyball: {
      title: 'Volleyball — Rules & Regulations',
      points: [
        'Two teams of six rally to ground the ball on the opponent’s court.',
        'A match is best-of-5 sets; sets are to 25 (by 2), the decider to 15.',
        'Three touches per side max (usually bump, set, spike); the same player may not touch twice consecutively.',
        'The ball must cross the net within the antennae and not be caught or thrown.',
        'Rotations move players clockwise after winning a serve from the opponent.',
        'Back-row players may not attack the ball above the net from in front of the attack line.'
      ]
    },
    kabaddi: {
      title: 'Kabaddi — Rules & Regulations',
      points: [
        'Two teams of seven; a “raider” crosses to tag defenders and return without taking a breath.',
        'The raider must chant “kabaddi” continuously while in the opponent’s half.',
        'Tagged defenders are out; a successful raid scores a point and revives prior out teammates.',
        'Defenders earn a point by stopping the raider before they return to their side.',
        'Bonus line gives an extra point when 6+ defenders are on the court.',
        'A match has two 20-minute halves; the side with the most points wins.'
      ]
    },
    'e-sports': {
      title: 'E-Sports — Rules & Regulations',
      points: [
        'Team-based competitive gaming; formats vary by title (5v5, battle royale, 1v1).',
        'Matches are played on official patches with approved hardware and settings.',
        'Objectives differ by game (destroy base, eliminate opponents, capture control points).',
        'Pauses require an admin; intentional disconnects are penalised.',
        'Behavioural rules forbid cheating, scripting, toxicity and collusion.',
        'Series are best-of-3/5; the bracket or league table decides the champion.'
      ]
    }
  };
  const RULE_SET = RULES[SPORT] || RULES.cricket;

  // ------------------------------------------------------------------ name pools
  const FIRST = ['Aarav', 'Vihaan', 'Kabir', 'Reyansh', 'Aditya', 'Sai', 'Arjun', 'Vivaan', 'Liam', 'Noah', 'James', 'Harry', 'Ben', 'Joe', 'Sam', 'Will', 'Marcus', 'Bruno', 'Kevin', 'Leo', 'Rafael', 'Toni', 'Luka', 'Nikola', 'Carlos', 'Novak', 'Jannik', 'Daniil', 'Shohei', 'Aaron', 'Mookie', 'Freddie', 'Alex', 'Connor', 'Tom', 'Jack'];
  const LAST = ['Sharma', 'Kohli', 'Patel', 'Smith', 'Root', 'Brook', 'Buttler', 'Archer', 'Bumrah', 'Siraj', 'Kumar', 'Yadav', 'Duckett', 'Tongue', 'Curran', 'Jacks', 'Rashid', 'Livingstone', 'Bethell', 'Dawson', 'Silva', 'Martinez', 'Fernandes', 'Garcia', 'James', 'Brown', 'Wilson', 'Davis', 'Miller', 'Moore', 'Johnson', 'Williams', 'Anderson', 'Thompson', 'Lee'];
  function genName() { return pick(FIRST) + ' ' + pick(LAST); }
  function genSquad(n) {
    const out = []; const used = {};
    for (let i = 0; i < n; i++) {
      let nm; do { nm = genName(); } while (used[nm]); used[nm] = 1;
      const r = i === 0 ? 'Captain' : pick(['Batter', 'Batter', 'All-rounder', 'Bowler', 'WK-Batter']);
      out.push({ n: nm, r: r, c: i === 0, wk: r === 'WK-Batter' });
    }
    return out;
  }

  // ------------------------------------------------------------------ build MATCH data
  const M = { sport: SPORT, state: STATE, home: HOME_T, away: AWAY_T };

  // meta
  const VENUES = ['Edgbaston, Birmingham', 'Wankhede, Mumbai', 'MCG, Melbourne', 'Lord’s, London', 'Old Trafford, Manchester', 'Eden Gardens, Kolkata', 'Anfield, Liverpool', 'Etihad, Manchester', 'Camp Nou, Barcelona', 'Staples Center, LA', 'Yankee Stadium, NY', 'T-Mobile Arena, Vegas'];
  const SERIES = ['ICC Series 2026', 'League Round ' + ri(1, 30), 'Champions Trophy', 'World Cup 2026', 'Friendly', 'Playoff Game ' + ri(1, 7)];
  M.meta = {
    title: HOME_T.name + ' vs ' + AWAY_T.name,
    sub: SC.label + ' · ' + (SERIES_PARAM || SERIES[0]),
    venue: pick(VENUES),
    date: STATE === 'upcoming' ? 'Starts in ' + ri(2, 48) + 'h ' + ri(1, 59) + 'm' : 'Played ' + ri(1, 28) + ' ' + pick(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']) + ' 2026',
    series: SERIES_PARAM || SERIES[0],
    format: FORMAT_PARAM || SC.label,
    toss: pick([HOME_T.name, AWAY_T.name]) + ' won the toss',
    umpires: pick(['K Dharmasena, M Burns', 'A Wharf, R Illingworth', 'R Tucker, C Gaffaney', 'M Erasmus, J Wilson'])
  };

  // scores
  function genCricketScore(chasing) {
    const runs = ri(120, 320); const wkts = ri(2, 10); const ov = (ri(20, 50)) + (Math.random() < 0.5 ? 0 : 0.1 * ri(1, 5));
    const crr = (runs / ov).toFixed(2);
    return { runs, wkts, ov: ov.toFixed(1), crr, sub: wkts + ' wickets', detail: ov.toFixed(1) + ' Overs · CRR ' + crr };
  }
  function genBallScore() {
    const a = ri(0, 4), b = ri(0, 4);
    const winner = a === b ? -1 : (a > b ? 0 : 1);
    return { a, b, winner };
  }

  if (SC.isCricket) {
    if (STATE === 'upcoming') {
      M.score = {
        home: { score: '—', sub: '', detail: 'Yet to bat' },
        away: { score: '—', sub: '', detail: 'Yet to bat' },
        resultText: 'Match begins soon', subText: M.meta.date, status: 'upcoming', icon: '⏳'
      };
    } else if (STATE === 'live') {
      const h = genCricketScore(false), aw = genCricketScore(false);
      const hScore = HS ? HS.score : h.runs, hWk = HS ? HS.wkts : h.wkts;
      const aScore = AS ? AS.score : aw.runs, aWk = AS ? AS.wkts : aw.wkts;
      const detail = HS && AS ? (HS.wkts != null ? HS.score + '/' + HS.wkts + ' (' + h.ov + ' ov)' : HS.score + ' (' + h.ov + ' ov)') : h.detail;
      M.score = {
        home: { score: hScore, sub: hWk != null ? '/' + hWk : '', detail: detail },
        away: { score: aScore, sub: aWk != null ? '/' + aWk : '', detail: aw.detail },
        resultText: 'Live', subText: 'Target ' + (Math.max(parseInt(hScore,10), parseInt(aScore,10)) + ri(5, 40)), status: 'live', icon: '🔴'
      };
    } else {
      const h = genCricketScore(false), aw = genCricketScore(false);
      const hScore = HS ? HS.score : h.runs, hWk = HS ? HS.wkts : h.wkts;
      const aScore = AS ? AS.score : aw.runs, aWk = AS ? AS.wkts : aw.wkts;
      const homeWon = parseInt(hScore,10) > parseInt(aScore,10);
      const margin = Math.abs(parseInt(hScore,10) - parseInt(aScore,10));
      M.score = {
        home: { score: hScore, sub: hWk != null ? '/' + hWk : '', detail: h.detail, won: homeWon },
        away: { score: aScore, sub: aWk != null ? '/' + aWk : '', detail: aw.detail, won: !homeWon },
        resultText: (homeWon ? HOME_T.name : AWAY_T.name) + ' won by ' + margin + ' runs',
        subText: 'Target ' + (Math.min(parseInt(hScore,10), parseInt(aScore,10)) + ri(1, 30)), status: 'finished', icon: '🏆'
      };
    }
  } else if (SPORT === 'tennis') {
    if (STATE === 'upcoming') {
      M.score = { home: { score: '—', sub: '', detail: '' }, away: { score: '—', sub: '', detail: '' }, resultText: 'Match begins soon', subText: M.meta.date, status: 'upcoming', icon: '⏳' };
    } else if (STATE === 'live') {
      const hs = HS ? parseInt(HS.score,10) : ri(1, 2), as = AS ? parseInt(AS.score,10) : ri(0, 1);
      M.score = { home: { score: hs, sub: ' sets', detail: 'Set ' + (hs + as + 1) }, away: { score: as, sub: ' sets', detail: '' }, resultText: 'Live', subText: 'Set ' + (hs + as + 1), status: 'live', icon: '🔴' };
    } else {
      const hs = HS ? parseInt(HS.score,10) : ri(2, 3), as = AS ? parseInt(AS.score,10) : (HS ? 0 : 3 - hs);
      M.score = { home: { score: hs, sub: ' sets', detail: 'Winner', won: hs > as }, away: { score: as, sub: ' sets', detail: '', won: as > hs }, resultText: (hs > as ? HOME_T.name : AWAY_T.name) + ' won', subText: hs + '–' + as + ' sets', status: 'finished', icon: '🏆' };
    }
  } else {
    // football / basketball / baseball / hockey
    const s = genBallScore();
    if (STATE === 'upcoming') {
      M.score = { home: { score: '0', sub: '', detail: '' }, away: { score: '0', sub: '', detail: '' }, resultText: 'Match begins soon', subText: M.meta.date, status: 'upcoming', icon: '⏳' };
    } else if (STATE === 'live') {
      const clock = SPORT === 'basketball' ? 'Q' + ri(1, 4) + ' · ' + ri(1, 11) + ':' + ri(10, 59) : 'Min ' + ri(1, SC.xMax);
      const ha = HS ? HS.score : s.a, aa = AS ? AS.score : s.b;
      M.score = { home: { score: ha, sub: '', detail: clock }, away: { score: aa, sub: '', detail: '' }, resultText: 'Live', subText: clock, status: 'live', icon: '🔴' };
    } else {
      const clock = SPORT === 'basketball' ? 'Final' : (SPORT === 'baseball' ? 'Final' : 'FT');
      const ha = HS ? HS.score : s.a, aa = AS ? AS.score : s.b;
      const winner = ha === aa ? -1 : (ha > aa ? 0 : 1);
      M.score = {
        home: { score: ha, sub: '', detail: clock, won: winner === 0 },
        away: { score: aa, sub: '', detail: '', won: winner === 1 },
        resultText: winner === -1 ? 'Draw ' + ha + '–' + aa : (winner === 0 ? HOME_T.name + ' won' : AWAY_T.name + ' won'),
        subText: clock + ' · ' + ha + '–' + aa, status: 'finished', icon: '🏆'
      };
    }
  }

  // squads + players (needed before summary)
  M.squads = {
    home: squadFor(HOME, SPORT),
    away: squadFor(AWAY, SPORT)
  };
  M.players = {
    home: M.squads.home.xi.map(p => p.n),
    away: M.squads.away.xi.map(p => p.n)
  };

  // summary
  M.summary = {
    resultLine: M.score.resultText,
    sub: M.meta.sub + ' · ' + M.meta.venue,
    points: [
      { i: '🪙', t: '<b>Toss:</b> ' + M.meta.toss + ' and chose to ' + pick(['bat', 'bowl', 'attack', 'push forward']) + ' first.' },
      { i: SC.icon, t: '<b>' + HOME_T.name + ':</b> ' + (SC.isCricket ? ('Scored ' + M.score.home.score + M.score.home.sub + ' in ' + M.score.home.detail + '.') : ('Put ' + M.score.home.score + ' on the board.')) },
      { i: '📊', t: '<b>' + AWAY_T.name + ':</b> ' + (SC.isCricket ? ('Managed ' + M.score.away.score + M.score.away.sub + '.') : ('Finished with ' + M.score.away.score + '.')) },
      { i: '🏆', t: '<b>Result:</b> ' + M.score.resultText + (M.score.subText ? (' — ' + M.score.subText + '.') : '') }
    ],
    performers: [
      { flag: HOME_T.flag, label: 'Top Performer (' + HOME_T.name + ')', name: pick(M.players.home.length ? M.players.home : [genName()]) + ' · ' + ri(20, 120) + (SC.isCricket ? ' runs' : ' pts') },
      { flag: AWAY_T.flag, label: 'Top Performer (' + AWAY_T.name + ')', name: pick(M.players.away.length ? M.players.away : [genName()]) + ' · ' + ri(20, 120) + (SC.isCricket ? ' runs' : ' pts') },
      { flag: '⚡', label: 'Key Moment', name: pick(['A stunning ' + (SC.isCricket ? 'six' : 'strike'), 'A crucial ' + (SC.isCricket ? 'wicket' : 'save'), 'A game-changing ' + (SC.isCricket ? 'catch' : 'pass')]) },
      { flag: '🤝', label: 'Best Partnership', name: pick(M.players.home.length ? M.players.home : [genName()]) + ' & ' + pick(M.players.away.length ? M.players.away : [genName()]) + ' · ' + ri(40, 160) + ' runs' }
    ],
    potm: { name: pick(M.players.home.length ? M.players.home : [genName()]), desc: ri(40, 130) + (SC.isCricket ? ' runs' : ' points') + ' · Player of the Match' }
  };

  // scorecard (sport-aware)
  M.scorecard = buildScorecard();

  // commentary
  M.comm = buildCommentary();

  // graph
  M.graph = buildGraph();

  // news
  M.news = buildNews();

  // info extras
  M.info = {
    formHome: Array.from({ length: 5 }, () => pick(['W', 'L', 'D'])),
    formAway: Array.from({ length: 5 }, () => pick(['W', 'L', 'D'])),
    h2h: { home: ri(2, 8), away: ri(2, 8) },
    weather: { temp: (ri(18, 32)) + '.4', hum: ri(40, 80) + '%', rain: ri(0, 20) + '%', cond: pick(['Sunny', 'Partly Cloudy', 'Clear', 'Humid']) },
    pace: ri(40, 60)
  };

  // ============================================================ builders
  function buildScorecard() {
    if (SC.isCricket) {
      const inn = [HOME_T, AWAY_T].map((tm, idx) => {
        const bat = M.squads[tm.code === HOME ? 'home' : 'away'].xi.slice(0, Math.min(11, M.squads[tm.code === HOME ? 'home' : 'away'].xi.length)).map(p => {
          const r = ri(0, 120), b = ri(5, 90), f = ri(0, 14), sx = ri(0, 6);
          return { n: p.n + (p.c ? ' (C)' : '') + (p.wk ? ' (WK)' : ''), r, b, f, sx, sr: (b ? (r / b * 100).toFixed(2) : '0.00'), out: rng() > 0.4 };
        });
        const bowl = M.squads[tm.code === HOME ? 'home' : 'away'].xi.slice(0, Math.min(6, M.squads[tm.code === HOME ? 'home' : 'away'].xi.length)).map(p => {
          const o = (ri(2, 10) + (Math.random() < 0.5 ? 0 : 0.1 * ri(1, 5))).toFixed(1);
          const r = ri(10, 90), w = ri(0, 5);
          return { n: p.n, o, m: 0, r, w, econ: (r / parseFloat(o)).toFixed(2) };
        });
        const total = bat.reduce((s, x) => s + x.r, 0) + ri(5, 20);
        const wkts = bat.filter(x => x.out).length + ri(0, 2);
        return { team: tm, label: (idx === 0 ? '1st' : '2nd') + ' Innings', bat, bowl, total, wkts, ov: (ri(20, 50) + 0.1 * ri(0, 5)).toFixed(1), crr: (total / 40).toFixed(2) };
      });
      return { type: 'cricket', innings: inn };
    }
    if (SPORT === 'tennis') {
      const sets = ri(3, 5);
      const rows = [];
      for (let i = 0; i < sets; i++) {
        rows.push({ set: i + 1, home: ri(0, 7), away: ri(0, 7), tb: rng() > 0.7 ? ri(5, 9) : null });
      }
      return { type: 'tennis', rows, home: HOME_T, away: AWAY_T };
    }
    if (SPORT === 'baseball') {
      const inn = [];
      for (let i = 1; i <= 9; i++) inn.push({ n: i, home: ri(0, 3), away: ri(0, 3) });
      return { type: 'baseball', innings: inn, home: HOME_T, away: AWAY_T };
    }
    // football / basketball / hockey -> stats comparison + lineups
    const stats = [
      { k: 'Possession', h: ri(30, 70), a: 100 },
      { k: 'Shots', h: ri(5, 25), a: ri(5, 25) },
      { k: 'Shots on Target', h: ri(2, 12), a: ri(2, 12) },
      { k: 'Corners', h: ri(2, 14), a: ri(2, 14) },
      { k: 'Fouls', h: ri(5, 20), a: ri(5, 20) }
    ].map(s => { if (s.k === 'Possession') s.a = 100 - s.h; return s; });
    return { type: 'stats', stats, home: HOME_T, away: AWAY_T };
  }

  function buildCommentary() {
    const items = [];
    if (SC.isCricket) {
      const totalOv = STATE === 'upcoming' ? 0 : ri(15, 50);
      for (let ov = 1; ov <= totalOv; ov++) {
        const balls = 6;
        for (let b = 0; b < balls; b++) {
          const r = rng();
          let type = 'normal', runs = 0, badge = '•';
          if (r > 0.93) { type = 'six'; runs = 6; badge = '6'; }
          else if (r > 0.86) { type = 'four'; runs = 4; badge = '4'; }
          else if (r > 0.82) { type = 'wicket'; runs = 'W'; badge = 'W'; }
          else if (r > 0.78) { type = 'milestone'; runs = 1; badge = '★'; }
          else { runs = ri(0, 3); }
          const striker = pick(M.players.home.concat(M.players.away)), bowler = pick(M.players.home.concat(M.players.away));
          const pool = M.players.home.concat(M.players.away).filter(n => n !== striker);
          const newBat = type === 'wicket' ? pick(pool) : null;
          let text;
          if (type === 'six') text = striker + ' launches ' + bowler + ' over the ropes for a massive six!';
          else if (type === 'four') text = striker + ' cracks ' + bowler + ' through the off side for a boundary.';
          else if (type === 'wicket') text = striker + ' c & b ' + bowler + ' ' + ri(0, 40) + ' (' + ri(1, 30) + '). Wicket! ' + (newBat ? newBat + ' joins the crease.' : '');
          else if (type === 'milestone') text = striker + ' brings up a well-made half-century.';
          else text = runs === 0 ? 'Dot ball. ' + bowler + ' lands it on a good length.' : runs + ' run' + (runs > 1 ? 's' : '') + ' taken.';
          items.push({ over: ov + '.' + b, type, runs, badge, text, striker, bowler, nonstriker: pick(pool), newBatsman: newBat });
        }
      }
    } else if (SPORT === 'tennis') {
      const total = STATE === 'upcoming' ? 0 : ri(10, 40);
      for (let g = 1; g <= total; g++) {
        const r = rng();
        let type = 'normal', badge = '•', text;
        if (r > 0.9) { type = 'six'; badge = 'ACE'; text = pick([HOME_T.name, AWAY_T.name]) + ' fires down an unreturnable ace!'; }
        else if (r > 0.82) { type = 'wicket'; badge = 'BRK'; text = 'Break point converted! ' + pick([HOME_T.name, AWAY_T.name]) + ' breaks serve.'; }
        else if (r > 0.76) { type = 'milestone'; badge = '★'; text = 'A thunderous winner from the baseline.'; }
        else { type = 'normal'; text = 'Rally won, ' + pick([HOME_T.name, AWAY_T.name]) + ' holds serve.'; }
        items.push({ over: 'G' + g, type, runs: badge, badge, text, striker: pick(M.players.home.concat(M.players.away)), bowler: 'Serve' });
      }
    } else {
      const total = STATE === 'upcoming' ? 0 : ri(8, SC.xMax);
      for (let m = 1; m <= total; m++) {
        const r = rng();
        let type = 'normal', badge = '•', text;
        if (r > 0.9) { type = 'six'; badge = 'GOAL'; text = 'GOOOAL! ⚽ ' + pick([HOME_T.name, AWAY_T.name]) + ' find the net!'; }
        else if (r > 0.84) { type = 'four'; badge = 'PTS'; text = pick([HOME_T.name, AWAY_T.name]) + ' score! The crowd erupts.'; }
        else if (r > 0.8) { type = 'wicket'; badge = 'SAVE'; text = 'Brilliant save to deny ' + pick([HOME_T.name, AWAY_T.name]) + '!'; }
        else if (r > 0.76) { type = 'milestone'; badge = '★'; text = 'A moment of magic in the ' + m + (SPORT === 'basketball' ? 'th minute' : 'th minute') + '.'; }
        else { type = 'normal'; text = 'Play resumes. ' + pick([HOME_T.name, AWAY_T.name]) + ' with possession.'; }
        items.push({ over: (SPORT === 'basketball' ? 'Q' + ri(1, 4) + ' ' : '') + m + (SPORT === 'basketball' ? '' : "'"), type, runs: badge, badge, text, striker: pick(M.players.home.concat(M.players.away)), bowler: '—' });
      }
    }
    return { items, label: (SC.isCricket ? 'Ball-by-Ball' : 'Minute-by-Minute') + ' Commentary' };
  }

  function buildGraph() {
    const N = 24;
    const home = [], away = [];
    let h = 50, a = 50;
    for (let i = 0; i <= N; i++) {
      const x = (i / N) * SC.xMax;
      h += (rng() - 0.48) * 8; a = 100 - h + (rng() - 0.5) * 6;
      h = Math.max(5, Math.min(95, h)); a = Math.max(5, Math.min(95, a));
      home.push({ x, v: Math.round(h) }); away.push({ x, v: Math.round(a) });
    }
    return {
      filters: [
        { key: 'momentum', label: SC.label + ' Momentum' },
        { key: 'winprob', label: 'Win Probability' }
      ],
      active: 'momentum',
      home, away,
      xMax: SC.xMax, xUnit: SC.xUnit
    };
  }

  function buildNews() {
    const titles = [
      HOME_T.name + ' name strong XI for ' + M.meta.series,
      AWAY_T.name + ' ' + pick(['stun', 'edge past', 'dominate']) + ' in thrilling contest',
      'Player Watch: ' + genName() + ' in focus ahead of clash',
      SC.label + ' wrap: key takeaways from ' + HOME_T.name + ' vs ' + AWAY_T.name,
      M.meta.toss + ' — what it means for the result',
      'Fan reactions pour in as ' + M.score.resultText.toLowerCase()
    ];
    return {
      source: pick(['ESPN', 'Cricbuzz', 'BBC Sport', 'Sky Sports', 'The Athletic']),
      articles: titles.slice(0, 5).map((t, i) => ({
        title: t,
        desc: 'Latest ' + SC.label.toLowerCase() + ' update covering ' + HOME_T.name + ' and ' + AWAY_T.name + ' from ' + M.meta.venue + '.',
        time: pick(['2h ago', '5h ago', '1d ago', 'Just now', '3h ago']),
        image: i % 2 === 0 ? ('https://images.unsplash.com/photo-' + pick(['1531415074968', '1543326727', '1461896836934', '1574629810360']) + '?w=200') : ''
      }))
    };
  }

  // ============================================================ RENDERERS
  function badgeClass(type) {
    if (type === 'wicket' || type === 'six') return 'bg-red-500 text-white';
    if (type === 'four') return 'bg-crexGold text-white';
    if (type === 'milestone') return 'bg-emerald-500 text-white';
    return 'bg-gray-200 dark:bg-white/10 text-gray-700 dark:text-gray-200';
  }
  // avatar for a player name (initials fallback, team-colored)
  function avatarFor(name, teamCode) {
    const tm = teamMeta(teamCode);
    const initials = name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase();
    return 'https://ui-avatars.com/api/?name=' + encodeURIComponent(initials) + '&background=' + tm.color.replace('#', '') + '&color=ffffff&size=64&bold=true&format=png';
  }
  // crex-style commentary item with avatars + new-batsman on wicket
  function commItemHtml(it) {
    const cls = it.type === 'wicket' ? 'text-red-500' : (it.type === 'four' || it.type === 'six' ? 'text-gray-900 dark:text-white' : '');
    const av = (nm, teamCode, z) => '<a href="player.html" class="relative z-' + z + '"><img alt="' + esc(nm) + '" title="' + esc(nm) + '" class="w-9 h-9 rounded-full border-2 border-white dark:border-[#12172D] cursor-pointer hover:ring-2 hover:ring-crexGold transition" src="' + avatarFor(nm, teamCode) + '"></a>';
    const strikerTeam = M.players.home.indexOf(it.striker) >= 0 ? HOME : (M.players.away.indexOf(it.striker) >= 0 ? AWAY : (rng() > 0.5 ? HOME : AWAY));
    const bowlerTeam = it.bowler && it.bowler !== '—' && it.bowler !== 'Serve' ? (M.players.home.indexOf(it.bowler) >= 0 ? HOME : (M.players.away.indexOf(it.bowler) >= 0 ? AWAY : (rng() > 0.5 ? AWAY : HOME))) : (rng() > 0.5 ? AWAY : HOME);
    let avatars = '';
    if (it.bowler && it.bowler !== '—' && it.bowler !== 'Serve') {
      avatars = '<div class="comm-avatars shrink-0 flex items-center -space-x-2">' + av(it.striker, strikerTeam, 30) + av(it.bowler, bowlerTeam, 20) + (it.nonstriker ? av(it.nonstriker, strikerTeam, 10) : '') + '</div>';
    } else {
      avatars = '<div class="comm-avatars shrink-0 flex items-center -space-x-2">' + av(it.striker, strikerTeam, 30) + '</div>';
    }
    const newBat = it.type === 'wicket' && it.newBatsman
      ? '<div class="mt-1 text-[11px] text-crexGold font-semibold">🏏 New batsman: ' + esc(it.newBatsman) + '</div>' : '';
    return '<div class="comm-item flex gap-3 p-4" data-type="' + it.type + '">' +
      '<span class="shrink-0 w-12 text-right text-xs font-bold ' + (it.type === 'wicket' ? 'text-red-500' : 'text-crexGold') + ' mt-1">' + esc(it.over) + '</span>' +
      avatars +
      '<div class="flex-1 min-w-0"><div class="flex items-center gap-2 mb-1 flex-wrap"><span class="text-xs font-semibold text-gray-800 dark:text-white">' + esc(it.striker) + '</span>' +
      (it.bowler && it.bowler !== '—' && it.bowler !== 'Serve' ? '<span class="text-[10px] text-gray-400">v</span><span class="text-xs font-semibold text-gray-800 dark:text-white">' + esc(it.bowler) + '</span>' : '') +
      '<span class="shrink-0 inline-flex items-center justify-center w-7 h-7 rounded-full ' + badgeClass(it.type) + ' text-xs font-bold">' + esc(it.badge) + '</span></div>' +
      '<div class="text-sm text-gray-700 dark:text-gray-200 ' + cls + '">' + esc(it.text) + '</div>' + newBat + '</div></div>';
  }

  function renderScoreHeader() {
    const sec = $('score-header'); if (!sec) return;
    const st = M.score;
    const statusBadge = st.status === 'live'
      ? '<span class="inline-flex items-center gap-1.5 self-start sm:self-auto px-3 py-1 rounded-full bg-red-500/20 text-red-300 text-[11px] font-semibold border border-red-500/30"><span class="w-1.5 h-1.5 rounded-full bg-red-400 animate-pulse"></span> Live</span>'
      : st.status === 'upcoming'
        ? '<span class="inline-flex items-center gap-1.5 self-start sm:self-auto px-3 py-1 rounded-full bg-blue-500/15 text-blue-300 text-[11px] font-semibold border border-blue-500/30">Upcoming</span>'
        : '<span class="inline-flex items-center gap-1.5 self-start sm:self-auto px-3 py-1 rounded-full bg-emerald-500/15 text-emerald-300 text-[11px] font-semibold border border-emerald-500/30"><span class="w-1.5 h-1.5 rounded-full bg-emerald-400"></span> Result</span>';

    const teamPanel = (tm, sc, reverse) => {
      const won = sc.won;
      const resBadge = st.status === 'finished'
        ? '<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full ' + (won ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-300' : 'bg-red-500/15 text-red-600 dark:text-red-300') + ' text-[10px] font-bold uppercase tracking-wide">' + (won ? 'Won' : 'Lost') + '</span>'
        : '';
      return '<div class="flex items-center gap-4 p-5 md:p-6 ' + (reverse ? 'md:flex-row-reverse md:text-right' : '') + '">' +
        '<img alt="' + esc(tm.name) + '" class="w-14 h-14 md:w-16 md:h-16 rounded-full border-2 border-slate-200 dark:border-white/20 shadow-lg shrink-0" src="' + tm.img + '" onerror="this.src=\'https://ui-avatars.com/api/?name=' + encodeURIComponent(tm.code.toUpperCase()) + '&background=6B7280&color=fff&size=64\'">' +
        '<div class="min-w-0">' +
        '<div class="flex items-center gap-2 ' + (reverse ? 'md:justify-end' : '') + '"><p class="text-base font-semibold text-slate-900 dark:text-white">' + esc(tm.name) + '</p>' + resBadge + '</div>' +
        '<div class="flex items-baseline gap-1.5 mt-1 ' + (reverse ? 'md:justify-end' : '') + '"><span class="score-flash text-4xl md:text-5xl font-extrabold tracking-tight text-slate-900 dark:text-white">' + esc(sc.score) + '</span><span class="text-xl font-semibold text-slate-500 dark:text-gray-300">' + esc(sc.sub) + '</span></div>' +
        '<p class="text-xs text-slate-500 dark:text-gray-400 mt-1 ' + (reverse ? 'md:text-right' : '') + '">' + esc(sc.detail || '') + '</p>' +
        '</div></div>';
    };

    const clockHtml = st.status === 'live'
      ? '<div id="live-clock" class="mt-2 inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-red-500/15 text-red-300 text-[11px] font-bold border border-red-500/30"><span class="w-1.5 h-1.5 rounded-full bg-red-400 animate-pulse"></span><span id="live-clock-text">' + esc(st.subText || 'LIVE') + '</span></div>'
      : '';
    const center = '<div class="flex flex-col items-center justify-center px-4 py-4 md:py-0 md:px-8 border-y md:border-y-0 md:border-x border-gray-200 dark:border-gray-800 bg-slate-50 dark:bg-white/5">' +
      '<div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-crexGold/20 mb-2"><span class="text-2xl">' + st.icon + '</span></div>' +
      '<h2 class="text-crexGold text-center text-lg md:text-xl font-bold leading-tight">' + esc(st.resultText) + '</h2>' +
      '<p class="text-[11px] text-slate-500 dark:text-gray-400 mt-1 text-center">' + esc(st.subText || '') + '</p>' + clockHtml + '</div>';

    sec.innerHTML =
      '<div class="max-w-7xl mx-auto">' +
      '<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-5">' +
      '<p class="text-xs text-gray-300">' + esc(M.meta.sub) + ' &middot; ' + esc(M.meta.venue) + '</p>' + statusBadge +
      '</div>' +
      '<div class="rounded-2xl bg-white text-slate-900 dark:bg-[#12172D] dark:text-white border border-gray-200 dark:border-gray-800 shadow-sm overflow-hidden">' +
      '<div class="grid grid-cols-1 md:grid-cols-[1fr_auto_1fr] items-stretch">' +
      teamPanel(HOME_T, st.home, false) + center + teamPanel(AWAY_T, st.away, true) +
      '</div></div>' +
      '<div id="current-players" class="max-w-7xl mx-auto mt-4 flex flex-wrap items-center justify-center gap-4 sm:gap-8 text-white"></div>' +
      '</div>';

    renderCurrentPlayers();
  }

  function renderCurrentPlayers() {
    const el = $('current-players'); if (!el) return;
    if (STATE !== 'live') { el.innerHTML = ''; return; }
    const homeXI = M.squads.home.xi, awayXI = M.squads.away.xi;
    const homePlayer = homeXI.length ? homeXI[0].n : (M.players.home.length ? M.players.home[0] : genName());
    const awayPlayer = awayXI.length ? awayXI[0].n : (M.players.away.length ? M.players.away[0] : genName());
    const mk = (nm, role, team) => {
      const tm = teamMeta(team);
      const initials = nm.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase();
      const img = 'https://ui-avatars.com/api/?name=' + encodeURIComponent(initials) + '&background=' + tm.color.replace('#', '') + '&color=ffffff&size=64&bold=true&format=png';
      return '<div class="flex items-center gap-2 px-4 py-2 rounded-xl bg-white/10 backdrop-blur"><img alt="' + esc(nm) + '" class="w-9 h-9 rounded-full border border-white/20" src="' + img + '"><div class="text-left leading-tight"><p class="text-xs font-semibold">' + esc(nm) + '</p><p class="text-[10px] text-gray-300">' + esc(role) + '</p></div></div>';
    };
    let roleHome = 'Striker', roleAway = 'Bowler';
    if (SPORT === 'football' || SPORT === 'hockey') { roleHome = 'On Ball'; roleAway = 'Defending'; }
    else if (SPORT === 'basketball') { roleHome = 'With Ball'; roleAway = 'Guarding'; }
    else if (SPORT === 'tennis' || SPORT === 'tabletennis' || SPORT === 'volleyball') { roleHome = 'Serving'; roleAway = 'Receiving'; }
    else if (SPORT === 'kabaddi' || SPORT === 'e-sports') { roleHome = 'Raider'; roleAway = 'Cover'; }
    else if (SPORT === 'baseball') { roleHome = 'At Bat'; roleAway = 'Pitching'; }
    el.innerHTML = mk(homePlayer, roleHome + ' · ' + HOME_T.name, HOME) + mk(awayPlayer, roleAway + ' · ' + AWAY_T.name, AWAY);
  }

  function renderMatchInfo() {
    const p = $('panel-match-info'); if (!p) return;
    const formRow = (tm, form) => '<div class="flex items-center justify-between"><div class="flex items-center space-x-3"><img alt="' + esc(tm.name) + '" class="w-6 h-6 rounded-full" src="' + tm.img + '"><span class="font-medium text-gray-700 dark:text-gray-200">' + esc(tm.name) + '</span></div><div class="flex space-x-1">' + form.map(f => '<span class="w-6 h-6 rounded flex items-center justify-center text-[10px] text-white ' + (f === 'W' ? 'bg-green-500' : f === 'L' ? 'bg-red-500' : 'bg-gray-400') + '">' + f + '</span>').join('') + '</div></div>';
    const h2hTotal = M.info.h2h.home + M.info.h2h.away;
    const h2hPct = Math.round(M.info.h2h.home / h2hTotal * 100);
    p.innerHTML =
      '<div class="col-span-12 lg:col-span-8 space-y-6">' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-5 flex items-start space-x-6"><div class="w-16 h-16 bg-gray-100 dark:bg-white/5 rounded-lg flex items-center justify-center border text-3xl">' + SC.icon + '</div>' +
      '<div class="flex-1"><div class="flex items-center justify-between"><span class="text-xs text-gray-500 dark:text-gray-400">' + esc(M.meta.format) + '</span><span class="text-xs text-blue-600 font-medium">' + esc(HOME_T.code.toUpperCase()) + ' vs ' + esc(AWAY_T.code.toUpperCase()) + ' 2026 &gt;</span></div>' +
      '<div class="mt-4 space-y-2 text-sm text-gray-600 dark:text-gray-300"><div class="flex items-center space-x-3"><span class="w-4">📅</span><span>' + esc(M.meta.date) + '</span></div>' +
      '<div class="flex items-center space-x-3"><span class="w-4">📍</span><span class="text-blue-500">' + esc(M.meta.venue) + '</span></div>' +
      '<div class="flex items-center space-x-3"><span class="w-4">📺</span><span>Broadcast partner</span></div></div></div></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6"><div class="flex justify-between items-center mb-6"><h3 class="font-bold text-gray-800 dark:text-white">' + esc(HOME_T.code.toUpperCase()) + ' &amp; ' + esc(AWAY_T.code.toUpperCase()) + ' Team Form</h3><span class="text-xs text-gray-400">(Last 5)</span></div><div class="space-y-4">' + formRow(HOME_T, M.info.formHome) + formRow(AWAY_T, M.info.formAway) + '</div></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6"><div class="flex justify-between items-center mb-6"><h3 class="font-bold text-gray-800 dark:text-white uppercase text-sm tracking-wide">' + esc(HOME_T.code.toUpperCase()) + ' vs ' + esc(AWAY_T.code.toUpperCase()) + ' Head to Head</h3><span class="text-xs text-gray-400">(Last 10)</span></div>' +
      '<div class="flex items-center justify-between mb-8"><div class="flex flex-col items-center"><img class="w-10 h-10 rounded-full mb-1" src="' + HOME_T.img + '"><span class="font-bold text-gray-800 dark:text-white text-sm">' + esc(HOME_T.code.toUpperCase()) + '</span></div>' +
      '<div class="flex-1 px-8"><div class="flex justify-between mb-1 text-2xl font-bold"><span class="text-blue-500">' + M.info.h2h.home + '</span><span class="text-gray-300">-</span><span class="text-blue-500">' + M.info.h2h.away + '</span></div><div class="w-full h-2 bg-gray-100 dark:bg-white/10 rounded-full flex overflow-hidden"><div class="bg-blue-300" style="width:' + h2hPct + '%"></div><div class="bg-blue-600 flex-1"></div></div></div>' +
      '<div class="flex flex-col items-center"><img class="w-10 h-10 rounded-full mb-1" src="' + AWAY_T.img + '"><span class="font-bold text-gray-800 dark:text-white text-sm">' + esc(AWAY_T.code.toUpperCase()) + '</span></div></div></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase mb-2">' + esc(HOME_T.code.toUpperCase()) + ' vs ' + esc(AWAY_T.code.toUpperCase()) + ' Weather &amp; Pitch Report</h3>' +
      '<p class="text-xs text-gray-500 dark:text-gray-400 mb-6">Weather in ' + esc(M.meta.venue) + ' expected to be ' + M.info.weather.cond + ' with ' + M.info.weather.hum + ' humidity and around ' + M.info.weather.temp + '°C. Rain chance ' + M.info.weather.rain + '.</p>' +
      '<div class="bg-blue-50/50 dark:bg-white/5 rounded-xl p-6 flex flex-wrap items-center justify-between"><div class="flex items-center space-x-4"><div class="w-12 h-12 bg-yellow-400 rounded-full flex items-center justify-center text-2xl">☀️</div><div><p class="text-xs text-gray-500 dark:text-gray-400 font-medium">' + esc(M.meta.venue) + '</p><h4 class="text-3xl font-bold">' + M.info.weather.temp + ' °C</h4></div></div>' +
      '<div class="flex items-center space-x-8 text-sm"><div class="flex items-center"><span class="mr-2">💧</span><span class="text-gray-500 dark:text-gray-400">' + M.info.weather.hum + ' (Humidity)</span></div><div class="flex items-center"><span class="mr-2">🌧️</span><span class="text-gray-500 dark:text-gray-400">' + M.info.weather.rain + ' Chance</span></div></div></div></section>' +
      '</div>' +
      '<aside class="col-span-12 lg:col-span-4 space-y-6">' +
      '<section class="bg-white dark:bg-[#12172D] rounded-xl shadow-sm overflow-hidden border border-gray-200 dark:border-gray-800"><div class="aspect-video w-full overflow-hidden bg-slate-100 dark:bg-slate-800"><img src="https://images.unsplash.com/photo-1531415074968?w=640" alt="Venue" class="w-full h-full object-cover" onerror="this.style.display=\'none\'"></div>' +
      '<div class="p-5 space-y-4"><h3 class="font-bold text-gray-800 dark:text-white uppercase tracking-wide text-sm">Toss &amp; Report</h3>' +
      '<div class="space-y-3"><div class="flex items-start space-x-3 bg-gray-50 dark:bg-white/5 p-3 rounded-lg"><span class="text-crexGold mt-0.5 text-lg">🪙</span><div><p class="text-[11px] font-semibold text-crexGold mb-1 uppercase tracking-wide">Toss Result</p><p class="text-sm text-gray-700 dark:text-gray-200">' + esc(M.meta.toss) + '.</p></div></div>' +
      '<div class="flex items-start space-x-3 bg-gray-50 dark:bg-white/5 p-3 rounded-lg"><span class="text-blue-500 mt-0.5 text-lg">📊</span><div><p class="text-[11px] font-semibold text-blue-500 mb-1 uppercase tracking-wide">Match Context</p><p class="text-sm text-gray-600 dark:text-gray-300">' + esc(M.meta.series) + ' — a key fixture at ' + esc(M.meta.venue) + '.</p></div></div></div></div></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-4">Match Info</h3><div class="space-y-3 text-sm">' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Format</span><span class="font-bold text-gray-800 dark:text-white">' + esc(M.meta.format) + '</span></div>' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Series</span><span class="font-bold text-gray-800 dark:text-white text-right">' + esc(M.meta.series) + '</span></div>' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Venue</span><span class="font-bold text-gray-800 dark:text-white text-right">' + esc(M.meta.venue) + '</span></div>' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Umpires</span><span class="font-bold text-gray-800 dark:text-white text-right">' + esc(M.meta.umpires) + '</span></div></div></section>' +
      '</aside>';
  }

  function renderSummary() {
    const p = $('panel-summary'); if (!p) return;
    const st = M.score;
    const resBadge = st.status === 'finished'
      ? '<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-300 text-[11px] font-semibold border border-emerald-500/30"><span class="w-1.5 h-1.5 rounded-full bg-emerald-400"></span> Result</span>'
      : st.status === 'live' ? '<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-red-500/20 text-red-300 text-[11px] font-semibold border border-red-500/30"><span class="w-1.5 h-1.5 rounded-full bg-red-400 animate-pulse"></span> Live</span>'
        : '<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-500/15 text-blue-300 text-[11px] font-semibold border border-blue-500/30">Upcoming</span>';
    const points = M.summary.points.map(pt => '<li class="flex items-start gap-3"><span class="text-xl mt-0.5">' + pt.i + '</span><span>' + pt.t + '</span></li>').join('');
    const perf = M.summary.performers.map(pf => '<div class="flex items-center gap-3 bg-gray-50 dark:bg-white/5 rounded-lg p-3"><span class="text-2xl">' + pf.flag + '</span><div><p class="text-xs text-gray-400">' + esc(pf.label) + '</p><p class="font-bold text-gray-800 dark:text-white">' + esc(pf.name) + '</p></div></div>').join('');
    p.innerHTML =
      '<div class="col-span-12 lg:col-span-8 space-y-6">' +
      '<section class="rounded-2xl overflow-hidden shadow-lg bg-white dark:bg-[#12172D] border border-gray-200 dark:border-gray-800"><div class="bg-gradient-to-r from-[#0b1626] to-[#1c2e4a] px-6 py-5 flex items-center justify-between"><div class="flex items-center gap-3"><span class="text-3xl">' + st.icon + '</span><div><h2 class="text-white text-xl font-bold leading-tight">' + esc(st.resultText) + '</h2><p class="text-gray-300 text-xs mt-0.5">' + esc(M.summary.sub) + '</p></div></div>' + resBadge + '</div>' +
      '<div class="grid grid-cols-1 md:grid-cols-2 divide-y md:divide-y-0 md:divide-x divide-gray-200 dark:divide-gray-800">' +
      teamSummaryCard(HOME_T, st.home) + teamSummaryCard(AWAY_T, st.away) + '</div></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-4">Match Summary</h3><ul class="space-y-3 text-sm text-gray-600 dark:text-gray-300">' + points + '</ul></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-4">Key Performers</h3><div class="grid grid-cols-1 sm:grid-cols-2 gap-4">' + perf + '</div></section>' +
      (st.status === 'finished' ? '<section class="bg-gradient-to-r from-crexGold/10 to-transparent rounded-lg shadow-sm p-6 border border-crexGold/30"><div class="flex items-center justify-between mb-3"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide">Player of the Match</h3><span class="text-2xl">🏆</span></div><div class="flex items-center gap-4"><div class="w-14 h-14 rounded-full bg-crexGold/20 flex items-center justify-center text-2xl">⭐</div><div><p class="font-bold text-gray-800 dark:text-white">' + esc(M.summary.potm.name) + '</p><p class="text-xs text-gray-500 dark:text-gray-400">' + esc(M.summary.potm.desc) + '</p></div></div></section>' : '') +
      '</div>' +
      '<aside class="col-span-12 lg:col-span-4 space-y-6">' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-4">Result Detail</h3><div class="space-y-3 text-sm">' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Result</span><span class="font-bold ' + (st.status === 'finished' ? 'text-emerald-600 dark:text-emerald-400' : 'text-crexGold') + '">' + esc(st.resultText) + '</span></div>' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Status</span><span class="font-bold text-gray-800 dark:text-white">' + (st.status === 'live' ? 'In Progress' : st.status === 'upcoming' ? 'Not Started' : 'Completed') + '</span></div>' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Toss</span><span class="font-bold text-gray-800 dark:text-white text-right">' + esc(M.meta.toss) + '</span></div></div></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-4">Match Info</h3><div class="space-y-3 text-sm">' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Format</span><span class="font-bold text-gray-800 dark:text-white">' + esc(M.meta.format) + '</span></div>' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Series</span><span class="font-bold text-gray-800 dark:text-white text-right">' + esc(M.meta.series) + '</span></div>' +
      '<div class="flex justify-between"><span class="text-gray-500 dark:text-gray-400">Venue</span><span class="font-bold text-gray-800 dark:text-white text-right">' + esc(M.meta.venue) + '</span></div></div></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-4">About the Teams</h3><div class="space-y-4 text-sm text-gray-600 dark:text-gray-300">' +
      '<div class="flex gap-3"><span class="text-2xl shrink-0">' + HOME_T.flag + '</span><div><p class="font-bold text-gray-800 dark:text-white mb-1">' + esc(HOME_T.name) + '</p><p>One of the leading sides in ' + SC.label.toLowerCase() + ', featuring a balanced squad with proven match-winners.</p></div></div>' +
      '<div class="flex gap-3"><span class="text-2xl shrink-0">' + AWAY_T.flag + '</span><div><p class="font-bold text-gray-800 dark:text-white mb-1">' + esc(AWAY_T.name) + '</p><p>A competitive outfit with depth across the lineup, capable of turning games around.</p></div></div>' +
      '</div></section></aside>';
  }

  function teamSummaryCard(tm, sc) {
    const won = sc.won;
    return '<div class="p-6 flex items-center gap-4"><img alt="' + esc(tm.name) + '" class="w-14 h-14 rounded-full border-2 border-slate-200 dark:border-white/20 shadow" src="' + tm.img + '">' +
      '<div><div class="flex items-center gap-2"><p class="text-base font-semibold text-slate-900 dark:text-white">' + esc(tm.name) + '</p>' +
      (M.score.status === 'finished' ? '<span class="px-2 py-0.5 rounded-full ' + (won ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-300' : 'bg-red-500/15 text-red-600 dark:text-red-300') + ' text-[10px] font-bold uppercase">' + (won ? 'Won' : 'Lost') + '</span>' : '') + '</div>' +
      '<div class="flex items-baseline gap-1.5 mt-1"><span class="text-3xl font-extrabold text-slate-900 dark:text-white">' + esc(sc.score) + '</span><span class="text-lg font-semibold text-slate-500 dark:text-gray-300">' + esc(sc.sub) + '</span></div>' +
      '<p class="text-xs text-slate-500 dark:text-gray-400 mt-1">' + esc(sc.detail || '') + '</p></div></div>';
  }

  function renderScorecard() {
    const p = $('panel-scorecard'); if (!p) return;
    const sc = M.scorecard;
    let html = '<div class="col-span-12 space-y-6">';
    if (sc.type === 'cricket') {
      sc.innings.forEach(inn => {
        const batRows = inn.bat.map(b => '<tr class="border-b border-gray-100 dark:border-gray-800"><td class="py-2 pr-4">' + esc(b.n) + (b.out ? '' : ' <span class="text-emerald-600 dark:text-emerald-400 text-xs font-semibold">NOT OUT</span>') + '</td><td class="py-2 px-2 text-right font-semibold">' + b.r + '</td><td class="py-2 px-2 text-right">' + b.b + '</td><td class="py-2 px-2 text-right">' + b.f + '</td><td class="py-2 px-2 text-right">' + b.sx + '</td><td class="py-2 px-2 text-right">' + b.sr + '</td></tr>').join('');
        const bowlRows = inn.bowl.map(b => '<tr class="border-b border-gray-100 dark:border-gray-800"><td class="py-2 pr-4">' + esc(b.n) + '</td><td class="py-2 px-2 text-right">' + b.o + '</td><td class="py-2 px-2 text-right">' + b.m + '</td><td class="py-2 px-2 text-right">' + b.r + '</td><td class="py-2 px-2 text-right font-semibold text-emerald-600 dark:text-emerald-400">' + b.w + '</td><td class="py-2 px-2 text-right">' + b.econ + '</td></tr>').join('');
        html += '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm overflow-hidden border border-gray-200 dark:border-gray-800"><div class="flex items-center justify-between px-5 py-4 bg-[#0b1626] text-white"><div class="flex items-center gap-3"><img alt="' + esc(inn.team.name) + '" class="w-8 h-8 rounded-full" src="' + inn.team.img + '"><div><h3 class="font-bold text-lg leading-none">' + esc(inn.team.code.toUpperCase()) + '</h3><p class="text-xs text-gray-300 mt-1">' + inn.total + '-' + inn.wkts + ' (' + inn.ov + ')</p></div></div><span class="text-xs text-gray-300">' + inn.label + '</span></div>' +
          '<div class="p-5"><h4 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-3">Batting</h4><div class="overflow-x-auto"><table class="w-full text-sm text-left"><thead><tr class="text-gray-400 text-xs uppercase border-b border-gray-200 dark:border-gray-700"><th class="py-2 pr-4 font-medium">Batter</th><th class="py-2 px-2 font-medium text-right">R</th><th class="py-2 px-2 font-medium text-right">B</th><th class="py-2 px-2 font-medium text-right">4s</th><th class="py-2 px-2 font-medium text-right">6s</th><th class="py-2 px-2 font-medium text-right">SR</th></tr></thead><tbody class="text-gray-700 dark:text-gray-200">' + batRows + '</tbody></table></div></div>' +
          '<div class="p-5 border-t border-gray-200 dark:border-gray-800"><h4 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-3">Bowling</h4><div class="overflow-x-auto"><table class="w-full text-sm text-left"><thead><tr class="text-gray-400 text-xs uppercase border-b border-gray-200 dark:border-gray-700"><th class="py-2 pr-4 font-medium">Bowler</th><th class="py-2 px-2 font-medium text-right">O</th><th class="py-2 px-2 font-medium text-right">M</th><th class="py-2 px-2 font-medium text-right">R</th><th class="py-2 px-2 font-medium text-right">W</th><th class="py-2 px-2 font-medium text-right">Econ</th></tr></thead><tbody class="text-gray-700 dark:text-gray-200">' + bowlRows + '</tbody></table></div></div></section>';
      });
    } else if (sc.type === 'tennis') {
      const rows = sc.rows.map(r => '<tr class="border-b border-gray-100 dark:border-gray-800"><td class="py-2 px-4 font-semibold">' + r.set + '</td><td class="py-2 px-4 text-right">' + r.home + '</td><td class="py-2 px-4 text-right">' + r.away + '</td><td class="py-2 px-4 text-right text-gray-400">' + (r.tb != null ? ('TB ' + r.tb) : '—') + '</td></tr>').join('');
      html += '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm overflow-hidden border border-gray-200 dark:border-gray-800"><div class="p-5"><h4 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-3">' + esc(sc.home.name) + ' vs ' + esc(sc.away.name) + ' — Set Scores</h4><div class="overflow-x-auto"><table class="w-full text-sm text-left"><thead><tr class="text-gray-400 text-xs uppercase border-b border-gray-200 dark:border-gray-700"><th class="py-2 px-4 font-medium">Set</th><th class="py-2 px-4 font-medium text-right">' + esc(sc.home.code.toUpperCase()) + '</th><th class="py-2 px-4 font-medium text-right">' + esc(sc.away.code.toUpperCase()) + '</th><th class="py-2 px-4 font-medium text-right">Tiebreak</th></tr></thead><tbody class="text-gray-700 dark:text-gray-200">' + rows + '</tbody></table></div></div></section>';
    } else if (sc.type === 'baseball') {
      const rows = sc.innings.map(r => '<tr class="border-b border-gray-100 dark:border-gray-800"><td class="py-2 px-4 font-semibold">' + r.n + '</td><td class="py-2 px-4 text-right">' + r.home + '</td><td class="py-2 px-4 text-right">' + r.away + '</td></tr>').join('');
      html += '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm overflow-hidden border border-gray-200 dark:border-gray-800"><div class="p-5"><h4 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-3">Innings Breakdown</h4><div class="overflow-x-auto"><table class="w-full text-sm text-left"><thead><tr class="text-gray-400 text-xs uppercase border-b border-gray-200 dark:border-gray-700"><th class="py-2 px-4 font-medium">Inn</th><th class="py-2 px-4 font-medium text-right">' + esc(sc.home.code.toUpperCase()) + '</th><th class="py-2 px-4 font-medium text-right">' + esc(sc.away.code.toUpperCase()) + '</th></tr></thead><tbody class="text-gray-700 dark:text-gray-200">' + rows + '</tbody></table></div></div></section>';
    } else {
      const rows = sc.stats.map(s => {
        const hp = Math.round(s.h / (s.h + s.a) * 100);
        return '<tr class="border-b border-gray-100 dark:border-gray-800"><td class="py-2 px-4 text-right font-semibold text-gray-800 dark:text-white">' + s.h + '</td><td class="py-2 px-4 text-center text-xs text-gray-400 uppercase">' + s.k + '</td><td class="py-2 px-4 text-right font-semibold text-gray-800 dark:text-white">' + s.a + '</td></tr>' +
          '<tr><td colspan="3" class="py-1"><div class="w-full h-2 bg-gray-100 dark:bg-white/10 rounded-full flex overflow-hidden"><div class="bg-' + sc.home.code + ' h-full" style="width:' + hp + '%"></div><div class="bg-' + sc.away.code + ' h-full" style="width:' + (100 - hp) + '%"></div></div></td></tr>';
      }).join('');
      html += '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm overflow-hidden border border-gray-200 dark:border-gray-800"><div class="p-5"><h4 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-3">Match Stats</h4><div class="overflow-x-auto"><table class="w-full text-sm text-left"><thead><tr class="text-gray-400 text-xs uppercase border-b border-gray-200 dark:border-gray-700"><th class="py-2 px-4 font-medium text-right">' + esc(sc.home.code.toUpperCase()) + '</th><th class="py-2 px-4"></th><th class="py-2 px-4 font-medium text-right">' + esc(sc.away.code.toUpperCase()) + '</th></tr></thead><tbody>' + rows + '</tbody></table></div></div></section>';
    }
    html += '</div>';
    p.innerHTML = html;
  }

  function renderSquads() {
    const p = $('panel-squads'); if (!p) return;
    const squadCol = (tm, key) => {
      const xi = M.squads[key].xi.map(p => {
        const badges = (p.c ? '<span class="text-[10px] font-bold text-crexGold border border-crexGold/40 rounded px-1">C</span>' : '') + (p.wk ? '<span class="text-[10px] font-bold text-blue-500 border border-blue-500/40 rounded px-1">WK</span>' : '');
        return '<a href="player.html" class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group" data-pname="' + esc(p.n) + '" data-pcountry="' + esc(tm.name) + '"><img alt="' + esc(p.n) + '" class="w-8 h-8 rounded-full border border-gray-200 dark:border-white/10 shrink-0" src="https://ui-avatars.com/api/?name=' + encodeURIComponent(p.n.split(' ').map(w => w[0]).join('')) + '&background=' + tm.color.replace('#', '') + '&color=fff&size=64"><div class="min-w-0 flex-1"><div class="flex items-center gap-1.5"><span class="text-sm font-medium text-gray-800 dark:text-white group-hover:text-crexGold truncate">' + esc(p.n) + '</span>' + badges + '</div><p class="text-[11px] text-gray-400 truncate">' + esc(p.r) + '</p></div></a>';
      }).join('');
      const bench = M.squads[key].bench.map(n => '<a href="player.html" class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group" data-pname="' + esc(n) + '" data-pcountry="' + esc(tm.name) + '"><img alt="' + esc(n) + '" class="w-8 h-8 rounded-full border border-gray-200 dark:border-white/10 shrink-0" src="https://ui-avatars.com/api/?name=' + encodeURIComponent(n.split(' ').map(w => w[0]).join('')) + '&background=' + tm.color.replace('#', '') + '&color=fff&size=64"><div class="min-w-0 flex-1"><span class="text-sm font-medium text-gray-800 dark:text-white group-hover:text-crexGold truncate">' + esc(n) + '</span></div></a>').join('');
      return '<div><p class="text-xs font-bold text-gray-500 dark:text-gray-400 mb-2 uppercase tracking-wide">' + esc(tm.name) + '</p><div class="rounded-lg border border-gray-200 dark:border-gray-800 overflow-hidden divide-y divide-gray-100 dark:divide-gray-800">' + xi + '</div><div class="mt-3"><p class="text-[11px] font-semibold text-gray-400 uppercase tracking-wide mb-1">Bench</p><div class="rounded-lg border border-dashed border-gray-200 dark:border-gray-700 overflow-hidden divide-y divide-gray-100 dark:divide-gray-800">' + bench + '</div></div></div>';
    };
    p.innerHTML = '<div class="col-span-12 bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-6">Squads</h3><div id="squads" class="grid grid-cols-1 md:grid-cols-2 gap-8">' + squadCol(HOME_T, 'home') + squadCol(AWAY_T, 'away') + '</div></div>';
    p.querySelectorAll('a[data-pname]').forEach(a => a.addEventListener('click', () => {
      sessionStorage.setItem('playerSport', SC.label);
      sessionStorage.setItem('playerView', JSON.stringify({ player: { name: a.dataset.pname, country: a.dataset.pcountry }, sport: SC.label }));
    }));
  }

  function renderCommentary() {
    const p = $('panel-commentary'); if (!p) return;
    const feed = M.comm.items.map(it => commItemHtml(it)).join('');
    const liveTag = STATE === 'live'
      ? '<span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-red-500/20 text-red-300 text-[11px] font-semibold border border-red-500/30"><span class="w-1.5 h-1.5 rounded-full bg-red-400 animate-pulse"></span> LIVE</span>'
      : '';
    p.innerHTML =
      '<div class="col-span-12 lg:col-span-8 space-y-6">' +
      '<div id="comm-players" class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm border border-gray-200 dark:border-gray-800 p-4 flex items-center gap-4 overflow-x-auto"><span class="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wide shrink-0">' + esc(M.comm.label) + '</span></div>' +
      '<div class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm border border-gray-200 dark:border-gray-800 p-4 flex flex-col sm:flex-row sm:items-center gap-4"><div class="inline-flex rounded-lg overflow-hidden border border-gray-200 dark:border-gray-700" id="comm-filters"><button class="comm-filter px-3.5 py-1.5 text-xs font-semibold rounded-md text-white bg-crexGold" data-filter="all">All</button><button class="comm-filter px-3.5 py-1.5 text-xs font-semibold rounded-md text-gray-500 dark:text-gray-400 hover:text-gray-800 dark:hover:text-white" data-filter="four">4s/PTS</button><button class="comm-filter px-3.5 py-1.5 text-xs font-semibold rounded-md text-gray-500 dark:text-gray-400 hover:text-gray-800 dark:hover:text-white" data-filter="six">6s/GOAL</button><button class="comm-filter px-3.5 py-1.5 text-xs font-semibold rounded-md text-gray-500 dark:text-gray-400 hover:text-gray-800 dark:hover:text-white" data-filter="wicket">Wickets</button><button class="comm-filter px-3.5 py-1.5 text-xs font-semibold rounded-md text-gray-500 dark:text-gray-400 hover:text-gray-800 dark:hover:text-white" data-filter="milestone">Milestones</button></div>' + (STATE === 'live' ? '<span class="text-xs text-gray-400 ml-auto hidden sm:block">Updates every few seconds · scroll for history</span>' : '') + '</div>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm overflow-hidden border border-gray-200 dark:border-gray-800"><div class="flex items-center justify-between px-5 py-4 bg-[#0b1626] text-white"><h3 class="font-bold text-sm uppercase tracking-wide">Commentary</h3>' + liveTag + '<span id="comm-innings-label" class="text-xs text-gray-300">' + esc(M.comm.label) + '</span></div><div id="comm-feed" class="divide-y divide-gray-100 dark:divide-gray-800">' + (feed || '<p class="p-6 text-sm text-gray-400">No commentary yet.</p>') + '</div></section>' +
      '</div>' +
      '<aside class="col-span-12 lg:col-span-4 space-y-6">' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-4">This ' + (SC.isCricket ? 'Over' : 'Minute') + '</h3><div id="this-over-widget"><div class="flex items-center justify-between text-sm mb-2"><span class="text-gray-500 dark:text-gray-400">Over 0</span><span class="font-mono text-emerald-600 dark:text-emerald-400 font-bold">— = 0</span></div><div class="flex gap-1.5"><span class="text-xs text-gray-400">Waiting for first ball…</span></div></div></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-4">Over-by-Over</h3><div id="over-history"><p class="text-xs text-gray-400">Over-by-over summary will appear here.</p></div></section>' +
      '<section class="bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800"><h3 class="font-bold text-gray-800 dark:text-white text-sm uppercase tracking-wide mb-4">Live Positions</h3><div id="live-positions"><p class="text-xs text-gray-400">Live player positions appear here during the match.</p></div></section>' +
      '</aside>';

    // filter handlers
    const feedEl = $('comm-feed');
    p.querySelectorAll('.comm-filter').forEach(btn => btn.addEventListener('click', () => {
      const f = btn.dataset.filter;
      p.querySelectorAll('.comm-filter').forEach(b => { const on = b === btn; b.classList.toggle('bg-crexGold', on); b.classList.toggle('text-white', on); b.classList.toggle('text-gray-500', !on); b.classList.toggle('dark:text-gray-400', !on); });
      feedEl.querySelectorAll('.comm-item').forEach(it => { it.style.display = (f === 'all' || it.dataset.type === f) ? '' : 'none'; });
    }));

    // live loop — only for live matches (score + commentary update live)
    if (STATE === 'live') startLiveLoop(feedEl);
  }

  // Rules & Regulations panel (sport-aware, proper for ALL games)
  function renderRules() {
    const p = $('panel-rules'); if (!p) return;
    const pts = RULE_SET.points.map(pt => '<li class="flex items-start gap-3"><span class="text-crexGold mt-0.5 text-lg">•</span><span class="text-sm text-gray-600 dark:text-gray-300">' + esc(pt) + '</span></li>').join('');
    p.innerHTML =
      '<div class="col-span-12 bg-white dark:bg-[#12172D] rounded-lg shadow-sm p-6 border border-gray-200 dark:border-gray-800">' +
      '<div class="flex items-center gap-3 mb-5"><span class="text-3xl">' + SC.icon + '</span><h3 class="font-bold text-gray-800 dark:text-white text-lg">' + esc(RULE_SET.title) + '</h3></div>' +
      '<ul class="space-y-3" id="rules-list">' + pts + '</ul>' +
      '<p class="text-xs text-gray-400 mt-5">Applies to ' + esc(HOME_T.name) + ' vs ' + esc(AWAY_T.name) + ' · ' + esc(SC.label) + '.</p>' +
      '</div>';
  }

  let liveTimer = null;
  let liveTick = 0;
  function flashScore() {
    const sec = $('score-header'); if (!sec) return;
    sec.querySelectorAll('.score-flash').forEach(el => {
      el.classList.remove('score-flash');
      void el.offsetWidth; // restart animation
      el.classList.add('score-flash');
    });
  }
  // Crex-style floating "score update" toast that pops on every live change
  function showScoreToast(team, delta, label) {
    let host = $('live-toast-host');
    if (!host) {
      host = document.createElement('div');
      host.id = 'live-toast-host';
      host.className = 'fixed z-[120] bottom-5 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 pointer-events-none';
      document.body.appendChild(host);
    }
    const t = document.createElement('div');
    t.className = 'live-toast flex items-center gap-2 px-4 py-2 rounded-full bg-crexGold text-white text-sm font-bold shadow-lg';
    t.innerHTML = '<span class="material-symbols-outlined text-[18px]">sports_cricket</span>' +
      '<span>' + esc(team) + ' ' + (delta > 0 ? '+' : '') + delta + ' &middot; ' + esc(label) + '</span>';
    host.appendChild(t);
    requestAnimationFrame(() => t.classList.add('show'));
    setTimeout(() => { t.classList.remove('show'); setTimeout(() => t.remove(), 400); }, 2600);
  }
  // Pulsing LIVE badge + animated scoreboard header for live matches
  function ensureLiveBanner() {
    const sec = $('score-header'); if (!sec) return;
    if ($('live-banner')) return;
    const banner = document.createElement('div');
    banner.id = 'live-banner';
    banner.className = 'max-w-7xl mx-auto mb-3 flex items-center justify-center gap-2';
    banner.innerHTML =
      '<span class="live-dot"></span>' +
      '<span class="text-crexGold text-xs font-extrabold uppercase tracking-[0.2em]">Live</span>' +
      '<span class="text-gray-300 text-xs">· ball-by-ball updates &amp; commentary</span>';
    const inner = sec.querySelector('.max-w-7xl');
    if (inner) inner.insertBefore(banner, inner.firstChild);
  }
  // ---- Live match clock (ticks forward, valid per sport) ----
  let liveClock = { min: 0, sec: 0, over: 0, ball: 0, quarter: 1, set: 1, inn: 1 };
  function clockLabel() {
    if (SC.isCricket) {
      const ov = liveClock.over, ball = liveClock.ball;
      return ov + '.' + ball + ' ov';
    }
    if (SPORT === 'basketball') return 'Q' + liveClock.quarter + ' · ' + String(liveClock.min).padStart(2, '0') + ':' + String(liveClock.sec).padStart(2, '0');
    if (SPORT === 'tennis' || SPORT === 'tabletennis' || SPORT === 'volleyball') return 'Set ' + liveClock.set + ' · ' + String(liveClock.min).padStart(2, '0') + ':' + String(liveClock.sec).padStart(2, '0');
    if (SPORT === 'baseball') return 'Inn ' + liveClock.inn + ' · ' + String(liveClock.min).padStart(2, '0') + ':' + String(liveClock.sec).padStart(2, '0');
    return String(liveClock.min).padStart(2, '0') + ':' + String(liveClock.sec).padStart(2, '0');
  }
  function clockMaxReached() {
    if (SC.isCricket) return liveClock.over >= SC.xMax;
    if (SPORT === 'basketball') return liveClock.quarter > 4;
    if (SPORT === 'baseball') return liveClock.inn > 9;
    if (SPORT === 'tennis' || SPORT === 'tabletennis' || SPORT === 'volleyball') return liveClock.set > 3;
    return liveClock.min >= SC.xMax;
  }
  function tickClock() {
    if (SC.isCricket) {
      liveClock.ball++;
      if (liveClock.ball >= 6) { liveClock.ball = 0; liveClock.over++; }
    } else if (SPORT === 'basketball') {
      liveClock.sec += 12;
      if (liveClock.sec >= 60) { liveClock.sec = 0; liveClock.min++; }
      if (liveClock.min >= 12) { liveClock.min = 0; liveClock.quarter++; }
    } else if (SPORT === 'baseball') {
      liveClock.sec += 30; if (liveClock.sec >= 60) { liveClock.sec = 0; liveClock.min++; }
      if (liveClock.min >= 5) { liveClock.min = 0; liveClock.inn++; }
    } else if (SPORT === 'tennis' || SPORT === 'tabletennis' || SPORT === 'volleyball') {
      liveClock.sec += 45; if (liveClock.sec >= 60) { liveClock.sec = 0; liveClock.min++; }
      if (liveClock.min >= 10) { liveClock.min = 0; liveClock.set++; }
    } else {
      liveClock.sec += 30; if (liveClock.sec >= 60) { liveClock.sec = 0; liveClock.min++; }
    }
  }
  function updateClockUI() {
    const el = $('live-clock-text'); if (el) el.textContent = clockLabel();
  }
  function startLiveClock() {
    if (liveClockTimer) return;
    liveClockTimer = setInterval(() => {
      if (clockMaxReached()) { clearInterval(liveClockTimer); liveClockTimer = null; return; }
      tickClock();
      updateClockUI();
    }, 1000);
  }
  let liveClockTimer = null;

  // ---- Cricket innings state (one team bats at a time) ----
  let liveInnings = null;
  function getWkts(sc) { const m = /(\d+)/.exec(sc.sub || ''); return m ? parseInt(m[1], 10) : 0; }
  function setWkts(sc, w) { sc.sub = '/' + w; }
  function initLiveInnings() {
    if (!SC.isCricket) return;
    liveInnings = { num: 1, batting: 'home', target: null };
    // Bowling team is yet to bat
    M.score.away.score = '—'; M.score.away.sub = ''; M.score.away.detail = 'Yet to bat';
  }
  function switchInnings() {
    if (!SC.isCricket || !liveInnings) return;
    if (liveInnings.num === 1) {
      const homeScore = parseInt(M.score.home.score, 10) || 0;
      liveInnings.num = 2;
      liveInnings.batting = 'away';
      liveInnings.target = homeScore + 1;
      M.score.away.score = '0'; M.score.away.sub = ''; M.score.away.detail = 'Target ' + liveInnings.target;
      liveClock.over = 0; liveClock.ball = 0; updateClockUI();
    } else {
      liveInnings = null; // match complete
    }
  }

  function startLiveLoop(feedEl) {
    if (liveTimer) return;
    ensureLiveBanner();
    if (SC.isCricket) initLiveInnings();
    startLiveClock();
    // Track the current over's balls for the "This Over" widget (Crex-style)
    let overBalls = [];
    let lastOverNo = -1;
    liveTimer = setInterval(() => {
      liveTick++;
      const r = rng();
      let type = 'normal', badge = '•', text, runs = 0;
      const pool = M.players.home.concat(M.players.away);
      const striker = pick(pool);
      const bowler = pick(pool);
      const isCricket = SC.isCricket;
      const isFootball = SPORT === 'football' || SPORT === 'hockey';
      const isBasket = SPORT === 'basketball';
      const isTennis = SPORT === 'tennis' || SPORT === 'tabletennis' || SPORT === 'volleyball';
      const isKabaddi = SPORT === 'kabaddi' || SPORT === 'e-sports';
      if (isCricket) {
        if (r > 0.9) { type = 'six'; badge = '6'; runs = 6; text = striker + ' launches ' + bowler + ' over the ropes for a massive six! '; }
        else if (r > 0.84) { type = 'four'; badge = '4'; runs = 4; text = striker + ' picks up a boundary off ' + bowler + '!'; }
        else if (r > 0.8) {
          type = 'wicket'; badge = 'W'; runs = 'W';
          const dismissals = ['c ' + bowler + ' b ' + bowler, 'b ' + bowler, 'lbw b ' + bowler, 'run out (' + bowler + ')', 'st ' + bowler + ' b ' + bowler, 'c & b ' + bowler];
          const d = pick(dismissals);
          text = striker + ' ' + d + '. Wicket!';
        }
        else if (r > 0.76) { type = 'milestone'; badge = '★'; text = striker + ' reaches a milestone.'; }
        else { runs = ri(0, 3); badge = String(runs); text = runs === 0 ? 'Dot ball. ' + bowler + ' lands it on a good length.' : runs + ' run' + (runs > 1 ? 's' : '') + ' taken.'; }
      } else if (isFootball) {
        if (r > 0.88) { type = 'goal'; badge = '⚽'; text = 'GOAL! ' + striker + ' finds the net past ' + bowler + '!'; }
        else if (r > 0.82) { type = 'save'; badge = '🧤'; text = 'Brilliant save by ' + bowler + ' to deny ' + striker + '!'; }
        else if (r > 0.78) { type = 'card'; badge = '🟥'; text = striker + ' shown a card by the referee.'; }
        else { type = 'normal'; text = 'Play continues. ' + striker + ' with possession.'; }
      } else if (isBasket) {
        if (r > 0.88) { type = 'goal'; badge = '🏀'; text = 'BASKET! ' + striker + ' scores against ' + bowler + '!'; }
        else if (r > 0.82) { type = 'pts'; badge = '+' + ri(1, 3); text = striker + ' adds ' + ri(1, 3) + ' points.'; }
        else { type = 'normal'; text = striker + ' brings the ball up court.'; }
      } else if (isTennis) {
        if (r > 0.88) { type = 'set'; badge = '🎾'; text = striker + ' takes the set off ' + bowler + '!'; }
        else if (r > 0.82) { type = 'ace'; badge = 'A'; text = striker + ' fires down an ace past ' + bowler + '!'; }
        else { type = 'normal'; text = striker + ' holds serve against ' + bowler + '.'; }
      } else if (isKabaddi) {
        if (r > 0.85) { type = 'raid'; badge = '🟡'; text = 'RAID! ' + striker + ' goes in for the raid against ' + bowler + ' (' + pick(['left corner', 'right corner', 'center', 'mid']) + ').'; }
        else if (r > 0.8) { type = 'touch'; badge = '✋'; text = striker + ' gets a touch point on ' + bowler + '!'; }
        else { type = 'normal'; text = 'Raid continues. ' + striker + ' looking for a point.'; }
      } else {
        if (r > 0.9) { type = 'six'; badge = '6'; text = striker + ' launches ' + bowler + ' for a big one! '; }
        else if (r > 0.84) { type = 'four'; badge = '4'; text = striker + ' scores!'; }
        else { type = 'normal'; text = 'Play continues. ' + striker + ' with the initiative.'; }
      }
      // Use the live clock for the over/label so it stays valid
      let over;
      if (isCricket) over = liveClock.over + '.' + liveClock.ball;
      else if (isBasket) over = 'Q' + liveClock.quarter;
      else if (isTennis) over = 'Set ' + liveClock.set;
      else if (SPORT === 'baseball') over = 'Inn ' + liveClock.inn;
      else over = clockLabel();
      const newBat = type === 'wicket' ? pick(pool.filter(n => n !== striker)) : null;
      // sport-aware type labels already set above (goal/save for football, set/ace for tennis, raid for kabaddi)
      const it = { over, type, runs: badge, badge, text, striker, bowler, nonstriker: pick(pool.filter(n => n !== striker)), newBatsman: newBat };
      const wrap = document.createElement('div');
      wrap.innerHTML = commItemHtml(it);
      const item = wrap.firstElementChild;
      item.classList.add('score-flash');
      feedEl.insertBefore(item, feedEl.firstChild);
      // ---- Score update logic (innings-wise for cricket) ----
      const isGoalLike = (type === 'six' || type === 'four' || type === 'goal' || type === 'set' || type === 'raid' || type === 'pts');
      if (isGoalLike) {
        let tgt, tgtTeam, add = 1;
        if (SC.isCricket && liveInnings) {
          // Only the batting side's score moves
          tgt = (liveInnings.batting === 'home') ? M.score.home : M.score.away;
          tgtTeam = (liveInnings.batting === 'home') ? HOME_T : AWAY_T;
          if (type === 'six') add = 6; else if (type === 'four') add = 4;
          if (!isNaN(parseInt(tgt.score))) tgt.score = parseInt(tgt.score) + add;
          // Wicket also increments the batting side's wickets
          if (type === 'wicket') { const w = getWkts(tgt) + 1; setWkts(tgt, w); }
          // Innings change when target reached (2nd innings) or 50 overs done
          if (liveInnings.num === 2 && liveInnings.target && parseInt(tgt.score, 10) >= liveInnings.target) {
            switchInnings();
          } else if (liveClock.over >= SC.xMax) {
            switchInnings();
          }
        } else {
          tgt = rng() > 0.5 ? M.score.home : M.score.away;
          tgtTeam = (tgt === M.score.home) ? HOME_T : AWAY_T;
          if (type === 'six') add = 6; else if (type === 'four' && SC.isCricket) add = 4; else if (type === 'pts') add = ri(1, 3); else if (type === 'set' || type === 'raid') add = 1;
          if (!isNaN(parseInt(tgt.score))) tgt.score = parseInt(tgt.score) + add;
        }
        renderScoreHeader();
        flashScore();
        showScoreToast(tgtTeam.name, add, (type === 'six' ? 'SIX' : type === 'four' ? 'FOUR' : type === 'goal' ? 'GOAL' : type === 'set' ? 'SET' : type === 'raid' ? 'RAID' : 'POINT'));
      }
      // ---- Crex-style ball animation + "This Over" tracker (cricket) ----
      if (SC.isCricket) {
        const ballLabel = (type === 'six') ? '6' : (type === 'four') ? '4' : (type === 'wicket') ? 'W' : (type === 'milestone') ? '★' : String(runs);
        if (liveClock.over !== lastOverNo) {
          // new over started — push previous over's balls into the scorecard history
          if (overBalls.length) pushOverHistory(lastOverNo, overBalls.slice());
          overBalls = [];
          lastOverNo = liveClock.over;
        }
        overBalls.push({ type, label: ballLabel, runs });
        animateBall(type, ballLabel);
        updateThisOverWidget(liveClock.over, overBalls);
        updateLivePositions();
      } else {
        updateLivePositions();
      }
    }, 3500);
  }

  // ---- Crex-style floating ball animation ----
  function animateBall(type, label) {
    let host = $('ball-anim-host');
    if (!host) {
      host = document.createElement('div');
      host.id = 'ball-anim-host';
      host.className = 'fixed inset-0 z-[115] pointer-events-none overflow-hidden';
      document.body.appendChild(host);
    }
    const el = document.createElement('div');
    el.className = 'crex-ball crex-ball-' + type;
    el.textContent = label;
    // random horizontal start near center-top
    const leftPct = 35 + Math.random() * 30;
    el.style.left = leftPct + 'vw';
    el.style.top = '30vh';
    host.appendChild(el);
    setTimeout(() => el.remove(), 1600);
  }

  // ---- "This Over" widget (Crex-style over balls) ----
  function updateThisOverWidget(overNo, balls) {
    const el = $('this-over-widget'); if (!el) return;
    const total = balls.reduce((s, b) => s + (typeof b.runs === 'number' ? b.runs : 0), 0);
    const ballsHtml = balls.map(b => '<span class="over-ball ' + b.type + '">' + esc(b.label) + '</span>').join('');
    el.innerHTML =
      '<div class="flex items-center justify-between text-sm mb-2"><span class="text-gray-500 dark:text-gray-400">Over ' + overNo + '</span>' +
      '<span class="font-mono text-emerald-600 dark:text-emerald-400 font-bold">' + (balls.length ? balls.map(b => b.label).join(' ') : '—') + ' = ' + total + '</span></div>' +
      '<div class="flex gap-1.5 flex-wrap">' + (ballsHtml || '<span class="text-xs text-gray-400">Waiting for first ball…</span>') + '</div>';
  }

  // ---- Last over history shown in scorecard ----
  let overHistory = [];
  function pushOverHistory(overNo, balls) {
    overHistory.unshift({ over: overNo, balls });
    if (overHistory.length > 6) overHistory.pop();
    renderOverHistory();
  }
  function renderOverHistory() {
    const el = $('over-history'); if (!el) return;
    if (!overHistory.length) { el.innerHTML = '<p class="text-xs text-gray-400">Over-by-over summary will appear here.</p>'; return; }
    el.innerHTML = overHistory.map(o => {
      const total = o.balls.reduce((s, b) => s + (typeof b.runs === 'number' ? b.runs : 0), 0);
      const balls = o.balls.map(b => '<span class="over-ball ' + b.type + ' !w-6 !h-6 !text-[10px]">' + esc(b.label) + '</span>').join('');
      return '<div class="flex items-center justify-between py-1.5 border-b border-gray-100 dark:border-gray-800 last:border-0">' +
        '<span class="text-xs font-semibold text-crexGold w-10">' + o.over + '</span>' +
        '<div class="flex gap-1 flex-1">' + balls + '</div>' +
        '<span class="text-xs font-mono text-emerald-600 dark:text-emerald-400 font-bold">' + total + '</span></div>';
    }).join('');
  }

  // ---- Live player positions (cricket pitch / kabaddi raid / football formation) ----
  function updateLivePositions() {
    const el = $('live-positions'); if (!el) return;
    const isCricket = !!SC.isCricket;
    const isKabaddi = !!SC.isKabaddi;
    const isFootball = SPORT === 'football' || SPORT === 'hockey';
    if (isCricket) {
      // Two batters at crease + bowler running in
      const batting = liveInnings ? (liveInnings.batting === 'home' ? M.squads.home.xi : M.squads.away.xi) : M.squads.home.xi;
      const bowlTeam = liveInnings ? (liveInnings.batting === 'home' ? M.squads.away.xi : M.squads.home.xi) : M.squads.away.xi;
      const s1 = batting[0] ? batting[0].n : 'Striker';
      const s2 = batting[1] ? batting[1].n : 'Non-striker';
      const bowler = bowlTeam[0] ? bowlTeam[0].n : 'Bowler';
      el.innerHTML = '<div class="pitch-wrap"><div class="cricket-pitch">' +
        '<div class="pos pos-striker" title="' + esc(s1) + '"><span class="pos-dot"></span><span class="pos-label">' + esc(s1) + '</span></div>' +
        '<div class="pos pos-nonstriker" title="' + esc(s2) + '"><span class="pos-dot"></span><span class="pos-label">' + esc(s2) + '</span></div>' +
        '<div class="pos pos-bowler" title="' + esc(bowler) + '"><span class="pos-dot"></span><span class="pos-label">' + esc(bowler) + '</span></div>' +
        '<div class="pos pos-keeper" title="WK"><span class="pos-dot"></span><span class="pos-label">WK</span></div>' +
        '</div></div>';
    } else if (isKabaddi) {
      const raider = M.squads.home.xi[0] ? M.squads.home.xi[0].n : 'Raider';
      const defender = M.squads.away.xi[0] ? M.squads.away.xi[0].n : 'Cover';
      const rx = 30 + (liveTick % 5) * 8, ry = 50 + (liveTick % 3) * 6;
      el.innerHTML = '<div class="kabaddi-mat"><div class="kabaddi-half left"></div><div class="kabaddi-half right"></div>' +
        '<div class="pos pos-raider" style="left:' + rx + '%;top:' + ry + '%" title="' + esc(raider) + '"><span class="pos-dot"></span><span class="pos-label">' + esc(raider) + '</span></div>' +
        '<div class="pos pos-defender" style="left:' + (100 - rx) + '%;top:' + (100 - ry) + '%" title="' + esc(defender) + '"><span class="pos-dot"></span><span class="pos-label">' + esc(defender) + '</span></div>' +
        '</div>';
    } else if (isFootball) {
      const f = (n, x, y) => '<div class="pos" style="left:' + x + '%;top:' + y + '%" title="' + esc(n) + '"><span class="pos-dot"></span><span class="pos-label">' + esc(n) + '</span></div>';
      const home = M.squads.home.xi.slice(0, 5).map((p, i) => p.n);
      const away = M.squads.away.xi.slice(0, 5).map((p, i) => p.n);
      let html = '<div class="football-pitch"><div class="pitch-line center"></div><div class="pitch-line circle"></div>';
      const spots = [[20,30],[35,55],[50,40],[65,60],[80,35],[20,70],[40,75],[60,25],[75,65],[50,80]];
      home.concat(away).forEach((n, i) => { const s = spots[i % spots.length]; html += f(n, s[0], s[1]); });
      html += '</div>';
      el.innerHTML = html;
    } else {
      el.innerHTML = '<p class="text-xs text-gray-400">Live positions are shown for cricket, kabaddi and football.</p>';
    }
  }

  function renderGraph() {
    const p = $('panel-graph'); if (!p) return;
    const filtersEl = $('graph-filters'); const svg = $('graph-svg'); const legend = $('graph-legend'); const loading = $('graph-loading');
    if (!svg) return;
    let active = M.graph.active;
    function draw() {
      const W = 600, H = 320, padL = 44, padR = 16, padT = 16, padB = 34;
      const xMax = M.graph.xMax, yMax = 100;
      const x = v => padL + (v / xMax) * (W - padL - padR);
      const y = v => padT + (1 - v / yMax) * (H - padT - padB);
      const cH = HOME_T.color, cA = AWAY_T.color;
      let s = '<defs><linearGradient id="hFill" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="' + cH + '" stop-opacity="0.28"/><stop offset="100%" stop-color="' + cH + '" stop-opacity="0.02"/></linearGradient><linearGradient id="aFill" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="' + cA + '" stop-opacity="0.28"/><stop offset="100%" stop-color="' + cA + '" stop-opacity="0.02"/></linearGradient><filter id="glow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="2.5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>';
      for (let g = 0; g <= 100; g += 25) { s += '<line x1="' + padL + '" y1="' + y(g) + '" x2="' + (W - padR) + '" y2="' + y(g) + '" stroke="rgba(148,163,184,0.16)" stroke-width="1"/><text x="' + (padL - 8) + '" y="' + (y(g) + 3) + '" fill="currentColor" font-size="9" text-anchor="end" opacity="0.55">' + g + '</text>'; }
      const step = xMax > 50 ? 10 : (xMax > 20 ? 5 : 2);
      for (let o = 0; o <= xMax; o += step) { s += '<line x1="' + x(o) + '" y1="' + padT + '" x2="' + x(o) + '" y2="' + (H - padB) + '" stroke="rgba(148,163,184,0.10)" stroke-width="1"/><text x="' + x(o) + '" y="' + (H - padB + 14) + '" fill="currentColor" font-size="9" text-anchor="middle" opacity="0.55">' + o + '</text>'; }
      s += '<text x="' + (W / 2) + '" y="' + (H - 4) + '" fill="currentColor" font-size="9" text-anchor="middle" opacity="0.6">' + M.graph.xUnit + '</text>';
      s += '<text x="' + (padL - 30) + '" y="' + (padT + (H - padT - padB) / 2) + '" fill="currentColor" font-size="9" text-anchor="middle" opacity="0.6" transform="rotate(-90 ' + (padL - 30) + ' ' + (padT + (H - padT - padB) / 2) + ')">Value</text>';
      s += '<line id="graph-guide" x1="0" y1="' + padT + '" x2="0" y2="' + (H - padB) + '" stroke="rgba(247,148,29,0.6)" stroke-width="1" stroke-dasharray="3 3" style="display:none"/>';
      const hPts = M.graph.home.map(d => x(d.x) + ',' + y(d.v)).join(' ');
      const aPts = M.graph.away.map(d => x(d.x) + ',' + y(d.v)).join(' ');
      s += '<polygon points="' + padL + ',' + y(100) + ' ' + hPts + ' ' + (W - padR) + ',' + y(100) + '" fill="url(#hFill)"/>';
      s += '<polyline points="' + hPts + '" fill="none" stroke="' + cH + '" stroke-width="2.5" stroke-linejoin="round" filter="url(#glow)"/>';
      s += '<polygon points="' + padL + ',' + y(0) + ' ' + aPts + ' ' + (W - padR) + ',' + y(0) + '" fill="url(#aFill)"/>';
      s += '<polyline points="' + aPts + '" fill="none" stroke="' + cA + '" stroke-width="2.5" stroke-linejoin="round" filter="url(#glow)"/>';
      const series = [
        { color: cH, label: HOME_T.name, pts: M.graph.home.map(d => ({ px: x(d.x), py: y(d.v), x: d.x, val: d.v, unit: '%' })) },
        { color: cA, label: AWAY_T.name, pts: M.graph.away.map(d => ({ px: x(d.x), py: y(d.v), x: d.x, val: d.v, unit: '%' })) }
      ];
      series.forEach(se => se.pts.forEach(pt => { s += '<circle class="graph-dot" cx="' + pt.px + '" cy="' + pt.py + '" r="12" fill="transparent" style="cursor:pointer"/><circle class="graph-marker" data-color="' + se.color + '" cx="' + pt.px + '" cy="' + pt.py + '" r="3.5" fill="' + se.color + '" stroke="#fff" stroke-width="1.5" style="display:none;pointer-events:none"/>'; }));
      svg.innerHTML = s;
      svg._series = series;
      legend.innerHTML = '<span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-sm" style="background:' + cH + '"></span> ' + esc(HOME_T.name) + '</span><span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-sm" style="background:' + cA + '"></span> ' + esc(AWAY_T.name) + '</span>';
    }
    filtersEl.innerHTML = '';
    M.graph.filters.forEach(f => {
      const b = document.createElement('button');
      b.textContent = f.label; b.dataset.key = f.key;
      b.className = 'px-3 py-1.5 rounded-full text-xs font-semibold border transition-colors ' + (f.key === active ? 'bg-crexGold text-white border-crexGold' : 'border-gray-300 dark:border-gray-700 text-gray-600 dark:text-gray-300 hover:border-crexGold');
      b.addEventListener('click', () => { active = f.key; filtersEl.querySelectorAll('button').forEach(x => { const on = x === b; x.classList.toggle('bg-crexGold', on); x.classList.toggle('text-white', on); x.classList.toggle('border-crexGold', on); x.classList.toggle('border-gray-300', !on); x.classList.toggle('dark:border-gray-700', !on); x.classList.toggle('text-gray-600', !on); x.classList.toggle('dark:text-gray-300', !on); }); draw(); });
      filtersEl.appendChild(b);
    });
    if (loading) loading.style.display = 'none';
    draw();

    // tooltip
    const tooltip = $('graph-tooltip');
    function show(cx, cy) {
      const series = svg._series; if (!series) return;
      const rect = svg.getBoundingClientRect();
      const sx = rect.width / 600, sy = rect.height / 320;
      const vx = (cx - rect.left) / sx, vy = (cy - rect.top) / sy;
      let best = null, bd = Infinity;
      series.forEach(se => se.pts.forEach(pt => { const d = Math.hypot(pt.px - vx, pt.py - vy); if (d < bd) { bd = d; best = { se, pt }; } }));
      if (!best || bd > 40) { tooltip.classList.add('hidden'); hideM(); return; }
      const { se, pt } = best;
      tooltip.innerHTML = '<div class="font-semibold mb-1" style="color:' + se.color + '">' + esc(se.label) + '</div><div class="opacity-80">' + M.graph.xUnit + ' ' + pt.x + '</div><div class="text-sm font-bold">' + pt.val + (pt.unit || '') + '</div>';
      tooltip.classList.remove('hidden');
      const guide = svg.querySelector('#graph-guide'); if (guide) { guide.setAttribute('x1', pt.px); guide.setAttribute('x2', pt.px); guide.style.display = ''; }
      svg.querySelectorAll('.graph-marker').forEach(m => m.style.display = 'none');
      let near = null, nd = Infinity; svg.querySelectorAll('.graph-marker').forEach(m => { const d = Math.hypot(parseFloat(m.getAttribute('cx')) - pt.px, parseFloat(m.getAttribute('cy')) - pt.py); if (d < nd) { nd = d; near = m; } });
      if (near) { near.setAttribute('cx', pt.px); near.setAttribute('cy', pt.py); near.style.display = ''; }
      const wrap = svg.parentElement; const wrect = wrap.getBoundingClientRect();
      let left = cx - wrect.left + 12, top = cy - wrect.top - 10;
      if (left + 140 > wrect.width) left = wrect.width - 150; if (top + 60 > wrect.height) top = wrect.height - 70;
      tooltip.style.left = Math.max(4, left) + 'px'; tooltip.style.top = Math.max(4, top) + 'px';
    }
    function hideM() { const g = svg.querySelector('#graph-guide'); if (g) g.style.display = 'none'; svg.querySelectorAll('.graph-marker').forEach(m => m.style.display = 'none'); }
    svg.addEventListener('mousemove', e => show(e.clientX, e.clientY));
    svg.addEventListener('mouseleave', () => { tooltip.classList.add('hidden'); hideM(); });
    svg.addEventListener('click', e => { show(e.clientX, e.clientY); setTimeout(() => { tooltip.classList.add('hidden'); hideM(); }, 2500); });
  }

  function renderNews() {
    const p = $('panel-news'); if (!p) return;
    const list = $('news-list'); const src = $('news-source'); const loading = $('news-loading');
    if (src) src.textContent = M.news.source;
    if (!list) return;
    list.innerHTML = M.news.articles.map(a => '<a href="#" class="flex gap-3 rounded-lg border border-gray-200 dark:border-gray-800 p-3 hover:border-crexGold transition-colors bg-gray-50/40 dark:bg-white/5">' +
      (a.image ? '<img src="' + a.image + '" alt="" class="w-16 h-16 rounded-md object-cover shrink-0 border border-gray-200 dark:border-white/10" onerror="this.style.display=\'none\'">' : '') +
      '<div class="min-w-0 flex-1"><p class="text-sm font-semibold text-gray-800 dark:text-white leading-snug">' + esc(a.title) + '</p><p class="text-xs text-gray-500 dark:text-gray-400 mt-1 line-clamp-2">' + esc(a.desc) + '</p><p class="text-[10px] text-gray-400 mt-1.5 uppercase tracking-wide">' + esc(a.time) + '</p></div></a>').join('');
    if (loading) loading.style.display = 'none';
  }

  // ============================================================ tabs
  function setupTabs() {
    const tabs = document.querySelectorAll('#match-tabs .tab-link');
    const panels = document.querySelectorAll('.tab-panel');
    function activate(tab) {
      const target = tab.dataset.tab;
      tabs.forEach(t => { t.classList.remove('border-crexGold', 'text-crexGold', 'font-bold'); t.classList.add('border-transparent'); });
      tab.classList.add('border-crexGold', 'text-crexGold', 'font-bold'); tab.classList.remove('border-transparent');
      panels.forEach(p => p.classList.toggle('hidden', p.id !== 'panel-' + target));
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
    tabs.forEach(tab => tab.addEventListener('click', e => { e.preventDefault(); activate(tab); }));
  }

  // ============================================================ init
  function init() {
    try { renderScoreHeader(); } catch (e) { console.error('scoreHeader', e); }
    try { renderMatchInfo(); } catch (e) { console.error('matchInfo', e); }
    try { renderSummary(); } catch (e) { console.error('summary', e); }
    try { renderScorecard(); } catch (e) { console.error('scorecard', e); }
    try { renderCommentary(); } catch (e) { console.error('commentary', e); }
    try { renderRules(); } catch (e) { console.error('rules', e); }
    try { renderSquads(); } catch (e) { console.error('squads', e); }
    try { renderGraph(); } catch (e) { console.error('graph', e); }
    try { renderNews(); } catch (e) { console.error('news', e); }
    try { setupTabs(); } catch (e) { console.error('tabs', e); }
    document.title = M.meta.title + ' | Fanconnact Match Center';
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
