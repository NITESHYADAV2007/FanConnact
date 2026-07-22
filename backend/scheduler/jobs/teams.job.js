const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class TeamsJob {

    async run() {

        await Promise.all([

            this.refreshInternational(),
            this.refreshLeague(),
            this.refreshDomestic(),
            this.refreshWomen()

        ]);

    }

    async refreshInternational() {

        try {

            const data =
                await providers.teams.getInternationalTeams();

            cache.set(
                "teams:international",
                data,
                86400
            );

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshLeague() {

        try {

            const data =
                await providers.teams.getLeagueTeams();

            cache.set(
                "teams:league",
                data,
                86400
            );

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshDomestic() {

        try {

            const data =
                await providers.teams.getDomesticTeams();

            cache.set(
                "teams:domestic",
                data,
                86400
            );

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshWomen() {

        try {

            const data =
                await providers.teams.getWomenTeams();

            cache.set(
                "teams:women",
                data,
                86400
            );

        } catch (e) {

            console.error(e.message);

        }

    }

}

module.exports = new TeamsJob();