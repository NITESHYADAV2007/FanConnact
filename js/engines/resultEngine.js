/* ==========================================================
        FanConnact Result Engine
========================================================== */

import * as predictionService from "../services/predictionService.js";

import {

    processRewards

}

    from "./rewardEngine.js";
/* ==========================================================
        Process Match Results
========================================================== */

export async function processMatchResults(match) {

    try {

        if (!match) {

            return;

        }

        const predictions =

            await predictionService.getPredictionsByMatch(

                match.id

            );

        for (

            const prediction

            of predictions

        ) {

            await processPredictionResult(

                prediction,

                match

            );

        }

    }

    catch (error) {

        console.error(

            "Result Engine Error",

            error

        );

    }

}

/* ==========================================================
        Process Single Prediction
========================================================== */

async function processPredictionResult(

    prediction,

    match

) {

    const correctOption =

        getCorrectOption(

            prediction,

            match

        );

    if (

        correctOption == null

    ) {

        return;

    }

    await predictionService.publishResult(

        prediction.id,

        correctOption

    );

    prediction.correctOption =

        correctOption;

    await processRewards(

        prediction

    );
}

/* ==========================================================
        Correct Option Resolver
========================================================== */

function getCorrectOption(

    prediction,

    match

){

    switch(

        prediction.type

    ){

        /* ==========================
                PRE MATCH
        ========================== */

        case "MATCH_WINNER":

            return match.winner;

        case "TOSS_WINNER":

            return match.tossWinner;

        case "HIGHEST_SCORER":

            return match.highestScorerId;

        case "TOTAL_RUNS":

            return match.totalRunsRange;

        /* ==========================
                LIVE MATCH
        ========================== */

        case "POWERPLAY_SCORE":

            return match.powerplayRange;

        case "NEXT_WICKET":

            return match.nextWicketBowlerId;

        case "NEXT_BOUNDARY":

            return match.nextBoundaryResult;

        case "PLAYER_FIFTY":

            return(

                match.playerReached50

                ? "yes"

                : "no"

            );

        case "PLAYER_CENTURY":

            return(

                match.playerReached100

                ? "yes"

                : "no"

            );

        case "DEATH_OVER":

            return match.deathOverRange;

        case "CHASE":

            return(

                match.chaseSuccessful

                ? "yes"

                : "no"

            );
                    /* ==========================
                FOOTBALL
        ========================== */

        case "FIRST_GOAL":

            return match.firstGoalTeam;

        case "NEXT_GOAL":

            return match.nextGoalTeam;

        case "TOTAL_GOALS":

            return match.totalGoalsRange;

        case "HALF_TIME":

            return match.halfTimeWinner;

        case "FULL_TIME":

            return match.winner;

        case "BOTH_TEAMS_SCORE":

            return (

                match.homeScore > 0 &&

                match.awayScore > 0

            )

            ? "yes"

            : "no";

        case "CLEAN_SHEET":

            return (

                match.homeScore === 0 ||

                match.awayScore === 0

            )

            ? "yes"

            : "no";

        case "YELLOW_CARD":

            return (

                match.nextYellowCard

            )

            ? "yes"

            : "no";

        case "RED_CARD":

            return (

                match.nextRedCard

            )

            ? "yes"

            : "no";

        case "PENALTY":

            return (

                match.penaltyAwarded

            )

            ? "yes"

            : "no";

                    /* ==========================
                BASKETBALL
        ========================== */

        case "FIRST_TO_50":

            return match.firstTo50;

        case "FIRST_TO_100":

            return match.firstTo100;

        case "TOTAL_POINTS":

            return match.totalPointsRange;

        case "NEXT_THREE_POINTER":

            return match.nextThreePointer;

        case "NEXT_FREE_THROW":

            return match.nextFreeThrow;

        case "NEXT_QUARTER_WINNER":

            return match.quarterWinner;

        case "OVERTIME":

            return (

                match.overtime

            )

            ? "yes"

            : "no";

            /* ==========================
        HOCKEY
========================== */

case "FIRST_GOAL":

    return match.firstGoalTeam;

case "NEXT_GOAL":

    return match.nextGoalTeam;

case "TOTAL_GOALS":

    return match.totalGoalsRange;

case "HALF_TIME":

    return match.halfTimeWinner;

case "FULL_TIME":

    return match.winner;

case "PENALTY_CORNER":

    return match.penaltyCorner

    ? "yes"

    : "no";

case "PENALTY_STROKE":

    return match.penaltyStroke

    ? "yes"

    : "no";

case "CLEAN_SHEET":

    return(

        match.homeScore===0 ||

        match.awayScore===0

    )

    ? "yes"

    : "no";

    /* ==========================
        TENNIS
========================== */

case "FIRST_SET":

    return match.firstSetWinner;

case "SECOND_SET":

    return match.secondSetWinner;

case "MATCH_SETS":

    return match.totalSets;

case "NEXT_GAME":

    return match.nextGameWinner;

case "NEXT_BREAK":

    return match.nextBreak

    ? "yes"

    : "no";

case "NEXT_ACE":

    return match.nextAce

    ? "yes"

    : "no";

case "NEXT_DOUBLE_FAULT":

    return match.nextDoubleFault

    ? "yes"

    : "no";

case "TIE_BREAK":

    return match.tieBreak

    ? "yes"

    : "no";

case "MATCH_POINT":

    return match.matchPointWinner;

case "COMEBACK":

    return match.comeback

    ? "yes"

    : "no";

    /* ==========================
        VOLLEYBALL
========================== */

case "FIRST_SET":

    return match.firstSetWinner;

case "SECOND_SET":

    return match.secondSetWinner;

case "MATCH_SETS":

    return match.totalSets;

case "NEXT_POINT":

    return match.nextPointWinner;

case "NEXT_SET_WINNER":

    return match.currentSetWinner;

case "MATCH_POINT":

    return match.matchPointWinner;

case "FIVE_SET_MATCH":

    return match.fiveSetMatch

    ? "yes"

    : "no";

case "COMEBACK":

    return match.comeback

    ? "yes"

    : "no";

    /* ==========================
        KABADDI
========================== */

case "FIRST_RAID":

    return match.firstRaidWinner;

case "FIRST_TO_20":

    return match.firstTo20;

case "FIRST_HALF":

    return match.firstHalfWinner;

case "NEXT_POINT":

    return match.nextPointWinner;

case "SUPER_RAID":

    return match.superRaid

    ? "yes"

    : "no";

case "SUPER_TACKLE":

    return match.superTackle

    ? "yes"

    : "no";

case "ALL_OUT":

    return match.allOut

    ? "yes"

    : "no";

case "DO_OR_DIE_RAID":

    return match.doOrDieRaid

    ? "yes"

    : "no";

case "BONUS_POINT":

    return match.bonusPoint

    ? "yes"

    : "no";

case "FULL_TIME":

    return match.winner;

    /* ==========================
        BASEBALL
========================== */

case "FIRST_INNING":

    return match.firstInningWinner;

case "HOME_RUN":

    return match.homeRun

    ? "yes"

    : "no";

case "NEXT_RUN":

    return match.nextRunTeam;

case "NEXT_STRIKEOUT":

    return match.nextStrikeout

    ? "yes"

    : "no";

case "TOTAL_RUNS":

    return match.totalRunsRange;

case "FIRST_TO_5":

    return match.firstTo5;

case "EXTRA_INNINGS":

    return match.extraInnings

    ? "yes"

    : "no";

case "FULL_TIME":

    return match.winner;

case "STOLEN_BASE":

    return match.stolenBase

    ? "yes"

    : "no";

case "GRAND_SLAM":

    return match.grandSlam

    ? "yes"

    : "no";

        default:

            return null;

    }

}