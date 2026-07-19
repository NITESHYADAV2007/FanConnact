const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class RankingsProvider {

    async getBatsmen(format, women) {

        const { data } = await api.get(
            endpoints.RANKING_BATSMEN(format, women)
        );

        return data;
    }

    async getBowlers(format, women) {

        const { data } = await api.get(
            endpoints.RANKING_BOWLERS(format, women)
        );

        return data;
    }

    async getAllRounders(format, women) {

        const { data } = await api.get(
            endpoints.RANKING_ALLROUNDERS(format, women)
        );

        return data;
    }

    async getTeams(format, women) {

        const { data } = await api.get(
            endpoints.RANKING_TEAMS(format, women)
        );

        return data;
    }

}

module.exports = new RankingsProvider();