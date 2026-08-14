/* ==========================================================
        FanConnact Prediction Builder
========================================================== */

// Keep the builder independent from predictionEngine.js.
// This avoids the circular import: engine -> cricketRules -> builder -> engine.
const PredictionTrigger = Object.freeze({
    MATCH_WINNER: "MATCH_WINNER",
    TOSS: "TOSS",
    HIGHEST_SCORER: "HIGHEST_SCORER",
    TOTAL_SCORE: "TOTAL_SCORE",
    POWERPLAY_END: "POWERPLAY_END",
    NEXT_OVER_RUNS: "NEXT_OVER_RUNS",
    WICKET: "WICKET",
    NEXT_SIX: "NEXT_SIX",
    NEXT_WICKET: "NEXT_WICKET",
    NEXT_BOUNDARY: "NEXT_BOUNDARY",
    BATSMAN_50: "BATSMAN_50",
    BATSMAN_100: "BATSMAN_100",
    DEATH_OVER: "DEATH_OVER",
    CHASE: "CHASE"
});

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

        difficulty:"hard",

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
        Next Over Runs
========================================================== */

export function nextOverRuns(
    match,
    options,
    expiresAt,
    difficulty = "medium",
    checkpoint = null
){
    return {
        ...build({
            trigger: PredictionTrigger.NEXT_OVER_RUNS,
            match,
            type: "NEXT_OVER_RUNS",
            difficulty,
            question: checkpoint
                ? `How many runs will be scored in over ${checkpoint}?`
                : "How many runs will be scored in the next over?",
            options,
            expiresAt
        }),
        checkpointOver: checkpoint
    };
}

/* ==========================================================
        Wicket Yes / No
========================================================== */

export function wicketYesNo(
    match,
    expiresAt,
    difficulty = "medium"
){
    return build({
        trigger: PredictionTrigger.WICKET,
        match,
        type: "WICKET",
        difficulty,
        question: "Will a wicket fall in the next over?",
        options: [
            { id: "yes", text: "Yes" },
            { id: "no", text: "No" }
        ],
        expiresAt
    });
}

/* ==========================================================
        Six Yes / No
========================================================== */

export function nextSix(
    match,
    expiresAt,
    difficulty = "easy"
){
    return build({
        trigger: PredictionTrigger.NEXT_SIX,
        match,
        type: "NEXT_SIX",
        difficulty,
        question: "Will a six be hit in the next over?",
        options: [
            { id: "yes", text: "Yes" },
            { id: "no", text: "No" }
        ],
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

        difficulty:"hard",

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