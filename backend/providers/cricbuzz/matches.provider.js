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

    async getCommentary(matchId){

    const { data } = await api.get(

        endpoints.COMMENTARY(matchId)

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

async getOvers(matchId){

    const { data } = await api.get(

        endpoints.OVERS(matchId)

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

async getBallsGraph(matchId){

    const { data } = await api.get(

        endpoints.BALL_GRAPH(matchId)

    );

    return data;

}

async getPartnershipGraph(matchId){

    const { data } = await api.get(

        endpoints.PARTNERSHIP_GRAPH(matchId)

    );

    return data;

}

}

module.exports = new MatchesProvider();