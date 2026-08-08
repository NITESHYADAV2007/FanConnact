# Fanconnact App — Full Technical Breakdown & Implementation Spec

---

## PART 0: EXISTING CODEBASE ANALYSIS

### 0.1 Current Stack
| Layer | Technology | Status |
|-------|-----------|--------|
| **Mobile App** | Flutter 3.12+ (Dart) | ~50% built |
| **Backend API** | Node.js/Express (port 3001) | ~70% built |
| **WebSocket Chat** | ws library, `/ws/chat` | Built |
| **WebSocket Notifications** | ws library, `/ws/notifications` | Built |
| **Firebase** | Auth, Firestore, Core | Connected |
| **Hosting** | Render (backend), Firebase (likely) | Deployed |
| **Website** | HTML/CSS/JS (Tailwind) | Static pages built |

### 0.2 Existing Flutter Files (lib/)

| File | Purpose | State |
|------|---------|-------|
| `main.dart` | App entry, Firebase init, theme/locale provider, `CricketHubService` stub | Has duplicate widget classes (messy) |
| `config.dart` | `apiBaseUrl` | Ready |
| `data.dart` | `Sport`, `MatchItem`, `NewsItem` models | Solid |
| `theme.dart` | `AppColors`, `buildTheme()` | Ready |
| `l10n.dart` | `AppStrings` localization (en/hi/es) | Ready |
| `firebase_options.dart` | Firebase config | Ready |
| `screens/auth_gate.dart` | Auth state stream → MainShell | Ready |
| `screens/splash_screen.dart` | Splash → next screen | Ready |
| `screens/main_shell.dart` | Bottom nav: Home, Series, Matches, Predict, Profile | Built but tab layout differs from new spec |
| `screens/home_screen.dart` | Live matches carousel + news/reels feed (sport filter) | **Needs heavy rework** |
| `screens/match_detail_screen.dart` | Cracks-style: Scorecard, Commentary, Info, Squads, Series, Live Chat, Games | Cricket tabs built; non-cricket basic |
| `screens/sports_screen.dart` | Sport selector + tournament chips + match cards | Built |
| `screens/leaderboard_screen.dart` | Firestore user ranking (XP) | Basic, lacks teams/fans toggle |
| `screens/profile_screen.dart` | Avatar, XP, coins, level, followers/following | Basic, needs FanCoin history |
| `screens/settings_screen.dart` | Actually in `main_shell.dart` as `SettingsScreenWithTheme` | Has theme, language, sign out |
| `screens/login_screen.dart` | Firebase Auth login | Ready |
| `screens/series_screen.dart` | Series listing | Built |
| `screens/reels_viewer_screen.dart` | Full-screen reel viewer | Built |
| `screens/player_rankings_screen.dart` | Rankings table with filter chips | Built |
| `screens/player_detail_screen.dart` | Player detail | Built |
| `screens/team_matches_screen.dart` | Team's matches filter | Built |
| `screens/prediction_screen.dart` | Predictions/games | Basic |
| `screens/cricket_hub_screen.dart` | Cricket hub | Built |
| `services/live_match_service.dart` | API client with 15s cache, polling | Ready |
| `services/news_service.dart` | News API with pagination | Ready |
| `services/reels_service.dart` | Reels API with pagination | Ready |
| `services/match_chat_service.dart` | WebSocket chat client | Ready |
| `services/cricket_hub_service.dart` | Cricket squad/player/team/commentary API | Ready |
| `services/rapid_api_service.dart` | Cricbuzz/RapidAPI fallback | Ready |
| `services/player_ranking_service.dart` | Rankings API | Ready |
| `services/social_service.dart` | Social features | Basic |
| `widgets/app_top_bar.dart` | Top bar widget | Ready |
| `widgets/live_score_card.dart` | Live match card | Ready |
| `widgets/match_card.dart` | Match list card | Ready |
| `widgets/news_card.dart` | News card | Ready |
| `widgets/news_post_card.dart` | News post card | Ready |
| `widgets/reels_card.dart` | Reel card | Ready |
| `widgets/reels_section.dart` | Reels section | Ready |
| `widgets/sport_selector.dart` | Horizontal sport selector | Ready |
| `widgets/match_games.dart` | Games/predictions | Built |
| `widgets/glow_wrapper.dart` | Decorative glow | Ready |

### 0.3 Existing Backend (backend/)

| File | Purpose |
|------|---------|
| `server.js` | Main Express app: live matches, news, reels, rankings, 100/day quota, persistent cache |
| `rankings-sync.js` | Cron-based rank sync (ICC, FIFA, ESPN, etc.) |
| `chat-server.js` | WebSocket chat server |
| `notif-server.js` | WebSocket notification server |
| `api-quota.js` | Daily budget (100 req) + 6h TTL disk cache |

### 0.4 Existing Website (root *.html)
- Individual sport pages (cricket, football, tabletennis, tennis, volleyball, kabbadi, hockey, baseball, e-sports)
- `index.html` — main site
- `leaderboard.html`, `fancoin.html`, `prediction.html`, `profile.html`, `match-center.html`
- `setting.html`, `notification.html`, `login.html`, `signup.html`
- CSS in `/css/`, JS in `/js/`

### 0.5 Key Issues / Technical Debt
1. **`main.dart` has massive duplication** — all screen classes defined inside main.dart are repeated 5+ times (very messy, needs cleanup)
2. **`main_shell.dart` tabs don't match new spec** — currently: Home, Series, Matches, Predict, Profile. New: Home, Matches, Leaderboard, Communities, Profile
3. **No Communities tab at all** — entirely new screen needed
4. **Leaderboard** — only shows user XP ranking from Firestore. Needs team leaderboards (per sport/format) + fan leaderboard toggle
5. **No dedicated Match Center for non-cricket sports** — most detailed features (live animation, graphs, wagon wheel) are cricket-only
6. **No live animation system** — `_LiveAnimationTab` is a stub with just placeholder text
7. **No FanCoin history screen** — profile shows coin count but no transaction history
8. **No player profile page from match center** — squad names not tappable

---

## PART 1: PRIORITY SPORTS (Ranked)

| Priority | Sport | Key | Detail Level |
|----------|-------|-----|-------------|
| 1 | Cricket | `cricket` | Full (Cracks-level) |
| 2 | Football | `football` | High |
| 3 | Table Tennis | `tabletennis` | Medium-High |
| 4 | Tennis | `tennis` | Medium-High |
| 5 | Volleyball | `volleyball` | Medium |
| 6 | Kabaddi | `kabaddi` | Medium |
| 7 | Hockey | `hockey` | Medium |
| 8 | Baseball | `baseball` | Medium-Low |
| 9 | E-Sports | `esports` | Medium-Low |

---

## PART 2: GLOBAL APP SHELL

### 2.1 Top Bar (AppBar)
- **Left**: Logo + "Fan" (white/black) + "connact" (blue/green) wordmark
- **Right**: Theme toggle (🌙/☀️) → Notification bell (🔔) → Settings gear (⚙️) → Profile avatar
- **Behavior**: Settings only available when logged in (else redirect to login)

### 2.2 Bottom Navigation (5 tabs)
| Tab | Icon | Label | Auth Required |
|-----|------|-------|---------------|
| 1 | 🏠 | Home | No |
| 2 | 🏟️ | Matches | No |
| 3 | 🏆 | Leaderboard | No |
| 4 | 👥 | Communities | Yes |
| 5 | 👤 | Profile | Yes |

### 2.3 Guest vs Logged-in
- **Guest**: Home, Matches, Leaderboard tabs functional. Everything else shows login prompt.
- **Logged-in**: Full access to all tabs, Live Chat, Predictions/Games, Communities, Profile, Settings

---

## PART 3: HOME TAB (Tab 1)

### 3.1 Layout (Top to Bottom)
```
┌─ Top Bar (Logo + Toggle + Notification + Settings + Profile) ─┐
├─ Live Matches (Horizontal sliding cards, auto-refresh) ────────┤
├─ Sport Filter Chips (All, Cricket, Football, Tennis, …) ──────┤
├─ News + Reels Feed (Vertical scroll, endless) ─────────────────┤
│  ┌─ Reel Card ──────────────────────────────────────────────┐  │
│  ├─ News Post Card ────────────────────────────────────────┤  │
│  ├─ Reel Card ──────────────────────────────────────────────┤  │
│  ├─ News Post Card ────────────────────────────────────────┤  │
│  └─ … endless scroll ──────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

### 3.2 Live Matches Section (Top)
- **Horizontal sliding cards** (NOT vertical scroll — use `PageView` or horizontal `ListView` with snapping)
- Each card shows: team logos, abbreviated names, scores, status (LIVE/UPCOMING/COMPLETED)
- Auto-refresh every 3-5 seconds via backend polling
- Cards filterable by sport (but only live ones shown by default)
- **Tap card** → opens Match Center (MatchDetailScreen)
- When no live matches: "No live matches right now" placeholder

### 3.3 Sport Filter Chips
- Horizontal scrollable chips: All, Cricket 🏏, Football ⚽, Table Tennis 🏓, Tennis 🎾, Volleyball 🏐, Kabaddi 🤼, Hockey 🏑, Baseball ⚾, E-Sports 🎮
- Selecting a chip filters the **entire feed below** (reels + news) to that sport
- "All" shows everything mixed together

### 3.4 News + Reels Feed (Endless Vertical Scroll)
- **Mixed interleaved feed**: Reel (tall card), News Post Card, Reel, News Post Card…
- **Reel cards**: Show thumbnail, caption, like/view count; tap opens full-screen ReelsViewerScreen (vertical swipe, like Instagram)
- **News post cards**: Show image, title, source, time, tag; tap opens news article in WebView or in-app browser
- **Endless pagination**: Load more when user scrolls near bottom
- **Pull to refresh** resets all data
- Each card has **like button** (heart icon) — requires login

---

## PART 4: MATCH CENTER (MatchDetailScreen)

This is the **most feature-rich screen** — opens when tapping a live match card (from Home or Matches tab) or any match from series/match listing.

### 4.1 Score Header (Always visible at top)
- **Cricket**: Dark gradient background (navy → purple), 56px team logos, big scores (24px), match type badge, venue/time, pulsing LIVE indicator, share button
- **Non-cricket**: Clean card with status bar, team logos, scores, VS divider, venue/time, share button
- Auto-updates every 3s when match is LIVE

### 4.2 Tab Structure (Scrollable tabs)

For **Cricket**:
| Tab | Content |
|-----|---------|
| 1. Scorecard | Innings selector, batting table (R/B/4s/6s/SR), bowling table (O/M/R/W/Eco), total score header, extras, fall-of-wickets chips |
| 2. Commentary | Ball-by-ball with color-coded badges (red=wicket, amber=six, blue=boundary); filter by over/innings/milestone |
| 3. Info | Venue details, weather, pitch report, head-to-head record, match officials |
| 4. Squads | Both teams with avatars, roles, C/WK badges; tappable → Player Profile |
| 5. Series | Series standings, H2H record bar, recent meetings |
| 6. Live Chat | Real-time chat with scorecard overlay; requires login |
| 7. Graphs | Wagons (cricket), bar charts, comparison graphs |
| 8. Games/Predictions | Prediction mini-games; requires login |

For **Non-Cricket**:
| Tab | Content |
|-----|---------|
| 1. Info | Venue, weather, head-to-head |
| 2. Squads/Lineups | Both team rosters with profiles |
| 3. Commentary | Event-by-event with sport-specific highlights |
| 4. Live Visual | 2D/3D visualization (pitch, court, field) |
| 5. Live Chat | Real-time chat; requires login |
| 6. Summary/Stats | Match summary, key stats |
| 7. Graphs | Statistics charts |
| 8. Series | Tournament standings |
| 9. Games | Predictions; requires login |

### 4.3 Live Animation System (CRITICAL FEATURE)

**Cricket**: Animated cards showing:
- Six: ball flies over boundary with "SIX!" animation
- Four: ball races to boundary
- Wicket: stumps breaking animation
- Fifty/Century: milestone card with player name
- Spin/Swing/Wicket type badges
- Source: real-time from commentary stream

**Football**: Goal celebration animation, foul card, free kick, corner, offside, yellow/red card

**Tennis**: Ace, serve, break point, set point animation

**Table Tennis**: Point score, serve change, smash animation

**Hockey**: Goal, penalty corner, green/yellow/red card

**Volleyball**: Spike, block, serve, point

**Kabaddi**: Raid, tackle, bonus point, ALL OUT animation

**Baseball**: Home run, strikeout, steal animation

**E-Sports**: Kill, headshot, victory animation

**Implementation approach**: 
- `SportsAnimationEngine` class per sport
- Animations triggered by event type from commentary/API
- Lottie/JSON animations or custom Flutter animations
- Stacked overlay on the score header area

### 4.4 Commentary Tab Enhancements
- **Ball-by-ball** (cricket) or **Event-by-event** (other sports)
- Color-coded event badges: red=wicket/dismissal, amber=six/home run/goal, blue=boundary/other
- **Filter button**: Over-wise, innings-wise, milestone-only (sixes, fours, wickets), highlights mode
- Special milestone cards: 🎯 Century, 🎯 Fifty, 🎯 5-wicket haul, 🎯 Hat-trick
- Clean text (remove cryptic `B1$` codes from raw API data)

### 4.5 Live Visualization Tab
- **Cricket**: 2D pitch view showing batsman (on strike), bowler (running in), field positions, scorecard overlay
- **Football**: Mini pitch with player positions, ball movement tracking
- **Tennis**: Court view showing server, receiver positions
- **Kabaddi**: Court with raider/defender positions
- **Hockey**: Field with player positions
- **Table Tennis**: Table view showing server side, player names
- **Volleyball**: Court with rotation positions

### 4.6 Player Profile (from Squads)
- Tapping a player in Squads tab → `PlayerDetailScreen`
- Shows: Full name, age, nationality, role, batting/bowling style
- Career stats: Matches, Runs, Wickets, Average, Strike Rate
- Recent form: Last 5-10 matches performance
- Photo/avatar, team logo

### 4.7 Graphs Tab
- **Cricket**: Wagon wheel (shot direction), pitch map, run rate graph, partnership chart, fall of wickets timeline
- **Football**: Possession pie, shots on target bar, pass completion, heat map
- **Tennis**: Serve placement, rally length distribution
- **Other sports**: Sport-appropriate statistical visualizations
- Implement using `fl_chart` package

### 4.8 Live Chat
- Real-time WebSocket via `/ws/chat`
- Shows scorecard header (mini version) + scrollable messages
- User can send text messages, reply to others
- Emoji support
- Message reactions (👍 ❤️ 😂)
- Requires login
- Admin/moderator badges

---

## PART 5: MATCHES TAB (Tab 2)

### 5.1 Layout
```
┌─ Sport Selector (horizontal chips, default: Cricket) ──────────┐
├─ Filter: All | Live | Upcoming | Completed ────────────────────┤
├─ Tournament/Series chips (horizontal) ─────────────────────────┤
├─ Tournament Header (image + name) ────────────────────────────┤
│  ┌─ Match Card ─────────────────────────────────────────────┐  │
│  ├─ Match Card ─────────────────────────────────────────────┤  │
│  └─ Match Card ─────────────────────────────────────────────┘  │
├─ Next Tournament Header ──────────────────────────────────────┤
│  ┌─ Match Card ─────────────────────────────────────────────┐  │
│  └─ … ──────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

### 5.2 Behavior
- **Default sport**: Cricket (then whatever user last selected)
- **Tournament chips**: Live series/tournaments at top (shown horizontally)
- Each tournament header shows: image/banner, name, clickable → opens series detail
- Matches grouped by tournament/series
- "Rankings" button in AppBar → opens `PlayerRankingsScreen`
- Same match cards as Home but full list, not just live
- Pull-to-refresh

### 5.3 Series Detail (when tapping tournament)
- Series banner + info
- Points table/standings
- Upcoming matches list
- Live matches list
- Completed matches with results
- Top run-scorers / wicket-takers (cricket), top scorers (football), etc.
- Click match → Match Center

---

## PART 6: LEADERBOARD TAB (Tab 3)

### 6.1 Layout
```
┌─ Toggle: [Teams] [Fans] ──────────────────────────────────────┐
├─ Sport Selector (default: Cricket) ───────────────────────────┤
├─ Format Selector (T20, ODI, Test / PL, La Liga, etc.) ────────┤
├─ Leaderboard Entries ─────────────────────────────────────────┤
│  ┌─ 1. Team/Fan Name 🥇 ────────────────────────────────────┐  │
│  ├─ 2. Team/Fan Name 🥈 ────────────────────────────────────┤  │
│  ├─ 3. Team/Fan Name 🥉 ────────────────────────────────────┤  │
│  ├─ 4. Team/Fan Name ───────────────────────────────────────┤  │
│  └─ … ──────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

### 6.2 Teams Mode
- Sport selector + Format selector (sport-dependent)
- Data source: Backend `/api/rankings/:sport` (ICC, FIFA, ESPN, database)
- Shows team rank, name, logo, points/rating, change indicator (▲ ▼)
- Cards show flag/country

### 6.3 Fans Mode
- Shows fan leaderboard (from Firestore user XP/coins)
- Same format as current `LeaderboardScreen` but styled consistently
- Shows rank, avatar, username, level, XP, coins
- Tapping fan → their Profile (public view)

---

## PART 7: COMMUNITIES TAB (Tab 4)

### 7.1 Layout
```
┌─ Top: "My Communities" ───────────────────────────────────────┐
├─ [Create Community] button (costs coins) ─────────────────────┤
├─ Joined Community Card ───────────────────────────────────────┤
│  ├─ Avatar + Name + Member count + Unread badge ────────────  │
│  └─ Tap → Community Feed ────────────────────────────────────  │
├─ Joined Community Card ───────────────────────────────────────┤
├─ "Discover Communities" section ──────────────────────────────┤
├─ Suggested Community Card (public) ───────────────────────────┤
│  └─ [Join] button ───────────────────────────────────────────  │
└───────────────────────────────────────────────────────────────┘
```

### 7.2 Community Feed (when tapping a joined community)
- Post wall: users can share text, images, videos
- Like, comment, share on posts
- Member list with follow button
- Admin controls (if creator)
- Real-time updates via WebSocket

### 7.3 Create Community
- Name, description, icon/cover image
- Cost: X FanCoins to create
- Privacy: Public / Private (requires approval)

### 7.4 Social Features
- Follow/unfollow users
- See follower/following lists
- User profiles (public view) show: avatar, bio, sports interests, level, communities they're in
- Built on Firestore `users/{uid}/` with `followers`, `following` arrays + `communities` collection

---

## PART 8: PROFILE TAB (Tab 5)

### 8.1 Layout
```
┌─ Avatar (big) ────────────────────────────────────────────────┐
├─ Username @handle ────────────────────────────────────────────┤
├─ Level X · XXX XP ────────────────────────────────────────────┤
├─ XP Progress Bar ─────────────────────────────────────────────┤
├─ Stats Row: Coins | Followers | Following | Rank ─────────────┤
├─ [FanCoin Wallet] → Coin History Screen ──────────────────────┤
├─ [My Predictions] ────────────────────────────────────────────┤
├─ [My Communities] ────────────────────────────────────────────┤
├─ [Settings] → Settings Screen ───────────────────────────────┘
```

### 8.2 FanCoin History Screen
- List of transactions: earned (predictions won, daily rewards, achievements) / spent (community creation, predictions entry fee)
- Shows: date, description, amount (+/-), balance
- Filterable by earned/spent
- Pull to refresh

### 8.3 Settings Screen
| Section | Options |
|---------|---------|
| **Appearance** | Dark/Light toggle, Custom theme picker (predefined themes) |
| **Account** | Edit Profile, Notifications, Privacy/Security, Favorite Sports |
| **Preferences** | Language (EN/HI/ES), Content Region |
| **About** | About, Terms & Conditions, Contact Us |
| **Sign Out** | Google Sign-In sign out |

---

## PART 9: AUTH & ONBOARDING

### 9.1 Auth Methods
- Email/Password (Firebase Auth)
- Google Sign-In
- (Optional) Apple Sign-In, Facebook, Twitter

### 9.2 Guest Mode
- Can browse: Home (live matches + news/reels), Matches, Leaderboard
- Cannot access: Communities, Profile, Live Chat, Predictions/Games, Settings
- Tapping locked features → Login Screen (with option to continue as guest)

### 9.3 Login Screen
- Email/Password fields
- Google Sign-In button
- "Forgot Password?" link
- "Sign Up" link
- Theme-aware

### 9.4 Sign Up / Complete Profile
- Email, Password, Username
- Select favorite sports (at least 1)
- Upload avatar (optional)
- Location, Gender (optional)
- Welcome bonus: +100 FanCoins

---

## PART 10: BACKEND API ENDPOINTS (Existing + Needed)

### 10.1 Existing Endpoints (backend/server.js covers most)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/live-matches?sport=` | All live matches (ESPN + cricket) |
| GET | `/api/live-matches/:id?sport=` | Single match detail |
| GET | `/api/news?sport=&language=&page=&pageSize=` | News feed with pagination |
| GET | `/api/reels?sport=&page=&pageSize=` | Reels with pagination |
| GET | `/api/rankings/:sport/:category?` | Player/team rankings |
| GET | `/api/sports/:sport` | Sport-specific data |
| GET | `/api/sync/status` | Last sync info |
| POST | `/api/sync/trigger` | Manual sync trigger |
| GET | `/api/quota` | API quota usage |
| WS | `/ws/chat?matchId=` | Live match chat |
| WS | `/ws/notifications` | User notifications |

### 10.2 New Endpoints Needed

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/communities` | List communities, joined/suggested |
| POST | `/api/communities` | Create community |
| GET | `/api/communities/:id` | Community detail + posts |
| POST | `/api/communities/:id/join` | Join community |
| POST | `/api/communities/:id/post` | Create post |
| POST | `/api/communities/:id/like` | Like post |
| GET | `/api/users/:uid/profile` | Public user profile |
| POST | `/api/users/:uid/follow` | Follow user |
| GET | `/api/fancoin/history` | Coin transaction history |
| POST | `/api/fancoin/award` | Award coins (admin) |
| GET | `/api/leaderboard/teams?sport=&format=` | Team leaderboard |
| GET | `/api/leaderboard/fans` | Fan leaderboard (already in Firestore) |
| GET | `/api/match/:id/graphs` | Match graph data |
| GET | `/api/match/:id/live-visual` | Live positions/state |

---

## PART 11: IMPLEMENTATION ROADMAP

### Phase 1: Cleanup & Foundation (Week 1)
1. **Refactor `main.dart`** — remove all duplicate widget classes, keep only app entry + FanconnactApp
2. **Refactor `main_shell.dart`** — update bottom nav to: Home, Matches, Leaderboard, Communities, Profile
3. **Create `communities_screen.dart`** — new Communities tab shell
4. **Create `matches_screen.dart`** — split from `sports_screen.dart`, add tournament/series focus
5. **Update `leaderboard_screen.dart`** — add Teams/Fans toggle, sport selector, format selector

### Phase 2: Match Center Expansion (Week 2)
1. **Live Animation System** — `SportsAnimationEngine` per sport with Lottie/Flutter animations
2. **Non-cricket Match Center** — generalize tabs for football, tennis, etc.
3. **Player Profile from Squads** — wire up tappable squad names to `PlayerDetailScreen`
4. **Graphs Tab** — integrate `fl_chart`, wagon wheel for cricket
5. **Commentary Filters** — over/innings/milestone/highlight filter chips

### Phase 3: Social Features (Week 3)
1. **Communities Full Implementation** — create, join, post, like, member list
2. **User Follow System** — follow/unfollow, follower/following lists
3. **Public User Profiles** — view other users' profiles from communities/leaderboard
4. **FanCoin History Screen** — transaction list with filter
5. **Live Chat Enhancements** — message reactions, reply threading, emoji picker

### Phase 4: Polish & Optimization (Week 4)
1. **Graphs for all sports** — sport-appropriate charts
2. **Settings Screen** — custom themes, contact us, complete language/locale support
3. **News/Reels Feed Polish** — smooth animations, loading states, error states
4. **Backend Enhancements** — new endpoints from §10.2
5. **Performance** — lazy loading, image caching, scroll performance, memory management
6. **Analytics & Error Tracking** — Firebase Analytics, Crashlytics

---

## PART 12: TECHNICAL DECISIONS & CONSTRAINTS

### 12.1 State Management
- Keep using `setState` + `StatefulWidget` for now (no Provider/Bloc/Riverpod yet)
- Or migrate to **Riverpod** for better scalability (recommended before Phase 3)

### 12.2 Packages to Add
| Package | Use |
|---------|-----|
| `fl_chart` | Graphs, charts, wagon wheel |
| `lottie` | Animations (six, goal, wicket, etc.) |
| `cached_network_image` | Image caching for logos, avatars |
| `emoji_picker_flutter` | Chat emoji picker |
| `share_plus` | Share match info |
| `url_launcher` | Open news links, WebView |
| `provider` or `riverpod` | State management (if migrating) |

### 12.3 API Quota Management
- Backend has 100 requests/day budget for upstream APIs
- 6-hour sync interval for rankings
- 20-second server cache for match data
- 3-second polling from app is fine (hits cache, not upstream)
- News/reels use free RSS + Instagram scraping (no budget impact)

### 12.4 File Structure (Recommended)
```
lib/
├── main.dart
├── config.dart
├── theme.dart
├── l10n.dart
├── firebase_options.dart
├── data/
│   ├── match.dart (MatchItem)
│   ├── news.dart (NewsItem)
│   ├── reels.dart (ReelItem)
│   ├── sport.dart (Sport enum + list)
│   └── user.dart (UserProfile)
├── services/ (same as now)
├── screens/
│   ├── auth_gate.dart
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── matches_screen.dart (NEW, from sports_screen)
│   ├── leaderboard_screen.dart
│   ├── communities_screen.dart (NEW)
│   ├── profile_screen.dart
│   ├── settings_screen.dart
│   ├── match_detail_screen.dart
│   ├── player_detail_screen.dart
│   ├── player_rankings_screen.dart
│   ├── reels_viewer_screen.dart
│   ├── series_screen.dart
│   ├── prediction_screen.dart
│   └── team_matches_screen.dart
├── widgets/ (same as now)
├── animations/ (NEW)
│   ├── sports_animation_engine.dart
│   ├── cricket_animations.dart
│   ├── football_animations.dart
│   └── ...
└── utils/
    ├── formatters.dart
    └── time_ago.dart
```

---

## PART 13: UI/UX DESIGN PRINCIPLES

### 13.1 Dark Theme (Default)
- Background: `#0E1116`
- Surface: `#161B22`
- Card: `#1C2230`
- Primary Blue: `#2196F3`
- Live Red: `#E53935`
- Accent Green (dark): `#21C25A`
- Text: White / White 70%

### 13.2 Light Theme
- Background: `#F4F6FA`
- Surface: `#FFFFFF`
- Card: `#FFFFFF`
- Primary Blue: `#2196F3`
- Live Red: `#E53935`
- Accent Blue (light): `#2196F3`
- Text: `#1A1F2B` / Black 54%

### 13.3 Cracks-like Design Cues
- Cards with rounded corners (12-14px radius)
- Subtle shadows/gradients on cards
- Bold typography (w800/w900 for scores)
- Status badges with colored backgrounds
- Live indicator: red dot with pulsing glow
- Clean white/dark cards with minimal borders
- Icons + text for all navigation

### 13.4 Animations & Micro-interactions
- Smooth page transitions
- Live score cards slide in/out when updating
- Pull-to-refresh animation
- Heart/like animation on news/reels
- Skeleton loading placeholders
- Comment balloon pop on new chat message
- Notification badge count on bell icon

---

## PART 14: RESPONSIVE & PLATFORM CONSIDERATIONS

- **Android-first** but iOS-compatible
- Support tablets (adaptive layout)
- Bottom nav adapts to 3 items on small screens (hide Communities if needed)
- Top bar collapses on scroll
- Match Center uses scrollable tabs (works on all screen sizes)
- Image caching to reduce bandwidth
- Offline fallback: show last cached data when offline

---

## SUMMARY OF EXISTING vs NEW

| Feature | Status | Effort |
|---------|--------|--------|
| Bottom nav (Home, Matches, Leaderboard, Profile) | Built (different order) | Low |
| Communities tab | **Not built** | High |
| Live matches carousel | Built | Low |
| News + reels feed | Built | Medium |
| Cricket match center (scorecard, commentary, squads) | Built | Low-Medium |
| Non-cricket match center | Basic | High |
| Live animation system | **Stub only** | Very High |
| Live visualization (pitch, field, court) | **Not built** | Very High |
| Commentary filters | **Not built** | Medium |
| Graphs tab (wagon wheel, charts) | **Not built** | High |
| Player profile from squads | **Not wired** | Medium |
| Live chat | Built | Low |
| Series/Matches tab | Built | Medium |
| Leaderboard (teams/fans toggle) | Basic (fans only) | Medium |
| FanCoin history | **Not built** | Medium |
| Settings (custom themes, contact us) | Partial | Medium |
| Auth & onboarding | Built | Low |
| Guest mode | Built | Low |
| Community social features | **Not built** | Very High |
