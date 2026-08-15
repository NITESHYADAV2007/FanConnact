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
    NEXT_BALL_EVENT: "NEXT_BALL_EVENT",
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

    expiresAt,

    milestoneTarget = null,

    targetPlayerId = null,

    targetPlayerName = null

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

        expiresAt,

        ...(milestoneTarget != null ? { milestoneTarget } : {}),

        ...(targetPlayerId != null ? { targetPlayerId: String(targetPlayerId) } : {}),

        ...(targetPlayerName ? { targetPlayerName: String(targetPlayerName) } : {})

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

        expiresAt,

        milestoneTarget: 50,

        targetPlayerId: batter.id ?? batter.playerId ?? batter.name,

        targetPlayerName: batter.name

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
        Event -> Next Ball Prediction
        The triggering event is stored so resultEngine can resolve
        against the FIRST provider event after the trigger.
========================================================== */

function sourceEventKey(match){
    return String(
        match?.lastEvent?.id ??
        match?.lastEvent?.eventId ??
        match?.lastEvent?.timestamp ??
        match?.lastEvent?.ballId ??
        match?.lastEvent?.key ??
        ""
    );
}

function sourceEventType(match){
    const event = match?.lastEvent || {};
    const explicit = String(event.type ?? event.eventType ?? event.name ?? "").toUpperCase();
    if(explicit.includes("WICKET")) return "WICKET";
    if(explicit.includes("SIX")) return "SIX";
    if(explicit.includes("FOUR") || explicit.includes("BOUNDARY")) return "FOUR";
    if(event.wicket || event.isWicket || event.dismissal) return "WICKET";
    const runs = Number(event.runs ?? event.totalRuns ?? event.batRuns);
    if(runs === 6) return "SIX";
    if(runs === 4 || event.isBoundary) return "FOUR";
    return "";
}

export function nextBallEvent(
    match,
    expiresAt,
    difficulty = "easy"
){
    return {
        ...build({
            trigger: PredictionTrigger.NEXT_BALL_EVENT,
            match,
            type: "NEXT_BALL_EVENT",
            difficulty,
            question: "What will happen on the next ball?",
            options: [
                { id: "FOUR", text: "Four" },
                { id: "SIX", text: "Six" },
                { id: "WICKET", text: "Wicket" },
                { id: "OTHER", text: "Other" }
            ],
            expiresAt
        }),
        eventPrediction: true,
        sourceEventKey: sourceEventKey(match),
        sourceEventType: sourceEventType(match),
        eventOver: Number(match?.currentOver ?? match?.over ?? match?.currentInnings?.over ?? 0) || 0
    };
}

/* ==========================================================
        Legacy Event Predictions
        Kept for compatibility with older stored predictions.
========================================================== */

export function wicketYesNo(match, expiresAt, difficulty = "medium"){
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

export function nextSix(match, expiresAt, difficulty = "easy"){
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

export function nextBoundary(match, expiresAt){
    return build({
        trigger: PredictionTrigger.NEXT_BOUNDARY,
        match,
        type: "NEXT_BOUNDARY",
        difficulty: "easy",
        question: "Will the next scoring shot be a Boundary?",
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

        expiresAt,

        milestoneTarget: 100,

        targetPlayerId: batter.id ?? batter.playerId ?? batter.name,

        targetPlayerName: batter.name

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