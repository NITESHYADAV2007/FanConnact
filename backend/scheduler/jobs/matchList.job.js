const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

const CACHE_KEYS = {
    LIVE: "matches:live",
    UPCOMING: "matches:upcoming",
    RECENT: "matches:recent"
};

class MatchListJob {

    async run() {

        try {

            await this.refreshLive();

            await this.refreshUpcoming();

            await this.refreshRecent();

        } catch (err) {

            console.error("❌ MatchList Job Failed");
            console.error(err.message);

        }

    }

    async refreshLive() {

        try {

            const live = await providers.matches.getLiveMatches();

            cache.set(
                CACHE_KEYS.LIVE,
                live,
                30
            );

            console.log(
                "✅ Live Matches Cache Updated"
            );

        } catch (err) {

            console.error(
                "Live Refresh Failed:",
                err.message
            );

        }

    }

    async refreshUpcoming() {

        try {

            const upcoming =
                await providers.matches.getUpcomingMatches();

            cache.set(
                CACHE_KEYS.UPCOMING,
                upcoming,
                600
            );

            console.log(
                "✅ Upcoming Cache Updated"
            );

        } catch (err) {

            console.error(
                "Upcoming Refresh Failed:",
                err.message
            );

        }

    }

    async refreshRecent() {

        try {

            const recent =
                await providers.matches.getRecentMatches();

            cache.set(
                CACHE_KEYS.RECENT,
                recent,
                3600
            );

            console.log(
                "✅ Recent Cache Updated"
            );

        } catch (err) {

            console.error(
                "Recent Refresh Failed:",
                err.message
            );

        }

    }

}

module.exports = new MatchListJob();