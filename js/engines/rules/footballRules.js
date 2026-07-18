/* ==========================================================
        Football Rules
========================================================== */

import * as Builder from "../builders/predictionBuilder.js";

import {

PredictionTrigger

}

from "../engine/predictionEngine.js";

import{

goalOptions,

footballWinnerOptions,

yesNoOptions

}

from "../helpers/predictionHelper.js";

export const footballRules=[];

/* ==========================================================
        Match Winner
========================================================== */

footballRules.push({

    id:"MATCH_WINNER",

    priority:100,

    condition(match){

        return(

            match.status==="UPCOMING"

        );

    },

    build(match){

        return Builder.create({

            trigger:

            PredictionTrigger.MATCH_WINNER,

            matchId:match.id,

            sport:"football",

            difficulty:"easy",

            type:"MATCH_WINNER",

            question:

            "Who will win the match?",

            options:

            footballWinnerOptions(match)

        });

    }

});

/* ==========================================================
        Total Goals
========================================================== */

footballRules.push({

    id:"TOTAL_GOALS",

    priority:90,

    condition(match){

        return(

            match.status==="UPCOMING"

        );

    },

    build(match){

        return Builder.create({

            trigger:

            PredictionTrigger.TOTAL_GOALS,

            matchId:match.id,

            sport:"football",

            difficulty:"easy",

            type:"TOTAL_GOALS",

            question:

            "How many total goals will be scored?",

            options:

            goalOptions()

        });

    }

});

/* ==========================================================
        Both Teams To Score
========================================================== */

footballRules.push({

    id:"BOTH_TEAMS_SCORE",

    priority:85,

    condition(match){

        return match.status==="UPCOMING";

    },

    build(match){

        return Builder.create({

            trigger:
            PredictionTrigger.BOTH_TEAMS_SCORE,

            matchId:match.id,

            sport:"football",

            difficulty:"medium",

            type:"BOTH_TEAMS_SCORE",

            question:"Will both teams score?",

            options:yesNoOptions()

        });

    }

});

/* ==========================================================
        Half Time Winner
========================================================== */

footballRules.push({

    id:"HALF_TIME",

    priority:80,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:
            PredictionTrigger.HALF_TIME,

            matchId:match.id,

            sport:"football",

            difficulty:"medium",

            type:"HALF_TIME",

            question:"Who will lead at Half Time?",

            options:footballWinnerOptions(match)

        });

    }

});
/* ==========================================================
        First Goal
========================================================== */

footballRules.push({

    id:"FIRST_GOAL",

    priority:95,

    condition(match){

        return(

            match.status==="LIVE" &&

            match.homeScore===0 &&

            match.awayScore===0

        );

    },

    build(match){

        return Builder.create({

            trigger:
            PredictionTrigger.FIRST_GOAL,

            matchId:match.id,

            sport:"football",

            difficulty:"medium",

            type:"FIRST_GOAL",

            question:"Which team will score the first goal?",

            options:[

                {

                    id:"home",

                    text:match.homeTeam.name

                },

                {

                    id:"away",

                    text:match.awayTeam.name

                }

            ]

        });

    }

});

/* ==========================================================
        Next Goal
========================================================== */

footballRules.push({

    id:"NEXT_GOAL",

    priority:78,

    condition(match){

        return(

            match.status==="LIVE"

        );

    },

    build(match){

        return Builder.create({

            trigger:
            PredictionTrigger.NEXT_GOAL,

            matchId:match.id,

            sport:"football",

            difficulty:"hard",

            type:"NEXT_GOAL",

            question:"Which team will score the next goal?",

            options:[

                {

                    id:"home",

                    text:match.homeTeam.name

                },

                {

                    id:"away",

                    text:match.awayTeam.name

                }

            ]

        });

    }

});

/* ==========================================================
        Clean Sheet
========================================================== */

footballRules.push({

    id:"CLEAN_SHEET",

    priority:60,

    condition(match){

        return(

            match.status==="LIVE"

        );

    },

    build(match){

        return Builder.create({

            trigger:
            PredictionTrigger.CLEAN_SHEET,

            matchId:match.id,

            sport:"football",

            difficulty:"hard",

            type:"CLEAN_SHEET",

            question:"Will either team keep a clean sheet?",

            options:yesNoOptions()

        });

    }

});

/* ==========================================================
        Yellow Card
========================================================== */

footballRules.push({

    id:"YELLOW_CARD",

    priority:50,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.YELLOW_CARD,

            matchId:match.id,

            sport:"football",

            difficulty:"hard",

            type:"YELLOW_CARD",

            question:"Will there be a yellow card in the next 10 minutes?",

            options:yesNoOptions()

        });

    }

});

/* ==========================================================
        Red Card
========================================================== */

footballRules.push({

    id:"RED_CARD",

    priority:55,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.RED_CARD,

            matchId:match.id,

            sport:"football",

            difficulty:"expert",

            type:"RED_CARD",

            question:"Will a red card be shown?",

            options:yesNoOptions()

        });

    }

});

/* ==========================================================
        Penalty
========================================================== */

footballRules.push({

    id:"PENALTY",

    priority:60,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.PENALTY,

            matchId:match.id,

            sport:"football",

            difficulty:"expert",

            type:"PENALTY",

            question:"Will a penalty be awarded?",

            options:yesNoOptions()

        });

    }

});

/* ==========================================================
        Full Time Result
========================================================== */

footballRules.push({

    id:"FULL_TIME",

    priority:65,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.FULL_TIME,

            matchId:match.id,

            sport:"football",

            difficulty:"medium",

            type:"FULL_TIME",

            question:"Who will win at Full Time?",

            options:footballWinnerOptions(match)

        });

    }

});