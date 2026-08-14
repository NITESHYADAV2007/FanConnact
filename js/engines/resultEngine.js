/* ==========================================================
        FanConnact Result Engine
========================================================== */

import * as predictionService from "../services/predictionService.js";
import { processRewards } from "./rewardEngine.js";

/* ==========================================================
        Process Match Results
========================================================== */

export async function processMatchResults(match, uid = null){

    if(!match) return;

    try{
        const predictions = await predictionService.getPredictionsByMatch(match.id);

        for(const prediction of predictions){
            await processPredictionResult(prediction, match, uid);
        }
    }
    catch(error){
        console.error("Result Engine Error:", error);
    }
}

/* ==========================================================
        Process Single Prediction
        Exported so lifecycle can resolve expired live questions
        from the latest match snapshot instead of blindly locking them.
========================================================== */

export async function processPredictionResult(prediction, match, uid = null){

    if(!prediction || !match) return false;

    if(prediction.status === "CANCELLED") return false;

    const correctOption = getCorrectOption(prediction, match);

    if(correctOption == null){
        return false;
    }

    const published = await predictionService.publishResult(
        prediction.id,
        correctOption
    );

    if(!published){
        return false;
    }

    prediction.correctOption = correctOption;
    prediction.status = "COMPLETED";

    await processRewards(prediction, uid);
    return true;
}

/* ==========================================================
        Normalizers / Resolvers
========================================================== */

function normalizeText(value){
    return String(value ?? "").trim().toLowerCase();
}

function objectIdOrName(value){
    if(value == null) return null;
    if(typeof value === "object"){
        return value.id ?? value.playerId ?? value.teamId ?? value.name ?? value.displayName ?? null;
    }
    return value;
}

function matchesOption(value, option){
    if(value == null || !option) return false;

    const actual = objectIdOrName(value);
    const actualText = normalizeText(actual);
    const optionId = normalizeText(option.id);
    const optionText = normalizeText(option.text ?? option.label ?? option.name);

    return (
        actualText === optionId ||
        actualText === optionText
    );
}

function resolveOptionByValue(prediction, value){
    if(value == null || !Array.isArray(prediction.options)) return null;

    const option = prediction.options.find(o => matchesOption(value, o));
    return option ? option.id : null;
}

function booleanOption(prediction, value){
    if(value == null) return null;

    const yes = value === true ||
        normalizeText(value) === "yes" ||
        normalizeText(value) === "true" ||
        normalizeText(value) === "1";

    const no = value === false ||
        normalizeText(value) === "no" ||
        normalizeText(value) === "false" ||
        normalizeText(value) === "0";

    if(yes){
        return resolveOptionByValue(prediction, "yes") ?? "yes";
    }

    if(no){
        return resolveOptionByValue(prediction, "no") ?? "no";
    }

    return null;
}

function numericValue(value){
    if(typeof value === "number" && Number.isFinite(value)) return value;
    const n = Number(String(value ?? "").replace(/,/g, "").match(/-?\d+(?:\.\d+)?/)?.[0]);
    return Number.isFinite(n) ? n : null;
}

function rangeContains(label, value){
    const text = normalizeText(label).replace(/,/g, "");
    const n = numericValue(value);
    if(n == null) return false;

    const plus = text.match(/^(\d+(?:\.\d+)?)\s*\+$/);
    if(plus) return n >= Number(plus[1]);

    const range = text.match(/^(\d+(?:\.\d+)?)\s*[-–]\s*(\d+(?:\.\d+)?)$/);
    if(range){
        const min = Number(range[1]);
        const max = Number(range[2]);
        return n >= min && n <= max;
    }

    return false;
}

function resolveRangeOption(prediction, actualValue){
    if(actualValue == null || !Array.isArray(prediction.options)) return null;

    const direct = resolveOptionByValue(prediction, actualValue);
    if(direct) return direct;

    const option = prediction.options.find(o =>
        rangeContains(o.text ?? o.label ?? o.name, actualValue)
    );

    return option?.id ?? null;
}

function resolveTeamOrPlayerOption(prediction, value){
    return resolveOptionByValue(prediction, value);
}

/* ==========================================================
        Correct Option Resolver
========================================================== */

function getCorrectOption(prediction, match){

    const type = prediction.type;

    /* ==========================
            CRICKET
    ========================== */

    switch(type){

        case "MATCH_WINNER": {
            const value = match.winner ?? match.winnerId ?? match.result?.winner;
            return resolveTeamOrPlayerOption(prediction, value) ??
                (value != null ? String(value) : null);
        }

        case "TOSS_WINNER": {
            const value = match.tossWinner ?? match.tossWinnerId ?? match.toss?.winner;
            return resolveTeamOrPlayerOption(prediction, value) ??
                (value != null ? String(value) : null);
        }

        case "HIGHEST_SCORER": {
            const value = match.highestScorerId ?? match.highestScorer?.id ??
                match.highestScorer?.playerId ?? match.highestScorer?.name;
            return resolveTeamOrPlayerOption(prediction, value) ??
                (value != null ? String(value) : null);
        }

        case "TOTAL_RUNS": {
            const actual = match.totalRuns ?? match.totalScore ??
                match.firstInningsRuns ?? match.innings?.[0]?.runs;
            return resolveRangeOption(prediction, actual) ??
                resolveOptionByValue(prediction, match.totalRunsRange);
        }

        case "POWERPLAY_SCORE": {
            const actual = match.powerplayScore ?? match.powerplayRuns ??
                match.currentPowerplayRuns ?? match.powerplay?.runs;
            return resolveRangeOption(prediction, actual) ??
                resolveOptionByValue(prediction, match.powerplayRange);
        }

        case "NEXT_OVER_RUNS": {
            const actual =
                match.nextOverRuns ??
                match.lastOverRuns ??
                match.previousOverRuns ??
                match.completedOverRuns ??
                match.overRuns ??
                match.currentOverRuns ??
                match.overHistory?.find?.(row =>
                    Number(row?.over ?? row?.overNumber) ===
                    Number(prediction?.checkpointOver)
                )?.runs ??
                null;

            return resolveRangeOption(prediction, actual) ??
                resolveOptionByValue(prediction, match.nextOverRunsRange);
        }

        case "WICKET": {
            const explicit =
                match.wicketInNextOver ??
                match.nextWicket ??
                match.lastOverHadWicket ??
                match.wicketInOver ??
                null;

            if(explicit != null){
                if(typeof explicit === "object"){
                    return booleanOption(
                        prediction,
                        explicit.yes ??
                        explicit.occurred ??
                        explicit.happened ??
                        explicit.value
                    );
                }

                return booleanOption(prediction, explicit);
            }

            const eventType = normalizeText(match.lastEvent?.type);
            if(eventType === "wicket"){
                return booleanOption(prediction, true);
            }

            return null;
        }

        case "NEXT_SIX": {
            const explicit =
                match.nextSix ??
                match.sixInNextOver ??
                match.lastOverHadSix ??
                match.sixInOver ??
                null;

            if(explicit != null){
                return booleanOption(prediction, explicit);
            }

            const eventType = normalizeText(match.lastEvent?.type);
            if(eventType === "six"){
                return booleanOption(prediction, true);
            }

            return null;
        }

        case "NEXT_WICKET": {
            const value = match.nextWicketBowlerId ??
                match.nextWicket?.bowlerId ??
                match.nextWicket?.bowler?.id ??
                match.nextWicket?.bowler?.name;
            return resolveTeamOrPlayerOption(prediction, value) ??
                (value != null ? String(value) : null);
        }

        case "NEXT_BOUNDARY": {
            const explicit = match.nextBoundaryResult ?? match.nextBoundary ?? match.lastEvent?.isBoundary;
            if(explicit != null) return booleanOption(prediction, explicit);

            const eventType = normalizeText(match.lastEvent?.type);
            if(["four", "six", "boundary"].includes(eventType)){
                return booleanOption(prediction, true);
            }
            if(eventType && ["single", "double", "triple", "run", "dot", "wicket", "wide", "no_ball"].includes(eventType)){
                return booleanOption(prediction, false);
            }
            return null;
        }

        case "PLAYER_FIFTY": {
            const explicit = match.playerReached50 ?? match.currentBatter?.reached50;
            if(explicit != null) return booleanOption(prediction, explicit);
            const runs = numericValue(match.currentBatter?.runs);
            return runs != null ? booleanOption(prediction, runs >= 50) : null;
        }

        case "PLAYER_CENTURY": {
            const explicit = match.playerReached100 ?? match.currentBatter?.reached100;
            if(explicit != null) return booleanOption(prediction, explicit);
            const runs = numericValue(match.currentBatter?.runs);
            return runs != null ? booleanOption(prediction, runs >= 100) : null;
        }

        case "DEATH_OVER": {
            const actual = match.deathOverRuns ?? match.deathOverRange ?? match.currentOverRuns;
            return resolveRangeOption(prediction, actual) ??
                resolveOptionByValue(prediction, match.deathOverRange);
        }

        case "CHASE":
            return booleanOption(
                prediction,
                match.chaseSuccessful ?? match.chaseResult
            );
    }

    /* ==========================
            OTHER SPORTS
            Existing generic fields retained.
    ========================== */

    switch(type){
        case "FIRST_GOAL":
        case "FIRST_GOAL_HOCKEY":
            return resolveOptionByValue(prediction, match.firstGoalTeam);
        case "NEXT_GOAL":
        case "NEXT_GOAL_HOCKEY":
            return resolveOptionByValue(prediction, match.nextGoalTeam);
        case "TOTAL_GOALS":
        case "TOTAL_GOALS_HOCKEY":
            return resolveRangeOption(prediction, match.totalGoals) ??
                resolveOptionByValue(prediction, match.totalGoalsRange);
        case "HALF_TIME":
        case "HALF_TIME_HOCKEY":
            return resolveOptionByValue(prediction, match.halfTimeWinner);
        case "FULL_TIME":
        case "FULL_TIME_HOCKEY":
        case "FULL_TIME_KABADDI":
        case "FULL_TIME_BASEBALL":
            return resolveOptionByValue(prediction, match.winner);
        case "BOTH_TEAMS_SCORE":
            return booleanOption(prediction, Number(match.homeScore) > 0 && Number(match.awayScore) > 0);
        case "CLEAN_SHEET":
        case "CLEAN_SHEET_HOCKEY":
            return booleanOption(prediction, Number(match.homeScore) === 0 || Number(match.awayScore) === 0);
        case "YELLOW_CARD":
            return booleanOption(prediction, match.nextYellowCard);
        case "RED_CARD":
            return booleanOption(prediction, match.nextRedCard);
        case "PENALTY":
            return booleanOption(prediction, match.penaltyAwarded);
        case "FIRST_TO_50": return resolveOptionByValue(prediction, match.firstTo50);
        case "FIRST_TO_100": return resolveOptionByValue(prediction, match.firstTo100);
        case "TOTAL_POINTS": return resolveRangeOption(prediction, match.totalPoints) ?? resolveOptionByValue(prediction, match.totalPointsRange);
        case "NEXT_THREE_POINTER": return booleanOption(prediction, match.nextThreePointer);
        case "NEXT_FREE_THROW": return booleanOption(prediction, match.nextFreeThrow);
        case "NEXT_QUARTER_WINNER": return resolveOptionByValue(prediction, match.quarterWinner);
        case "OVERTIME": return booleanOption(prediction, match.overtime);
        case "FIRST_SET": return resolveOptionByValue(prediction, match.firstSetWinner);
        case "SECOND_SET": return resolveOptionByValue(prediction, match.secondSetWinner);
        case "MATCH_SETS": return resolveOptionByValue(prediction, match.totalSets);
        case "NEXT_GAME": return resolveOptionByValue(prediction, match.nextGameWinner);
        case "NEXT_BREAK": return booleanOption(prediction, match.nextBreak);
        case "NEXT_ACE": return booleanOption(prediction, match.nextAce);
        case "NEXT_DOUBLE_FAULT": return booleanOption(prediction, match.nextDoubleFault);
        case "TIE_BREAK": return booleanOption(prediction, match.tieBreak);
        case "MATCH_POINT": return resolveOptionByValue(prediction, match.matchPointWinner);
        case "COMEBACK": return booleanOption(prediction, match.comeback);
        case "FIRST_RAID": return resolveOptionByValue(prediction, match.firstRaidWinner);
        case "FIRST_TO_20": return resolveOptionByValue(prediction, match.firstTo20);
        case "FIRST_HALF": return resolveOptionByValue(prediction, match.firstHalfWinner);
        case "NEXT_POINT": return resolveOptionByValue(prediction, match.nextPointWinner);
        case "NEXT_SET_WINNER": return resolveOptionByValue(prediction, match.currentSetWinner);
        case "SUPER_RAID": return booleanOption(prediction, match.superRaid);
        case "SUPER_TACKLE": return booleanOption(prediction, match.superTackle);
        case "ALL_OUT": return booleanOption(prediction, match.allOut);
        case "DO_OR_DIE_RAID": return booleanOption(prediction, match.doOrDieRaid);
        case "BONUS_POINT": return booleanOption(prediction, match.bonusPoint);
        case "FIRST_INNING": return resolveOptionByValue(prediction, match.firstInningWinner);
        case "HOME_RUN": return booleanOption(prediction, match.homeRun);
        case "NEXT_RUN": return resolveOptionByValue(prediction, match.nextRunTeam);
        case "NEXT_STRIKEOUT": return booleanOption(prediction, match.nextStrikeout);
        case "FIRST_TO_5": return resolveOptionByValue(prediction, match.firstTo5);
        case "EXTRA_INNINGS": return booleanOption(prediction, match.extraInnings);
        case "STOLEN_BASE": return booleanOption(prediction, match.stolenBase);
        case "GRAND_SLAM": return booleanOption(prediction, match.grandSlam);
        default:
            return null;
    }
}
