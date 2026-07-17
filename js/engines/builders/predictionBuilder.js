/* ==========================================================
        FanConnact Prediction Builder
========================================================== */

import {

PredictionTrigger

}

from "../predictionEngine.js";

/* ==========================================================
        Helper
========================================================== */

function build({

    trigger,

    match,

    sport,

    type,

    difficulty,

    question,

    options,

    expiresAt

}){
    return{

        trigger,

        matchId:match.id,

       sport:
sport ||

match.sport,

        type,

        difficulty,

        question,

        options,

        expiresAt

    };

}
/* ==========================================================
        Match Winner
========================================================== */

export function matchWinner(

    match,

    expiresAt

){

    return build({

        trigger:

        PredictionTrigger.MATCH_WINNER,

        match,

        type:"MATCH_WINNER",

        difficulty:"easy",

        question:

        "Who will win the match?",

        options:[

            {

                id:"home",

                text:

                match.homeTeam.name

            },

            {

                id:"away",

                text:

                match.awayTeam.name

            }

        ],

        expiresAt

    });

}

/* ==========================================================
        Powerplay
========================================================== */

export function powerplay(

    match,

    options,

    expiresAt

){

    return build({

        trigger:

        PredictionTrigger.POWERPLAY_END,

        match,

        type:"POWERPLAY_SCORE",

        difficulty:"medium",

        question:

        "What will be the Powerplay Score?",

        options,

        expiresAt

    });

}

/* ==========================================================
        Player Fifty
========================================================== */

export function playerFifty(

    match,

    batter,

    expiresAt

){

    return build({

        trigger:

        `${PredictionTrigger.BATSMAN_50}_${batter.id}`,

        match,

        type:"PLAYER_FIFTY",

        difficulty:"expert",

        question:

        `Will ${batter.name} score a Fifty?`,

        options:[

            {

                id:"yes",

                text:"Yes"

            },

            {

                id:"no",

                text:"No"

            }

        ],

        expiresAt

    });

}

/* ==========================================================
        Toss Winner
========================================================== */

export function tossWinner(

    match,

    expiresAt

){

    return build({

        trigger:

        PredictionTrigger.TOSS,

        match,

        type:"TOSS_WINNER",

        difficulty:"easy",

        question:

        "Who will win the Toss?",

        options:[

            {

                id:"home",

                text:match.homeTeam.name

            },

            {

                id:"away",

                text:match.awayTeam.name

            }

        ],

        expiresAt

    });

}

/* ==========================================================
        Highest Scorer
========================================================== */

export function highestScorer(

    match,

    players,

    expiresAt

){

    return build({

        trigger:

        PredictionTrigger.HIGHEST_SCORER,

        match,

        type:"HIGHEST_SCORER",

        difficulty:"medium",

        question:

        "Who will be the Highest Run Scorer?",

        options:players,

        expiresAt

    });

}

/* ==========================================================
        Total Runs
========================================================== */

export function totalRuns(

    match,

    options,

    expiresAt

){

    return build({

        trigger:

        PredictionTrigger.TOTAL_SCORE,

        match,

        type:"TOTAL_RUNS",

        difficulty:"hard",

        question:

        "What will be the Total Score?",

        options,

        expiresAt

    });

}

/* ==========================================================
        Next Wicket
========================================================== */

export function nextWicket(

    match,

    bowlers,

    expiresAt

){

    return build({

        trigger:

        PredictionTrigger.NEXT_WICKET,

        match,

        type:"NEXT_WICKET",

        difficulty:"medium",

        question:

        "Who will take the next wicket?",

        options:bowlers,

        expiresAt

    });

}

/* ==========================================================
        Boundary
========================================================== */

export function nextBoundary(

    match,

    expiresAt

){

    return build({

        trigger:

        PredictionTrigger.NEXT_BOUNDARY,

        match,

        type:"NEXT_BOUNDARY",

        difficulty:"easy",

        question:

        "Will the next scoring shot be a Boundary?",

        options:[

            {

                id:"yes",

                text:"Yes"

            },

            {

                id:"no",

                text:"No"

            }

        ],

        expiresAt

    });

}

/* ==========================================================
        Player Century
========================================================== */

export function playerCentury(

    match,

    batter,

    expiresAt

){

    return build({

        trigger:

        `${PredictionTrigger.BATSMAN_100}_${batter.id}`,

        match,

        type:"PLAYER_CENTURY",

        difficulty:"expert",

        question:

        `Will ${batter.name} score a Century?`,

        options:[

            {

                id:"yes",

                text:"Yes"

            },

            {

                id:"no",

                text:"No"

            }

        ],

        expiresAt

    });

}

/* ==========================================================
        Death Overs
========================================================== */

export function deathOvers(

    match,

    options,

    expiresAt

){

    return build({

        trigger:

        PredictionTrigger.DEATH_OVER,

        match,

        type:"DEATH_OVER",

        difficulty:"hard",

        question:

        "How many runs will be scored in this over?",

        options,

        expiresAt

    });

}

/* ==========================================================
        Chase
========================================================== */

export function chase(

    match,

    expiresAt

){

    return build({

        trigger:

        PredictionTrigger.CHASE,

        match,

        type:"CHASE",

        difficulty:"hard",

        question:

        "Will the batting team successfully chase the target?",

        options:[

            {

                id:"yes",

                text:"Yes"

            },

            {

                id:"no",

                text:"No"

            }

        ],

        expiresAt

    });

}