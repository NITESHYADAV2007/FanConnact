/* ==========================================================
        Tennis Rules
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

export const tennisRules=[];

/* ==========================================================
        Match Winner
========================================================== */

tennisRules.push({

id:"MATCH_WINNER",

priority:100,

condition(match){

return match.status==="UPCOMING";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.MATCH_WINNER,

sport:"tennis",

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
        First Set Winner
========================================================== */

tennisRules.push({

id:"FIRST_SET",

priority:95,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.FIRST_SET,

sport:"tennis",

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

text:match.homeTeam.name

}

]

});

}

});

/* ==========================================================
        Second Set Winner
========================================================== */

tennisRules.push({

id:"SECOND_SET",

priority:90,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.SECOND_SET,

sport:"tennis",

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
        Match Sets
========================================================== */

tennisRules.push({

id:"MATCH_SETS",

priority:85,

condition(match){

return true;

},

build(match){

return Builder.create({

trigger:PredictionTrigger.MATCH_SETS,

sport:"tennis",

matchId:match.id,

difficulty:"medium",

type:"MATCH_SETS",

question:"How many sets will be played?",

options:[

{

id:"2",

text:"2 Sets"

},

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
        Match Sets
========================================================== */

tennisRules.push({

id:"MATCH_SETS",

priority:85,

condition(match){

return true;

},

build(match){

return Builder.create({

trigger:PredictionTrigger.MATCH_SETS,

sport:"tennis",

matchId:match.id,

difficulty:"medium",

type:"MATCH_SETS",

question:"How many sets will be played?",

options:[

{

id:"2",

text:"2 Sets"

},

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
        Next Game
========================================================== */

tennisRules.push({

id:"NEXT_GAME",

priority:80,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.NEXT_GAME,

sport:"tennis",

matchId:match.id,

difficulty:"medium",

type:"NEXT_GAME",

question:"Who will win the next game?",

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
        Next Ace
========================================================== */

tennisRules.push({

id:"NEXT_ACE",

priority:70,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.NEXT_ACE,

sport:"tennis",

matchId:match.id,

difficulty:"medium",

type:"NEXT_ACE",

question:"Will the next point be an Ace?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Double Fault
========================================================== */

tennisRules.push({

id:"NEXT_DOUBLE_FAULT",

priority:65,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.NEXT_DOUBLE_FAULT,

sport:"tennis",

matchId:match.id,

difficulty:"hard",

type:"NEXT_DOUBLE_FAULT",

question:"Will the next point be a Double Fault?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Tie Break
========================================================== */

tennisRules.push({

id:"TIE_BREAK",

priority:60,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.TIE_BREAK,

sport:"tennis",

matchId:match.id,

difficulty:"expert",

type:"TIE_BREAK",

question:"Will this set go to a Tie Break?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Comeback
========================================================== */

tennisRules.push({

id:"COMEBACK",

priority:50,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.COMEBACK,

sport:"tennis",

matchId:match.id,

difficulty:"expert",

type:"COMEBACK",

question:"Will the losing player make a comeback?",

options:yesNoOptions()

});

}

});