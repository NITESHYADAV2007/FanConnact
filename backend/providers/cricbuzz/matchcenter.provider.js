const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class MatchCenterProvider {

    async getHome() {

        const { data } =
        await api.get(endpoints.HOME);

        return data;

    }

    async getMatchInfo(id) {

        const { data } =
        await api.get(endpoints.MATCH_INFO(id));

        return data;

    }

}

module.exports = new MatchCenterProvider();