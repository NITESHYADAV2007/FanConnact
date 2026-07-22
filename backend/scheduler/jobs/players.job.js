const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class PlayersJob {

    async run() {

        try {

            await this.refreshTrending();

        } catch (err) {

            console.error("Players Job Error:", err.message);

        }

    }

    async refreshTrending() {

        try {

            const data =
                await providers.players.getTrendingPlayers();

            cache.set(
                "players:trending",
                data,
                900
            );

            console.log("✅ Players Trending Updated");

        } catch (err) {

            console.error(
                "Players Trending Failed:",
                err.message
            );

        }

    }

}

module.exports = new PlayersJob();