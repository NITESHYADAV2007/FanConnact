/* ==========================================================
        FanConnact Leaderboard Engine
========================================================== */

import {

    db

} from "../firebase-config.js";

import {

    collection,

    getDocs,

    query,

    orderBy,

    limit,

    doc,

    setDoc,

    serverTimestamp

} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

import { calculateLevel } from "../services/userService.js";

/* ==========================================================
        Collections
========================================================== */

const USERS = "users";

const LEADERBOARD = "leaderboards";

/* ==========================================================
        Update Global Leaderboard
========================================================== */

export async function updateGlobalLeaderboard(){

    try{

        const q = query(

            collection(

                db,

                USERS

            ),

            orderBy(

                "xp",

                "desc"

            ),

            limit(100)

        );

        const snapshot =

        await getDocs(q);

        const leaderboard = [];

        let rank = 1;

        snapshot.forEach(user=>{

            const data = user.data();

            leaderboard.push({

                rank,

                uid:user.id,

                username:data.username,

                avatar:data.avatar,

                xp:Number(data.xp) || 0,

                level:calculateLevel(Number(data.xp) || 0),

                coins:Number(data.coins) || 0,

                accuracy:data.accuracy || 0

            });

            rank++;

        });

        await saveLeaderboard(

            "global",

            leaderboard

        );

    }

    catch(error){

        console.error(

            "Leaderboard Error",

            error

        );

    }

}

/* ==========================================================
        Match Leaderboard
========================================================== */

export async function updateMatchLeaderboard(

    matchId,

    users

){

    const sorted =

    [...users].sort(

        (a,b)=>{

            if(

                b.correct!==a.correct

            ){

                return(

                    b.correct-a.correct

                );

            }

            return(

                b.xp-a.xp

            );

        }

    );

    sorted.forEach(

        (user,index)=>{

            user.rank=index+1;

        }

    );

    await saveLeaderboard(

        matchId,

        sorted

    );

}

/* ==========================================================
        Save Leaderboard
========================================================== */

async function saveLeaderboard(

    id,

    leaderboard

){

    await setDoc(

        doc(

            db,

            LEADERBOARD,

            id

        ),

        {

            updatedAt:

            serverTimestamp(),

            leaderboard

        }

    );

}