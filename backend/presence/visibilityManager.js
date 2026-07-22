const presence =
require("./presenceManager");

module.exports = {

    foreground(matchId, userId) {

        presence.watch(

            matchId,

            userId

        );

    },

    background(matchId, userId) {

        presence.leave(

            matchId,

            userId

        );

    }

};