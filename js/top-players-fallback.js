var FALLBACK = (function() {

  var SPORTS = {
    cricket: {
      label: "Cricket", icon: "sports_cricket", title: "ICC Cricket Rankings",
      subtitle: "Top 100 ranked players across formats",
      defaultCategory: "odi_bat_men",
      filters: [{ group: "format", label: "Format", options: [{ value: "odi", label: "ODI" }, { value: "t20", label: "T20" }, { value: "test", label: "Test" }] }, { group: "role", label: "Role", options: [{ value: "bat", label: "Batsman" }, { value: "bowl", label: "Bowler" }, { value: "ar", label: "All-Rounder" }] }, { group: "gender", label: "Gender", options: [{ value: "men", label: "Men" }, { value: "women", label: "Women" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "country", label: "Country" }, { key: "rating", label: "Rating", align: "center" }, { key: "matches", label: "Mat", align: "center", hide: "sm" }, { key: "runs", label: "Runs", align: "center", hide: "md" }, { key: "wkts", label: "Wkts", align: "center", hide: "md" }, { key: "avg", label: "Avg", align: "center", hide: "lg" }, { key: "econ", label: "Econ/SR", align: "center", hide: "lg" }]
    },
    football: {
      label: "Football", icon: "sports_soccer", title: "Football Top Players",
      subtitle: "Top ranked footballers",
      defaultCategory: "scorers_men",
      filters: [{ group: "stat", label: "Category", options: [{ value: "scorers", label: "Top Scorers" }, { value: "assists", label: "Top Assists" }, { value: "rating", label: "Highest Rated" }] }, { group: "gender", label: "Gender", options: [{ value: "men", label: "Men" }, { value: "women", label: "Women" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "country", label: "Country" }, { key: "team", label: "Team", hide: "sm" }, { key: "position", label: "Pos", align: "center", hide: "md" }, { key: "goals", label: "Goals", align: "center" }, { key: "assists", label: "Assists", align: "center", hide: "md" }, { key: "matches", label: "Mat", align: "center", hide: "sm" }, { key: "rating", label: "Rating", align: "center", hide: "lg" }]
    },
    basketball: {
      label: "Basketball", icon: "sports_basketball", title: "NBA Top Players",
      subtitle: "Top ranked NBA players by season stats",
      defaultCategory: "points",
      filters: [{ group: "stat", label: "Category", options: [{ value: "points", label: "Points" }, { value: "rebounds", label: "Rebounds" }, { value: "assists", label: "Assists" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "team", label: "Team", hide: "sm" }, { key: "position", label: "Pos", align: "center", hide: "md" }, { key: "points", label: "PPG", align: "center" }, { key: "rebounds", label: "RPG", align: "center", hide: "md" }, { key: "assists", label: "APG", align: "center", hide: "md" }, { key: "fg_pct", label: "FG%", align: "center", hide: "lg" }, { key: "rating", label: "EFF", align: "center", hide: "lg" }]
    },
    tennis: {
      label: "Tennis", icon: "sports_tennis", title: "ATP/WTA Rankings",
      subtitle: "Top ranked tennis players",
      defaultCategory: "atp_singles",
      filters: [{ group: "type", label: "Tour", options: [{ value: "atp", label: "ATP" }, { value: "wta", label: "WTA" }] }, { group: "category", label: "Category", options: [{ value: "singles", label: "Singles" }, { value: "doubles", label: "Doubles" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "country", label: "Country" }, { key: "points", label: "Points", align: "center" }, { key: "tournaments", label: "Tourn", align: "center", hide: "md" }, { key: "titles", label: "Titles", align: "center", hide: "sm" }, { key: "winrate", label: "Win%", align: "center", hide: "lg" }, { key: "prize", label: "Prize $M", align: "center", hide: "lg" }]
    },
    baseball: {
      label: "Baseball", icon: "sports_baseball", title: "MLB Top Players",
      subtitle: "Top ranked MLB players",
      defaultCategory: "hr",
      filters: [{ group: "stat", label: "Category", options: [{ value: "hr", label: "Home Runs" }, { value: "avg", label: "Batting Avg" }, { value: "rbi", label: "RBI" }, { value: "ops", label: "OPS" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "team", label: "Team", hide: "sm" }, { key: "position", label: "Pos", align: "center", hide: "md" }, { key: "hr", label: "HR", align: "center" }, { key: "avg", label: "AVG", align: "center", hide: "md" }, { key: "rbi", label: "RBI", align: "center", hide: "md" }, { key: "ops", label: "OPS", align: "center", hide: "lg" }, { key: "games", label: "G", align: "center", hide: "lg" }]
    },
    hockey: {
      label: "Hockey", icon: "sports_hockey", title: "FIH Hockey Rankings",
      subtitle: "Top ranked field hockey players",
      defaultCategory: "goals_men",
      filters: [{ group: "stat", label: "Category", options: [{ value: "goals", label: "Top Scorers" }, { value: "assists", label: "Top Assists" }] }, { group: "gender", label: "Gender", options: [{ value: "men", label: "Men" }, { value: "women", label: "Women" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "country", label: "Country" }, { key: "position", label: "Pos", align: "center", hide: "md" }, { key: "goals", label: "Goals", align: "center" }, { key: "assists", label: "Assists", align: "center", hide: "md" }, { key: "matches", label: "Mat", align: "center", hide: "sm" }, { key: "rating", label: "Rating", align: "center", hide: "lg" }]
    },
    volleyball: {
      label: "Volleyball", icon: "sports_volleyball", title: "FIVB Volleyball Rankings",
      subtitle: "Top ranked volleyball players",
      defaultCategory: "points_men",
      filters: [{ group: "stat", label: "Category", options: [{ value: "points", label: "Total Points" }, { value: "spikes", label: "Best Spiker" }, { value: "blocks", label: "Best Blocker" }] }, { group: "gender", label: "Gender", options: [{ value: "men", label: "Men" }, { value: "women", label: "Women" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "country", label: "Country" }, { key: "position", label: "Pos", align: "center", hide: "md" }, { key: "points", label: "Points", align: "center" }, { key: "spikes", label: "Spikes", align: "center", hide: "md" }, { key: "blocks", label: "Blocks", align: "center", hide: "md" }, { key: "aces", label: "Aces", align: "center", hide: "lg" }, { key: "rating", label: "Rating", align: "center", hide: "lg" }]
    },
    kabbaddi: {
      label: "Kabaddi", icon: "sports_kabaddi", title: "PKL Top Players",
      subtitle: "Top ranked Pro Kabaddi players",
      defaultCategory: "raid",
      filters: [{ group: "stat", label: "Category", options: [{ value: "raid", label: "Raid Points" }, { value: "tackle", label: "Tackle Points" }, { value: "allround", label: "All-Round" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "team", label: "Team", hide: "sm" }, { key: "position", label: "Pos", align: "center", hide: "md" }, { key: "raid_pts", label: "Raid Pts", align: "center" }, { key: "tackle_pts", label: "Tackle Pts", align: "center", hide: "md" }, { key: "total_pts", label: "Total", align: "center", hide: "md" }, { key: "matches", label: "Mat", align: "center", hide: "sm" }, { key: "rating", label: "Rating", align: "center", hide: "lg" }]
    },
    "e-sports": {
      label: "E-Sports", icon: "sports_esports", title: "E-Sports Top Players",
      subtitle: "Top ranked e-sports players by prize money",
      defaultCategory: "earnings",
      filters: [{ group: "game", label: "Game", options: [{ value: "all", label: "All Games" }, { value: "valorant", label: "Valorant" }, { value: "lol", label: "League of Legends" }, { value: "cs2", label: "CS:GO/CS2" }, { value: "dota2", label: "Dota 2" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "team", label: "Team", hide: "sm" }, { key: "game", label: "Game", hide: "md" }, { key: "earnings", label: "Prize $M", align: "center" }, { key: "tournaments", label: "Tourn", align: "center", hide: "md" }, { key: "winrate", label: "Win%", align: "center", hide: "lg" }, { key: "rating", label: "Rating", align: "center", hide: "lg" }]
    },
    "table-tennis": {
      label: "Table Tennis", icon: "sports_tennis", title: "ITTF Table Tennis Rankings",
      subtitle: "Top ranked table tennis players",
      defaultCategory: "singles_men",
      filters: [{ group: "category", label: "Category", options: [{ value: "singles", label: "Singles" }, { value: "doubles", label: "Doubles" }] }, { group: "gender", label: "Gender", options: [{ value: "men", label: "Men" }, { value: "women", label: "Women" }] }],
      columns: [{ key: "name", label: "Player" }, { key: "country", label: "Country" }, { key: "points", label: "Points", align: "center" }, { key: "tournaments", label: "Tourn", align: "center", hide: "md" }, { key: "titles", label: "Titles", align: "center", hide: "sm" }, { key: "winrate", label: "Win%", align: "center", hide: "lg" }, { key: "prize", label: "Prize $M", align: "center", hide: "lg" }]
    }
  };

  var CRICKET_NAMES = ["Virat Kohli","Babar Azam","Rohit Sharma","Shubman Gill","Travis Head","Suryakumar Yadav","Heinrich Klaasen","KL Rahul","Pathum Nissanka","Rassie van der Dussen","Daryl Mitchell","Shai Hope","Harry Tector","Devon Conway","Glenn Maxwell","Ben Stokes","Mohammad Rizwan","Litton Das","David Warner","Steve Smith","Marnus Labuschagne","Joe Root","Kane Williamson","Jonny Bairstow","Temba Bavuma","Aiden Markram","Quinton de Kock","Fakhar Zaman","Kusal Mendis","Charith Asalanka","Nicholas Pooran","Sherfane Rutherford","Sean Williams","Sikandar Raza","Paul Stirling","Scott Edwards","Bas de Leede","Gerhard Erasmus","Tom Latham","Glenn Phillips","Finn Allen","Mark Chapman","Sam Curran","Moeen Ali","Jason Roy","Alex Hales","MS Dhoni","Sachin Tendulkar","Ricky Ponting","Chris Gayle","Brian Lara","Jacques Kallis","AB de Villiers","Kumar Sangakkara","Mahela Jayawardene"];
  var CRICKET_COUNTRIES = ["India","Australia","England","New Zealand","South Africa","Pakistan","Sri Lanka","West Indies","Bangladesh","Afghanistan","Zimbabwe","Ireland","Netherlands","Namibia","Scotland"];
  var CRICKET_COUNTRIES_W = ["Australia","England","India","New Zealand","South Africa","West Indies","Sri Lanka","Pakistan","Bangladesh","Ireland","Netherlands","Scotland","Thailand","Zimbabwe","PNG"];

  var CRICKET_CR = { odi_bat_men: [["Shubman Gill","India",796,50,2876,0,58.2,102.3],["Babar Azam","Pakistan",778,125,5934,0,56.8,89.4],["Rohit Sharma","India",765,267,10866,0,48.9,90.2],["Virat Kohli","India",746,295,13906,0,57.3,93.2],["Daryl Mitchell","New Zealand",730,45,1983,12,52.6,96.1],["Harry Tector","Ireland",722,52,2198,0,47.8,89.4],["KL Rahul","India",708,86,3614,0,48.5,88.7],["Rassie van der Dussen","South Africa",702,56,2467,0,52.8,87.9],["Pathum Nissanka","Sri Lanka",695,52,2234,0,46.2,85.6],["Travis Head","Australia",680,78,3124,21,42.8,98.7],["Kane Williamson","New Zealand",672,170,7046,12,48.2,81.3],["Steve Smith","Australia",665,158,6321,8,43.7,86.9],["Joe Root","England",652,178,7432,28,51.3,85.6],["Fakhar Zaman","Pakistan",648,95,3954,0,45.6,92.3],["Quinton de Kock","South Africa",632,155,6743,0,45.8,96.2],["David Warner","Australia",625,165,6932,0,44.6,95.3],["Ben Stokes","England",590,118,3578,82,41.6,96.4],["Glenn Maxwell","Australia",580,142,3654,72,37.8,102.3],["Heinrich Klaasen","South Africa",660,52,1965,0,45.3,106.2],["Suryakumar Yadav","India",638,62,2254,0,44.2,104.3],["Shai Hope","West Indies",688,132,4789,0,44.6,80.5],["Jonny Bairstow","England",585,106,3856,0,43.2,98.7],["Litton Das","Bangladesh",608,92,3654,0,43.2,87.6],["Mohammad Rizwan","Pakistan",602,86,3165,0,42.8,86.3],["Aiden Markram","South Africa",596,72,2786,14,43.8,91.2],["Charith Asalanka","Sri Lanka",612,58,2187,28,44.8,90.5],["Kusal Mendis","Sri Lanka",672,62,2156,0,43.5,88.2],["Nicholas Pooran","West Indies",642,72,2456,0,45.5,92.6],["Sean Williams","Zimbabwe",575,56,2104,52,45.2,84.6],["Paul Stirling","Ireland",565,165,5893,0,40.2,82.5]] };

  function shuffleSeed(arr, seed) {
    var a = arr.slice();
    var s = seed || 42;
    for (var i = a.length - 1; i > 0; i--) {
      s = (s * 9301 + 49297) % 233280;
      var j = Math.floor((s / 233280) * (i + 1));
      var tmp = a[i]; a[i] = a[j]; a[j] = tmp;
    }
    return a;
  }

  function makeCricketPlayers(sportId, cat) {
    var parts = cat.split("_");
    var format = parts[0], role = parts[1] || "bat", gender = parts[2] || "men";
    var key = format + "_" + role + "_" + gender;
    var raw = CRICKET_CR[key];
    if (raw && raw.length >= 5) return raw.map(function(p, i){ return { rank: i+1, name: p[0], country: p[1], rating: p[2], matches: p[3], runs: p[4], wkts: p[5], avg: p[6], econ: p[7] }; });
    var names = gender === "women" ? CRICKET_NAMES.slice(0, 30) : CRICKET_NAMES;
    var countries = gender === "women" ? CRICKET_COUNTRIES_W : CRICKET_COUNTRIES;
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var rating = Math.max(1, 700 - Math.floor(i * 6.5));
      var isB = role === "bowl", isA = role === "ar";
      ps.push({ rank: i+1, name: names[i % names.length], country: countries[i % countries.length], rating: rating, matches: Math.round(10 + Math.random() * 80), runs: isB ? Math.round(50+Math.random()*500) : isA ? Math.round(200+Math.random()*5000) : Math.round(500+Math.random()*10000), wkts: isB ? Math.round(10+Math.random()*150) : isA ? Math.round(5+Math.random()*80) : Math.round(Math.random()*20), avg: (20 + Math.random() * 40).toFixed(1), econ: (3+Math.random()*4).toFixed(1) });
    }
    return ps;
  }

  var FOOTBALL_NAMES = ["Erling Haaland","Kylian Mbappe","Harry Kane","Lionel Messi","Cristiano Ronaldo","Mohamed Salah","Robert Lewandowski","Karim Benzema","Kevin De Bruyne","Neymar","Vinicius Jr","Jude Bellingham","Rodri","Antoine Griezmann","Bukayo Saka","Phil Foden","Jamal Musiala","Lautaro Martinez","Victor Osimhen","Rafael Leao","Bernardo Silva","Pedri","Luka Modric","Toni Kroos","Joshua Kimmich","Declan Rice","Martin Odegaard","Bruno Fernandes","Marcus Rashford","Gabriel Jesus","Jack Grealish","Kai Havertz","Christopher Nkunku","Florian Wirtz","Serge Gnabry","Thomas Muller","Leroy Sane","Alphonso Davies","Ousmane Dembele","Olivier Giroud","Gianluigi Donnarumma","Federico Valverde","Rodrygo Goes","Lamine Yamal","Xavi Simons","Darwin Nunez","Luis Diaz","Virgil van Dijk","Trent Alexander-Arnold","Alisson Becker","Ruben Dias","Ederson","Frenkie de Jong","Son Heung-min","Min-jae Kim","Takefusa Kubo"];
  var FOOTBALL_TEAMS = ["Manchester City","Real Madrid","Bayern Munich","PSG","Liverpool","Barcelona","Arsenal","Inter Milan","AC Milan","Juventus","Chelsea","Tottenham","Manchester United","Atletico Madrid","Borussia Dortmund","RB Leipzig","Napoli","Benfica","Porto","Ajax","Roma","Lazio","Celtic","Club Brugge"];
  var FOOTBALL_COUNTRIES = ["Norway","France","England","Argentina","Portugal","Egypt","Poland","Belgium","Brazil","Germany","Spain","Netherlands","Croatia","Senegal","South Korea","Japan","Morocco","Uruguay","Colombia","Ghana","Nigeria","Switzerland","Denmark","Sweden","Austria","Serbia","Turkey","Iran","Australia","Cameroon"];
  var FOOTBALL_POS = ["FW","FW","MF","FW","MF","FW","MF","DF","GK","FW","MF","DF","MF","FW","MF"];

  function makeFootballPlayers(cat) {
    var parts = cat.split("_");
    var stat = parts[0], gender = parts[1] || "men";
    var prefix = gender === "women" ? "W. " : "";
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var base = 100 - i;
      ps.push({ rank: i+1, name: prefix + FOOTBALL_NAMES[i % FOOTBALL_NAMES.length], country: FOOTBALL_COUNTRIES[i % FOOTBALL_COUNTRIES.length], team: FOOTBALL_TEAMS[i % FOOTBALL_TEAMS.length], position: FOOTBALL_POS[i % FOOTBALL_POS.length], goals: Math.max(0, Math.round(base * 0.5 + Math.random() * 10)), assists: Math.max(0, Math.round(base * 0.35 + Math.random() * 8)), matches: Math.round(20 + Math.random() * 30), rating: (6.5 + Math.random() * 2.5).toFixed(1) });
    }
    if (stat === "scorers") ps.sort(function(a,b){return b.goals-a.goals});
    else if (stat === "assists") ps.sort(function(a,b){return b.assists-a.assists});
    else ps.sort(function(a,b){return parseFloat(b.rating)-parseFloat(a.rating)});
    ps.forEach(function(p,i){p.rank=i+1});
    return ps;
  }

  var TENNIS_ATP = ["Jannik Sinner","Novak Djokovic","Carlos Alcaraz","Daniil Medvedev","Alexander Zverev","Andrey Rublev","Stefanos Tsitsipas","Casper Ruud","Holger Rune","Hubert Hurkacz","Alex de Minaur","Taylor Fritz","Grigor Dimitrov","Tommy Paul","Ugo Humbert","Ben Shelton","Felix Auger-Aliassime","Lorenzo Musetti","Sebastian Korda","Frances Tiafoe","Andy Murray","Stan Wawrinka","Marin Cilic","Matteo Berrettini","Dominic Thiem","Cameron Norrie","Daniel Evans","Alexei Popyrin","Richard Gasquet","Arthur Fils"];
  var TENNIS_WTA = ["Iga Swiatek","Aryna Sabalenka","Coco Gauff","Elena Rybakina","Jessica Pegula","Ons Jabeur","Maria Sakkari","Jelena Ostapenko","Barbora Krejcikova","Madison Keys","Daria Kasatkina","Petra Kvitova","Victoria Azarenka","Elina Svitolina","Mirra Andreeva","Linda Noskova","Danielle Collins","Sloane Stephens","Sofia Kenin","Emma Raducanu","Naomi Osaka","Angelique Kerber","Donna Vekic","Qinwen Zheng","Leylah Fernandez","Bianca Andreescu","Karolina Pliskova","Katerina Siniakova"];
  var TENNIS_COUNTRIES = ["Spain","Italy","Serbia","Russia","Greece","Norway","Denmark","Poland","Australia","USA","Bulgaria","Germany","Canada","France","UK","Argentina","Chile","Croatia","Switzerland","Netherlands","Belgium","Japan","China","Czech Republic","Romania","Ukraine","Tunisia","Kazakhstan","Brazil","Hungary"];

  function makeTennisPlayers(cat) {
    var parts = cat.split("_");
    var type = parts[0], ccat = parts[1] || "singles";
    var pool = type === "atp" ? TENNIS_ATP : TENNIS_WTA;
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var pts = Math.max(1, Math.round(10000 - i * 70 + Math.random() * 50));
      ps.push({ rank: i+1, name: pool[i % pool.length], country: TENNIS_COUNTRIES[i % TENNIS_COUNTRIES.length], points: pts, tournaments: Math.round(10 + Math.random() * 20), titles: Math.round(i < 10 ? 5 + Math.random() * 15 : Math.random() * 5), winrate: parseFloat((50 + Math.random() * 40).toFixed(1)), prize: parseFloat((i < 30 ? 10 - i * 0.3 : Math.random() * 3).toFixed(1)) });
    }
    ps.sort(function(a,b){return b.points-a.points});
    ps.forEach(function(p,i){p.rank=i+1});
    return ps;
  }

  var BASEBALL_NAMES = ["Shohei Ohtani","Aaron Judge","Juan Soto","Mookie Betts","Ronald Acuna Jr","Mike Trout","Bryce Harper","Freddie Freeman","Manny Machado","Jose Ramirez","Corey Seager","Yordan Alvarez","Vladimir Guerrero Jr","Rafael Devers","Matt Olson","Pete Alonso","Nolan Arenado","Paul Goldschmidt","Francisco Lindor","Trea Turner","Fernando Tatis Jr","Bo Bichette","Wander Franco","Julio Rodriguez","Adley Rutschman","Bobby Witt Jr","Gunnar Henderson","Corbin Carroll","Spencer Strider","Jacob deGrom","Max Scherzer","Justin Verlander","Gerrit Cole","Clayton Kershaw","Zack Wheeler","Aaron Nola","Kevin Gausman","Dylan Cease","Framber Valdez","Luis Castillo"];
  var BASEBALL_TEAMS = ["LAD","NYY","SD","LAA","ATL","HOU","PHI","NYM","TOR","BOS","CHC","MIL","STL","SF","TEX","SEA","MIN","CLE","TB","BAL","ARI","MIA","CIN","PIT","KC","DET","CWS","OAK","COL","WSH"];
  var BASEBALL_POS = ["1B","2B","3B","SS","OF","C","DH","P"];

  function makeBaseballPlayers(cat) {
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var base = 70 - i * 0.6;
      ps.push({ rank: i+1, name: BASEBALL_NAMES[i % BASEBALL_NAMES.length], team: BASEBALL_TEAMS[i % BASEBALL_TEAMS.length], position: BASEBALL_POS[i % BASEBALL_POS.length], hr: Math.max(0, Math.round(base * 0.5 + Math.random() * 10)), avg: parseFloat(Math.min(0.35, 0.22 + Math.random() * 0.12).toFixed(3)), rbi: Math.max(0, Math.round(base * 1.5 + Math.random() * 20)), ops: parseFloat((0.65 + Math.random() * 0.4).toFixed(3)), games: Math.round(100 + Math.random() * 60) });
    }
    if (cat === "hr") ps.sort(function(a,b){return b.hr-a.hr});
    else if (cat === "avg") ps.sort(function(a,b){return b.avg-a.avg});
    else if (cat === "rbi") ps.sort(function(a,b){return b.rbi-a.rbi});
    else ps.sort(function(a,b){return b.ops-a.ops});
    ps.forEach(function(p,i){p.rank=i+1});
    return ps;
  }

  var HOCKEY_NAMES_M = ["Harmanjit Singh","Abhishek","Sukhjeet Singh","Lalit Upadhyay","Mandeep Singh","Gurjant Singh","Shamsher Singh","Akashdeep Singh","Dilpreet Singh","Jugraj Singh","Vivek Sagar Prasad","Hardik Singh","Manpreet Singh","Nilakanta Sharma","Sumit","Jarmanpreet Singh","Amit Rohidas","Surender Kumar","Harmanpreet Singh","Varun Kumar","PR Sreejesh","Krishan Pathak","Arthur De Sloover","Loic Luypaert","Alexander Hendrickx","Tom Boon","Felix Denayer","John-John Dohmen","Florent van Aubel","Romain Onnlin"];
  var HOCKEY_NAMES_W = ["Salima Tete","Navneet Kaur","Vandana Katariya","Lalremsiami","Grace Xess","Sangita Kumari","Neha Goyal","Sushila Chanu","Savitri Punia","Nisha Warsi","Monika Malik","Deep Grace Ekka","Udita","Ishika Chaudhary","Nikita Pradhan","Rajani Etimarpu","Bichu Devi","Savita Punia","Eva de Goede","Maria Verschoor","Caia van Maasakker","Lidewij Welten","Xan de Waard","Marloes Keetels","Margot van Geffen","Frderique Matla","Felice Albers","Pien Sanders","Josine Koning","Anne Veenendaal"];
  var HOCKEY_COUNTRIES = ["Netherlands","Belgium","Germany","Australia","India","Argentina","England","Spain","New Zealand","South Korea","Malaysia","South Africa","Ireland","France","Japan","China","USA","Chile","Canada","Poland"];

  function makeHockeyPlayers(cat) {
    var parts = cat.split("_");
    var stat = parts[0], gender = parts[1] || "men";
    var pool = gender === "women" ? HOCKEY_NAMES_W : HOCKEY_NAMES_M;
    var pos = ["FW","MF","DF","GK"];
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var base = 80 - i * 0.5;
      ps.push({ rank: i+1, name: pool[i % pool.length], country: HOCKEY_COUNTRIES[i % HOCKEY_COUNTRIES.length], position: pos[i % pos.length], goals: Math.max(0, Math.round(base * 0.4 + Math.random() * 8)), assists: Math.max(0, Math.round(base * 0.3 + Math.random() * 6)), matches: Math.round(30 + Math.random() * 100), rating: parseFloat((60 + Math.random() * 35).toFixed(0)) });
    }
    if (stat === "goals") ps.sort(function(a,b){return b.goals-a.goals});
    else ps.sort(function(a,b){return b.assists-a.assists});
    ps.forEach(function(p,i){p.rank=i+1});
    return ps;
  }

  var VOLLEYBALL_NAMES_M = ["Earvin Ngapeth","Wilfredo Leon","Ivan Zaytsev","Yuji Nishida","Osmany Juantorena","Michal Kubiak","Bartosz Kurek","Mateusz Bieniek","Pawel Zatorski","Benjamin Toniutti","Antoine Brizard","Stephen Boyer","Trevor Clevenot","Yuki Ishikawa","Ran Takahashi","Tatsunori Otsuka","Samuel Tuia","Taylor Sander","Maxwell Holt","Matt Anderson","Aaron Russell","Micha Christenson","TJ DeFalco","Thomas Jaeschke","Kyle Ensing","David Smith","Micah Christenson","Erik Shoji","Gabi Garcia Fernandez","Lucas Saatkamp"];
  var VOLLEYBALL_NAMES_W = ["Zhu Ting","Paola Egonu","Eda Erdem","Melissa Vargas","Isabelle Haak","Monica De Gennaro","Alessia Orro","Miriam Sylla","Elena Pietrini","Caterina Bosetti","Marta Drpa","Britt Herbots","Celine Van Gestel","Lise Van Hecke","Dominika Sobolska","Megan Easy","Jordan Larson","Annie Drews","Andrea Drews","Madi Rishel","Kelsey Robinson","Lauren Carlini","Jordyn Poulter","Justine Wong-Orantes","Chiaka Ogbogu","Haleigh Washington","Foluke Akinradewo","Sarah Wilhite","Tori Dixon","Micha Hancock"];
  var VOLLEYBALL_POS = ["OH","OP","MB","S","L","MB","OH","OP","S","L"];
  var VOLLEYBALL_COUNTRIES = ["Poland","Italy","France","Brazil","USA","Japan","Russia","Argentina","Slovenia","Iran","Germany","Netherlands","Canada","Cuba","Belgium","Serbia","Turkey","China","South Korea","Thailand","Dominican Republic","Netherlands","Puerto Rico","Colombia","Kenya","Cameroon","Mexico","Chile","Peru","Algeria"];

  function makeVolleyballPlayers(cat) {
    var parts = cat.split("_");
    var stat = parts[0], gender = parts[1] || "men";
    var pool = gender === "women" ? VOLLEYBALL_NAMES_W : VOLLEYBALL_NAMES_M;
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var base = 90 - i * 0.5;
      ps.push({ rank: i+1, name: pool[i % pool.length], country: VOLLEYBALL_COUNTRIES[i % VOLLEYBALL_COUNTRIES.length], position: VOLLEYBALL_POS[i % VOLLEYBALL_POS.length], points: Math.max(0, Math.round(base * 1.2 + Math.random() * 20)), spikes: Math.max(0, Math.round(base * 0.5 + Math.random() * 10)), blocks: Math.max(0, Math.round(base * 0.2 + Math.random() * 5)), aces: Math.max(0, Math.round(base * 0.1 + Math.random() * 3)), rating: parseFloat((70 + Math.random() * 28).toFixed(0)) });
    }
    if (stat === "points") ps.sort(function(a,b){return b.points-a.points});
    else if (stat === "spikes") ps.sort(function(a,b){return b.spikes-a.spikes});
    else ps.sort(function(a,b){return b.blocks-a.blocks});
    ps.forEach(function(p,i){p.rank=i+1});
    return ps;
  }

  var KABADDI_NAMES = ["Pardeep Narwal","Rahul Chaudhari","Ajay Thakur","Deepak Niwas Hooda","Maninder Singh","Pawan Sehrawat","Siddharth Desai","Naveen Kumar","Rohit Kumar","Vikas Kandola","Vijay","Sachin T","Abhishek Singh","Mohit Goyat","Chandran Ranjith","Manjeet Chhillar","Fazel Atrachali","Mohammad Nabibakhsh","Sandeep Narwal","Dharmaraj Cheralathan","Ravinder Pahal","Surender Nada","Joginder Narwal","Amit Hooda","Rinku Narwal","Rohit Baliyan","Nitin Rawal","Sagar Kumar","Ankush","Rakesh","Sunil Kumar","Jaideep","Parvesh Bhainswal","Amit Dhankar","Deepak Hooda","Darshan Kadian","Surjeet Singh","Girish Maruti Ernak","Raju Lal Choudhary","Anup Kumar"];
  var KABADDI_TEAMS = ["Patna Pirates","Bengal Warriors","U Mumba","Jaipur Pink Panthers","Dabang Delhi","Telugu Titans","Puneri Paltan","Haryana Steelers","Tamil Thalaivas","Bengaluru Bulls","Gujarat Giants","UP Yoddhas","U Mumba","Jaipur Pink Panthers","Dabang Delhi","Bengal Warriors","Patna Pirates","Haryana Steelers","Puneri Paltan","Tamil Thalaivas","Telugu Titans","Bengaluru Bulls","Gujarat Giants","UP Yoddhas"];

  function makeKabaddiPlayers(cat) {
    var pos = ["Raider","Defender","All-Round"];
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var base = 90 - i * 0.5;
      var raid = Math.max(0, Math.round(base * 2 + Math.random() * 30));
      var tackle = Math.max(0, Math.round(base * 1.2 + Math.random() * 20));
      ps.push({ rank: i+1, name: KABADDI_NAMES[i % KABADDI_NAMES.length], team: KABADDI_TEAMS[i % KABADDI_TEAMS.length], position: pos[i % pos.length], raid_pts: raid, tackle_pts: tackle, total_pts: raid + tackle, matches: Math.round(20 + Math.random() * 60), rating: parseFloat((60 + Math.random() * 35).toFixed(0)) });
    }
    if (cat === "raid") ps.sort(function(a,b){return b.raid_pts-a.raid_pts});
    else if (cat === "tackle") ps.sort(function(a,b){return b.tackle_pts-a.tackle_pts});
    else ps.sort(function(a,b){return b.total_pts-a.total_pts});
    ps.forEach(function(p,i){p.rank=i+1});
    return ps;
  }

  var ESPORTS_NAMES = ["TenZ","Demon1","Jawgemo","zekken","aspas","Sacy","FNS","Victor","Crashies","yay","cNed","nAts","Derke","Boaster","Chronicle","Shao","Leo","Suguru","Minds","Alfajer","Faker","Chovy","ShowMaker","Caps","knight","Rookie","Scout","Chovy","Viper","Deft","Keria","Oner","Gumayusi","Zeus","Peanut","Delight","Viper","Zeka","Kingen","Beryl","s1mple","ZywOo","donk","sh1ro","mONESY","NiKo","device","dupreeh","Magisk","Twistzz","elige","NAF","Ethan","jks","Hobbit","Ax1Le","Yatoro","Collapse","gpk","Mira","TORONTOTOKYO","Ame","NothingToSay","Faith_bian","xinQ","dnz","Quinn","Cr1t","Puppey","SumaiL","Miracle-","No[o]ne","RAMZES666","KuroKy"];
  var ESPORTS_TEAMS = ["Sentinels","Fnatic","LOUD","Cloud9","DRX","NRG","Evil Geniuses","Team Liquid","Optic Gaming","Paper Rex","NAVI","FaZe Clan","G2 Esports","ENCE","Vitality","Astralis","Team Spirit","LGD Gaming","OG","Team Secret","PSG.LGD","Tundra Esports","Talon Esports","Shopify Rebellion","MOUZ","Heroic","MIBR","Furia","Leviatán","KRU"];
  var ESPORTS_GAMES = ["Valorant","League of Legends","CS:GO/CS2","Dota 2","Fortnite","Overwatch"];

  function makeEsportsPlayers(cat) {
    var game = cat || "all";
    var defaultGame = "Multi";
    if (game !== "all") {
      var gmap = { valorant: "Valorant", lol: "League of Legends", cs2: "CS:GO/CS2", dota2: "Dota 2" };
      defaultGame = gmap[game] || "Multi";
    }
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var g = game === "all" ? ESPORTS_GAMES[i % ESPORTS_GAMES.length] : defaultGame;
      ps.push({ rank: i+1, name: ESPORTS_NAMES[i % ESPORTS_NAMES.length], team: ESPORTS_TEAMS[i % ESPORTS_TEAMS.length], game: g, earnings: parseFloat((i < 20 ? 5 - i * 0.2 : Math.random() * 2).toFixed(2)), tournaments: Math.round(5 + Math.random() * 40), winrate: parseFloat((40 + Math.random() * 45).toFixed(1)), rating: parseFloat((65 + Math.random() * 30).toFixed(0)) });
    }
    ps.sort(function(a,b){return b.earnings-a.earnings});
    ps.forEach(function(p,i){p.rank=i+1});
    return ps;
  }

  var TABLETENNIS_NAMES_M = ["FAN Zhendong","MA Long","WANG Chuqin","LIANG Jingkun","LIN Gaoyuan","LIN Shidong","Tomokazu HARIMOTO","Hugo CALDERANO","Truls MOREGARD","Dimitrij OVTCHAROV","Felix LEBRUN","Alexis LEBRUN","Quadri ARUNA","Darko JORGIC","Patrick FRANZISKA","Dang QIU","LI Shangzhu","Kao Cheng-Jui","Lin Yun-Ju","Chuang Chih-Yuan","Koki NIWA","Shunsuke TOGAMI","Hiroto SHINOZUKA","Mizuki OIKAWA","Sora MATSUSHIMA","An Jae-Hyun","Lim Jong-Hoon","Jang Woo-Jin","Cho Dae-Seong","Oh Joon-Sung","Paul DRINKHALL","Liam PITCHFORD","Sam WALKER","Tom JARVIS","Benedek OLAH","Daniel HABESOHN","Robert GARDOS","Timo BOLL","Kirill GERASSIMOV","Marcos MADRID"];
  var TABLETENNIS_NAMES_W = ["SUN Yingsha","WANG Manyu","WANG Yidi","CHEN Xingtong","CHEN Meng","WANG Yidi","QIAN Tianyi","Hina HAYATA","Miwa HARIMOTO","Mima ITO","Miyuu KIHARA","Miu HIRANO","Sakura MORI","Yuka UMEMURA","Suh Hyo-Won","Shin Yu-Bin","Jeon Ji-Hee","Lee Eun-Hye","Kim Na-Rae","Yang Ha-Eun","CHENG I-Ching","CHEN Szu-Yu","LIU Hsing-Yin","HUANG Yi-Hua","Zeng Jian","Zhou Jingyi","Sneha MUKHERJEE","Reeth RISHYA","Diya Parag CHITALE","Sreeja AKULA","Natalia BIJAK","Natalia PARTYKA","Anna WEGRZYN","Zuzanna WIELGOSZ","Georgina POTA","Maria XIAO","Shao Jieni","Bernadette SZOCS","Dora MADARASZ","Elizabeta SAMARA"];
  var TABLETENNIS_COUNTRIES_M = ["China","Japan","Germany","Brazil","Chinese Taipei","France","Sweden","South Korea","India","Nigeria","Egypt","Portugal","Slovenia","Denmark","Austria","Spain","Argentina","Croatia","Puerto Rico","Poland","Romania","Hungary","Belgium","England","Iran","Kazakhstan","Luxembourg","Singapore","Hong Kong","Australia"];
  var TABLETENNIS_COUNTRIES_W = ["China","Japan","Germany","Hong Kong","South Korea","Romania","Austria","Chinese Taipei","Singapore","Thailand","Poland","USA","Portugal","France","Egypt","India","Brazil","Australia","England","Hungary","Sweden","Italy","Spain","Puerto Rico","Turkey","Netherlands","Luxembourg","Czech Republic","Kazakhstan","Argentina"];

  function makeTableTennisPlayers(cat) {
    var parts = cat.split("_");
    var tcat = parts[0] || "singles", gender = parts[1] || "men";
    var pool = gender === "women" ? TABLETENNIS_NAMES_W : TABLETENNIS_NAMES_M;
    var countries = gender === "women" ? TABLETENNIS_COUNTRIES_W : TABLETENNIS_COUNTRIES_M;
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var base = 9000 - i * 65;
      ps.push({ rank: i+1, name: pool[i % pool.length], country: countries[i % countries.length], points: Math.max(1, Math.round(base + Math.random() * 100)), tournaments: Math.round(5 + Math.random() * 20), titles: Math.round(i < 15 ? 3 + Math.random() * 10 : Math.random() * 4), winrate: parseFloat((50 + Math.random() * 40).toFixed(1)), prize: parseFloat((i < 25 ? 5 - i * 0.15 : Math.random() * 2).toFixed(2)) });
    }
    if (tcat === "singles") ps.sort(function(a,b){return b.points-a.points});
    else ps.sort(function(a,b){return b.titles-a.titles});
    ps.forEach(function(p,i){p.rank=i+1});
    return ps;
  }

  var BASKETBALL_NAMES = ["LeBron James","Stephen Curry","Kevin Durant","Giannis Antetokounmpo","Luka Doncic","Joel Embiid","Nikola Jokic","Jayson Tatum","Shai Gilgeous-Alexander","Anthony Edwards","Devin Booker","Kyrie Irving","Damian Lillard","Anthony Davis","Jimmy Butler","Paolo Banchero","Donovan Mitchell","Trae Young","Ja Morant","Zion Williamson","Victor Wembanyama","Jamal Murray","Brandon Ingram","Darius Garland","Tyrese Haliburton","LaMelo Ball","Chet Holmgren","Alperen Sengun","Scottie Barnes","Jalen Brunson","Domantas Sabonis","Bam Adebayo","Jaylen Brown","Desmond Bane","CJ McCollum","Klay Thompson","Andrew Wiggins","Rudy Gobert","Karl-Anthony Towns","Mikal Bridges","Jalen Green","Cade Cunningham","Scoot Henderson","Brandon Miller","Amen Thompson","Ausar Thompson","Bilal Coulibaly","Jarace Walker","Taylor Hendricks","Keyonte George"];
  var BASKETBALL_TEAMS = ["LAL","GSW","PHX","MIL","DAL","PHI","DEN","BOS","OKC","MIN","PHX","DAL","MIL","LAL","MIA","ORL","CLE","ATL","MEM","NOP","SAS","DEN","NOP","CLE","IND","CHA","OKC","HOU","TOR","NYK","SAC","MIA","BOS","MEM","NOP","GSW","GSW","MIN","MIN","BKN","HOU","DET","POR","CHA","HOU","DET","WAS","IND","UTA","UTA"];
  var BASKETBALL_POS = ["SF","PG","SF","PF","PG","C","C","SF","PG","SG","SG","PG","PG","PF","SF","PF","SG","PG","PG","PF","C","PG","SF","PG","PG","PG","C","C","SF","PG","C","C","SG","SG","SG","SG","SF","C","C","SF","SG","PG","PG","SF","SG","SG","SF","SF","PF","SG"];

  function makeBasketballPlayers(cat) {
    var ps = [];
    for (var i = 0; i < 100; i++) {
      var base = 50 - i * 0.4;
      var ppg = parseFloat(Math.max(5, (base * 0.6 + Math.random() * 15)).toFixed(1));
      var rpg = parseFloat(Math.max(2, (base * 0.2 + Math.random() * 8)).toFixed(1));
      var apg = parseFloat(Math.max(1, (base * 0.15 + Math.random() * 7)).toFixed(1));
      var fgp = parseFloat((0.4 + Math.random() * 0.2).toFixed(3));
      ps.push({ rank: i+1, name: BASKETBALL_NAMES[i % BASKETBALL_NAMES.length], team: BASKETBALL_TEAMS[i % BASKETBALL_TEAMS.length], position: BASKETBALL_POS[i % BASKETBALL_POS.length], points: ppg, rebounds: rpg, assists: apg, fg_pct: fgp, rating: parseFloat((ppg + rpg * 1.2 + apg * 1.5).toFixed(1)) });
    }
    if (cat === "points") ps.sort(function(a,b){return b.points-a.points});
    else if (cat === "rebounds") ps.sort(function(a,b){return b.rebounds-a.rebounds});
    else ps.sort(function(a,b){return b.assists-a.assists});
    ps.forEach(function(p,i){p.rank=i+1});
    return ps;
  }

  function getConfig(sportId) {
    var cfg = SPORTS[sportId];
    if (!cfg) return null;
    return { id: sportId, label: cfg.label, icon: cfg.icon, title: cfg.title, subtitle: cfg.subtitle, defaultCategory: cfg.defaultCategory, filters: cfg.filters, columns: cfg.columns };
  }

  function getPlayers(sportId, cat) {
    if (!cat) {
      var cfg = SPORTS[sportId];
      if (!cfg) return [];
      cat = cfg.defaultCategory;
    }
    switch (sportId) {
      case "cricket": return makeCricketPlayers(sportId, cat);
      case "football": return makeFootballPlayers(cat);
      case "basketball": return makeBasketballPlayers(cat);
      case "tennis": return makeTennisPlayers(cat);
      case "baseball": return makeBaseballPlayers(cat);
      case "hockey": return makeHockeyPlayers(cat);
      case "volleyball": return makeVolleyballPlayers(cat);
      case "kabbaddi": return makeKabaddiPlayers(cat);
      case "e-sports": return makeEsportsPlayers(cat);
      case "table-tennis": return makeTableTennisPlayers(cat);
      default: return [];
    }
  }

  var staticData = null;
  var staticLoaded = false;

  function getStaticData(sportId, cat) {
    if (!staticLoaded) return null;
    if (!staticData || !staticData[sportId]) return null;
    var sportData = staticData[sportId];
    if (sportData[cat] && sportData[cat].length) return sportData[cat];
    var parts = cat.split("_");
    if (parts.length >= 2 && sportData[parts[0] + "_" + parts[1]]) return sportData[parts[0] + "_" + parts[1]];
    if (parts.length >= 3 && sportData[parts[0] + "_" + parts[1] + "_" + parts[2]]) return sportData[parts[0] + "_" + parts[1] + "_" + parts[2]];
    return null;
  }

  async function loadStaticData() {
    if (staticLoaded) return;
    try {
      var res = await fetch('data/player-stats.json', { signal: AbortSignal.timeout(3000) });
      if (!res.ok) throw new Error('Not found');
      staticData = await res.json();
      staticLoaded = true;
    } catch(e) {
      staticLoaded = true;
    }
  }

  function getPlayers(sportId, cat) {
    if (!cat) {
      var cfg = SPORTS[sportId];
      if (!cfg) return [];
      cat = cfg.defaultCategory;
    }
    if (staticData && staticData[sportId]) {
      var sportData = staticData[sportId];
      if (sportData[cat] && sportData[cat].length) return sportData[cat].slice(0, 100);
    }
    switch (sportId) {
      case "cricket": return makeCricketPlayers(sportId, cat);
      case "football": return makeFootballPlayers(cat);
      case "basketball": return makeBasketballPlayers(cat);
      case "tennis": return makeTennisPlayers(cat);
      case "baseball": return makeBaseballPlayers(cat);
      case "hockey": return makeHockeyPlayers(cat);
      case "volleyball": return makeVolleyballPlayers(cat);
      case "kabbaddi": return makeKabaddiPlayers(cat);
      case "e-sports": return makeEsportsPlayers(cat);
      case "table-tennis": return makeTableTennisPlayers(cat);
      default: return [];
    }
  }

  return { getConfig: getConfig, getPlayers: getPlayers, getStaticData: getStaticData, loadStaticData: loadStaticData, SPORTS: SPORTS };
})();
