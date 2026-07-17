/**
 * api-quota.js — Shared daily API-budget + on-disk cache layer.
 *
 * Problem: the external data provider (API-Sports / ICC / FIFA / ESPN) allows
 * only ~100 requests per day. With many users hitting the site, naive live
 * fetching would exhaust that budget in minutes.
 *
 * Solution:
 *   1. A persistent DAILY QUOTA counter (stored in data/api-quota.json) that
 *      tracks every outbound external request and refuses to call the API once
 *      the daily limit is reached.
 *   2. An on-disk CACHE (data/api-cache.json) keyed by URL+params. Every
 *      successful external response is cached for a configurable TTL, so the
 *      same request from any user is served from disk — not from the API.
 *   3. The backend only refreshes the cache during scheduled syncs (every 6h),
 *      so 100 users all read the same cached file. The daily quota is never
 *      touched by normal page traffic.
 *
 * Result: ~100 external calls/day max, served to unlimited users via cache.
 */

const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', 'data');
const QUOTA_PATH = path.join(DATA_DIR, 'api-quota.json');
const CACHE_PATH = path.join(DATA_DIR, 'api-cache.json');

// ── Tunables ────────────────────────────────────────────────────────────────
const DAILY_LIMIT = 100;          // provider's hard daily cap
const QUOTA_RESET_MS = 24 * 60 * 60 * 1000;
const DEFAULT_TTL_MS = 6 * 60 * 60 * 1000; // 6h — matches the sync interval

// ── Low-level persistence ────────────────────────────────────────────────────
function loadJSON(p, fallback) {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return fallback; }
}
function saveJSON(p, data) {
  try { fs.writeFileSync(p, JSON.stringify(data, null, 2), 'utf8'); } catch (e) {
    console.error('[api-quota] save failed:', e.message);
  }
}

// ── Quota state ──────────────────────────────────────────────────────────────
function loadQuota() {
  const q = loadJSON(QUOTA_PATH, null);
  const now = Date.now();
  if (!q || !q.date || (now - new Date(q.date).getTime()) >= QUOTA_RESET_MS) {
    // New day (or first run) → reset the counter
    const fresh = { date: new Date(now).toISOString(), used: 0, limit: DAILY_LIMIT, history: [] };
    saveJSON(QUOTA_PATH, fresh);
    return fresh;
  }
  return q;
}
function saveQuota(q) { saveJSON(QUOTA_PATH, q); }

function quotaStatus() {
  const q = loadQuota();
  return {
    date: q.date,
    used: q.used,
    limit: q.limit,
    remaining: Math.max(0, q.limit - q.used),
    exhausted: q.used >= q.limit,
    resetsInHours: +(((new Date(q.date).getTime() + QUOTA_RESET_MS) - Date.now()) / 3600000).toFixed(1)
  };
}

/**
 * Call BEFORE making any external request.
 * Returns true if a request is allowed (and increments the counter),
 * false if the daily budget is exhausted.
 */
function consumeQuota(n = 1) {
  const q = loadQuota();
  if (q.used + n > q.limit) return false;
  q.used += n;
  if (!q.history) q.history = [];
  q.history.push({ t: new Date().toISOString(), n });
  if (q.history.length > 200) q.history = q.history.slice(-200);
  saveQuota(q);
  return true;
}

// ── Cache state ──────────────────────────────────────────────────────────────
function loadCache() { return loadJSON(CACHE_PATH, {}); }
function saveCache(c) { saveJSON(CACHE_PATH, c); }

function cacheKey(url, params) {
  const p = params ? '?' + (typeof params === 'string' ? params : new URLSearchParams(params).toString()) : '';
  return (url + p).replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 200);
}

/**
 * Read from cache. Returns { hit, data, ageMs }.
 */
function getCached(url, params, ttlMs = DEFAULT_TTL_MS) {
  const c = loadCache();
  const k = cacheKey(url, params);
  const entry = c[k];
  if (!entry) return { hit: false };
  const age = Date.now() - entry.ts;
  if (age > ttlMs) return { hit: false, stale: true, data: entry.data, ageMs: age };
  return { hit: true, data: entry.data, ageMs: age };
}

/**
 * Write to cache.
 */
function setCached(url, params, data, ttlMs = DEFAULT_TTL_MS) {
  const c = loadCache();
  c[cacheKey(url, params)] = { ts: Date.now(), ttl: ttlMs, url: url + (params ? '?' + (typeof params === 'string' ? params : new URLSearchParams(params).toString()) : ''), data };
  saveCache(c);
}

/**
 * High-level fetch with quota + cache.
 *   - If a fresh cached copy exists → return it (no API call, no quota used).
 *   - Else if quota remains → call fetcher(), cache + count it, return data.
 *   - Else (quota exhausted) → return stale cache if present, else null.
 *
 * @param {string} url
 * @param {object|string} params
 * @param {function} fetcher  async () => data   (the actual external call)
 * @param {object} opts  { ttlMs, cost }
 */
async function cachedFetch(url, params, fetcher, opts = {}) {
  const ttlMs = opts.ttlMs || DEFAULT_TTL_MS;
  const cost = opts.cost || 1;

  const cached = getCached(url, params, ttlMs);
  if (cached.hit) {
    return { data: cached.data, source: 'cache', ageMs: cached.ageMs, quotaUsed: false };
  }

  // Need a live call — but only if budget allows
  if (!consumeQuota(cost)) {
    if (cached.stale) {
      return { data: cached.data, source: 'stale-cache', ageMs: cached.ageMs, quotaUsed: false, quotaExhausted: true };
    }
    return { data: null, source: 'quota-exhausted', quotaUsed: false, quotaExhausted: true };
  }

  try {
    const data = await fetcher();
    if (data !== null && data !== undefined) {
      setCached(url, params, data, ttlMs);
      return { data, source: 'live', ageMs: 0, quotaUsed: true };
    }
    // Fetcher returned nothing — fall back to stale cache if we have it
    if (cached.stale) return { data: cached.data, source: 'stale-cache', ageMs: cached.ageMs, quotaUsed: true };
    return { data: null, source: 'empty', quotaUsed: true };
  } catch (e) {
    if (cached.stale) return { data: cached.data, source: 'stale-cache', ageMs: cached.ageMs, quotaUsed: true, error: e.message };
    return { data: null, source: 'error', quotaUsed: true, error: e.message };
  }
}

module.exports = {
  DAILY_LIMIT,
  quotaStatus,
  consumeQuota,
  getCached,
  setCached,
  cachedFetch,
  cacheKey
};
