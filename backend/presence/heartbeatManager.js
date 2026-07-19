const presence =
require("./presenceManager");

class HeartbeatManager {

    beat(matchId, userId) {

        presence.heartbeat(

            matchId,

            userId

        );

    }

}

module.exports =
new HeartbeatManager();