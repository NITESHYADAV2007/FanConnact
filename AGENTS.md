# Session Summary

## All-Sports Scores + Players + Crex-style Team Click (CURRENT)
- **Backend** (`backend/server.js`, LOCAL only — NOT yet on Render):
  - Rewrote `/api/live-matches` to fetch ALL sports via ESPN scoreboard (free, real logos) + cricket API. sport=all → 101 matches (11 live, 85 w/ logos).
  - Added rugby, golf, mma to `SPORTS` config + `makeRugbyPlayers`/`makeGolfPlayers`/`makeMmaPlayers` generators.
  - Added `SPORT_ALIASES` map so app keys (`kabaddi`, `esports`, `tabletennis`) resolve to config keys (`kabbaddi`, `e-sports`, `table-tennis`). Applied in `/api/rankings/:sport`, `/api/sports/:sport`, `/api/live-matches`.
  - Rankings now return 100 players for ALL 13 sports (cricket=icc real, football/basketball/tennis/hockey/baseball/volleyball=kabaddi/tabletennis=database, rugby/golf/mma/esports=generated).
- **Flutter app**:
  - `lib/data.dart`: added rugby 🏉, golf ⛳, mma 🥊 to `sports` list + emojiMap.
  - `lib/services/player_ranking_service.dart` (NEW): typed client for `/api/rankings/:sport/:category` with filters/columns.
  - `lib/screens/player_rankings_screen.dart` (NEW): Crex-style rankings table with filter chips + source badge.
  - `lib/screens/team_matches_screen.dart` (NEW): Crex-style "tap team → all that team's matches" screen.
  - `lib/widgets/match_card.dart`: added `onTeamTap` callback; team rows now tappable (navigate to TeamMatchesScreen).
  - `lib/screens/sports_screen.dart`: added "Rankings" button (opens PlayerRankingsScreen for selected sport) + wired `onTeamTap` on MatchCards.
  - Deleted unused `lib/services/match_service.dart` (referenced removed static `matches` list → broke analyze).
  - `lib/config.dart` temporarily set to `http://127.0.0.1:3001` for USB test (Render lacks these changes). **Must revert to Render URL before final deploy.**
- **Testing**: `flutter analyze` → 0 errors. Built debug APK, installed on Xiaomi (V4JVSCF67X99759L) via `adb install -r`. USB reverse `tcp:3001 tcp:3001` active so phone hits local backend.
- **TODO before shipping**: (1) Redeploy backend to Render, (2) Revert `apiBaseUrl` to `https://fanconnact-api.onrender.com`, (3) Rebuild + reinstall APK, (4) gh auth login (failed) → commit/push.

## News API Enhancement (Reverted)
- GNews API addition was reverted by user request (no second API)
- News flow is back to: **Currents API** → **static fallback**
- `fetchFromCurrents` restored to original with multi-page pagination
- Static fallback preserved for both empty results and errors

## Fan Coin Page (`fancoin.html`)
- Created at root with dashboard layout (wallet, earn cards, levels, transactions)
- Uses shared top bar (logo + theme toggle + notification + profile) — no sidebar, no hamburger menu
- All styles in `css/fancoin.css`, asset paths root-relative
- `index.html` coin badge, View Wallet button, FanCoins card → all link to `fancoin.html`
- "Earn Coins" → `index.html` (predictions), "Coin History" + "View All" → expand 35 transactions inline
- Full page respects light/dark theme toggle

## Rankings Auto-Sync System
- Creates `backend/rankings-sync.js` - auto-sync service that scrapes ICC rankings, FIFA rankings, ESPN stats (NBA, MLB), and API-Sports endpoints
- Sync runs every 6 hours via node-cron (`0 */6 * * *`)
- Data served from `data/player-rankings.json` (player stats) and `data/team-rankings.json` (team rankings) - both updated by sync service
- API endpoints: `/api/sync/status`, `/api/sync/trigger` (POST), `/api/sync/last-updated`, `/api/quota`
- `top-players.html` shows source badges (ICC, ESPN, FIFA, etc.), last-updated timestamp, manual refresh button, and link to team rankings per sport
- `leaderboard.html` fetches from backend API first, falls back to static JSON. Shows sync timestamp
- Dependencies added: `axios`, `cheerio`, `node-cron` (all installed in `backend/node_modules/`)
- Start backend: `cd backend && npm start` (runs on port 3001)

## API Quota + Cache Layer (100 requests/day budget)
- **Problem**: External provider (API-Sports/ICC/FIFA/ESPN) allows only ~100 requests/day. Many users would exhaust it instantly.
- **Solution**: `backend/api-quota.js` — shared module enforcing a daily budget + on-disk cache.
  - `data/api-quota.json`: persistent daily counter (resets every 24h), tracks `used`/`limit`/`history`.
  - `data/api-cache.json`: keyed by URL+params, TTL 6h (matches sync interval). Successful responses cached to disk.
  - `cachedFetch(url, params, fetcher, opts)`: returns cached copy if fresh (0 quota used); else consumes 1 quota unit and fetches live; if quota exhausted, serves stale cache or null.
  - All external calls in `rankings-sync.js` (`fetchWithTimeout`) and `server.js` (`cachedFetchJSON` for sportscore/ESPN/tennis) now route through this layer.
  - Tennis athlete detail fetches capped to top 20 to protect budget.
  - New endpoint `GET /api/quota` returns `{ used, limit, remaining, exhausted, resetsInHours }`.
  - `getSyncStatus()` now includes `quota` field.
- **Result**: ~100 external calls/day max (during 6h syncs), served to unlimited users via cache. Verified: 2nd sync hit cache for FIFA/NBA/MLB (0 quota used), quota went 9→15 (only ICC scrapes made new calls).
- **Frontend**: `js/sport-stats.js` already degrades gracefully (try/catch → empty container) if backend/quota down.

## Previous Work (by session context)
- Blue accent theme (#2196f3) across all pages with light/dark CSS overrides
- Auth redirect fix in `js/script.js` (guestAllowedPages)
- Tabletennis surface class overrides, removed Top Players/Upcoming Event
- Notification CSS rewrite (glassmorphism, animations, responsive)
- Theme toggle on `berforeloginindex.html` and `notification.html`
- Canvas scene backgrounds (stadium, cricket, football, basketball)
