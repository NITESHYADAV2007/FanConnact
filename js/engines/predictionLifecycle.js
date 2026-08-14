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

export async function closeExpiredPredictions(){
    try{
        const predictions = await predictionService.getAllLivePredictions(100);
        const now = Date.now();

        for(const prediction of predictions){
            const expiresAt = toMillis(prediction.expiresAt);
            if(expiresAt == null || expiresAt > now) continue;

            let resolved = false;
            if(prediction.matchId){
                const match = await predictionService.getMatch(prediction.matchId);
                if(match) resolved = await processPredictionResult(prediction, match, auth.currentUser?.uid || null);
            }

            if(!resolved){
                await predictionService.closePrediction(prediction.id);
            }
        }
    }catch(error){
        console.error("Lifecycle Error", error);
    }
}

export async function handleMatchFinished(match){
    if(!match) return;
    await processMatchResults(match, auth.currentUser?.uid || null);
}
