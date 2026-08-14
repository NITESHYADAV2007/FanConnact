# Session Summary

## RULE (ALWAYS): APP ONLY — NEVER TOUCH WEBSITE
- ALWAYS make changes ONLY in the Flutter app (`lib/`, `pubspec.yaml`, etc.).
- NEVER modify, edit, or create anything for the website: no `index.html`, `*.html`, `css/`, `js/` (except if it's backend serving the app). The website must NEVER be harmed.
- All feature changes go in the app ONLY.

## NON-CRICKET ENRICHMENT — allsportsapi2 + FlashLive (REMEMBER)
- **Goal**: enrich every non-cricket Match Center (football/NFL, basketball, baseball, hockey, kabaddi, esports, volleyball, tabletennis, tennis) with lineups, play-by-play commentary, shot map (basketball) and squad/player rosters.
- **Shared RapidAPI key**: allsportsapi2, FlashLive AND cricbuzz ALL use the SAME key (`CRICKET_KEY`/`ALLSPORTS_KEY`). It is rate-limited (HTTP 429 seen). So the app NEVER calls these APIs directly — it calls the backend proxy.
- **Backend proxy** (`backend/server.js`, serves the app → allowed):
  - `GET /api/sport-detail/:sport/match/:id/incidents`
  - `GET /api/sport-detail/:sport/match/:id/lineups`
  - `GET /api/sport-detail/:sport/match/:id/shotmap?team=:teamId` (basketball only)
  - `GET /api/sport-detail/:sport/team/:id/players`
  - Routing: if `APP_TO_ALLSPORTS[sport]` exists → allsportsapi2 (basketball, baseball, american-football, volleyball); else → FlashLive (hockey, kabaddi, esports, tabletennis, tennis). All responses normalized to `{home:[{name,number,position,starter}],away:[...]}` / `{incidents:[...]}` / `{shotmap:[{x,y,made,missed,saved}]}` / `{players:[{name,position,number,height}]}`. Cached 10 min in-memory (`SPORT_DETAIL_CACHE`).
  - `mapAllsportsEvent` already returns `matchId`/`teamIdA`/`teamIdB`; FlashLive mapping now also returns `teamIdA`/`teamIdB` (best-effort `HOME_TEAM_ID`/`AWAY_TEAM_ID`).
- **allsportsapi2 coverage (verified)**: incidents ✅ all sports; lineups/players ✅ basketball/baseball/american-football (NOT volleyball — 404); shotmap ✅ basketball only.
- **FlashLive coverage**: live `events/list` works for hockey/kabaddi/esports/tabletennis/tennis (gives `EVENT_ID`). Detail endpoints (incidents/lineups/players) attempted with fallback path probes; some may still 429/404 until verified — app hides empty tabs gracefully.
- **App**: `lib/services/allsports_api_service.dart` calls the backend proxy (10-min client cache). `lib/widgets/sport_match_center.dart` has `SportCommentaryTab` (real incidents + mock fallback), `SportLineupsTab` (real lineups + mock), `SportSquadsTab` (real roster via players + mock), `SportShotmapTab` (basketball half-court chart). `lib/screens/match_detail_screen.dart` _tabs now: Scorecard, Lineups, Commentary, Live, Info, Squads, [Shotmap if basketball], Graphs, Series, News, (Live Chat, Games if logged in).
- **NOTE**: "football" in the app maps to American Football (NFL) via allsportsapi2. Soccer has full allsportsapi2 data but the app has NO soccer live feed yet (separate sport entry needed).

## Full Crex-style Cricket Match Center (CURRENT)
- **`lib/screens/match_detail_screen.dart`** fully redesigned for cricket:
  - **Dynamic tabs**: Cricket shows Scorecard > Commentary > Info > Squads > Series > Live Chat > Games; non-cricket keeps Info > Live Chat > Summary > Series > News > Games
  - **`_CricketScoreHeader`**: New dark gradient header (deep navy/purple) with 56px team logos, big score display (24px), match type badge, venue/time in muted white, pulsing live indicator
  - **`_CricketScorecardTab`**: Stateful widget fetching from `CricketHubService.matchAdvance()`; innings selector (horizontal chip bar), batting table (batter, R, B, 4s, 6s, SR with OUT highlight), bowling table (bowler, O, M, R, W, Eco), total score header with overs/extras, fall-of-wickets chip list
  - **`_CricketCommentaryTab`**: Fetches from `CricketHubService.matchCommentary()`; ball-by-ball cards with color-coded over badges (red=wicket, amber=six, blue=other), bold wicket/boundary text
  - **`_CricketSquadsTab`**: Fetches from `CricketHubService.matchSquads()`; team cards with avatar, role, captain(C)/wicketkeeper(WK) badges, player count
  - **Non-cricket**: Existing `_ScoreHeader`, `_ChatTab`, `_SummaryTab` preserved unchanged
  - `flutter analyze` → 0 errors, 0 warnings; `flutter build apk --debug` builds successfully

## Match Detail Screen (Crex-style) + Detail API Fix (PREVIOUS)
- **Backend** (`backend/server.js`, DEPLOYED to Render):
  - **FIXED `/api/live-matches/:id`**: previously returned generic "Team A vs Team B" with empty scores/venue for cricket. Root cause: it merged cricket-live-line1 `/match/:id` placeholder names over the real list data, and read from the stale persisted DB (`getLast`) instead of the in-memory `matchCache` that `/api/live-matches` actually serves. Fix: (1) search `matchCache` for the exact sport key (`matches|cricket`) before `matches|all`, (2) prefer the real list entry for names/scores/logos, only using the detail call when the list entry is missing, (3) detect "Team A"/"Team B" placeholders and fall back to `base`, (4) added a 20s detail cache keyed `detail|sport|id` so the app's 3s polling doesn't hammer upstream APIs. Verified: `/api/live-matches/13845?sport=cricket` → "West Indies vs New Zealand", 188-10 / 46-2, Providence Stadium, LIVE.
  - News endpoint returns key `"articles"` (NOT `"news"`) — `lib/services/news_service.dart` already parses `articles` correctly.
- **Flutter app**:
  - `lib/data.dart`: added `abbrA`/`abbrB` fields to `MatchItem` + parsing from `homeAbbr`/`awayAbbr`.
  - `lib/screens/match_detail_screen.dart`: expanded to 6 tabs (Info, Live Chat, Summary, Series, News, Games). Professional `_ScoreHeader` (logos, abbr, venue/time, share via Clipboard), richer Info (head-to-head card), richer Summary (commentary feed + wagon wheel chart), richer Series (H2H record bar + recent meetings), NEW `_NewsTab` using `NewsService`. `flutter analyze` → 0 errors; `flutter build apk --debug` builds `app-debug.apk`.
  - `lib/config.dart`: `apiBaseUrl = 'https://fanconnact-api.onrender.com'` (reverted from local test URL).

## All-Sports Scores + Players + Crex-style Team Click
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
