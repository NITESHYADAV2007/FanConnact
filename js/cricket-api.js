/* FANCONNECT real cricket data client — Cricbuzz proxy (backend).
 * Loaded by match-center.html BEFORE match-center-engine.js.
 * Exposes window.FANCONNECT_CRICKET_API used by fetchCricketApi() for
 * scorecard, ball-by-ball commentary and wagon/overs data.
 */
window.FANCONNECT_CRICKET_API = (function () {
  var PROXY = (location.hostname === "localhost" || location.hostname === "127.0.0.1")
    ? "http://localhost:5000/api/real/cricket/proxy"
    : "https://fanconnact-api.onrender.com/api/real/cricket/proxy";

  function jget(path) {
    return fetch(PROXY + path, { signal: AbortSignal.timeout(12000) })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) { return j && j.data !== undefined ? j.data : j; })
      .catch(function () { return null; });
  }

  // Flatten cricbuzz advance payload into legacy innings[] arrays.
  function inningsOf(adv) {
    if (!adv) return null;
    if (Array.isArray(adv.innings) && adv.innings.length) return adv.innings;
    var out = [];
    if (adv.score && adv.score.team1) {
      out = out.concat((adv.score.team1.innings || []).map(function (i) {
        return Object.assign({ batteamname: adv.score.team1.name }, i);
      }));
    }
    if (adv.score && adv.score.team2) {
      out = out.concat((adv.score.team2.innings || []).map(function (i) {
        return Object.assign({ batteamname: adv.score.team2.name }, i);
      }));
    }
    return out.length ? out : null;
  }

  function commentaryOf(comm) {
    if (!comm) return null;
    if (Array.isArray(comm)) return comm;
    return comm.commentary || comm.items || comm.comwrapper || comm.balls || null;
  }

  function oversArray(w) {
    if (!w) return null;
    if (Array.isArray(w)) return w;
    return w.overs || w.overs_breakdown || w.wagons || w.data || null;
  }

  return {
    getMatch: function (id) {
      if (!id) return Promise.resolve(null);
      return Promise.all([
        jget("/matches/" + id + "/advance"),
        jget("/matches/" + id + "/innings/1/commentary"),
        jget("/matches/" + id + "/oversgraph")
      ]).then(function (res) {
        return {
          _raw: {
            scorecard: inningsOf(res[0]),
            commentary: commentaryOf(res[1]),
            wagons: oversArray(res[2])
          }
        };
      });
    },
    getWagons: function (id) {
      if (!id) return Promise.resolve(null);
      return jget("/matches/" + id + "/oversgraph").then(function (w) { return oversArray(w); });
    }
  };
})();
