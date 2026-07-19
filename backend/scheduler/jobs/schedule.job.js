const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class ScheduleJob {

    async run() {

        cache.set("schedule:int", await providers.schedule.getInternational(), 3600);
        cache.set("schedule:league", await providers.schedule.getLeague(), 3600);
        cache.set("schedule:domestic", await providers.schedule.getDomestic(), 3600);
        cache.set("schedule:women", await providers.schedule.getWomen(), 3600);

    }

}

module.exports = new ScheduleJob();