// Backend base URL.
//
// ── LOCAL PHONE TESTING (USB, no Wi-Fi needed) ──
// Use 127.0.0.1 together with:  adb reverse tcp:3001 tcp:3001
// This tunnels the phone's localhost:3001 to the PC backend over USB
// (works even when phone & PC are on different Wi-Fi networks).
//
// ── SAME Wi-Fi, NO USB ──
// Set this to your PC LAN IP, e.g. http://192.168.29.53:3001
//
// ── HOSTED (no cable at all) ──
// Deploy backend/ to Render/Railway/Fly and paste the public URL here, e.g.
//   const String apiBaseUrl = 'https://fanconnact-api.onrender.com';
// The backend persists the last fetch to db/cache.json and auto-refreshes,
// so it keeps serving data even after restarts or when the 100/day API
// quota is exhausted.
//
// ✅ ACTIVE: backend is deployed to Render — works from anywhere, no USB needed.
const String apiBaseUrl = 'https://fanconnact-api.onrender.com';
