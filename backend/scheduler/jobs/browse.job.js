const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class BrowseJob {

    async run() {

        cache.set("browse:int", await providers.browse.getInternational(), 3600);
        cache.set("browse:league", await providers.browse.getLeague(), 3600);
        cache.set("browse:domestic", await providers.browse.getDomestic(), 3600);
        cache.set("browse:women", await providers.browse.getWomen(), 3600);

    }

}

module.exports = new BrowseJob();