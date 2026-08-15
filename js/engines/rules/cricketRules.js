import * as Builder from "../builders/predictionBuilder.js";
import {
    cricketFormat,
    formatConfig,
    isNormalOverSlot,
    selectedOverCheckpoint,
    shouldUseEventPrediction,
    eventType,
    eventKey,
    currentOverNumber,
    expiry,
    players,
    nextOverRunsOptions,
    currentBatter,
    bowlers,
    milestoneExpiry
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
    priority: 86,
    condition(match){
        const cfg = formatConfig(match);
        const over = currentOverNumber(match);
        if(String(match.status || "").toUpperCase() !== "LIVE") return false;
        if(cfg.powerplayStart == null || cfg.powerplayEnd == null || over == null) return false;

        // Open the powerplay question DURING the powerplay, not after it has
        // already finished. The result is resolved when the window closes.
        const wholeOver = Math.floor(over);
        return wholeOver >= cfg.powerplayStart && wholeOver < cfg.powerplayEnd;
    },
    build(match, helpers){
        return {
            ...Builder.powerplay(
                match,
                helpers.powerplayOptions(match),
                helpers.expiry(match, "POWERPLAY_SCORE", "medium")
            ),
            powerplayPrediction: true,
            powerplayEndOver: formatConfig(match).powerplayEnd
        };
    }
});

/* ==========================================================
   EVENT -> NEXT BALL
   A real FOUR/SIX/WICKET opens a next-ball event prediction.
   This is completely independent of normal over checkpoints.
   The engine applies event spacing so consecutive event balls do
   not create a prediction every poll/over.
========================================================== */

cricketRules.push({
    id: "EVENT_NEXT_BALL",
    priority: 94,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            Boolean(eventKey(match)) &&
            ["FOUR", "SIX", "WICKET"].includes(eventType(match)) &&
            shouldUseEventPrediction(match, "NEXT_BALL")
        );
    },
    build(match, helpers){
        return Builder.nextBallEvent(
            match,
            helpers.expiry(match, "NEXT_BALL_EVENT", "easy"),
            "easy"
        );
    }
});

/* ==========================================================
   PLAYER MILESTONES
   Works for every cricket format (T10, T20, ODI, The Hundred and Test).
========================================================== */

cricketRules.push({
    id: "PLAYER_FIFTY",
    priority: 76,
    condition(match){
        const batter = currentBatter(match);
        const runs = Number(batter?.runs);
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            Number.isFinite(runs) &&
            runs >= 41 &&
            runs < 50
        );
    },
    build(match, helpers){
        return Builder.playerFifty(
            match,
            currentBatter(match),
            helpers.milestoneExpiry()
        );
    }
});

cricketRules.push({
    id: "PLAYER_CENTURY",
    priority: 78,
    condition(match){
        const batter = currentBatter(match);
        const runs = Number(batter?.runs);
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            Number.isFinite(runs) &&
            runs >= 91 &&
            runs < 100
        );
    },
    build(match, helpers){
        return Builder.playerCentury(
            match,
            currentBatter(match),
            helpers.milestoneExpiry()
        );
    }
});


/* ==========================================================
   LIVE EVENT / CONTINUOUS PREDICTIONS
   All existing cricket prediction types are eligible. The engine
   enforces the format-specific active cap and duplicate protection.
========================================================== */

cricketRules.push({
    id: "NEXT_WICKET",
    priority: 68,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            bowlers(match).length >= 2
        );
    },
    build(match, helpers){
        return Builder.nextWicket(
            match,
            bowlers(match),
            helpers.expiry(match, "NEXT_WICKET", "medium")
        );
    }
});

cricketRules.push({
    id: "NEXT_BOUNDARY",
    priority: 58,
    condition(match){
        return String(match.status || "").toUpperCase() === "LIVE";
    },
    build(match, helpers){
        return Builder.nextBoundary(
            match,
            helpers.expiry(match, "NEXT_BOUNDARY", "easy")
        );
    }
});

cricketRules.push({
    id: "NEXT_SIX",
    priority: 56,
    condition(match){
        return String(match.status || "").toUpperCase() === "LIVE";
    },
    build(match, helpers){
        return Builder.nextSix(
            match,
            helpers.expiry(match, "NEXT_SIX", "easy")
        );
    }
});

cricketRules.push({
    id: "WICKET",
    priority: 54,
    condition(match){
        return (
            String(match.status || "").toUpperCase() === "LIVE" &&
            (
                match.wicketInNextOver != null ||
                match.nextWicket != null ||
                match.wicketInOver != null
            )
        );
    },
    build(match, helpers){
        return Builder.wicketYesNo(
            match,
            helpers.expiry(match, "WICKET", "medium"),
            "medium"
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
