/* ==========================================================
        Kabaddi Rules
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

export const kabaddiRules=[];

/* ==========================================================
        Match Winner
========================================================== */

kabaddiRules.push({

id:"MATCH_WINNER",

priority:100,

condition(match){

return match.status==="UPCOMING";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.MATCH_WINNER,

sport:"kabaddi",

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
        Match Winner
========================================================== */

kabaddiRules.push({

id:"MATCH_WINNER",

priority:100,

condition(match){

return match.status==="UPCOMING";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.MATCH_WINNER,

sport:"kabaddi",

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
        First To 20
========================================================== */

kabaddiRules.push({

id:"FIRST_TO_20",

priority:90,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.FIRST_TO_20,

sport:"kabaddi",

matchId:match.id,

difficulty:"medium",

type:"FIRST_TO_20",

question:"Which team will reach 20 points first?",

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
        First Half Winner
========================================================== */

kabaddiRules.push({

id:"FIRST_HALF",

priority:85,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.FIRST_HALF,

sport:"kabaddi",

matchId:match.id,

difficulty:"medium",

type:"FIRST_HALF",

question:"Who will lead at Half Time?",

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
        Next Point
========================================================== */

kabaddiRules.push({

id:"NEXT_POINT",

priority:80,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.NEXT_POINT_KABADDI,

sport:"kabaddi",

matchId:match.id,

difficulty:"medium",

type:"NEXT_POINT",

question:"Who will score the next point?",

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
        Super Raid
========================================================== */

kabaddiRules.push({

id:"SUPER_RAID",

priority:75,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.SUPER_RAID,

sport:"kabaddi",

matchId:match.id,

difficulty:"hard",

type:"SUPER_RAID",

question:"Will there be a Super Raid?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Super Tackle
========================================================== */

kabaddiRules.push({

id:"SUPER_TACKLE",

priority:70,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.SUPER_TACKLE,

sport:"kabaddi",

matchId:match.id,

difficulty:"hard",

type:"SUPER_TACKLE",

question:"Will there be a Super Tackle?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Super Tackle
========================================================== */

kabaddiRules.push({

id:"SUPER_TACKLE",

priority:70,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.SUPER_TACKLE,

sport:"kabaddi",

matchId:match.id,

difficulty:"hard",

type:"SUPER_TACKLE",

question:"Will there be a Super Tackle?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Do Or Die Raid
========================================================== */

kabaddiRules.push({

id:"DO_OR_DIE_RAID",

priority:60,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.DO_OR_DIE_RAID,

sport:"kabaddi",

matchId:match.id,

difficulty:"expert",

type:"DO_OR_DIE_RAID",

question:"Will the next raid be a Do-or-Die raid?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Bonus Point
========================================================== */

kabaddiRules.push({

id:"BONUS_POINT",

priority:55,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.BONUS_POINT,

sport:"kabaddi",

matchId:match.id,

difficulty:"medium",

type:"BONUS_POINT",

question:"Will the next point be a Bonus Point?",

options:yesNoOptions()

});

}

});

/* ==========================================================
        Bonus Point
========================================================== */

kabaddiRules.push({

id:"BONUS_POINT",

priority:55,

condition(match){

return match.status==="LIVE";

},

build(match){

return Builder.create({

trigger:PredictionTrigger.BONUS_POINT,

sport:"kabaddi",

matchId:match.id,

difficulty:"medium",

type:"BONUS_POINT",

question:"Will the next point be a Bonus Point?",

options:yesNoOptions()

});

}

});