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

let predictionGenerationInFlight = new Set();

async function triggerPredictionGeneration(matchOrMatches){
    const list = Array.isArray(matchOrMatches) ? matchOrMatches : [matchOrMatches];

    for(const raw of list){
        if(!raw) continue;

        const match = {
            ...raw,
            id: String(raw.id ?? raw.matchId ?? ""),
            sport: String(raw.sport || "cricket").toLowerCase()
        };

        if(!match.id || match.sport !== "cricket") continue;

        const status = String(
            match.status ?? match.state ?? match.matchState ?? ""
        ).toUpperCase();

        if(!["LIVE","IN PROGRESS","INPROGRESS","STARTED","ONGOING"].includes(status) &&
           raw.isLive !== true){
            continue;
        }

        const key = match.id;
        if(predictionGenerationInFlight.has(key)) continue;

        predictionGenerationInFlight.add(key);

        try{
            const engine = await import("../engines/predictionEngine.js");
            await engine.generatePredictions(match);
        }catch(error){
            // Prediction generation must never break Match Center.
            console.warn("Live prediction generation skipped:", error);
        }finally{
            predictionGenerationInFlight.delete(key);
        }
    }
}

/* ==========================================================
        Live Matches
========================================================== */

export async function getLiveMatches(forceRefresh = false){

    if(

        !forceRefresh &&

        matchCache.has("live")

    ){

        const cached = matchCache.get("live");
        // Fire-and-forget: cache remains exactly the same; predictions are
        // generated from the latest snapshot already available to Match Center.
        triggerPredictionGeneration(cached).catch(()=>{});
        return cached;

    }

    try{

        const matches =

            await matchAPI.getLiveMatches();

        matchCache.set(

            "live",

            matches

        );

        // Match Center's fresh API snapshot is also a prediction source.
        // This keeps generation independent from the Prediction page.
        triggerPredictionGeneration(matches).catch(()=>{});

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

        const cached = matchCache.get(matchId);
        triggerPredictionGeneration(cached).catch(()=>{});
        return cached;

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

        triggerPredictionGeneration(match).catch(()=>{});

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

                triggerPredictionGeneration(match).catch(()=>{});

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