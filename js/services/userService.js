import {
    db
} from "../firebase-config.js";

import {

doc,

getDoc,

updateDoc,

increment,

serverTimestamp,

collection,

addDoc,

onSnapshot

}

from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

/*====================================

USER SERVICE

====================================*/

const USERS = "users";
/*====================================

PREDICTION REWARDS

====================================*/

export const PREDICTION_REWARDS = {

    easy: {

        correct: {

            xp: 8,

            coins: 5

        },

        wrong: {

            xp: 1,

            coins: 0

        }

    },

    medium: {

        correct: {

            xp: 10,

            coins: 8

        },

        wrong: {

            xp: 2,

            coins: 0

        }

    },

    hard: {

        correct: {

            xp: 12,

            coins: 10

        },

        wrong: {

            xp: 2,

            coins: 0

        }

    },

    expert: {

        correct: {

            xp: 15,

            coins: 12

        },

        wrong: {

            xp: 2,

            coins: 0

        }

    }

};

export async function getUser(uid){

    try{

        const snap = await getDoc(

            doc(db, USERS, uid)

        );

        if(!snap.exists()){

            return null;

        }

        return {

            id:snap.id,

            ...snap.data()

        };

    }

    catch(error){

        console.error(

            "Get User Error:",

            error

        );

        return null;

    }

}
/*=====================================

LISTEN USER

=====================================*/

export function listenUser(

    uid,

    callback

){

    return onSnapshot(

        doc(

            db,

            USERS,

            uid

        ),

        (snapshot)=>{

            if(snapshot.exists()){

                callback({

                    id:snapshot.id,

                    ...snapshot.data()

                });

            }

        }

    );

}

export async function updateUser(

    uid,

    data

){

    try{

        await updateDoc(

            doc(db, USERS, uid),

            {

                ...data,

                updatedAt:

                serverTimestamp()

            }

        );

        return true;

    }

    catch(error){

        console.error(

            "Update User Error:",

            error

        );

        return false;

    }

}

export async function updateTheme(

    uid,

    theme

){

    return updateUser(

        uid,

        {

            theme

        }

    );

}

export async function updateSports(

    uid,

    sports

){

    return updateUser(

        uid,

        {

            selectedSports:sports

        }

    );

}

export async function updateSettings(

    uid,

    settings

){

    return updateUser(

        uid,

        settings

    );

}

/*====================================

LEVEL FORMULA

====================================*/

export function getRequiredXP(level){

    if(level <= 0) return 0;

    return Math.floor(

        150 * level +

        ((level - 1) * level * 25)

    );

}

export function calculateLevel(xp){

    let level = 0;

    while(

        xp >= getRequiredXP(level + 1)

    ){

        level++;

    }

    return level;

}

export async function addXP(

    uid,

    amount

){

    try{

        const user =

        await getUser(uid);

        if(!user) return false;

        const newXP =

        user.xp + amount;

        const newLevel =

        calculateLevel(newXP);

        await updateUser(

            uid,

            {

                xp:newXP,

                level:newLevel

            }

        );

        return{

            xp:newXP,

            level:newLevel

        };

    }

    catch(error){

        console.error(

            error

        );

        return false;

    }

}

export async function addCoins(

    uid,

    amount

){

    try{

        const user =

        await getUser(uid);

        if(!user) return false;

        await updateUser(

            uid,

            {

                coins:

                user.coins + amount

            }

        );

        return true;

    }

    catch(error){

        console.error(

            error

        );

        return false;

    }

}

export function calculateAccuracy(

    correct,

    total

){

    if(total===0){

        return 0;

    }

    return Number(

        (

            (correct/total)

            *100

        ).toFixed(1)

    );


}

export async function getUserStats(uid){

    const user=

    await getUser(uid);

    if(!user) return null;

    return{

        xp:user.xp,

        level:user.level,

        coins:user.coins,

        total:user.totalPredictions,

        correct:user.correctPredictions,

        wrong:user.wrongPredictions,

        streak:user.currentStreak,

        accuracy:

        calculateAccuracy(

            user.correctPredictions,

            user.totalPredictions

        )

    };

}

export async function updatePredictionStats(

    uid,

    isCorrect

){

    try{

        const user = await getUser(uid);

        if(!user) return false;

        const data = {

            totalPredictions:

                user.totalPredictions + 1,

            updatedAt:

                serverTimestamp()

        };

        if(isCorrect){

            data.correctPredictions =

                user.correctPredictions + 1;

        }

        else{

            data.wrongPredictions =

                user.wrongPredictions + 1;

        }

        await updateDoc(

            doc(db, USERS, uid),

            data

        );

        return true;

    }

    catch(error){

        console.error(

            "Prediction Stats Error",

            error

        );

        return false;

    }

}

export async function updateStreak(

    uid,

    isCorrect

){

    const user = await getUser(uid);

    if(!user) return;

    let streak =

        user.currentStreak;

    let best =

        user.bestStreak;

    if(isCorrect){

        streak++;

        if(streak > best){

            best = streak;

        }

    }

    else{

        streak = 0;

    }

    await updateUser(

        uid,

        {

            currentStreak: streak,

            bestStreak: best

        }

    );

}

export async function givePredictionReward(

    uid,

    difficulty,

    isCorrect

){

    try{

        const reward =

            PREDICTION_REWARDS

            [difficulty]

            [isCorrect

                ? "correct"

                : "wrong"

            ];

        await addXP(

            uid,

            reward.xp

        );

        if(reward.coins > 0){

            await addCoins(

                uid,

                reward.coins

            );

        }

        await updatePredictionStats(

            uid,

            isCorrect

        );

        await updateStreak(

            uid,

            isCorrect

        );
        await saveRewardHistory(

    uid,

    isCorrect

        ? "Correct Prediction"

        : "Wrong Prediction",

    reward.xp,

    reward.coins

);

        return reward;

    }

    catch(error){

        console.error(

            "Reward Error",

            error

        );

        return null;

    }

}

/*====================================

WELCOME BONUS

====================================*/

export async function giveWelcomeBonus(uid){

    try{

        const user = await getUser(uid);

        if(!user) return false;

        if(user.welcomeBonusClaimed){

            return false;

        }

        const newXP = user.xp + 10;

        const newLevel = calculateLevel(newXP);

        await updateUser(uid,{

            xp:newXP,

            level:newLevel,

            coins:user.coins + 5,

            welcomeBonusClaimed:true

        });

        return true;

    }

    catch(error){

        console.error(

            "Welcome Bonus Error",

            error

        );

        return false;

    }

}

/*====================================

DAILY MISSION

====================================*/

export async function updateDailyMission(

    uid,

    amount = 1

){

    try{

        const user = await getUser(uid);

        if(!user) return;

        await updateUser(

            uid,

            {

                dailyMissionCompleted:

                    user.dailyMissionCompleted +

                    amount

            }

        );

    }

    catch(error){

        console.error(error);

    }

}

/*====================================

WEEKLY MISSION

====================================*/

export async function updateWeeklyMission(

    uid,

    amount = 1

){

    try{

        const user = await getUser(uid);

        if(!user) return;

        await updateUser(

            uid,

            {

                weeklyMissionCompleted:

                    user.weeklyMissionCompleted +

                    amount

            }

        );

    }

    catch(error){

        console.error(error);

    }

}

/*====================================

RESET DAILY

====================================*/

export async function resetDailyMission(uid){

    return updateUser(

        uid,

        {

            dailyMissionCompleted:0

        }

    );

}


/*====================================

RESET WEEKLY

====================================*/

export async function resetWeeklyMission(uid){

    return updateUser(

        uid,

        {

            weeklyMissionCompleted:0

        }

    );

}

/*====================================

SAVE REWARD HISTORY

====================================*/

export async function saveRewardHistory(

    uid,

    reason,

    xp,

    coins

){

    try{

        await addDoc(

            collection(

                db,

                "rewards"

            ),

            {

                uid,

                reason,

                xp,

                coins,

                createdAt:

                    serverTimestamp()

            }

        );

    }

    catch(error){

        console.error(

            error

        );

    }

}
