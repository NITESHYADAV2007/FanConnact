/* ==========================================================
        Cricket Rules
========================================================== */

import * as Builder from "../builders/predictionBuilder.js";

/* ==========================================================
        Cricket Rules
========================================================== */

export const cricketRules = [];/* ==========================================================
        Match Winner
========================================================== */

cricketRules.push({

    id:"MATCH_WINNER",

    priority:100,

    condition(match){

        return(

            match.status==="UPCOMING"

        );

    },

    build(match,helpers){

        return Builder.matchWinner(

            match,

            helpers.expiry(

                match,

                "MATCH_WINNER"

            )

        );

    }

});
/* ==========================================================
        Toss Winner
========================================================== */

cricketRules.push({

    id:"TOSS",

    priority:95,

    condition(match){

        return(

            match.status==="UPCOMING"

        );

    },

    build(match,helpers){

        return Builder.tossWinner(

            match,

            helpers.expiry(

                match,

                "TOSS_WINNER"

            )

        );

    }

});
/* ==========================================================
        Highest Scorer
========================================================== */

cricketRules.push({

    id:"HIGHEST_SCORER",

    priority:40,

    condition(match){

        return(

            match.status==="UPCOMING"

        );

    },

    build(match,helpers){

        return Builder.highestScorer(

            match,

            helpers.players(match),

            helpers.expiry(

                match,

                "HIGHEST_SCORER"

            )

        );

    }

});

/* ==========================================================
        Total Runs
========================================================== */

cricketRules.push({

    id:"TOTAL_RUNS",

    priority:35,

    condition(match){

        return(

            match.status==="UPCOMING"

        );

    },

    build(match,helpers){

        return Builder.totalRuns(

            match,

            helpers.totalRunsOptions(

                match

            ),

            helpers.expiry(

                match,

                "TOTAL_SCORE"

            )

        );

    }

});

/* ==========================================================
        Total Runs
========================================================== */

cricketRules.push({

    id:"TOTAL_RUNS",

    priority:35,

    condition(match){

        return(

            match.status==="UPCOMING"

        );

    },

    build(match,helpers){

        return Builder.totalRuns(

            match,

            helpers.totalRunsOptions(

                match

            ),

            helpers.expiry(

                match,

                "TOTAL_SCORE"

            )

        );

    }

});

/* ==========================================================
        Powerplay
========================================================== */

cricketRules.push({

    id:"POWERPLAY",

    priority:70,

    condition(match){

        return(

            match.currentOver>=6

        );

    },

    build(match,helpers){

        return Builder.powerplay(

            match,

            helpers.powerplayOptions(

                match

            ),

            helpers.expiry(

                match,

                "POWERPLAY_SCORE"

            )

        );

    }

});

/* ==========================================================
        Next Wicket
========================================================== */

cricketRules.push({

    id:"NEXT_WICKET",

    priority:60,

    condition(match){

        return(

            match.lastEvent?.type==="WICKET"

        );

    },

    build(match,helpers){

        return Builder.nextWicket(

            match,

            helpers.bowlers(

                match

            ),

            helpers.expiry(

                match,

                "NEXT_WICKET"

            )

        );

    }

});

/* ==========================================================
        Boundary
========================================================== */

cricketRules.push({

    id:"BOUNDARY",

    priority:50,

    condition(match){

        return(

            match.lastEvent?.type==="FOUR"

        );

    },

    build(match,helpers){

        return Builder.nextBoundary(

            match,

            helpers.expiry(

                match,

                "NEXT_BOUNDARY"

            )

        );

    }

});

cricketRules.push({

id:"PLAYER_FIFTY",

priority:80,

condition(match){

return(

match.currentBatter?.runs>=45 &&

match.currentBatter?.runs<50

);

},

build(match,helpers){

return Builder.playerFifty(

match,

match.currentBatter,

helpers.expiry(

match,

"PLAYER_FIFTY"

)

);

}

});

cricketRules.push({

id:"PLAYER_CENTURY",

priority:90,

condition(match){

return(

match.currentBatter?.runs>=90 &&

match.currentBatter?.runs<100

);

},

build(match,helpers){

return Builder.playerCentury(

match,

match.currentBatter,

helpers.expiry(

match,

"PLAYER_CENTURY"

)

);

}

});

cricketRules.push({

id:"DEATH_OVER",

priority:75,

condition(match){

return(

match.currentOver>=16

);

},

build(match,helpers){

return Builder.deathOvers(

match,

helpers.deathOverOptions(

match),

helpers.expiry(

match,

"DEATH_OVER"

)

);

}

});

cricketRules.push({

id:"CHASE",

priority:95,

condition(match){

return(

match.target &&

match.runsNeeded<=40 &&

match.ballsRemaining<=30

);

},

build(match,helpers){

return Builder.chase(

match,

helpers.expiry(

match,

"CHASE"

)

);

}

});