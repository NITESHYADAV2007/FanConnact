const {

    normalizeLiveMatches,
    normalizeUpcomingMatches,
    normalizeRecentMatches,
    normalizeMatchDetails

} = require("../../normalizers/cricketNormalizer");

const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class CricbuzzProvider {

    /* ===============================
            LIVE MATCHES
    =============================== */

    async getLiveMatches() {

        const { data } = await api.get(
            endpoints.LIVE_MATCHES
        );

        return normalizeLiveMatches(data);

    }

    /* ===============================
            UPCOMING MATCHES
    =============================== */

    async getUpcomingMatches() {

        const { data } = await api.get(
            endpoints.UPCOMING_MATCHES
        );

        return normalizeUpcomingMatches(data);

    }

    /* ===============================
            RECENT MATCHES
    =============================== */

    async getRecentMatches() {

        const { data } = await api.get(
            endpoints.RECENT_MATCHES
        );

        return normalizeRecentMatches(data);

    }

    /* ===============================
            MATCH INFO
    =============================== */

    async getMatchDetails(matchId) {

        const { data } = await api.get(
            endpoints.MATCH_INFO(matchId)
        );

        return normalizeMatchDetails(data);

    }

    /* ===============================
        COMMENTARY
================================ */

async getCommentary(matchId, iid, tms) {

    const { data } = await api.get(

        endpoints.COMMENTARY(
            matchId,
            iid,
            tms
        )

    );

    return data;

}

/* ===============================
        HCOMMENTARY
================================ */

async getHCommentary(matchId, iid, tms) {

    const { data } = await api.get(

        endpoints.HCOMMENTARY(
            matchId,
            iid,
            tms
        )

    );

    return data;

}

/* ===============================
        SCORECARD
================================ */

async getScorecard(matchId) {

    const { data } = await api.get(

        endpoints.SCORECARD(matchId)

    );

    return data;

}
/* ===============================
        PLAYING XI
================================ */

async getSquads(matchId) {

    const { data } = await api.get(

        endpoints.SQUADS(matchId)

    );

    return data;

}
}

module.exports = new CricbuzzProvider();