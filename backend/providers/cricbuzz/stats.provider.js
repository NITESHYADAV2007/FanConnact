const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class StatsProvider {

    async getStatsList() {

        const { data } = await api.get(

            endpoints.STATS_LIST

        );

        return data;

    }

    async getStats(

        id = 0,
        statsType = "mostRuns",
        opponent = "",
        year = "",
        team = "",
        matchType = ""

    ) {

        const { data } = await api.get(

            endpoints.FETCH_STATS(

                id,
                statsType,
                opponent,
                year,
                team,
                matchType

            )

        );

        return data;

    }

}

module.exports = new StatsProvider();