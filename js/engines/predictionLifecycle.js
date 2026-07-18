/* ==========================================================
        FanConnact Prediction Lifecycle
========================================================== */

import * as predictionService from "../services/predictionService.js";

import {

processMatchResults

}

from "./resultEngine.js";

/* ==========================================================
        Close Expired Predictions
========================================================== */

export async function closeExpiredPredictions(){

    try{

        const predictions=

        await predictionService.getLivePredictions(100);

        const now=Date.now();

        for(

            const prediction

            of predictions

        ){

            if(

                prediction.expiresAt.toMillis()

                <=

                now

            ){

                await predictionService.closePrediction(

                    prediction.id

                );

            }

        }

    }

    catch(error){

        console.error(

            "Lifecycle Error",

            error

        );

    }

}

/* ==========================================================
        Match Finished
========================================================== */

export async function handleMatchFinished(match){

    await processMatchResults(match);

}

/* ==========================================================
        Match Finished
========================================================== */

export async function handleMatchFinished(match){

    await processMatchResults(match);

}