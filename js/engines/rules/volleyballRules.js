/* ==========================================================
        Volleyball Rules
========================================================== */

import * as Builder from "../builders/predictionBuilder.js";

import {

PredictionTrigger

}

from "../predictionEngine.js";

import {

yesNoOptions

}

from "../helpers/predictionHelpers.js";

export const volleyballRules=[];

/* ==========================================================
        Match Winner
========================================================== */

volleyballRules.push({

id:"MATCH_WINNER",

priority:100,

condition(match){

return match.status==="UPCOMING";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.MATCH_WINNER,

sport:"volleyball",

matchId:match.id,

difficulty:"easy",

type:"MATCH_WINNER",

question:"Who will win the match?",

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
        First Set
========================================================== */

volleyballRules.push({

id:"FIRST_SET",

priority:95,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.FIRST_SET_VOLLEYBALL,

sport:"volleyball",

matchId:match.id,

difficulty:"easy",

type:"FIRST_SET",

question:"Who will win the first set?",

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
        Second Set
========================================================== */

volleyballRules.push({

id:"SECOND_SET",

priority:90,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.SECOND_SET_VOLLEYBALL,

sport:"volleyball",

matchId:match.id,

difficulty:"medium",

type:"SECOND_SET",

question:"Who will win the second set?",

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
        Total Sets
========================================================== */

volleyballRules.push({

id:"MATCH_SETS",

priority:85,

condition(match){

return true;

},

build(match){

return Builder.create({

trigger:PredictionTrigger.MATCH_SETS_VOLLEYBALL,

sport:"volleyball",

matchId:match.id,

difficulty:"medium",

type:"MATCH_SETS",

question:"How many sets will be played?",

options:[

{

id:"3",

text:"3 Sets"

},

{

id:"4",

text:"4 Sets"

},

{

id:"5",

text:"5 Sets"

}

]

});

}

});

/* ==========================================================
        Next Point
========================================================== */

volleyballRules.push({

id:"NEXT_POINT",

priority:80,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.NEXT_POINT_VOLLEYBALL,

sport:"volleyball",

matchId:match.id,

difficulty:"medium",

type:"NEXT_POINT",

question:"Who will win the next point?",

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
        Next Set Winner
========================================================== */

volleyballRules.push({

id:"NEXT_SET_WINNER",

priority:75,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.NEXT_SET_WINNER,

sport:"volleyball",

matchId:match.id,

difficulty:"hard",

type:"NEXT_SET_WINNER",

question:"Who will win the current set?",

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
        Match Point
========================================================== */

volleyballRules.push({

id:"MATCH_POINT",

priority:70,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.MATCH_POINT_VOLLEYBALL,

sport:"volleyball",

matchId:match.id,

difficulty:"hard",

type:"MATCH_POINT",

question:"Who will score the match point?",

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
        Five Set Match
========================================================== */

volleyballRules.push({

id:"FIVE_SET_MATCH",

priority:65,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.FIVE_SET_MATCH,

sport:"volleyball",

matchId:match.id,

difficulty:"expert",

type:"FIVE_SET_MATCH",

question:"Will the match go to five sets?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Comeback
========================================================== */

volleyballRules.push({

id:"COMEBACK",

priority:60,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.COMEBACK_VOLLEYBALL,

sport:"volleyball",

matchId:match.id,

difficulty:"expert",

type:"COMEBACK",

question:"Will the trailing team make a comeback?",

options:yesNoOptions()

});

}

});