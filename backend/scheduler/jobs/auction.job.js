const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class AuctionJob {

    async run() {

        await Promise.all([

            this.refreshSeasons(),
            this.refreshTeams(),
            this.refreshCompleted(),
            this.refreshUpcoming(),
            this.refreshLive()

        ]);

    }

    async refreshSeasons() {

        cache.set(
            "auction:seasons",
            await providers.auction.getSeasons(),
            86400
        );

    }

    async refreshTeams() {

        cache.set(
            "auction:teams",
            await providers.auction.getTeams(),
            86400
        );

    }

    async refreshCompleted() {

        cache.set(
            "auction:completed",
            await providers.auction.getCompleted(),
            3600
        );

    }

    async refreshUpcoming() {

        cache.set(
            "auction:upcoming",
            await providers.auction.getUpcoming(),
            1800
        );

    }

    async refreshLive() {

        cache.set(
            "auction:live",
            await providers.auction.getLive(),
            30
        );

    }

}

module.exports = new AuctionJob();