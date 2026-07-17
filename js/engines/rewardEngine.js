/* ==========================================================
        FanConnact Reward Engine
========================================================== */

import * as predictionService from "../services/predictionService.js";

import {

givePredictionReward

}

from "../services/userService.js";

import {

updateGlobalLeaderboard

}

from "./leaderboardEngine.js";

/* ==========================================================
        Process Rewards
========================================================== */

export async function processRewards(

    prediction

){

    try{

        const users =

        await predictionService.getPredictionUsers(

            prediction.id

        );

        for(

            const userPrediction

            of users

        ){

            await rewardUser(

                prediction,

                userPrediction

            );

        }

    }

    catch(error){

        console.error(

            "Reward Engine Error",

            error

        );

    }

}
/* ==========================================================
        Reward User
========================================================== */

async function rewardUser(

    prediction,

    userPrediction

){

    const isCorrect =

        prediction.correctOption===

        userPrediction.selectedOption;

   await givePredictionReward(

    userPrediction.uid,

    prediction.difficulty,

    isCorrect

);

await updateGlobalLeaderboard();

}