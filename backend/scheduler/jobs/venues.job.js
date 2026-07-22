const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class VenuesJob {

    async run() {

        console.log("Venue Scheduler Started");

    }

    async refreshVenue(id) {

        try {

            const data =
                await providers.venues.getVenue(id);

            cache.set(
                `venue:${id}`,
                data,
                86400
            );

        } catch (err) {

            console.error(err.message);

        }

    }

    async refreshMatches(id) {

        try {

            const data =
                await providers.venues.getVenueMatches(id);

            cache.set(
                `venue:${id}:matches`,
                data,
                1800
            );

        } catch (err) {

            console.error(err.message);

        }

    }

    async refreshStats(id) {

        try {

            const data =
                await providers.venues.getVenueStats(id);

            cache.set(
                `venue:${id}:stats`,
                data,
                86400
            );

        } catch (err) {

            console.error(err.message);

        }

    }

}

module.exports = new VenuesJob();