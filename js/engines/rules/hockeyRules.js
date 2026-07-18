/* ==========================================================
        Hockey Rules
========================================================== */

import * as Builder from "../builders/predictionBuilder.js";

import {

PredictionTrigger

}

from "../predictionEngine.js";

import {

footballWinnerOptions,

goalOptions,

yesNoOptions

}

from "../helpers/predictionHelpers.js";

export const hockeyRules=[];

/* ==========================================================
        Match Winner
========================================================== */

hockeyRules.push({

id:"MATCH_WINNER",

priority:100,

condition(match){

return match.status==="UPCOMING";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.MATCH_WINNER,

sport:"hockey",

matchId:match.id,

difficulty:"easy",

type:"MATCH_WINNER",

question:"Who will win the match?",

options:footballWinnerOptions(match)

});

}

});

/* ==========================================================
        First Goal
========================================================== */

hockeyRules.push({

id:"FIRST_GOAL",

priority:95,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.FIRST_GOAL_HOCKEY,

sport:"hockey",

matchId:match.id,

difficulty:"medium",

type:"FIRST_GOAL",

question:"Who will score the first goal?",

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
        Total Goals
========================================================== */

hockeyRules.push({

id:"TOTAL_GOALS",

priority:90,

condition(match){

return true;

},

build(match){

return Builder.create({

trigger:PredictionTrigger.TOTAL_GOALS_HOCKEY,

sport:"hockey",

matchId:match.id,

difficulty:"medium",

type:"TOTAL_GOALS",

question:"How many goals will be scored?",

options:goalOptions()

});

}

});

/* ==========================================================
        Next Goal
========================================================== */

hockeyRules.push({

id:"NEXT_GOAL",

priority:80,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.NEXT_GOAL_HOCKEY,

sport:"hockey",

matchId:match.id,

difficulty:"hard",

type:"NEXT_GOAL",

question:"Who will score the next goal?",

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
        Half Time
========================================================== */

hockeyRules.push({

id:"HALF_TIME",

priority:85,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.HALF_TIME_HOCKEY,

sport:"hockey",

matchId:match.id,

difficulty:"medium",

type:"HALF_TIME",

question:"Who will lead at Half Time?",

options:footballWinnerOptions(match)

});

}

});

/* ==========================================================
        Full Time
========================================================== */

hockeyRules.push({

id:"FULL_TIME",

priority:75,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.FULL_TIME_HOCKEY,

sport:"hockey",

matchId:match.id,

difficulty:"medium",

type:"FULL_TIME",

question:"Who will win the match?",

options:footballWinnerOptions(match)

});

}

});

/* ==========================================================
        Penalty Corner
========================================================== */

hockeyRules.push({

id:"PENALTY_CORNER",

priority:70,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.PENALTY_CORNER,

sport:"hockey",

matchId:match.id,

difficulty:"hard",

type:"PENALTY_CORNER",

question:"Will there be a penalty corner in the next 5 minutes?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Penalty Stroke
========================================================== */

hockeyRules.push({

id:"PENALTY_STROKE",

priority:65,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.PENALTY_STROKE,

sport:"hockey",

matchId:match.id,

difficulty:"expert",

type:"PENALTY_STROKE",

question:"Will a penalty stroke be awarded?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Clean Sheet
========================================================== */

hockeyRules.push({

id:"CLEAN_SHEET",

priority:60,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.CLEAN_SHEET_HOCKEY,

sport:"hockey",

matchId:match.id,

difficulty:"hard",

type:"CLEAN_SHEET",

question:"Will any team keep a clean sheet?",

options:yesNoOptions()

});

}

});