const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class PlayersProvider {

    async getTrendingPlayers() {

        const { data } =
        await api.get(endpoints.PLAYER_TRENDING);

        return data;

    }

    async searchPlayers(name) {

        const { data } =
        await api.get(endpoints.PLAYER_SEARCH(name));

        return data;

    }

    async getPlayerInfo(id) {

        const { data } =
        await api.get(endpoints.PLAYER_INFO(id));

        return data;

    }

    async getPlayerBatting(id) {

        const { data } =
        await api.get(endpoints.PLAYER_BATTING(id));

        return data;

    }

    async getPlayerBowling(id) {

        const { data } =
        await api.get(endpoints.PLAYER_BOWLING(id));

        return data;

    }

    async getPlayerCareer(id) {

        const { data } =
        await api.get(endpoints.PLAYER_CAREER(id));

        return data;

    }

    async getPlayerNews(id) {

        const { data } =
        await api.get(endpoints.PLAYER_NEWS(id));

        return data;

    }

}

module.exports = new PlayersProvider();