/*==================================================
        Prediction Reward
==================================================*/

import * as userService from "./userService.js";

export async function givePredictionReward(

    uid,

    difficulty,

    isCorrect

){

    return await userService.givePredictionReward(

        uid,

        difficulty,

        isCorrect

    );

}
/*==================================================
        Mission Reward
==================================================*/

export async function giveMissionReward(

    uid,

    xp,

    coins,

    reason

){

    if(xp>0){

        await userService.addXP(

            uid,

            xp

        );

    }

    if(coins>0){

        await userService.addCoins(

            uid,

            coins

        );

    }

    await userService.saveRewardHistory(

        uid,

        reason,

        xp,

        coins

    );

}

/*==================================================
        Welcome Reward
==================================================*/

export async function giveWelcomeReward(

    uid

){

    return await userService

        .giveWelcomeBonus(uid);

}
/*==================================================
        Manual Reward
==================================================*/

export async function giveReward(

    uid,

    xp,

    coins,

    reason

){

    if(xp){

        await userService.addXP(

            uid,

            xp

        );

    }

    if(coins){

        await userService.addCoins(

            uid,

            coins

        );

    }

    await userService.saveRewardHistory(

        uid,

        reason,

        xp,

        coins

    );

}