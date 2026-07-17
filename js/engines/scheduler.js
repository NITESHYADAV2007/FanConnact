/* ==========================================================
        FanConnact Scheduler
========================================================== */

import {

closeExpiredPredictions

}

from "./predictionLifecycle.js";

export function startScheduler(){

    setInterval(

        async()=>{

            await closeExpiredPredictions();

        },

        30000

    );

}