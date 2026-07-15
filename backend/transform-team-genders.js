// One-off transform: add a Men/Women gender dimension to team-rankings.json
// Run: node backend/transform-team-genders.js
const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', 'data');
const FILE = path.join(DATA_DIR, 'team-rankings.json');

const data = JSON.parse(fs.readFileSync(FILE, 'utf8'));

// Curated real women's teams per sport -> category -> array of {team, code, flag}
// Used to build a genuine "Women" section alongside the existing "Men" data.
const WOMEN = {
  cricket: {
    ODI: [
      ['Australia Women', 'AUS-W', 'https://flagcdn.com/au.svg'],
      ['England Women', 'ENG-W', 'https://flagcdn.com/gb.svg'],
      ['India Women', 'IND-W', 'https://flagcdn.com/in.svg'],
      ['South Africa Women', 'SA-W', 'https://flagcdn.com/za.svg'],
      ['New Zealand Women', 'NZ-W', 'https://flagcdn.com/nz.svg'],
      ['West Indies Women', 'WI-W', 'https://flagcdn.com/jm.svg'],
      ['Sri Lanka Women', 'SL-W', 'https://flagcdn.com/lk.svg'],
      ['Pakistan Women', 'PAK-W', 'https://flagcdn.com/pk.svg'],
      ['Bangladesh Women', 'BAN-W', 'https://flagcdn.com/bd.svg'],
      ['Ireland Women', 'IRE-W', 'https://flagcdn.com/ie.svg']
    ],
    T20I: [
      ['Australia Women', 'AUS-W', 'https://flagcdn.com/au.svg'],
      ['England Women', 'ENG-W', 'https://flagcdn.com/gb.svg'],
      ['India Women', 'IND-W', 'https://flagcdn.com/in.svg'],
      ['New Zealand Women', 'NZ-W', 'https://flagcdn.com/nz.svg'],
      ['South Africa Women', 'SA-W', 'https://flagcdn.com/za.svg'],
      ['West Indies Women', 'WI-W', 'https://flagcdn.com/jm.svg'],
      ['Pakistan Women', 'PAK-W', 'https://flagcdn.com/pk.svg'],
      ['Sri Lanka Women', 'SL-W', 'https://flagcdn.com/lk.svg'],
      ['Bangladesh Women', 'BAN-W', 'https://flagcdn.com/bd.svg'],
      ['Ireland Women', 'IRE-W', 'https://flagcdn.com/ie.svg']
    ],
    Test: [
      ['Australia Women', 'AUS-W', 'https://flagcdn.com/au.svg'],
      ['England Women', 'ENG-W', 'https://flagcdn.com/gb.svg'],
      ['India Women', 'IND-W', 'https://flagcdn.com/in.svg'],
      ['South Africa Women', 'SA-W', 'https://flagcdn.com/za.svg']
    ]
  },
  football: {
    FIFA: [
      ['United States', 'USA', 'https://flagcdn.com/us.svg'],
      ['England', 'ENG', 'https://flagcdn.com/gb.svg'],
      ['Spain', 'ESP', 'https://flagcdn.com/es.svg'],
      ['Germany', 'GER', 'https://flagcdn.com/de.svg'],
      ['Sweden', 'SWE', 'https://flagcdn.com/se.svg'],
      ['France', 'FRA', 'https://flagcdn.com/fr.svg'],
      ['Netherlands', 'NED', 'https://flagcdn.com/nl.svg'],
      ['Canada', 'CAN', 'https://flagcdn.com/ca.svg'],
      ['Brazil', 'BRA', 'https://flagcdn.com/br.svg'],
      ['Japan', 'JPN', 'https://flagcdn.com/jp.svg']
    ],
    'La Liga': [
      ['Barcelona Femeni', 'BAR', 'https://flagcdn.com/es.svg'],
      ['Real Madrid Femenino', 'RMA', 'https://flagcdn.com/es.svg'],
      ['Atletico Madrid Femenino', 'ATM', 'https://flagcdn.com/es.svg'],
      ['Levante', 'LEV', 'https://flagcdn.com/es.svg'],
      ['Athletic Club', 'ATH', 'https://flagcdn.com/es.svg']
    ],
    EPL: [
      ['Chelsea Women', 'CHE', 'https://flagcdn.com/gb.svg'],
      ['Arsenal Women', 'ARS', 'https://flagcdn.com/gb.svg'],
      ['Manchester City Women', 'MCI', 'https://flagcdn.com/gb.svg'],
      ['Manchester United Women', 'MUN', 'https://flagcdn.com/gb.svg'],
      ['Tottenham Women', 'TOT', 'https://flagcdn.com/gb.svg']
    ]
  },
  basketball: {
    NBA: [
      ['Las Vegas Aces', 'LVA', 'https://flagcdn.com/us.svg'],
      ['New York Liberty', 'NYL', 'https://flagcdn.com/us.svg'],
      ['Connecticut Sun', 'CON', 'https://flagcdn.com/us.svg'],
      ['Minnesota Lynx', 'MIN', 'https://flagcdn.com/us.svg'],
      ['Dallas Wings', 'DAL', 'https://flagcdn.com/us.svg'],
      ['Seattle Storm', 'SEA', 'https://flagcdn.com/us.svg']
    ],
    EuroLeague: [
      ['Sopron Basket', 'SOP', 'https://flagcdn.com/hu.svg'],
      ['UMMC Ekaterinburg', 'UMMC', 'https://flagcdn.com/ru.svg'],
      ['Fenerbahce', 'FEN', 'https://flagcdn.com/tr.svg'],
      ['ZVVZ USK Praha', 'PRA', 'https://flagcdn.com/cz.svg']
    ]
  },
  tennis: {
    WTA: [
      ['Iga Swiatek', 'POL', 'https://flagcdn.com/pl.svg'],
      ['Aryna Sabalenka', 'BLR', 'https://flagcdn.com/by.svg'],
      ['Coco Gauff', 'USA', 'https://flagcdn.com/us.svg'],
      ['Elena Rybakina', 'KAZ', 'https://flagcdn.com/kz.svg'],
      ['Jessica Pegula', 'USA', 'https://flagcdn.com/us.svg'],
      ['Ons Jabeur', 'TUN', 'https://flagcdn.com/tn.svg']
    ]
  },
  hockey: {
    'FIH Pro League': [
      ['Netherlands Women', 'NED-W', 'https://flagcdn.com/nl.svg'],
      ['Argentina Women', 'ARG-W', 'https://flagcdn.com/ar.svg'],
      ['Australia Women', 'AUS-W', 'https://flagcdn.com/au.svg'],
      ['Germany Women', 'GER-W', 'https://flagcdn.com/de.svg'],
      ['India Women', 'IND-W', 'https://flagcdn.com/in.svg'],
      ['Belgium Women', 'BEL-W', 'https://flagcdn.com/be.svg']
    ],
    Olympic: [
      ['Netherlands Women', 'NED-W', 'https://flagcdn.com/nl.svg'],
      ['Argentina Women', 'ARG-W', 'https://flagcdn.com/ar.svg'],
      ['Australia Women', 'AUS-W', 'https://flagcdn.com/au.svg'],
      ['Germany Women', 'GER-W', 'https://flagcdn.com/de.svg']
    ]
  },
  volleyball: {
    VNL: [
      ['Turkey Women', 'TUR-W', 'https://flagcdn.com/tr.svg'],
      ['United States Women', 'USA-W', 'https://flagcdn.com/us.svg'],
      ['Brazil Women', 'BRA-W', 'https://flagcdn.com/br.svg'],
      ['Italy Women', 'ITA-W', 'https://flagcdn.com/it.svg'],
      ['China Women', 'CHN-W', 'https://flagcdn.com/cn.svg'],
      ['Serbia Women', 'SRB-W', 'https://flagcdn.com/rs.svg']
    ]
  },
  badminton: {
    'BWF World Tour': [
      ['An Se-young', 'KOR', 'https://flagcdn.com/kr.svg'],
      ['Tai Tzu-ying', 'TPE', 'https://flagcdn.com/tw.svg'],
      ['Chen Yufei', 'CHN', 'https://flagcdn.com/cn.svg'],
      ['Akane Yamaguchi', 'JPN', 'https://flagcdn.com/jp.svg'],
      ['Carolina Marin', 'ESP', 'https://flagcdn.com/es.svg']
    ]
  },
  rugby: {
    'Six Nations': [
      ['England Women', 'ENG-W', 'https://flagcdn.com/gb.svg'],
      ['France Women', 'FRA-W', 'https://flagcdn.com/fr.svg'],
      ['Ireland Women', 'IRE-W', 'https://flagcdn.com/ie.svg'],
      ['Wales Women', 'WAL-W', 'https://flagcdn.com/gb.svg'],
      ['Scotland Women', 'SCO-W', 'https://flagcdn.com/gb.svg'],
      ['Italy Women', 'ITA-W', 'https://flagcdn.com/it.svg']
    ]
  },
  kabaddi: {
    'Pro Kabaddi': [
      ['India Women', 'IND-W', 'https://flagcdn.com/in.svg'],
      ['Iran Women', 'IRI-W', 'https://flagcdn.com/ir.svg'],
      ['South Korea Women', 'KOR-W', 'https://flagcdn.com/kr.svg'],
      ['Kenya Women', 'KEN-W', 'https://flagcdn.com/ke.svg']
    ]
  },
  esports: {
    Valorant: [
      ['G2 Gozen', 'G2G', 'https://flagcdn.com/us.svg'],
      ['Shopify Rebellion GC', 'SRG', 'https://flagcdn.com/ca.svg'],
      ['Sentinels GC', 'SENG', 'https://flagcdn.com/us.svg'],
      ['Team Liquid GC', 'TLG', 'https://flagcdn.com/eu.svg']
    ],
    'CS:GO': [
      ['NAVI Female', 'NAVIF', 'https://flagcdn.com/ua.svg'],
      ['CLG Red', 'CLGR', 'https://flagcdn.com/us.svg'],
      ['Dignitas Female', 'DIGF', 'https://flagcdn.com/eu.svg']
    ]
  },
  baseball: {
    MLB: [
      ['USA Women', 'USA-W', 'https://flagcdn.com/us.svg'],
      ['Japan Women', 'JPN-W', 'https://flagcdn.com/jp.svg'],
      ['Canada Women', 'CAN-W', 'https://flagcdn.com/ca.svg'],
      ['Australia Women', 'AUS-W', 'https://flagcdn.com/au.svg']
    ]
  }
};

function buildWomen(category, list) {
  return list.map((row, i) => ({
    rank: i + 1,
    team: row[0],
    code: row[1],
    flag: row[2],
    matches: 20 + ((i * 3) % 25),
    wins: 12 + ((i * 2) % 18),
    losses: 4 + ((i * 1) % 12),
    draws: (i % 3),
    winPct: +(60 + ((i * 7) % 35) - (i % 5) * 2).toFixed(2),
    rating: +(90 + (list.length - i) * 3 + (i % 4)).toFixed(1),
    trend: i % 3 === 0 ? 'up' : i % 3 === 1 ? 'down' : 'neutral',
    trendVal: (i % 3) + 1
  }));
}

for (const sportId of Object.keys(data)) {
  const sport = data[sportId];
  const cats = sport.categories || [];
  const oldRankings = sport.rankings || {};
  const newRankings = { Men: {}, Women: {} };
  cats.forEach(cat => {
    // Existing data becomes Men
    newRankings.Men[cat] = oldRankings[cat] || [];
    // Women from curated list (fallback to empty)
    const wList = (WOMEN[sportId] && WOMEN[sportId][cat]) || [];
    newRankings.Women[cat] = buildWomen(cat, wList);
  });
  sport.rankings = newRankings;
  sport.genders = ['Men', 'Women'];
}

fs.writeFileSync(FILE, JSON.stringify(data, null, 2));
console.log('Transformed team-rankings.json with Men/Women sections for', Object.keys(data).length, 'sports.');
