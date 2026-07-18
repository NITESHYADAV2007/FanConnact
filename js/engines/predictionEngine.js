/* ==========================================================
        FanConnact Prediction Engine
========================================================== */

import * as predictionService from "../services/predictionService.js";


import * as Helpers from "./helpers/predictionHelpers.js";

import {

    cricketRules

}

    from "./rules/cricketRules.js";

import {

    footballRules

}

    from "./rules/footballRules.js";

import {

    basketballRules

}

    from "./rules/basketballRules.js";

    import {

hockeyRules

}

from "./rules/hockeyRules.js";

import {

tennisRules

}

from "./rules/tennisRules.js";

import {

volleyballRules

}

from "./rules/volleyballRules.js";

import {

kabaddiRules

}

from "./rules/kabaddiRules.js";

import {

baseballRules

}

from "./rules/baseballRules.js";
/* ==========================================================
        Prediction Triggers
========================================================== */

export const PredictionTrigger = {

    /* ==========================
            PRE MATCH
    ========================== */

    PRE_MATCH: "PRE_MATCH",

    TOSS: "TOSS",

    MATCH_WINNER: "MATCH_WINNER",

    HIGHEST_SCORER: "HIGHEST_SCORER",

    TOTAL_SCORE: "TOTAL_SCORE",

    /* ==========================
            LIVE MATCH
    ========================== */

    POWERPLAY_END: "POWERPLAY_END",

    POWERPLAY_SCORE: "POWERPLAY_SCORE",

    WICKET: "WICKET",

    NEXT_WICKET: "NEXT_WICKET",

    NEXT_BOUNDARY: "NEXT_BOUNDARY",

    NEXT_SIX: "NEXT_SIX",

    BATSMAN_50: "BATSMAN_50",

    BATSMAN_100: "BATSMAN_100",

    DEATH_OVER: "DEATH_OVER",

    CHASE: "CHASE",

    LAST_OVER: "LAST_OVER",

    SUPER_OVER: "SUPER_OVER",
    /* ==========================
        FOOTBALL
========================== */

    FIRST_GOAL: "FIRST_GOAL",

    NEXT_GOAL: "NEXT_GOAL",

    TOTAL_GOALS: "TOTAL_GOALS",

    HALF_TIME: "HALF_TIME",

    FULL_TIME: "FULL_TIME",

    BOTH_TEAMS_SCORE: "BOTH_TEAMS_SCORE",

    CLEAN_SHEET: "CLEAN_SHEET",

    CORNER_COUNT: "CORNER_COUNT",

    YELLOW_CARD: "YELLOW_CARD",

    RED_CARD: "RED_CARD",

    PENALTY: "PENALTY",
    /* ==========================
        BASKETBALL
========================== */

NEXT_THREE_POINTER:"NEXT_THREE_POINTER",

NEXT_FREE_THROW:"NEXT_FREE_THROW",

NEXT_FIELD_GOAL:"NEXT_FIELD_GOAL",

NEXT_QUARTER_WINNER:"NEXT_QUARTER_WINNER",

TOTAL_POINTS:"TOTAL_POINTS",

FIRST_TO_50:"FIRST_TO_50",

FIRST_TO_100:"FIRST_TO_100",

OVERTIME:"OVERTIME",


/* ==========================
        HOCKEY
========================== */

FIRST_GOAL_HOCKEY:"FIRST_GOAL_HOCKEY",

NEXT_GOAL_HOCKEY:"NEXT_GOAL_HOCKEY",

TOTAL_GOALS_HOCKEY:"TOTAL_GOALS_HOCKEY",

HALF_TIME_HOCKEY:"HALF_TIME_HOCKEY",

FULL_TIME_HOCKEY:"FULL_TIME_HOCKEY",

PENALTY_CORNER:"PENALTY_CORNER",

PENALTY_STROKE:"PENALTY_STROKE",

CLEAN_SHEET_HOCKEY:"CLEAN_SHEET_HOCKEY",

/* ==========================
        TENNIS
========================== */

FIRST_SET:"FIRST_SET",

SECOND_SET:"SECOND_SET",

MATCH_SETS:"MATCH_SETS",

NEXT_GAME:"NEXT_GAME",

NEXT_BREAK:"NEXT_BREAK",

NEXT_ACE:"NEXT_ACE",

NEXT_DOUBLE_FAULT:"NEXT_DOUBLE_FAULT",

TIE_BREAK:"TIE_BREAK",

MATCH_POINT:"MATCH_POINT",

COMEBACK:"COMEBACK",

/* ==========================
        VOLLEYBALL
========================== */

FIRST_SET_VOLLEYBALL:"FIRST_SET_VOLLEYBALL",

SECOND_SET_VOLLEYBALL:"SECOND_SET_VOLLEYBALL",

MATCH_SETS_VOLLEYBALL:"MATCH_SETS_VOLLEYBALL",

NEXT_POINT_VOLLEYBALL:"NEXT_POINT_VOLLEYBALL",

NEXT_SET_WINNER:"NEXT_SET_WINNER",

MATCH_POINT_VOLLEYBALL:"MATCH_POINT_VOLLEYBALL",

COMEBACK_VOLLEYBALL:"COMEBACK_VOLLEYBALL",

FIVE_SET_MATCH:"FIVE_SET_MATCH",

/* ==========================
        KABADDI
========================== */

FIRST_RAID:"FIRST_RAID",

NEXT_POINT_KABADDI:"NEXT_POINT_KABADDI",

SUPER_RAID:"SUPER_RAID",

SUPER_TACKLE:"SUPER_TACKLE",

ALL_OUT:"ALL_OUT",

FIRST_TO_20:"FIRST_TO_20",

FIRST_HALF:"FIRST_HALF",

FULL_TIME_KABADDI:"FULL_TIME_KABADDI",

DO_OR_DIE_RAID:"DO_OR_DIE_RAID",

BONUS_POINT:"BONUS_POINT",

/* ==========================
        BASEBALL
========================== */

FIRST_INNING,

HOME_RUN,

NEXT_RUN,

NEXT_STRIKEOUT,

TOTAL_RUNS_BASEBALL,

FIRST_TO_5,

EXTRA_INNINGS,

FULL_TIME_BASEBALL,

STOLEN_BASE,

GRAND_SLAM,

    /* ==========================
            POST MATCH
    ========================== */

    MATCH_END: "MATCH_END",

    RESULT_PUBLISHED: "RESULT_PUBLISHED"

};

/* ==========================================================
        Engine Configuration
========================================================== */

const ENGINE_CONFIG = {

    MIN_INTERVAL_SECONDS: 120,

    MAX_ACTIVE_PREDICTIONS: 2,

    MAX_PREMATCH: 4,

    MAX_LIVE: 12,

    MAX_POSTMATCH: 1

};

/* ==========================================================
        Prediction Priority
========================================================== */

const PredictionPriority = {

    MATCH_WINNER: 100,

    CHASE: 95,

    PLAYER_CENTURY: 90,

    PLAYER_FIFTY: 80,

    DEATH_OVER: 75,

    POWERPLAY_SCORE: 70,

    NEXT_WICKET: 60,

    NEXT_BOUNDARY: 50,

    NEXT_SIX: 45,

    TOTAL_SCORE: 40,

    HIGHEST_SCORER: 35,

    FIRST_GOAL: 95,

    TOTAL_GOALS: 90,

    BOTH_TEAMS_SCORE: 85,

    HALF_TIME: 80,

    NEXT_GOAL: 78,

    CLEAN_SHEET: 70,

    FULL_TIME: 65,

    PENALTY: 60,

    RED_CARD: 55,

    YELLOW_CARD: 50,

    CORNER_COUNT: 40,
    FIRST_TO_100:95,

FIRST_TO_50:90,

TOTAL_POINTS:85,

NEXT_QUARTER_WINNER:80,

NEXT_THREE_POINTER:75,

NEXT_FIELD_GOAL:70,

NEXT_FREE_THROW:60,

OVERTIME:50,

FIRST_GOAL_HOCKEY:95,

TOTAL_GOALS_HOCKEY:90,

HALF_TIME_HOCKEY:85,

NEXT_GOAL_HOCKEY:80,

FULL_TIME_HOCKEY:75,

PENALTY_CORNER:70,

PENALTY_STROKE:65,

CLEAN_SHEET_HOCKEY:60,

FIRST_SET:95,

SECOND_SET:90,

MATCH_SETS:85,

NEXT_GAME:80,

NEXT_BREAK:75,

NEXT_ACE:70,

NEXT_DOUBLE_FAULT:65,

TIE_BREAK:60,

MATCH_POINT:55,

COMEBACK:50,

FIRST_SET_VOLLEYBALL:95,

SECOND_SET_VOLLEYBALL:90,

MATCH_SETS_VOLLEYBALL:85,

NEXT_SET_WINNER:80,

NEXT_POINT_VOLLEYBALL:75,

MATCH_POINT_VOLLEYBALL:70,

FIVE_SET_MATCH:65,

COMEBACK_VOLLEYBALL:60,

FIRST_RAID:95,

FIRST_TO_20:90,

FIRST_HALF:85,

NEXT_POINT_KABADDI:80,

SUPER_RAID:75,

SUPER_TACKLE:70,

ALL_OUT:65,

FULL_TIME_KABADDI:60,

DO_OR_DIE_RAID:55,

BONUS_POINT:50,

FIRST_INNING:95,

HOME_RUN:90,

TOTAL_RUNS_BASEBALL:85,

FIRST_TO_5:80,

NEXT_RUN:75,

NEXT_STRIKEOUT:70,

EXTRA_INNINGS:65,

FULL_TIME_BASEBALL:60,

STOLEN_BASE:55,

GRAND_SLAM:50,

};

const engineState = {

    activePredictions: 0,

    generatedTriggers: new Set(),

    cooldowns: new Map()

};

/* ==========================================================
        Match Cooldown
========================================================== */

function canGeneratePrediction(matchId) {

    const last =

        engineState.cooldowns.get(matchId);

    if (!last) {

        return true;

    }

    return (

        Date.now() - last >

        ENGINE_CONFIG.MIN_INTERVAL_SECONDS * 1000

    );

}

/* ==========================================================
        Update Match Cooldown
========================================================== */

function updateCooldown(matchId) {

    engineState.cooldowns.set(

        matchId,

        Date.now()

    );

}
/* ==========================================================
        Duplicate Protection
========================================================== */

function hasTrigger(trigger) {

    return engineState.generatedTriggers.has(trigger);

}

function saveTrigger(trigger) {

    engineState.generatedTriggers.add(trigger);

}
/* ==========================================================
        Create Prediction
========================================================== */

async function generatePrediction(data) {

    if (

        !canGeneratePrediction(

            data.matchId

        )

    ) {

        return;

    }

    if (hasTrigger(data.trigger)) {

        return;

    }

    if (

        engineState.activePredictions >=

        ENGINE_CONFIG.MAX_ACTIVE_PREDICTIONS

    ) {

        return;

    }

    const result =

        await predictionService.createPrediction(data);

    if (result.success) {

        updateCooldown(

            data.matchId

        );

        saveTrigger(data.trigger);

        engineState.activePredictions++;

    }

}

export function predictionClosed() {

    if (engineState.activePredictions > 0) {

        engineState.activePredictions--;

    }

}

/* ==========================================================
        Priority Queue
========================================================== */

let pendingPredictions = [];

/* ==========================================================
        Queue Prediction
========================================================== */

function queuePrediction(

    priority,

    prediction

) {

    if (!prediction) {

        return;

    }

    pendingPredictions.push({

        priority,

        data: prediction

    });

}

/* ==========================================================
        Process Queue
========================================================== */

async function processPredictionQueue() {

    if (

        pendingPredictions.length === 0

    ) {

        return;

    }

    pendingPredictions.sort(

        (a, b) =>

            b.priority - a.priority

    );

    while (

        pendingPredictions.length > 0 &&

        engineState.activePredictions <

        ENGINE_CONFIG.MAX_ACTIVE_PREDICTIONS

    ) {

        const prediction =

            pendingPredictions.shift();

        await generatePrediction(

            prediction.data

        );

    }

    pendingPredictions = [];

}
/* ==========================================================
        Execute Rules
========================================================== */

async function executeRules(

    rules,

    match

) {

    for (const rule of rules) {

        try {

            if (

                !rule.condition(match)

            ) {

                continue;

            }

            const prediction =

                rule.build(

                    match,

                    Helpers

                );

            if (!prediction) {

                continue;

            }

            queuePrediction(

                rule.priority,

                prediction

            );

        }

        catch (error) {

            console.error(

                "Rule Error:",

                rule.id,

                error

            );

        }

    }

    await processPredictionQueue();

}


/* ==========================================================
        Prediction Engine
========================================================== */

export async function generatePredictions(match) {

    try {

        if (!match) {

            return;

        }

        switch (match.sport) {

            case "cricket":

                await generateCricketPredictions(match);

                break;

            case "football":

                await generateFootballPredictions(match);

                break;

            case "tennis":

                await generateTennisPredictions(match);

                break;

            case "basketball":

                await generateBasketballPredictions(match);

                break;

            case "hockey":

                await generateHockeyPredictions(match);

                break;

            case "volleyball":

                await generateVolleyballPredictions(match);

                break;

            case "kabaddi":

                await generateKabaddiPredictions(match);

                break;

                case "baseball":

    await generateBaseballPredictions(match);

    break;

            default:

                console.warn(

                    "Unsupported Sport",

                    match.sport

                );

        }

    }

    catch (error) {

        console.error(

            "Prediction Engine Error",

            error

        );

    }

}

/* ==========================================================
        Cricket
========================================================== */

/* ==========================================================
        Cricket Prediction Engine
========================================================== */

async function generateCricketPredictions(match) {

    if (!match) {

        return;

    }

    await executeRules(

        cricketRules,

        match

    );

}
/* ==========================================================
        Football
========================================================== */
async function generateFootballPredictions(match) {

    if (!match) {

        return;

    }

    await executeRules(

        footballRules,

        match

    );

}
/* ==========================================================
        Tennis
========================================================== */

async function generateTennisPredictions(match) {

}

/* ==========================================================
        Basketball
========================================================== */

async function generateBasketballPredictions(match){

    if(!match){

        return;

    }

    await executeRules(

        basketballRules,

        match

    );

}

/* ==========================================================
        Hockey
========================================================== */

async function generateHockeyPredictions(match){

    if(!match){

        return;

    }

    await executeRules(

        hockeyRules,

        match

    );

}

async function generateTennisPredictions(match){

    if(!match){

        return;

    }

    await executeRules(

        tennisRules,

        match

    );

}

/* ==========================================================
        Volleyball
========================================================== */
async function generateVolleyballPredictions(match){

    if(!match){

        return;

    }

    await executeRules(

        volleyballRules,

        match

    );

}
async function generateKabaddiPredictions(match){

    if(!match){

        return;

    }

    await executeRules(

        kabaddiRules,

        match

    );

}

async function generateBaseballPredictions(match){

    if(!match){

        return;

    }

    await executeRules(

        baseballRules,

        match

    );

}