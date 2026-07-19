class ActiveUsers {

    constructor() {

        this.matches = new Map();

        this.TIMEOUT = 45000;

    }

    addUser(matchId, userId) {

        if (!this.matches.has(matchId)) {

            this.matches.set(matchId, new Map());

        }

        this.matches.get(matchId).set(userId, {

            joinedAt: Date.now(),

            heartbeat: Date.now()

        });

    }

    updateHeartbeat(matchId, userId) {

        if (!this.matches.has(matchId)) return;

        const users = this.matches.get(matchId);

        if (!users.has(userId)) return;

        users.get(userId).heartbeat = Date.now();

    }

    removeUser(matchId, userId) {

        if (!this.matches.has(matchId)) return;

        const users = this.matches.get(matchId);

        users.delete(userId);

        if (users.size === 0) {

            this.matches.delete(matchId);

        }

    }

    cleanup() {

        const now = Date.now();

        for (const [matchId, users] of this.matches) {

            for (const [userId, data] of users) {

                if (now - data.heartbeat > this.TIMEOUT) {

                    users.delete(userId);

                }

            }

            if (users.size === 0) {

                this.matches.delete(matchId);

            }

        }

    }

    getWatchingCount(matchId) {

        if (!this.matches.has(matchId))

            return 0;

        return this.matches.get(matchId).size;

    }

    getWatchingMatches() {

        return [...this.matches.keys()];

    }

    hasActiveUsers() {

        return this.matches.size > 0;

    }

}

module.exports = new ActiveUsers();