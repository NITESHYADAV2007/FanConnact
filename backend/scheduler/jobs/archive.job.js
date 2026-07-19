const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class ArchiveJob {

    async run() {

        cache.set("archive:int", await providers.archive.getInternational(), 86400);
        cache.set("archive:league", await providers.archive.getLeague(), 86400);
        cache.set("archive:domestic", await providers.archive.getDomestic(), 86400);
        cache.set("archive:women", await providers.archive.getWomen(), 86400);

    }

}

module.exports = new ArchiveJob();