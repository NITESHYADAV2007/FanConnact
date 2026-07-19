const cron = require("node-cron");
const jobs = require("./jobs");

function startScheduler() {

    console.log("🚀 Scheduler Started");

    cron.schedule("*/15 * * * * *", jobs.refreshMatchCenter);

    cron.schedule("*/30 * * * * *", jobs.refreshMatchList);

    cron.schedule("*/5 * * * *", jobs.refreshNews);

    cron.schedule("*/15 * * * *", jobs.refreshPhotos);

    cron.schedule("*/10 * * * *", jobs.refreshAuction);

    cron.schedule("0 */1 * * *", jobs.refreshSeries);

    cron.schedule("0 */2 * * *", jobs.refreshTeams);

    cron.schedule("0 */2 * * *", jobs.refreshPlayers);

    cron.schedule("0 */6 * * *", jobs.refreshRankings);

    // Venue Scheduler Disabled
    // cron.schedule("0 */6 * * *", jobs.refreshVenues);

    cron.schedule("0 */12 * * *", jobs.refreshSchedule);

    cron.schedule("15 */12 * * *", jobs.refreshArchive);

    cron.schedule("30 */12 * * *", jobs.refreshBrowse);

    cron.schedule("45 */12 * * *", jobs.refreshStats);

    console.log("✅ All Cron Jobs Loaded");

}

module.exports = {
    startScheduler
};