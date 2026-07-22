const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class RankingsJob {

    async run() {

        await Promise.all([

            this.refreshBatsmen(),
            this.refreshBowlers(),
            this.refreshAllRounders(),
            this.refreshTeams()

        ]);

    }

    async refreshBatsmen() {

        try {

            const data =
                await providers.rankings.getBatsmen();

            cache.set(
                "rankings:batsmen",
                data,
                21600
            );

        } catch (err) {

            console.error(err.message);

        }

    }

    async refreshBowlers() {

        try {

            const data =
                await providers.rankings.getBowlers();

            cache.set(
                "rankings:bowlers",
                data,
                21600
            );

        } catch (err) {

            console.error(err.message);

        }

    }

    async refreshAllRounders() {

        try {

            const data =
                await providers.rankings.getAllRounders();

            cache.set(
                "rankings:allrounders",
                data,
                21600
            );

        } catch (err) {

            console.error(err.message);

        }

    }

    async refreshTeams() {

        try {

            const data =
                await providers.rankings.getTeams();

            cache.set(
                "rankings:teams",
                data,
                21600
            );

        } catch (err) {

            console.error(err.message);

        }

    }

}

module.exports = new RankingsJob();