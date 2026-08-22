// Real cricket proxy — exposes cricbuzz (RapidAPI) match-center data at the
// exact paths the Flutter app's CricketHubService expects:
//
//   GET /api/real/cricket/proxy/matches
//   GET /api/real/cricket/proxy/matches/:id/info
//   GET /api/real/cricket/proxy/matches/:id/advance        (scorecard)
//   GET /api/real/cricket/proxy/matches/:id/statistics     (per-over runs)
//   GET /api/real/cricket/proxy/matches/:id/content
//   GET /api/real/cricket/proxy/matches/:id/squads
//   GET /api/real/cricket/proxy/matches/:id/overs          (?iid=)
//   GET /api/real/cricket/proxy/matches/:id/oversgraph
//   GET /api/real/cricket/proxy/matches/:id/ballsgraph     (?iid=)
//   GET /api/real/cricket/proxy/matches/:id/partnershipgraph
//   GET /api/real/cricket/proxy/matches/:id/innings/:iid/commentary
//   GET /api/real/cricket/proxy/players
//   GET /api/real/cricket/proxy/teams
//   GET /api/real/cricket/proxy/competitions
//   GET /api/real/cricket/proxy/tournaments
//
// All calls go through cacheManager so the rate-limited upstream key is
// protected: live-ish data caches for seconds, heavy graph data for 6h.

const express = require("express");
const router = express.Router();
const cacheManager = require("../cache/cacheManager");
const { matches, players, teams, browse, schedule } = require("../providers/cricbuzz");

const TTL_INFO = 60;       // seconds
const TTL_LIVE = 10;
const TTL_LIST = 300;
const TTL_HEAVY = 21600;   // 6h — graphs / squads / highlights

function cached(key, ttl, fn) {
  return async (req, res) => {
    try {
      const cacheKey = typeof key === "function" ? key(req) : key;
      const data = await cacheManager.getOrCreate(cacheKey, ttl, () => fn(req));
      res.json({ data });
    } catch (err) {
      console.error(`cricket proxy error [${typeof key === "function" ? key(req) : key}]:`, err.message);
      res.status(500).json({ success: false, message: err.message });
    }
  };
}

/* ---- lists ---- */
router.get("/matches", cached("CB_LIST_MATCHES", TTL_LIST, () => matches.getLiveMatches()));
router.get("/players", cached("CB_LIST_PLAYERS", TTL_HEAVY, () => players.getTrendingPlayers()));
router.get("/teams", cached("CB_LIST_TEAMS", TTL_HEAVY, () => teams.getInternationalTeams()));
router.get("/competitions", cached("CB_LIST_COMPETITIONS", TTL_HEAVY, () => browse.getInternational()));
router.get("/tournaments", cached("CB_LIST_TOURNAMENTS", TTL_HEAVY, () => schedule.getInternational()));

/* ---- match-center ---- */
router.get("/matches/:id/info", cached((req) => `CB_MINFO_${req.params.id}`, TTL_INFO,
  (req) => matches.getMatchInfo(req.params.id)));

router.get("/matches/:id/advance", cached((req) => `CB_SCARD_${req.params.id}`, TTL_LIVE,
  (req) => matches.getScorecard(req.params.id)));

router.get("/matches/:id/statistics", cached((req) => `CB_OVERS_${req.params.id}_${req.query.iid || 1}`, TTL_LIVE,
  (req) => matches.getOvers(req.params.id, req.query.iid || 1)));

router.get("/matches/:id/content", cached((req) => `CB_HIGHLIGHTS_${req.params.id}`, TTL_HEAVY,
  (req) => matches.getHighlights(req.params.id)));

router.get("/matches/:id/squads", cached((req) => `CB_SQUADS_${req.params.id}`, TTL_HEAVY,
  (req) => matches.getSquads(req.params.id)));

// Playing XI / squad for a specific team in a match (real match-level endpoint).
router.get("/matches/:id/team/:teamId", cached((req) => `CB_TEAM_${req.params.id}_${req.params.teamId}`, TTL_HEAVY,
  (req) => matches.getTeamPlayers(req.params.id, req.params.teamId)));

router.get("/matches/:id/overs", cached((req) => `CB_OVERS_${req.params.id}_${req.query.iid || 1}`, TTL_LIVE,
  (req) => matches.getOvers(req.params.id, req.query.iid || 1)));

router.get("/matches/:id/oversgraph", cached((req) => `CB_OVERSGRAPH_${req.params.id}`, TTL_HEAVY,
  (req) => matches.getOversGraph(req.params.id)));

router.get("/matches/:id/ballsgraph", cached((req) => `CB_BALLSGRAPH_${req.params.id}_${req.query.iid || 1}`, TTL_HEAVY,
  (req) => matches.getBallsGraph(req.params.id, req.query.iid || 1)));

router.get("/matches/:id/partnershipgraph", cached((req) => `CB_PARTGRAPH_${req.params.id}`, TTL_HEAVY,
  (req) => matches.getPartnershipGraph(req.params.id)));

router.get("/matches/:id/wagons", cached((req) => `CB_WAGONS_${req.params.id}_${req.query.iid || 1}`, TTL_HEAVY,
  (req) => matches.getWagons(req.params.id, req.query.iid || 1)));

// Odds history: the cricbuzz plan exposes no odds endpoint — return an empty
// list so the app's odds tab degrades gracefully (same shape as other lists).
router.get("/matches/:id/oddshistory", cached((req) => `CB_ODDS_${req.params.id}`, TTL_HEAVY,
  () => []));

router.get("/matches/:id/innings/:iid/commentary",
  cached((req) => `CB_COMM_${req.params.id}_${req.params.iid}_${req.query.tms || 0}`, TTL_LIVE,
    (req) => matches.getCommentary(req.params.id, parseInt(req.params.iid, 10) || 1,
      req.query.tms ? parseInt(req.query.tms, 10) : Date.now())));

// Full-match commentary (all balls, every innings) — used to show the complete
// ball-by-ball history instead of only the latest window.
router.get("/matches/:id/hcomm",
  cached((req) => `CB_HCOMM_${req.params.id}`, TTL_LIVE,
    (req) => matches.getHCommentary(req.params.id, parseInt(req.query.iid, 10) || 1,
      req.query.tms ? parseInt(req.query.tms, 10) : Date.now())));

module.exports = router;