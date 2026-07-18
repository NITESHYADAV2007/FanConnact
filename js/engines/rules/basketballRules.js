/* ==========================================================
        Basketball Rules
========================================================== */

import * as Builder from "../builders/predictionBuilder.js";

import {

PredictionTrigger

}

from "../predictionEngine.js";

import{

yesNoOptions

}

from "../helpers/predictionHelpers.js";

export const basketballRules=[];

/* ==========================================================
        Match Winner
========================================================== */

basketballRules.push({

    id:"MATCH_WINNER",

    priority:100,

    condition(match){

        return match.status==="UPCOMING";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.MATCH_WINNER,

            sport:"basketball",

            matchId:match.id,

            difficulty:"easy",

            type:"MATCH_WINNER",

            question:"Who will win the game?",

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
        First To 50
========================================================== */

basketballRules.push({

    id:"FIRST_TO_50",

    priority:95,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.FIRST_TO_50,

            sport:"basketball",

            matchId:match.id,

            difficulty:"medium",

            type:"FIRST_TO_50",

            question:"Which team will reach 50 points first?",

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
        Total Points
========================================================== */

basketballRules.push({

    id:"TOTAL_POINTS",

    priority:90,

    condition(match){

        return true;

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.TOTAL_POINTS,

            sport:"basketball",

            matchId:match.id,

            difficulty:"medium",

            type:"TOTAL_POINTS",

            question:"How many total points will be scored?",

            options:[

                {

                    id:"1",

                    text:"Below 180"

                },

                {

                    id:"2",

                    text:"180-200"

                },

                {

                    id:"3",

                    text:"201-220"

                },

                {

                    id:"4",

                    text:"220+"

                }

            ]

        });

    }

});
/* ==========================================================
        First To 100
========================================================== */

basketballRules.push({

    id:"FIRST_TO_100",

    priority:95,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.FIRST_TO_100,

            sport:"basketball",

            matchId:match.id,

            difficulty:"hard",

            type:"FIRST_TO_100",

            question:"Which team will reach 100 points first?",

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
        Next 3 Pointer
========================================================== */

basketballRules.push({

    id:"NEXT_THREE_POINTER",

    priority:80,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.NEXT_THREE_POINTER,

            sport:"basketball",

            matchId:match.id,

            difficulty:"hard",

            type:"NEXT_THREE_POINTER",

            question:"Which team will score the next 3-pointer?",

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
        Next 3 Pointer
========================================================== */

basketballRules.push({

    id:"NEXT_THREE_POINTER",

    priority:80,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.NEXT_THREE_POINTER,

            sport:"basketball",

            matchId:match.id,

            difficulty:"hard",

            type:"NEXT_THREE_POINTER",

            question:"Which team will score the next 3-pointer?",

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
        Quarter Winner
========================================================== */

basketballRules.push({

    id:"NEXT_QUARTER_WINNER",

    priority:75,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.NEXT_QUARTER_WINNER,

            sport:"basketball",

            matchId:match.id,

            difficulty:"medium",

            type:"NEXT_QUARTER_WINNER",

            question:"Who will win this quarter?",

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
        Overtime
========================================================== */

basketballRules.push({

    id:"OVERTIME",

    priority:60,

    condition(match){

        return match.status==="LIVE";

    },

    build(match){

        return Builder.create({

            trigger:PredictionTrigger.OVERTIME,

            sport:"basketball",

            matchId:match.id,

            difficulty:"expert",

            type:"OVERTIME",

            question:"Will the match go into Overtime?",

            options:yesNoOptions()

        });

    }

});