const activeUsers =

require("./activeUsers");

module.exports = {

    join(matchId){

        activeUsers.addUser(matchId);

        console.log(

            "🟢 User Joined",

            matchId

        );

    },

    leave(matchId){

        activeUsers.removeUser(matchId);

        console.log(

            "🔴 User Left",

            matchId

        );

    }

};