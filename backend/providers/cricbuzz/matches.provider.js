const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

const {

    normalizeLiveMatches,

    normalizeUpcomingMatches,

    normalizeRecentMatches,

    normalizeMatchDetails

} = require("../../normalizers/cricketNormalizer");

class MatchesProvider {

    async getLiveMatches() {

        const { data } = await api.get(

            endpoints.LIVE_MATCHES

        );

        return normalizeLiveMatches(data);

    }

    async getUpcomingMatches() {

        const { data } = await api.get(

            endpoints.UPCOMING_MATCHES

        );

        return normalizeUpcomingMatches(data);

    }

    async getRecentMatches() {

        const { data } = await api.get(

            endpoints.RECENT_MATCHES

        );

        return normalizeRecentMatches(data);

    }

    async getMatchInfo(matchId) {

      const { data } = await api.get(

    endpoints.MATCH_INFO(matchId)

);


return normalizeMatchDetails(data);
    }

    async getCommentary(matchId, iid = 1, tms = 0){

    const { data } = await api.get(

        endpoints.COMMENTARY(matchId, iid, tms)

    );

    return data;

}

async getHCommentary(matchId){

    const { data } = await api.get(

        endpoints.HCOMMENTARY(matchId)

    );

    return data;

}

async getScorecard(matchId){

    const { data } = await api.get(

        endpoints.SCORECARD(matchId)

    );

    return data;

}

async getSquads(matchId){

    const { data } = await api.get(

        endpoints.SQUADS(matchId)

    );

    return data;

}

async getOvers(matchId, iid = 1, tms = Date.now()){

    const { data } = await api.get(

        endpoints.OVERS(matchId, iid, tms)

    );

    return data;

}

async getOversDetails(matchId){

    const { data } = await api.get(

        endpoints.OVER_DETAILS(matchId)

    );

    return data;

}

async getHighlights(matchId){

    const { data } = await api.get(

        endpoints.HIGHLIGHTS(matchId)

    );

    return data;

}

async getLeanback(matchId){

    const { data } = await api.get(

        endpoints.LEANBACK(matchId)

    );

    return data;

}

async getHLeanback(matchId){

    const { data } = await api.get(

        endpoints.HLEANBACK(matchId)

    );

    return data;

}

async getOversGraph(matchId){

    const { data } = await api.get(

        endpoints.OVERS_GRAPH(matchId)

    );

    return data;

}

async getBallsGraph(matchId, iid = 1){

    const { data } = await api.get(

        endpoints.BALL_GRAPH(matchId, iid)

    );

    return data;

}

async getPartnershipGraph(matchId){

    const { data } = await api.get(

        endpoints.PARTNERSHIP_GRAPH(matchId)

    );

    return data;

}

// Wagon wheel — derived best-effort from per-ball shot data (ballsGraph
// carries x/y field coordinates per delivery). Cricbuzz has no dedicated
// wagons endpoint, so we walk every list-of-maps in the payload looking for
// {x, y, runs} triples, normalize coordinates to 0..1 and classify each
// shot (dot / single / four / six). Any unrecognized payload degrades to
// an empty wagon list instead of erroring.
async getWagons(matchId, iid = 1){

    let balls;
    try {
        balls = await this.getBallsGraph(matchId, iid);
    } catch (e) {
        return { wagons: [], derived: false, error: e.message };
    }

    const wagons = [];
    const seen = new Set();

    const walk = (node) => {
        if (Array.isArray(node)) {
            node.forEach(walk);
            return;
        }
        if (!node || typeof node !== "object") return;
        const hasXY = Number.isFinite(node.x) && Number.isFinite(node.y);
        const runs = Number.isFinite(node.runs)
            ? node.runs
            : (Number.isFinite(node.run) ? node.run : null);
        if (hasXY && runs !== null) {
            const key = `${node.x},${node.y},${runs},${node.over ?? node.ball ?? ""}`;
            if (!seen.has(key)) {
                seen.add(key);
                const over = node.over ?? node.overnum ?? "";
                wagons.push({
                    x: Math.max(0, Math.min(1, Number(node.x) / 100)),
                    y: Math.max(0, Math.min(1, Number(node.y) / 100)),
                    runs,
                    boundary: runs >= 4,
                    isFour: runs === 4,
                    isSix: runs === 6,
                    label: runs === 0 ? "dot" : (runs === 4 ? "four" : (runs === 6 ? "six" : (runs >= 2 ? "multi" : "single"))),
                    over: over != null && over !== "" ? String(over) : undefined,
                    ball: node.ball != null ? String(node.ball) : undefined,
                });
            }
            return;
        }
        Object.values(node).forEach(walk);
    };

    walk(balls);

    wagons.sort((a, b) => {
        const oa = parseFloat(a.over ?? "999");
        const ob = parseFloat(b.over ?? "999");
        return oa - ob;
    });

    return { wagons, derived: true, count: wagons.length };

}

}

module.exports = new MatchesProvider();