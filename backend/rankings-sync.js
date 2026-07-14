const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

const API_SPORTS_KEY = '300dff825662a9fa64617cb19603443b';

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

async function fetchWithTimeout(url, opts = {}) {
  const { timeout = 10000, headers = {}, method = 'GET' } = opts;
  try {
    const res = await axios({ method, url, headers, timeout });
    return res.data;
  } catch {
    return null;
  }
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

async function fetchESPNRankings(sport, category) {
  const endpoints = {
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

  updates.push(
    scrapeICCRankings('odi', 'men').then(data => {
      if (data) {
        if (!playerData.cricket) playerData.cricket = {};
        playerData.cricket.odi_bat_men = data;
        log(`Updated ICC ODI batting (men): ${data.length} players`);
      }
    }).catch(() => {})
  );

  updates.push(
    scrapeICCRankings('t20', 'men').then(data => {
      if (data) {
        if (!playerData.cricket) playerData.cricket = {};
        playerData.cricket.t20_bat_men = data;
        log(`Updated ICC T20 batting (men): ${data.length} players`);
      }
    }).catch(() => {})
  );

  updates.push(
    scrapeICCRankings('test', 'men').then(data => {
      if (data) {
        if (!playerData.cricket) playerData.cricket = {};
        playerData.cricket.test_bat_men = data;
        log(`Updated ICC Test batting (men): ${data.length} players`);
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

  updates.push(
    scrapeFIFARankings().then(data => {
      if (data) {
        if (!playerData.football) playerData.football = {};
        playerData.football.fifa_rankings = data;
        log(`Updated FIFA rankings: ${data.length} teams`);
        if (teamData.football) {
          teamData.football.rankings.fifa_men = data.map(t => ({
            rank: t.rank,
            team: t.team,
            code: t.code,
            flag: t.flag,
            points: t.points,
            previousRank: t.previousRank,
            trend: t.rank < t.previousRank ? 'up' : t.rank > t.previousRank ? 'down' : 'neutral',
            trendVal: Math.abs(t.rank - t.previousRank)
          }));
        }
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
  log('Starting team rankings sync...');
  const teamData = loadJSON(TEAM_RANKINGS_PATH);
  if (!teamData) {
    log('No team rankings file found, creating default');
    return;
  }

  if (teamData.cricket?.rankings) {
    try {
      const odiData = await scrapeICCRankings('odi', 'men');
      const t20Data = await scrapeICCRankings('t20', 'men');
      const testData = await scrapeICCRankings('test', 'men');
    } catch {}
  }

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
    nextSync: lastSyncTime ? new Date(lastSyncTime + CACHE_DURATION).toISOString() : 'pending'
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
