const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class StatsJob {

    async run() {

        try {

            const list = await providers.stats.getStatsList();

            cache.set(
                "stats:list",
                list,
                86400
            );

        } catch (e) {

            console.error(e.message);

        }

    }

}

module.exports = new StatsJob();