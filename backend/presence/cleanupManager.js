const cron =
require("node-cron");

const activeUsers =
require("../scheduler/activeUsers");

function startCleanup() {

    cron.schedule(

        "*/15 * * * * *",

        () => {

            activeUsers.cleanup();

        }

    );

}

module.exports = {

    startCleanup

};