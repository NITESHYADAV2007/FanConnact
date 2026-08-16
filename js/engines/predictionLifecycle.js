/* ==========================================================
        FanConnact Prediction Lifecycle
        No optional rule-engine dependency on the prediction page.
========================================================== */

import * as predictionService from "../services/predictionService.js";
import { auth } from "../firebase-config.js";
import {
    processMatchResults,
    processPredictionResult
} from "./resultEngine.js";

function toMillis(value){
    if(value == null) return null;
    if(typeof value === "number") return value;
    if(value instanceof Date) return value.getTime();
    if(typeof value.toMillis === "function") return value.toMillis();
    if(typeof value.seconds === "number") return value.seconds * 1000;
    const parsed = new Date(value).getTime();
    return Number.isFinite(parsed) ? parsed : null;
}

function isFinishedMatch(match){
    const status = String(match?.status || "").toUpperCase();
    if(status === "FINISHED" || status === "COMPLETED") return true;

    const rawState = String(match?.state ?? match?.matchState ?? "").trim().toLowerCase();
    const rawStatus = String(match?.statusText ?? match?.status ?? "").trim().toLowerCase();
    const pattern = /finished|completed|complete|match ended|ended|result|abandoned|abandon|cancelled|canceled/;

    return pattern.test(rawState) || pattern.test(rawStatus);
}

// These questions depend on the final match outcome. They must not be
// completed merely because their prediction timer expired during LIVE play.
const POST_MATCH_ONLY_TYPES = new Set([
    "MATCH_WINNER",
    "HIGHEST_SCORER",
    "TOTAL_RUNS"
]);

export async function closeExpiredPredictions(){
    try{
        const predictions = await predictionService.getAllLivePredictions(100);
        const now = Date.now();

        for(const prediction of predictions){
            const expiresAt = toMillis(prediction.expiresAt);
            if(expiresAt == null || expiresAt > now) continue;

            let resolved = false;
            let match = null;
            if(prediction.matchId){
                // Result resolution must use a fresh provider/API snapshot.
                // Do not let the normal match cache keep the old LIVE state.
                match = await predictionService.getMatch(prediction.matchId, true);
                if(match){
                    const type = String(prediction.type || "").toUpperCase();

                    // A final-outcome question stays LIVE until the actual
                    // match finishes. Do not turn an expiry timer into a
                    // fake final result.
                    if(!POST_MATCH_ONLY_TYPES.has(type) || isFinishedMatch(match)){
                        resolved = await processPredictionResult(
                            prediction,
                            match,
                            auth.currentUser?.uid || null
                        );
                    }
                }
            }

            if(!resolved){
                // Keep post-match-only questions alive while the match is
                // still running. Other expired live questions can be closed.
                const type = String(prediction.type || "").toUpperCase();
                if(POST_MATCH_ONLY_TYPES.has(type) && match && !isFinishedMatch(match)){
                    continue;
                }
                await predictionService.closePrediction(prediction.id);
            }
        }
    }catch(error){
        console.error("Lifecycle Error", error);
    }
}

export async function handleMatchFinished(match, uid = null){
    if(!match || !isFinishedMatch(match)) return false;

    // Always obtain the authoritative final provider snapshot + scorecard here.
    // The normal live match object may contain only lifecycle/status text and
    // not the final winner/scorecard fields required to resolve predictions.
    let finalMatch = match;
    try{
        const fresh = await predictionService.getMatch(match.id, true);
        if(fresh) finalMatch = { ...match, ...fresh };
    }catch(error){
        console.warn("Final provider snapshot refresh failed:", error);
    }

    // IMPORTANT:
    // The Prediction page already knows the exact signed-in user's UID.
    // Prefer that explicit UID over auth.currentUser because Firebase Auth can
    // still be initializing when a finished match is finalized. Without this,
    // the result can become WON/LOST while the user's reward stays PENDING.
    const rewardUid = uid || auth.currentUser?.uid || null;

    await processMatchResults(finalMatch, rewardUid);
    return true;
}
