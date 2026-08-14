/* ==========================================================
        FanConnact Prediction Engine
========================================================== */

import * as predictionService from "../services/predictionService.js";


import * as Helpers from "./helpers/predictionHelpers.js";

import {
    cricketRules
} from "./rules/cricketRules.js";


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
    NEXT_OVER_RUNS: "NEXT_OVER_RUNS",

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

FIRST_INNING: "FIRST_INNING",

HOME_RUN: "HOME_RUN",

NEXT_RUN: "NEXT_RUN",

NEXT_STRIKEOUT: "NEXT_STRIKEOUT",

TOTAL_RUNS_BASEBALL: "TOTAL_RUNS_BASEBALL",

FIRST_TO_5: "FIRST_TO_5",

EXTRA_INNINGS: "EXTRA_INNINGS",

FULL_TIME_BASEBALL: "FULL_TIME_BASEBALL",

STOLEN_BASE: "STOLEN_BASE",

GRAND_SLAM: "GRAND_SLAM",

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
    // Safety floor between separate generation cycles for one match.
    MIN_INTERVAL_SECONDS: 45,

    // Never stack many live questions. Pre-match may show two at once.
    MAX_ACTIVE_LIVE_PREDICTIONS: 1,
    MAX_ACTIVE_PREMATCH_PREDICTIONS: 2,

    // At most two pre-match questions can be created in one engine pass.
    // Live/event generation is deliberately one at a time.
    MAX_GENERATIONS_PREMATCH_PER_RUN: 2,
    MAX_GENERATIONS_LIVE_PER_RUN: 1,

    MAX_PREMATCH: 2,
    MAX_LIVE: 1,
    MAX_POSTMATCH: 1
};

/* ==========================================================
        Cricket Format / Match Limits
========================================================== */

function normalizeCricketFormat(match){
    const raw = String(
        match?.matchType ??
        match?.matchFormat ??
        match?.format ??
        match?.matchInfo?.matchType ??
        ""
    ).toLowerCase();

    if(/\btest\b/.test(raw)) return "TEST";
    if(/\bt10(?:i)?\b|ten10|ten-10|10\s*over/.test(raw)) return "T10";
    if(/\bt20(?:i)?\b|twenty20|twenty-20|20\s*over/.test(raw)) return "T20";
    if(/\bodi\b|one day|50\s*over/.test(raw)) return "ODI";

    return "T20";
}

function getMatchPredictionLimit(match){
    switch(normalizeCricketFormat(match)){
        case "T10": return 4;
        case "T20": return 5;
        case "ODI": return 5;
        case "TEST": return 5;
        default: return 5;
    }
}

function maxActiveForMatch(match){
    return String(match?.status || "").toUpperCase() === "UPCOMING"
        ? ENGINE_CONFIG.MAX_ACTIVE_PREMATCH_PREDICTIONS
        : ENGINE_CONFIG.MAX_ACTIVE_LIVE_PREDICTIONS;
}

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

    // Active prediction count is tracked per match so one match cannot block
    // another match's prediction generation.
    activePredictions: new Map(),

    // Trigger keys are match/event scoped, never global.
    generatedTriggers: new Set(),

    cooldowns: new Map(),

    generatedCounts: new Map(),

    lastGeneratedAt: new Map()

};

/* ==========================================================
        Match Cooldown
========================================================== */

function canGeneratePrediction(matchId, ignoreCooldown = false) {
    if(ignoreCooldown) return true;

    const last = engineState.cooldowns.get(String(matchId));

    if(!last) return true;

    return (
        Date.now() - last >=
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

function getActiveCount(matchId){
    return engineState.activePredictions.get(String(matchId)) || 0;
}

function incrementActive(matchId){
    const key = String(matchId);
    engineState.activePredictions.set(key, getActiveCount(key) + 1);
}

export function predictionClosed(matchId){
    const key = String(matchId || "");
    const next = Math.max(0, getActiveCount(key) - 1);

    if(next === 0){
        engineState.activePredictions.delete(key);
    }else{
        engineState.activePredictions.set(key, next);
    }
}

function hasTrigger(triggerKey){
    return engineState.generatedTriggers.has(String(triggerKey));
}

function saveTrigger(triggerKey){
    engineState.generatedTriggers.add(String(triggerKey));
}

function buildTriggerKey(match, ruleId, prediction){
    const eventId =
        match?.lastEvent?.id ??
        match?.lastEvent?.eventId ??
        match?.lastEvent?.timestamp ??
        match?.lastEvent?.ballId ??
        "";

    const over =
        match?.currentOver ??
        match?.over ??
        match?.currentInnings?.over ??
        "";

    const batter =
        match?.currentBatter?.id ??
        match?.currentBatter?.playerId ??
        "";

    const base = prediction?.trigger || ruleId || "UNKNOWN";
    const type = String(prediction?.type || "");

    // One meaningful chase/milestone should not repeat every 30 seconds.
    if(type === "CHASE"){
        return `${match.id}:${base}`;
    }

    // Pre-match questions are inherently match-scoped.
    if([
        "MATCH_WINNER",
        "TOSS_WINNER",
        "TOTAL_RUNS",
        "HIGHEST_SCORER"
    ].includes(type)){
        return `${match.id}:${base}`;
    }

    return [
        match.id,
        base,
        over,
        eventId,
        batter
    ].join(":");
}

/* ==========================================================
        Create Prediction
========================================================== */

async function generatePrediction(data, options = {}){
    if(!data?.matchId) return false;

    const matchId = String(data.matchId);
    const formatLimit = Number(data.matchPredictionLimit) || 5;

    if(!canGeneratePrediction(matchId, options.ignoreCooldown === true)){
        return false;
    }

    const triggerKey = data.triggerKey ||
        `${matchId}:${data.trigger}`;

    if(hasTrigger(triggerKey)) return false;

    /*
     * DATABASE-AWARE DUPLICATE + MATCH LIMIT PROTECTION
     * This survives reloads and prevents duplicate generation from two tabs.
     */
    let existing = [];

    try{
        existing = await predictionService.getPredictionsByMatch(matchId);
    }catch(error){
        console.warn("Prediction count lookup failed:", error);
        return false;
    }

    const sameTrigger = existing.some(item =>
        String(item.triggerKey || "") === String(triggerKey)
    );

    if(sameTrigger) return false;

    const generatedTotal = existing.filter(item =>
        String(item.sport || "").toLowerCase() === "cricket"
    ).length;

    if(generatedTotal >= formatLimit) return false;

    const activeCount = existing.filter(item => {
        if(String(item.status || "").toUpperCase() !== "LIVE") return false;

        const expiresAt = item.expiresAt?.toMillis
            ? item.expiresAt.toMillis()
            : (item.expiresAt ? new Date(item.expiresAt).getTime() : null);

        return expiresAt == null || expiresAt > Date.now();
    }).length;

    const maxActive =
        Number.isFinite(Number(options.maxActive))
            ? Number(options.maxActive)
            : maxActiveForMatch(data);

    if(activeCount >= maxActive) return false;

    const result = await predictionService.createPrediction({
        ...data,
        sport: "cricket",
        format:
            data.format ||
            data.matchFormat ||
            data.matchType ||
            "T20",
        triggerKey,
        matchPredictionLimit: formatLimit
    });

    if(!result?.success) return false;

    updateCooldown(matchId);
    saveTrigger(triggerKey);
    incrementActive(matchId);

    engineState.generatedCounts.set(
        matchId,
        generatedTotal + 1
    );

    engineState.lastGeneratedAt.set(
        matchId,
        Date.now()
    );

    return true;
}

export function clearMatchState(matchId){
    const key = String(matchId || "");
    engineState.activePredictions.delete(key);
    engineState.cooldowns.delete(key);
    engineState.generatedCounts.delete(key);
    engineState.lastGeneratedAt.delete(key);

    for(const trigger of engineState.generatedTriggers){
        if(trigger.startsWith(key + ":")){
            engineState.generatedTriggers.delete(trigger);
        }
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

async function processPredictionQueue(match){
    if(pendingPredictions.length === 0) return;

    pendingPredictions.sort((a,b) => b.priority - a.priority);

    const isPrematch =
        String(match?.status || "").toUpperCase() === "UPCOMING";

    const maxActive =
        isPrematch
            ? ENGINE_CONFIG.MAX_ACTIVE_PREMATCH_PREDICTIONS
            : ENGINE_CONFIG.MAX_ACTIVE_LIVE_PREDICTIONS;

    const maxThisRun =
        isPrematch
            ? ENGINE_CONFIG.MAX_GENERATIONS_PREMATCH_PER_RUN
            : ENGINE_CONFIG.MAX_GENERATIONS_LIVE_PER_RUN;

    let created = 0;

    while(pendingPredictions.length > 0 && created < maxThisRun){
        const prediction = pendingPredictions.shift();

        if(!prediction?.data?.matchId) continue;

        /*
         * Active count is checked against Firestore inside generatePrediction().
         * Do not use the old in-memory counter here; it is not decremented by
         * the lifecycle worker and would permanently block later questions
         * after the first prediction expired.
         */
        /*
         * The second pre-match question in the SAME engine pass is allowed
         * without waiting 45 seconds. Separate lifecycle passes still respect
         * the 45-second generation floor.
         */
        const createdNow = await generatePrediction(
            prediction.data,
            {
                ignoreCooldown: isPrematch && created > 0,
                maxActive
            }
        );

        if(createdNow){
            created++;
        }
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

            prediction.triggerKey = buildTriggerKey(
                match,
                rule.id,
                prediction
            );

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

    await processPredictionQueue(match);

}


/* ==========================================================
        Prediction Engine
========================================================== */

export async function generatePredictions(match) {

    try {

        if (!match) {

            return;

        }

        // Prediction generation is intentionally cricket-only for now.
        // Other sports remain UI-ready for future work but their prediction
        // engines are not loaded or executed.
        if (String(match.sport || "").toLowerCase() !== "cricket") {
            return;
        }

        await generateCricketPredictions(match);

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
    if(!match) return;

    const sport = String(match.sport || "").toLowerCase();
    if(sport !== "cricket") return;

    const format = normalizeCricketFormat(match);
    const limit = getMatchPredictionLimit(match);

    let existing = [];
    try{
        existing = await predictionService.getPredictionsByMatch(
            String(match.id)
        );
    }catch(error){
        console.warn("Cricket prediction lookup failed:", error);
        return;
    }

    const totalGenerated = existing.filter(item =>
        String(item.sport || "").toLowerCase() === "cricket"
    ).length;

    if(totalGenerated >= limit) return;

    const active = existing.filter(item => {
        if(String(item.status || "").toUpperCase() !== "LIVE") return false;

        const expiresAt = item.expiresAt?.toMillis
            ? item.expiresAt.toMillis()
            : (item.expiresAt ? new Date(item.expiresAt).getTime() : null);

        return expiresAt == null || expiresAt > Date.now();
    }).length;

    if(active >= maxActiveForMatch(match)) return;

    await executeRules(
        cricketRules,
        {
            ...match,
            id: String(match.id),
            sport: "cricket",
            matchType: format,
            matchPredictionLimit: limit
        }
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
