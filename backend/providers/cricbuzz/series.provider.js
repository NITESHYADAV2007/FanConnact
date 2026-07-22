const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class SeriesProvider {

    async getSeriesMatches(seriesId) {

        const { data } = await api.get(

            endpoints.SERIES_MATCHES(seriesId)

        );

        return data;

    }

    async getPointsTable(seriesId) {

        const { data } = await api.get(

            endpoints.POINTS_TABLE(seriesId)

        );

        return data;

    }

    async getSquads(seriesId) {

        const { data } = await api.get(

            endpoints.SERIES_SQUADS(seriesId)

        );

        return data;

    }

    async getSquadDetails(seriesId, squadId) {

        const { data } = await api.get(

            endpoints.SQUAD_DETAILS(seriesId, squadId)

        );

        return data;

    }

    async getStats(seriesId, statsType = "mostRuns") {

        const { data } = await api.get(

            endpoints.SERIES_STATS(seriesId, statsType)

        );

        return data;

    }

    async getVenues(seriesId) {

        const { data } = await api.get(

            endpoints.SERIES_VENUES(seriesId)

        );

        return data;

    }

    async getNews(seriesId) {

        const { data } = await api.get(

            endpoints.SERIES_NEWS(seriesId)

        );

        return data;

    }

}

module.exports = new SeriesProvider();