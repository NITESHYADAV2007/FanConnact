const activeUsers = require("./activeUsers");

class MatchWatcher {

    getWatchingMatches() {

        return activeUsers.getWatchingMatches();

    }

    hasUsers() {

        return activeUsers.hasActiveUsers();

    }

    getWatchingCount(matchId) {

        return activeUsers.getWatchingCount(matchId);

    }

}

module.exports = new MatchWatcher();