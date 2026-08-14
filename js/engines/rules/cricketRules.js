import * as Builder from "../builders/predictionBuilder.js";
import {
    cricketFormat,
    formatConfig,
    isNormalOverSlot,
    selectedOverCheckpoint,
    shouldUseEventPrediction,
    eventType,
    expiry,
    players,
    nextOverRunsOptions
} from "../helpers/predictionHelpers.js";

export const cricketRules = [];

/* ==========================================================
   PRE-MATCH
   Only cricket. The engine intentionally creates only a small
   number of active questions at once.
========================================================== */

cricketRules.push({
    id: "MATCH_WINNER",
    priority: 100,
    condition(match){
        return String(match.status || "").toUpperCase() === "UPCOMING";
    },
    build(match, helpers){
        return Builder.matchWinner(
            match,
            helpers.expiry(match, "MATCH_WINNER")
        );
    }
});

cricketRules.push({
    id: "TOSS",
    priority: 95,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "UPCOMING" &&
            !match.tossWinner &&
            !match.tossWinnerId &&
            !match.toss?.winner
        );
    },
    build(match, helpers){
        return Builder.tossWinner(
            match,
            helpers.expiry(match, "TOSS_WINNER")
        );
    }
});

cricketRules.push({
    id: "HIGHEST_SCORER",
    priority: 40,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "UPCOMING" &&
            players(match).length >= 2
        );
    },
    build(match, helpers){
        return Builder.highestScorer(
            match,
            players(match),
            helpers.expiry(match, "HIGHEST_SCORER")
        );
    }
});

cricketRules.push({
    id: "TOTAL_RUNS",
    priority: 35,
    condition(match){
        return String(match.status || "").toUpperCase() === "UPCOMING";
    },
    build(match, helpers){
        return Builder.totalRuns(
            match,
            helpers.totalRunsOptions(match),
            helpers.expiry(match, "TOTAL_SCORE")
        );
    }
});

/* ==========================================================
   NORMAL LIVE OVER PREDICTION
   Selected checkpoints only. Never every over.
========================================================== */

cricketRules.push({
    id: "NEXT_OVER_RUNS",
    priority: 90,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            isNormalOverSlot(match)
        );
    },
    build(match){
        const format = cricketFormat(match);

        const difficulty =
            format === "T10" ? "easy" :
            format === "TEST" ? "hard" :
            "medium";

        const checkpoint = selectedOverCheckpoint(match);

        return Builder.nextOverRuns(
            match,
            nextOverRunsOptions(match),
            expiry(match, "NEXT_OVER_RUNS", difficulty),
            difficulty,
            checkpoint
        );
    }
});

/* ==========================================================
   POWERPLAY
========================================================== */

cricketRules.push({
    id: "POWERPLAY",
    priority: 85,
    condition(match){
        const cfg = formatConfig(match);
        const over = Math.floor(
            Number(
                match.currentOver ??
                match.over ??
                match.currentInnings?.over ??
                0
            )
        );

        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            cfg.powerplayEnd != null &&
            Number.isFinite(over) &&
            over === cfg.powerplayEnd
        );
    },
    build(match, helpers){
        return Builder.powerplay(
            match,
            helpers.powerplayOptions(match),
            helpers.expiry(match, "POWERPLAY_SCORE", "medium")
        );
    }
});

/* ==========================================================
   OCCASIONAL EVENT: WICKET
   Only a real provider event can open this.
========================================================== */

cricketRules.push({
    id: "EVENT_WICKET",
    priority: 72,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            eventType(match) === "WICKET" &&
            shouldUseEventPrediction(match, "WICKET")
        );
    },
    build(match){
        return Builder.wicketYesNo(
            match,
            expiry(match, "WICKET", "medium"),
            "medium"
        );
    }
});

/* ==========================================================
   OCCASIONAL EVENT: SIX
========================================================== */

cricketRules.push({
    id: "EVENT_SIX",
    priority: 70,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            eventType(match) === "SIX" &&
            shouldUseEventPrediction(match, "SIX")
        );
    },
    build(match){
        return Builder.nextSix(
            match,
            expiry(match, "NEXT_SIX", "easy"),
            "easy"
        );
    }
});

/* ==========================================================
   OCCASIONAL EVENT: FOUR / BOUNDARY
========================================================== */

cricketRules.push({
    id: "EVENT_BOUNDARY",
    priority: 68,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            ["FOUR", "BOUNDARY"].includes(eventType(match)) &&
            shouldUseEventPrediction(match, "BOUNDARY")
        );
    },
    build(match){
        return Builder.nextBoundary(
            match,
            expiry(match, "NEXT_BOUNDARY", "easy")
        );
    }
});

/* ==========================================================
   PLAYER MILESTONES
   Only when the real current batter is close to the milestone.
========================================================== */

cricketRules.push({
    id: "PLAYER_FIFTY",
    priority: 76,
    condition(match){
        const runs = Number(match.currentBatter?.runs);
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            Number.isFinite(runs) &&
            runs >= 45 &&
            runs < 50
        );
    },
    build(match, helpers){
        return Builder.playerFifty(
            match,
            match.currentBatter,
            helpers.expiry(match, "PLAYER_FIFTY", "hard")
        );
    }
});

cricketRules.push({
    id: "PLAYER_CENTURY",
    priority: 78,
    condition(match){
        const runs = Number(match.currentBatter?.runs);
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            Number.isFinite(runs) &&
            runs >= 90 &&
            runs < 100
        );
    },
    build(match, helpers){
        return Builder.playerCentury(
            match,
            match.currentBatter,
            helpers.expiry(match, "PLAYER_CENTURY", "hard")
        );
    }
});

/* ==========================================================
   DEATH OVER
   Only formats that actually have death overs.
========================================================== */

cricketRules.push({
    id: "DEATH_OVER",
    priority: 80,
    condition(match){
        const cfg = formatConfig(match);
        const over = Math.floor(
            Number(
                match.currentOver ??
                match.over ??
                match.currentInnings?.over ??
                0
            )
        );

        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            cfg.deathStart != null &&
            Number.isFinite(over) &&
            over === cfg.deathStart
        );
    },
    build(match, helpers){
        return Builder.deathOvers(
            match,
            helpers.deathOverOptions(match),
            helpers.expiry(match, "DEATH_OVER", "hard")
        );
    }
});

/* ==========================================================
   CHASE
   One meaningful late-chase question, not one every over.
========================================================== */

cricketRules.push({
    id: "CHASE",
    priority: 84,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            match.target != null &&
            match.runsNeeded != null &&
            match.ballsRemaining != null &&
            Number(match.runsNeeded) > 0 &&
            Number(match.runsNeeded) <= 40 &&
            Number(match.ballsRemaining) <= 30
        );
    },
    build(match, helpers){
        return Builder.chase(
            match,
            helpers.expiry(match, "CHASE", "hard")
        );
    }
});

export default cricketRules;
