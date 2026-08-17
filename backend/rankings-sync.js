const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');
const quota = require('./api-quota');

// Minimal .env loader (no external dep). Reads backend/.env (gitignored).
// The key is NEVER hardcoded in source and NEVER sent to the browser.
function loadEnv() {
  const envPath = path.join(__dirname, '.env');
  try {
    const txt = fs.readFileSync(envPath, 'utf8');
    txt.split('\n').forEach(line => {
      const m = line.match(/^\s*([\w.-]+)\s*=\s*(.*)\s*$/);
      if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    });
  } catch { /* no .env — rely on process.env */ }
}
loadEnv();
const API_SPORTS_KEY = process.env.API_SPORTS_KEY || '';
const RAPID_API_KEY = process.env.CRICKET_KEY || "";

const DATA_DIR = path.join(__dirname, '..', 'data');
const PLAYER_RANKINGS_PATH = path.join(DATA_DIR, 'player-rankings.json');
const TEAM_RANKINGS_PATH = path.join(DATA_DIR, 'team-rankings.json');

const CACHE_DURATION = 6 * 60 * 60 * 1000;
let lastSyncTime = null;
let syncInProgress = false;

function log(msg) {
  const ts = new Date().toISOString().replace('T', ' ').slice(0, 19);
  console.log(`[RankingsSync] ${ts} - ${msg}`);
}

function loadJSON(p) {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; }
}

function saveJSON(p, data) {
  fs.writeFileSync(p, JSON.stringify(data, null, 2), 'utf8');
}

/**
 * Quota-aware + cached fetch. Every outbound external request goes through
 * here so the daily 100-call budget is enforced and successful responses are
 * cached to disk (served to all users without touching the API again).
 */
async function fetchWithTimeout(url, opts = {}) {
  const { timeout = 10000, headers = {}, method = 'GET', params = null, ttlMs = CACHE_DURATION, cost = 1 } = opts;
  const result = await quota.cachedFetch(url, params, async () => {
    try {
      const res = await axios({ method, url, headers, timeout, params });
      return res.data;
    } catch {
      return null;
    }
  }, { ttlMs, cost });
  if (result.source === 'quota-exhausted') {
    log(`Quota exhausted — skipping ${url}`);
  } else if (result.source === 'cache') {
    log(`Cache hit for ${url} (age ${Math.round((result.ageMs || 0) / 1000)}s)`);
  } else if (result.source === 'live') {
    log(`Live fetch OK for ${url}`);
  }
  return result.data;
}

async function scrapeICCRankings(format, gender) {
  const slug = `${format}-${gender}`;
  const url = `https://www.icc-cricket.com/rankings/${slug}/player-rankings/batting`;
  log(`Scraping ICC rankings: ${slug}`);
  try {
    const html = await fetchWithTimeout(url, { timeout: 15000 });
    if (!html) return null;
    const $ = cheerio.load(html);
    const players = [];
    $('table tbody tr').each((i, row) => {
      if (players.length >= 100) return false;
      const cols = $(row).find('td');
      if (cols.length < 5) return;
      const name = $(cols[1]).text().trim();
      const rating = parseInt($(cols[3]).text().trim()) || 0;
      if (name && rating) {
        players.push({
          rank: players.length + 1,
          name,
          country: $(cols[2]).text().trim() || '',
          rating,
          matches: parseInt($(cols[4]).text().trim()) || 0,
          runs: 0, wkts: 0, avg: 0, econ: 0,
          _source: 'icc'
        });
      }
    });
    return players.length > 0 ? players : null;
  } catch (e) {
    log(`ICC scrape failed for ${slug}: ${e.message}`);
    return null;
  }
}

async function scrapeFIFARankings() {
  log('Scraping FIFA rankings');
  try {
    const html = await fetchWithTimeout('https://www.fifa.com/fifa-world-ranking/men', { timeout: 15000 });
    if (!html) return null;
    const $ = cheerio.load(html);
    const teams = [];
    $('table tbody tr').each((i, row) => {
      if (teams.length >= 50) return false;
      const cols = $(row).find('td');
      if (cols.length < 5) return;
      const rank = parseInt($(cols[0]).text().trim()) || i + 1;
      const team = $(cols[1]).text().trim();
      const points = parseInt($(cols[3]).text().trim()) || 0;
      if (team) {
        teams.push({
          rank,
          team,
          code: team.slice(0, 3).toUpperCase(),
          flag: `https://flagcdn.com/${team.slice(0, 2).toLowerCase()}.svg`,
          points,
          previousRank: parseInt($(cols[2]).text().trim()) || rank,
          confederation: '',
          _source: 'fifa'
        });
      }
    });
    return teams.length > 0 ? teams : null;
  } catch (e) {
    log(`FIFA scrape failed: ${e.message}`);
    return null;
  }
}

async function fetchAPISportsRankings(sport, endpoint) {
  const bases = {
    cricket: 'https://api.cricket.api-sports.io',
    tennis: 'https://api.tennis.api-sports.io',
    hockey: 'https://api.hockey.api-sports.io',
  };
  const base = bases[sport];
  if (!base) return null;
  const url = `${base}${endpoint}`;
  log(`Fetching API-Sports ${sport}: ${url}`);
  try {
    const data = await fetchWithTimeout(url, {
      timeout: 10000,
      headers: { 'x-apisports-key': API_SPORTS_KEY }
    });
    return data;
  } catch (e) {
    log(`API-Sports ${sport} failed: ${e.message}`);
    return null;
  }
}

// cricket-live-line-advance (entitysport) — OFFICIAL ICC rankings:
// both TEAM (Test/ODI/T20I, men + women) and PLAYER (batting/bowling/
// all-rounders) rankings, plus the Test Championship table.
// GET https://cricket-live-line-advance.p.rapidapi.com/iccranks
async function fetchICCranksFromAdvance() {
  const url = 'https://cricket-live-line-advance.p.rapidapi.com/iccranks';
  log('Fetching ICC rankings (teams + players) from cricket-live-line-advance');
  try {
    const data = await fetchWithTimeout(url, {
      timeout: 20000,
      headers: {
        'x-rapidapi-key': RAPID_API_KEY,
        'x-rapidapi-host': 'cricket-live-line-advance.p.rapidapi.com'
      }
    });
    if (!data || !data.response) return null;
    const resp = data.response;
    if (!resp.ranks) return null;
    return resp;
  } catch (e) {
    log(`ICC ranks (advance) failed: ${e.message}`);
    return null;
  }
}

// Map a single rank list to normalized player rows for player-rankings.json
function normalizeICCPlayers(list, formatLabel) {
  if (!Array.isArray(list)) return null;
  return list.map((r, i) => ({
    rank: parseInt(r.rank) || i + 1,
    name: r.player || 'Unknown',
    country: r.team || '',
    rating: parseFloat(r.rating) || 0,
    points: parseInt(r.points) || 0,
    matches: parseInt(r.matches) || 0,
    runs: 0, wkts: 0, avg: 0, econ: 0,
    image: r.image_url || '',
    format: formatLabel,
    _source: 'icc-advance'
  }));
}

// Map a single team rank list to normalized rows for team-rankings.json
function normalizeICCTeams(list) {
  if (!Array.isArray(list)) return null;
  return list.map((r, i) => ({
    rank: parseInt(r.rank) || i + 1,
    team: r.team || 'Unknown',
    code: r.team_short_name || (r.team || '').slice(0, 3).toUpperCase(),
    flag: '',
    logo: r.image_url || '',
    points: parseInt(r.points) || 0,
    rating: parseFloat(r.rating) || 0,
    matches: parseInt(r.matches) || 0,
    wins: parseInt(r.win) || 0,
    losses: parseInt(r.loss) || 0,
    draws: parseInt(r.drawn) || 0,
    winPct: parseFloat(r.pct) || 0,
    _source: 'icc-advance'
  }));
}

// Cricket "Live Line / Advance" via API-Sports — returns current teams/series.// Routed through the quota+cache layer so the 100/day budget is protected.
async function fetchCricketFromAPISports() {
  if (!API_SPORTS_KEY) { log('No API-Sports key configured — skipping cricket API'); return null; }
  try {
    const res = await fetchAPISportsRankings('cricket', '/teams?search=');
    if (!res || !res.response) return null;
    return res.response.slice(0, 50).map((t, i) => ({
      rank: i + 1,
      name: t.name || t.team || 'Unknown',
      code: (t.code || t.id || '').toString().toUpperCase(),
      country: t.country || '',
      rating: t.rating != null ? t.rating : 0,
      _source: 'api-sports-cricket'
    }));
  } catch (e) {
    log(`Cricket API-Sports failed: ${e.message}`);
    return null;
  }
}

async function fetchESPNRankings(sport, category) {  const endpoints = {
    basketball: {
      url: `https://site.web.api.espn.com/apis/common/v3/sports/basketball/nba/statistics/byathlete?season=2026&seasontype=2&limit=100`,
      parse: (data) => {
        if (!data.athletes) return null;
        return data.athletes.map((a, i) => {
          const ath = a.athlete;
          const o = a.categories?.[1]?.values || [];
          const g = a.categories?.[0]?.values || [];
          return {
            rank: i + 1,
            name: ath.displayName || '',
            athleteId: ath.id || '',
            team: ath.teamShortName || '',
            position: ath.position?.abbreviation || '',
            points: parseFloat(o[0]) || 0,
            rebounds: parseFloat(g[11]) || 0,
            assists: parseFloat(o[10]) || 0,
            fg_pct: parseFloat(o[3]) || 0,
            rating: 0,
            _source: 'espn'
          };
        });
      }
    },
    baseball: {
      url: `https://site.web.api.espn.com/apis/common/v3/sports/baseball/mlb/statistics/byathlete?category=batting&season=2026&seasontype=2&limit=100`,
      parse: (data) => {
        if (!data.athletes) return null;
        return data.athletes.map((a, i) => {
          const ath = a.athlete;
          const batting = a.categories?.find(c => c.name === 'batting');
          const v = batting?.values || [];
          return {
            rank: i + 1,
            name: ath.displayName || '',
            athleteId: ath.id || '',
            team: ath.teamShortName || '',
            position: ath.position?.abbreviation || '',
            hr: parseInt(v[7]) || 0,
            avg: parseFloat(v[4]) || 0,
            rbi: parseInt(v[8]) || 0,
            ops: parseFloat(v[15]) || 0,
            games: parseInt(v[0]) || 0,
            _source: 'espn'
          };
        });
      }
    },
    hockey: {
      url: `https://site.web.api.espn.com/apis/common/v3/sports/hockey/nhl/statistics/byathlete?season=2026&seasontype=2&limit=100`,
      parse: (data) => {
        if (!data.athletes) return null;
        return data.athletes.map((a, i) => {
          const ath = a.athlete;
          const o = a.categories?.find(c => c.name === 'offensive')?.values || [];
          const g = a.categories?.find(c => c.name === 'general')?.values || [];
          return {
            rank: i + 1,
            name: ath.displayName || '',
            athleteId: ath.id || '',
            team: ath.teamShortName || '',
            position: ath.position?.abbreviation || '',
            goals: parseInt(o[0]) || 0,
            assists: parseInt(o[1]) || 0,
            points: parseInt(o[2]) || 0,
            games: parseInt(g[0]) || 0,
            rating: parseInt(o[2]) || 0,
            _source: 'espn'
          };
        });
      }
    }
  };
  const config = endpoints[sport];
  if (!config) return null;
  try {
    const data = await fetchWithTimeout(config.url, { timeout: 10000 });
    if (!data) return null;
    return config.parse(data);
  } catch (e) {
    log(`ESPN ${sport} failed: ${e.message}`);
    return null;
  }
}

// sportscore.com — real football top scorers/assists (free, no key).
// GET https://sportscore.com/api/widget/topscorers/?sport=football&slug=english-premier-league&limit=50&stat=goals|assists
async function fetchFootballScorers(stat) {
  const url = `https://sportscore.com/api/widget/topscorers/?sport=football&slug=english-premier-league&limit=50&stat=${stat}&src=fanconnact`;
  log(`Fetching football ${stat} (sportscore.com)`);
  try {
    const data = await fetchWithTimeout(url, { timeout: 12000 });
    if (!data || !Array.isArray(data.scorers) || !data.scorers.length) return null;
    return data.scorers.map((s, i) => ({
      rank: i + 1,
      name: s.player || 'Unknown',
      team: s.team || '',
      country: '',
      position: '',
      goals: s.goals != null ? s.goals : 0,
      assists: s.assists != null ? s.assists : 0,
      matches: s.matches || 0,
      minutes: s.minutes || 0,
      rating: s.rating != null ? parseFloat(s.rating) : 0,
      logo: s.player_logo || '',
      _source: 'sportscore'
    }));
  } catch (e) {
    log(`Football ${stat} failed: ${e.message}`);
    return null;
  }
}

// ════════════════════════════════════════════════════════════════
// REAL TEAM RANKINGS (per game → league/format via live APIs)
// ════════════════════════════════════════════════════════════════

// FIFA API v3 — official world team rankings (men/women), no key needed.
// GET https://api.fifa.com/api/v3/rankings?gender=MALE|FEMALE&type=FIFA
async function fetchFIFATeamRankings(gender) {
  const url = `https://api.fifa.com/api/v3/rankings?gender=${gender}&type=FIFA`;
  log(`Fetching FIFA team rankings (${gender})`);
  try {
    const data = await fetchWithTimeout(url, { timeout: 15000 });
    if (!data || !Array.isArray(data.Results) || !data.Results.length) return null;
    return data.Results
      .filter(r => r.StatusRanked === 1)
      .map(r => ({
        rank: r.Rank || 0,
        team: (r.TeamName && r.TeamName[0] && r.TeamName[0].Description) || r.IdCountry || 'Unknown',
        code: r.IdCountry || '',
        flag: r.IdCountry ? `https://flagcdn.com/${r.IdCountry.toLowerCase()}.svg` : '',
        points: r.TotalPoints || 0,
        previousRank: r.PrevRank || r.Rank || 0,
        matches: r.Matches || 0,
        confederation: r.ConfederationName || '',
        trend: (r.Rank != null && r.PrevRank != null) ? (r.Rank < r.PrevRank ? 'up' : r.Rank > r.PrevRank ? 'down' : 'neutral') : 'neutral',
        trendVal: (r.Rank != null && r.PrevRank != null) ? Math.abs(r.Rank - r.PrevRank) : 0,
        _source: 'fifa-api'
      }))
      .sort((a, b) => (a.rank || 999) - (b.rank || 999));
  } catch (e) {
    log(`FIFA API ${gender} failed: ${e.message}`);
    return null;
  }
}

// ESPN standings API — real league tables with logos, free, no key.
// GET https://site.web.api.espn.com/apis/v2/sports/{sport}/{league}/standings
async function fetchESPNTeamStandings(sport, league, leagueLabel) {
  const url = `https://site.web.api.espn.com/apis/v2/sports/${sport}/${league}/standings`;
  log(`Fetching ESPN ${leagueLabel} standings`);
  try {
    const data = await fetchWithTimeout(url, { timeout: 15000 });
    if (!data || !data.children) return null;
    const rows = [];
    (data.children || []).forEach(child => {
      const entries = (child.standings && child.standings.entries) || [];
      entries.forEach(e => {
        const stats = {};
        (e.stats || []).forEach(s => { stats[s.name] = s.value; });
        const wins = parseInt(stats.wins) || 0;
        const losses = parseInt(stats.losses) || 0;
        const ties = parseInt(stats.ties) || 0;
        const played = parseInt(stats.gamesPlayed) || (wins + losses + ties) || 0;
        const winPct = stats.winPercent != null ? parseFloat(stats.winPercent) * 100 : (played ? (wins / played) * 100 : 0);
        const rank = stats.rank != null ? parseInt(stats.rank) : stats.playoffSeed != null ? parseInt(stats.playoffSeed) : 0;
        rows.push({
          rank: rank || 0,
          team: (e.team && (e.team.displayName || e.team.name)) || 'Unknown',
          code: (e.team && e.team.abbreviation) || '',
          flag: '',
          logo: (e.team && e.team.logos && e.team.logos[0] && e.team.logos[0].href) || '',
          matches: played,
          wins,
          losses,
          draws: ties,
          winPct: Math.round(winPct * 100) / 100,
          rating: stats.points != null ? parseFloat(stats.points) : Math.round(winPct * 100) / 100,
          points: stats.points != null ? parseFloat(stats.points) : 0,
          streak: stats.streak || '',
          division: (child.name || '').split(' ')[0],
          _source: 'espn-standings',
          _league: leagueLabel
        });
      });
    });
    if (!rows.length) return null;
    rows.sort((a, b) => (a.rank || 999) - (b.rank || 999));
    rows.forEach((r, i) => { if (!r.rank) r.rank = i + 1; });
    return rows;
  } catch (e) {
    log(`ESPN ${leagueLabel} standings failed: ${e.message}`);
    return null;
  }
}

// allsportsapi2 (RapidAPI) — official ATP/WTA live rankings.
// GET https://allsportsapi2.p.rapidapi.com/api/tennis/rankings/atp|wta/live
async function fetchTennisLiveRankings(tour) {
  const url = `https://allsportsapi2.p.rapidapi.com/api/tennis/rankings/${tour}/live`;
  log(`Fetching tennis ${tour.toUpperCase()} live rankings`);
  try {
    const data = await fetchWithTimeout(url, {
      timeout: 15000,
      headers: {
        'x-rapidapi-key': RAPID_API_KEY,
        'x-rapidapi-host': 'allsportsapi2.p.rapidapi.com'
      }
    });
    if (!data || !Array.isArray(data.rankings) || !data.rankings.length) return null;
    return data.rankings
      .filter(r => r.team)
      .map(r => ({
        rank: r.ranking || 0,
        team: (r.team && r.team.name) || r.rowName || 'Unknown',
        name: (r.team && r.team.name) || r.rowName || 'Unknown',
        code: (r.team && r.team.country && r.team.country.alpha2) || (r.country && r.country.alpha2) || '',
        country: (r.team && r.team.country && r.team.country.name) || '',
        flag: (() => {
          const c = (r.team && r.team.country && r.team.country.alpha2) || (r.country && r.country.alpha2) || '';
          return c ? `https://flagcdn.com/${c.toLowerCase()}.svg` : '';
        })(),
        points: r.points || 0,
        previousRank: r.previousRanking || r.ranking || 0,
        matches: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        winPct: 0,
        rating: r.points || 0,
        trend: (r.ranking != null && r.previousRanking != null) ? (r.ranking < r.previousRanking ? 'up' : r.ranking > r.previousRanking ? 'down' : 'neutral') : 'neutral',
        trendVal: (r.ranking != null && r.previousRanking != null) ? Math.abs(r.ranking - r.previousRanking) : 0,
        _source: 'allsportsapi'
      }))
      .sort((a, b) => (a.rank || 999) - (b.rank || 999));
  } catch (e) {
    log(`Tennis ${tour} failed: ${e.message}`);
    return null;
  }
}

function initializeDefaultData() {
  let playerData = loadJSON(PLAYER_RANKINGS_PATH);
  let teamData = loadJSON(TEAM_RANKINGS_PATH);

  if (!playerData) {
    log('Creating default player-rankings.json');
    playerData = {};
    saveJSON(PLAYER_RANKINGS_PATH, playerData);
  }
  if (!teamData) {
    log('Creating default team-rankings.json');
    teamData = {};
    saveJSON(TEAM_RANKINGS_PATH, teamData);
  }

  return { playerData, teamData };
}

async function syncPlayerRankings() {
  log('Starting player rankings sync...');
  const { playerData, teamData } = initializeDefaultData();

  const updates = [];

  // ICC rankings (men + women, teams + players) via cricket-live-line-advance
  updates.push(
    fetchICCranksFromAdvance().then(resp => {
      if (!resp) return;
      if (!playerData.cricket) playerData.cricket = {};
      const formatMap = { odis: 'ODI', tests: 'Test', t20s: 'T20I' };

      // Men: batting / bowling / all-rounders per format
      ['batsmen', 'bowlers', 'all-rounders'].forEach(cat => {
        const suffix = cat === 'batsmen' ? 'bat' : cat === 'bowlers' ? 'bowl' : 'all';
        Object.keys(formatMap).forEach(k => {
          const list = normalizeICCPlayers(resp.ranks[cat][k], formatMap[k]);
          if (list && list.length) {
            playerData.cricket[`${formatMap[k].toLowerCase()}_${suffix}_men`] = list;
            log(`Updated ICC ${formatMap[k]} ${cat} (men): ${list.length} players`);
          }
        });
      });

      // Women: batting / bowling / all-rounders per format
      if (resp.women_ranks) {
        ['batsmen', 'bowlers', 'all-rounders'].forEach(cat => {
          const suffix = cat === 'batsmen' ? 'bat' : cat === 'bowlers' ? 'bowl' : 'all';
          Object.keys(formatMap).forEach(k => {
            const list = resp.women_ranks[cat] && normalizeICCPlayers(resp.women_ranks[cat][k], formatMap[k]);
            if (list && list.length) {
              playerData.cricket[`${formatMap[k].toLowerCase()}_${suffix}_women`] = list;
              log(`Updated ICC ${formatMap[k]} ${cat} (women): ${list.length} players`);
            }
          });
        });
      }

      // WTC standings (Test Championship table) as team list
      if (Array.isArray(resp.test_championship_ranking) && resp.test_championship_ranking.length) {
        const wtc = resp.test_championship_ranking.map((r, i) => ({
          rank: parseInt(r.rank) || i + 1,
          team: r.team_name || r.team || 'Unknown',
          code: r.team_short_name || '',
          logo: r.team_logo || '',
          matches: parseInt(r.total_match) || 0,
          wins: parseInt(r.win) || 0,
          losses: parseInt(r.loss) || 0,
          draws: parseInt(r.drawn) || 0,
          points: parseInt(r.points) || 0,
          winPct: parseFloat(r.pct) || 0,
          _source: 'icc-advance'
        }));
        playerData.cricket.wtc = wtc;
        log(`Updated ICC WTC table: ${wtc.length} teams`);
      }
    }).catch(() => {})
  );

  // Cricket via API-Sports (live line / rankings) — budgeted + cached.
  updates.push(
    fetchCricketFromAPISports().then(data => {
      if (data && data.length) {
        if (!playerData.cricket) playerData.cricket = {};
        playerData.cricket.api_sports = data;
        log(`Updated cricket (API-Sports): ${data.length} teams/players`);
      }
    }).catch(() => {})
  );

  updates.push(
    fetchESPNRankings('basketball', 'points').then(data => {
      if (data) {
        if (!playerData.basketball) playerData.basketball = {};
        playerData.basketball.points = data;
        log(`Updated NBA scoring: ${data.length} players`);
      }
    }).catch(() => {})
  );

  updates.push(
    fetchESPNRankings('baseball', 'hr').then(data => {
      if (data) {
        if (!playerData.baseball) playerData.baseball = {};
        playerData.baseball.hr = data;
        log(`Updated MLB HR: ${data.length} players`);
      }
    }).catch(() => {})
  );

  // NHL scoring leaders via ESPN byathlete (real stats)
  updates.push(
    fetchESPNRankings('hockey', 'goals').then(data => {
      if (data) {
        if (!playerData.hockey) playerData.hockey = {};
        playerData.hockey.goals_men = data;
        log(`Updated NHL goals: ${data.length} players`);
      }
    }).catch(() => {})
  );

  // Football top scorers + assists via sportscore.com (real, free)
  updates.push(
    fetchFootballScorers('goals').then(data => {
      if (data) {
        if (!playerData.football) playerData.football = {};
        playerData.football.scorers_men = data;
        log(`Updated football scorers: ${data.length} players`);
      }
    }).catch(() => {})
  );

  updates.push(
    fetchFootballScorers('assists').then(data => {
      if (data) {
        if (!playerData.football) playerData.football = {};
        playerData.football.assists_men = data;
        log(`Updated football assists: ${data.length} players`);
      }
    }).catch(() => {})
  );

  // Tennis ATP/WTA player rankings via allsportsapi2 (real live rankings)
  updates.push(
    fetchTennisLiveRankings('atp').then(data => {
      if (data) {
        if (!playerData.tennis) playerData.tennis = {};
        playerData.tennis.atp_singles = data;
        log(`Updated tennis ATP: ${data.length} players`);
      }
    }).catch(() => {})
  );

  updates.push(
    fetchTennisLiveRankings('wta').then(data => {
      if (data) {
        if (!playerData.tennis) playerData.tennis = {};
        playerData.tennis.wta_singles = data;
        log(`Updated tennis WTA: ${data.length} players`);
      }
    }).catch(() => {})
  );

  updates.push(
    scrapeFIFARankings().then(data => {
      if (data) {
        if (!playerData.football) playerData.football = {};
        playerData.football.fifa_rankings = data;
        log(`Updated FIFA rankings: ${data.length} teams`);
      }
    }).catch(() => {})
  );

  await Promise.allSettled(updates);

  const lastUpdated = new Date().toISOString();
  if (!playerData._meta) playerData._meta = {};
  playerData._meta.lastSync = lastUpdated;
  playerData._meta.syncInterval = `${CACHE_DURATION / 1000 / 60 / 60}h`;

  saveJSON(PLAYER_RANKINGS_PATH, playerData);

  if (teamData._meta) teamData._meta.lastSync = lastUpdated;
  saveJSON(TEAM_RANKINGS_PATH, teamData);

  lastSyncTime = Date.now();
  log(`Player rankings sync complete. Next sync in ${CACHE_DURATION / 1000 / 60 / 60}h`);
}

async function syncTeamRankings() {
  log('Starting team rankings sync (real APIs)...');
  const teamData = loadJSON(TEAM_RANKINGS_PATH);
  if (!teamData) {
    log('No team rankings file found, creating default');
    return;
  }

  const apply = (sportId, gender, category, list) => {
    if (!list || !list.length) return false;
    if (!teamData[sportId]) return false;
    if (!teamData[sportId].rankings) teamData[sportId].rankings = {};
    if (!teamData[sportId].rankings[gender]) teamData[sportId].rankings[gender] = {};
    teamData[sportId].rankings[gender][category] = list;
    log(`  Updated ${sportId} ${gender}/${category}: ${list.length} teams`);
    return true;
  };

  // ── Football: FIFA world ranking (Men/Women) + ESPN league tables ──
  const [fifaMen, fifaWomen, epl, laliga] = await Promise.allSettled([
    fetchFIFATeamRankings('MALE'),
    fetchFIFATeamRankings('FEMALE'),
    fetchESPNTeamStandings('soccer', 'eng.1', 'EPL'),
    fetchESPNTeamStandings('soccer', 'esp.1', 'La Liga'),
  ]);
  if (fifaMen.status === 'fulfilled') apply('football', 'Men', 'FIFA', fifaMen.value);
  if (fifaWomen.status === 'fulfilled') apply('football', 'Women', 'FIFA', fifaWomen.value);
  if (epl.status === 'fulfilled') apply('football', 'Men', 'EPL', epl.value);
  if (laliga.status === 'fulfilled') apply('football', 'Men', 'La Liga', laliga.value);

  // ── Basketball: ESPN NBA standings ──
  const nba = await fetchESPNTeamStandings('basketball', 'nba', 'NBA');
  apply('basketball', 'Men', 'NBA', nba);

  // ── Baseball: ESPN MLB standings ──
  const mlb = await fetchESPNTeamStandings('baseball', 'mlb', 'MLB');
  apply('baseball', 'Men', 'MLB', mlb);

  // ── Hockey: ESPN NHL standings ──
  const nhl = await fetchESPNTeamStandings('hockey', 'nhl', 'NHL');
  apply('hockey', 'Men', 'NHL', nhl);

  // ── Tennis: ATP (Men) / WTA (Women) live rankings via RapidAPI ──
  const [atp, wta] = await Promise.allSettled([
    fetchTennisLiveRankings('atp'),
    fetchTennisLiveRankings('wta'),
  ]);
  if (atp.status === 'fulfilled') apply('tennis', 'Men', 'ATP', atp.value);
  if (wta.status === 'fulfilled') apply('tennis', 'Women', 'WTA', wta.value);

  // ── Cricket: official ICC team rankings (Test/ODI/T20I, Men + Women)
  //    via cricket-live-line-advance /iccranks ──
  const iccResp = await fetchICCranksFromAdvance();
  if (iccResp) {
    const formatMap = { odis: 'ODI', tests: 'Test', t20s: 'T20I' };
    // Men
    Object.keys(formatMap).forEach(k => {
      apply('cricket', 'Men', formatMap[k], normalizeICCTeams(iccResp.ranks.teams[k]));
    });
    // Women (ICC only ranks ODI + T20I for women)
    if (iccResp.women_ranks && iccResp.women_ranks.teams) {
      ['odis', 't20s'].forEach(k => {
        apply('cricket', 'Women', formatMap[k], normalizeICCTeams(iccResp.women_ranks.teams[k]));
      });
    }
  }

  if (!teamData._meta) teamData._meta = {};
  teamData._meta.lastSync = new Date().toISOString();
  teamData._meta.syncInterval = `${CACHE_DURATION / 1000 / 60 / 60}h`;

  saveJSON(TEAM_RANKINGS_PATH, teamData);
  log('Team rankings sync complete');
}

async function fullSync() {
  if (syncInProgress) {
    log('Sync already in progress, skipping');
    return;
  }
  syncInProgress = true;
  try {
    await syncPlayerRankings();
    await syncTeamRankings();
    log('Full sync cycle completed');
  } catch (e) {
    log(`Sync error: ${e.message}`);
  } finally {
    syncInProgress = false;
  }
}

function getLastSyncTime() {
  return lastSyncTime;
}

function startAutoSync(intervalMs = CACHE_DURATION) {
  log(`Starting auto-sync every ${intervalMs / 1000 / 60 / 60}h`);
  fullSync();
  setInterval(() => fullSync(), intervalMs);
}

function getSyncStatus() {
  return {
    lastSync: lastSyncTime ? new Date(lastSyncTime).toISOString() : null,
    inProgress: syncInProgress,
    cacheDuration: CACHE_DURATION,
    nextSync: lastSyncTime ? new Date(lastSyncTime + CACHE_DURATION).toISOString() : 'pending',
    quota: quota.quotaStatus()
  };
}

module.exports = {
  fullSync,
  startAutoSync,
  getSyncStatus,
  getLastSyncTime,
  syncPlayerRankings,
  syncTeamRankings,
  CACHE_DURATION
};
