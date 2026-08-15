/* ==========================================================
        FanConnact Prediction Scheduler
        Generates cricket predictions from the same live-match source
        used by Match Center, while keeping Match Service cache logic intact.
========================================================== */

import { closeExpiredPredictions } from "./predictionLifecycle.js";
import { getLiveMatches } from "../services/matchService.js";

let schedulerStarted = false;
let schedulerTimer = null;
let schedulerBusy = false;

async function runPredictionCycle(){
    if(schedulerBusy) return;
    schedulerBusy = true;

    try{
        const { generatePredictions } = await import("./predictionEngine.js");
        const liveMatches = await getLiveMatches(true);

        if(Array.isArray(liveMatches)){
            for(const match of liveMatches){
                if(String(match?.sport || "cricket").toLowerCase() !== "cricket") continue;
                await generatePredictions({
                    ...match,
                    id: String(match.id ?? match.matchId ?? ""),
                    sport: "cricket"
                });
            }
        }

        await closeExpiredPredictions();
    }catch(error){
        console.error("Prediction Scheduler Error:", error);
    }finally{
        schedulerBusy = false;
    }
}

export function startScheduler(){
    if(schedulerStarted) return;
    schedulerStarted = true;

    runPredictionCycle().catch(()=>{});

    schedulerTimer = setInterval(
        runPredictionCycle,
        20000
    );

    return () => {
        if(schedulerTimer){
            clearInterval(schedulerTimer);
            schedulerTimer = null;
        }
        schedulerStarted = false;
    };
}
