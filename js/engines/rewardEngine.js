/* ==========================================================
        FanConnact Reward Engine
        One-time / idempotent rewards
========================================================== */

import * as predictionService from "../services/predictionService.js";

import {
    givePredictionRewardOnce
} from "../services/userService.js";

import {
    updateGlobalLeaderboard
} from "./leaderboardEngine.js";

/* ==========================================================
        Process Rewards
========================================================== */

export async function processRewards(prediction, uid = null){

    try{

        // Client-side Firestore rules intentionally keep user_predictions
        // private. Therefore result processing must reward the current user
        // directly instead of querying every user's prediction.
        if(!uid){
            return false;
        }

        const userPrediction =
            await predictionService.getUserPrediction(
                uid,
                prediction.id
            );

        if(!userPrediction){
            return false;
        }

        const result = await rewardUser(
            prediction,
            userPrediction
        );

        if(result?.rewarded){
            // Leaderboard rebuilding is optional and may require privileged
            // server access. User XP/coins/reward history are already committed
            // atomically by givePredictionRewardOnce().
            return true;
        }

        return false;

    }
    catch(error){
        console.error("Reward Engine Error", error);
        return false;
    }

}

/* ==========================================================
        Reward User
========================================================== */

async function rewardUser(prediction, userPrediction){

    const selected = userPrediction.selectedOption;
    const correct = prediction.correctOption;

    if(selected == null || correct == null){
        return;
    }

    const isCorrect = String(correct) === String(selected);
    const uid = userPrediction.userId || userPrediction.uid;

    if(!uid){
        console.error(
            "Reward skipped: userId missing on user_prediction",
            userPrediction.id
        );
        return;
    }

    const result = await givePredictionRewardOnce(
        userPrediction.id,
        uid,
        prediction.difficulty,
        isCorrect
    );

    return result;
}
