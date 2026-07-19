const activeUsers =
require("../scheduler/activeUsers");

class PresenceManager {

    watch(matchId, userId) {

        activeUsers.addUser(

            matchId,

            userId

        );

    }

    heartbeat(matchId, userId) {

        activeUsers.updateHeartbeat(

            matchId,

            userId

        );

    }

    leave(matchId, userId) {

        activeUsers.removeUser(

            matchId,

            userId

        );

    }

}

module.exports =
new PresenceManager();