/* ==========================================================
    FanConnact - Match Service
========================================================== */
import { db } from "../firebase-config.js";

import {

    doc,

    onSnapshot

} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

import * as matchAPI from "../api/normalizeMatch.js";

/* ==========================================================
        Cache
========================================================== */

const matchCache = new Map();

/* ==========================================================
        Live Matches
========================================================== */

export async function getLiveMatches(forceRefresh = false){

    if(

        !forceRefresh &&

        matchCache.has("live")

    ){

        return matchCache.get("live");

    }

    try{

        const matches =

            await matchAPI.getLiveMatches();

        matchCache.set(

            "live",

            matches

        );

        return matches;

    }

    catch(error){

        console.error(

            "Live Match Error:",

            error

        );

        return [];

    }

}

/* ==========================================================
        Upcoming Matches
========================================================== */

export async function getUpcomingMatches(

    forceRefresh = false

){

    if(

        !forceRefresh &&

        matchCache.has("upcoming")

    ){

        return matchCache.get(

            "upcoming"

        );

    }

    try{

        const matches =

        await matchAPI

        .getUpcomingMatches();

        matchCache.set(

            "upcoming",

            matches

        );

        return matches;

    }

    catch(error){

        console.error(error);

        return [];

    }

}

/* ==========================================================
        Finished Matches
========================================================== */

export async function getFinishedMatches(

    forceRefresh = false

){

    if(

        !forceRefresh &&

        matchCache.has("finished")

    ){

        return matchCache.get(

            "finished"

        );

    }

    try{

        const matches =

        await matchAPI

        .getFinishedMatches();

        matchCache.set(

            "finished",

            matches

        );

        return matches;

    }

    catch(error){

        console.error(error);

        return [];

    }

}

/* ==========================================================
        Match By ID
========================================================== */

export async function getMatch(

    matchId,

    forceRefresh = false

){

    if(

        !forceRefresh &&

        matchCache.has(matchId)

    ){

        return matchCache.get(matchId);

    }

    try{

        const match =

        await matchAPI.getMatch(

            matchId

        );

        matchCache.set(

            matchId,

            match

        );

        return match;

    }

    catch(error){

        console.error(error);

        return null;

    }

}

/* ==========================================================
        Cache Helpers
========================================================== */

export function clearMatchCache(){

    matchCache.clear();

}

export function removeMatchFromCache(

    matchId

){

    matchCache.delete(matchId);

}

export function refreshLiveMatches(){

    return getLiveMatches(true);

}

export function refreshUpcomingMatches(){

    return getUpcomingMatches(true);

}

export function refreshFinishedMatches(){

    return getFinishedMatches(true);

}

/* ==========================================================
        Realtime Match Listener
========================================================== */

export function listenMatch(

    matchId,

    callback

){

    try{

        return onSnapshot(

            doc(

                db,

                "matches",

                matchId

            ),

            snapshot=>{

                if(!snapshot.exists()){

                    return;

                }

                const match={

                    id:snapshot.id,

                    ...snapshot.data()

                };

                /* Update Cache */

                matchCache.set(

                    matchId,

                    match

                );

                callback(match);

            }

        );

    }

    catch(error){

        console.error(

            "Match Listener Error:",

            error

        );

    }

}

/* ==========================================================
        Stop Listener
========================================================== */

export function stopListening(

    unsubscribe

){

    if(

        typeof unsubscribe==="function"

    ){

        unsubscribe();

    }

}