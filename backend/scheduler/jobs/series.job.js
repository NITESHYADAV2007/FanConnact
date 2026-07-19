const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class SeriesJob {

    async run() {

        await Promise.all([

            this.refreshMatches(),
            this.refreshPointsTable(),
            this.refreshSquads(),
            this.refreshStats(),
            this.refreshVenues(),
            this.refreshNews()

        ]);

    }

    async refreshMatches() {

        try {

            const data =
                await providers.series.getSeriesMatches();

            cache.set(
                "series:matches",
                data,
                300
            );

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshPointsTable() {

        try {

            const data =
                await providers.series.getPointsTable();

            cache.set(
                "series:points",
                data,
                300
            );

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshSquads() {

        try {

            const data =
                await providers.series.getSquads();

            cache.set(
                "series:squads",
                data,
                1800
            );

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshStats() {

        try {

            const data =
                await providers.series.getStats();

            cache.set(
                "series:stats",
                data,
                1800
            );

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshVenues() {

        try {

            const data =
                await providers.series.getVenues();

            cache.set(
                "series:venues",
                data,
                3600
            );

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshNews() {

        try {

            const data =
                await providers.series.getNews();

            cache.set(
                "series:news",
                data,
                600
            );

        } catch (e) {

            console.error(e.message);

        }

    }

}

module.exports = new SeriesJob();