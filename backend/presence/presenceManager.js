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

    getWatchingCount(matchId) {

        return activeUsers.getWatchingCount(matchId);

    }

    getTotalCount() {

        return activeUsers.getTotalCount();

    }

}

module.exports =
new PresenceManager();