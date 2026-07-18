import { db } from "../firebase-config.js";

import {

    collection,

    doc,

    getDoc,

    getDocs,

    query,

    where,

    orderBy,

    limit,

    addDoc,

    updateDoc,

    increment,

    onSnapshot,

    serverTimestamp,

    runTransaction

} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

/*=====================================

COLLECTIONS

=====================================*/

const PREDICTIONS = "predictions";

const USER_PREDICTIONS = "user_predictions";

const MATCHES = "matches";

/*=====================================

STATUS

=====================================*/

export const PredictionStatus = {

    LIVE: "LIVE",

    LOCKED: "LOCKED",

    COMPLETED: "COMPLETED",

    CANCELLED: "CANCELLED"

};

/*=====================================

DIFFICULTY

=====================================*/

export const Difficulty = {

    EASY: "easy",

    MEDIUM: "medium",

    HARD: "hard",

    EXPERT: "expert"

};

/*=====================================

PREDICTION TYPES

=====================================*/

export const PredictionType = {

    MATCH_WINNER: "MATCH_WINNER",

    NEXT_OVER_RUNS: "NEXT_OVER_RUNS",

    NEXT_WICKET: "NEXT_WICKET",

    NEXT_BOUNDARY: "NEXT_BOUNDARY",

    NEXT_SIX: "NEXT_SIX",

    POWERPLAY_SCORE: "POWERPLAY_SCORE",

    PLAYER_FIFTY: "PLAYER_FIFTY",

    PLAYER_CENTURY: "PLAYER_CENTURY",

    DEATH_OVER: "DEATH_OVER",

    CHASE: "CHASE",

    TOSS_WINNER: "TOSS_WINNER",

    TOTAL_RUNS: "TOTAL_RUNS",

    HIGHEST_SCORER: "HIGHEST_SCORER",

    NEXT_GOAL: "NEXT_GOAL",

    NEXT_SCORER: "NEXT_SCORER",

    NEXT_CORNER: "NEXT_CORNER",

    NEXT_YELLOW_CARD: "NEXT_YELLOW_CARD",

    NEXT_RED_CARD: "NEXT_RED_CARD",

    NEXT_ACE: "NEXT_ACE",

    NEXT_SET_WINNER: "NEXT_SET_WINNER",

    NEXT_RAID: "NEXT_RAID",

    NEXT_BONUS_POINT: "NEXT_BONUS_POINT",

    NEXT_SUPER_TACKLE: "NEXT_SUPER_TACKLE",

    NEXT_THREE_POINTER: "NEXT_THREE_POINTER",

    NEXT_FREE_THROW: "NEXT_FREE_THROW"

};

/*=====================================
    GET LIVE PREDICTIONS
=====================================*/

export async function getLivePredictions(

    matchId,

    sport,

    limitCount = 20

) {

    try {

        const q = query(

            collection(db, PREDICTIONS),

            where("matchId", "==", matchId),

            where("sport", "==", sport),

            where("status", "==", PredictionStatus.LIVE),

            orderBy("expiresAt", "asc"),

            limit(limitCount)

        );

        const snapshot = await getDocs(q);

        const predictions = [];

        snapshot.forEach(docSnap => {

            predictions.push({

                id: docSnap.id,

                ...docSnap.data()

            });

        });

        return predictions;

    }

    catch (error) {

        console.error(

            "Error getting live predictions:",

            error

        );

        return [];

    }

}

/*=====================================

GET PREDICTION BY ID

=====================================*/

export async function getPredictionById(predictionId) {

    try {

        const snapshot = await getDoc(

            doc(db, PREDICTIONS, predictionId)

        );

        if (!snapshot.exists()) {

            return null;

        }

        return {

            id: snapshot.id,

            ...snapshot.data()

        };

    }

    catch (error) {

        console.error(

            error

        );

        return null;

    }

}

/*=====================================
    GET LIVE MATCH
=====================================*/

export async function getLiveMatch(

    matchId

){

    return await getMatch(

        matchId

    );

}

/*=====================================

GET MATCH PREDICTIONS

=====================================*/

export async function getPredictionsByMatch(

    matchId

) {

    try {

        const q = query(

            collection(db, PREDICTIONS),

            where(

                "matchId",

                "==",

                matchId

            ),

            orderBy(

                "createdAt",

                "asc"

            )

        );

        const snapshot =

            await getDocs(q);

        const predictions = [];

        snapshot.forEach(docSnap => {

            predictions.push({

                id: docSnap.id,

                ...docSnap.data()

            });

        });

        return predictions;

    }

    catch (error) {

        console.error(error);

        return [];

    }

}

/*=====================================

UPCOMING PREDICTIONS

=====================================*/

export async function getUpcomingPredictions() {

    try {

        const q = query(

            collection(

                db,

                PREDICTIONS

            ),

            where(

                "status",

                "==",

                PredictionStatus.LOCKED

            ),

            orderBy(

                "expiresAt"

            )

        );

        const snapshot =

            await getDocs(q);

        const list = [];

        snapshot.forEach(docSnap => {

            list.push({

                id: docSnap.id,

                ...docSnap.data()

            });

        });

        return list;

    }

    catch (error) {

        console.error(error);

        return [];

    }

}

/*=====================================

CHECK AVAILABILITY

=====================================*/

export function checkPredictionAvailability(

    prediction

) {

    if (

        prediction.status

        !==

        PredictionStatus.LIVE

    ) {

        return false;

    }

    const now =

        Date.now();

    const expire =

        prediction.expiresAt

            ?.toMillis();

    if (!expire) {

        return false;

    }

    return now < expire;

}

/*=====================================

IS LOCKED

=====================================*/

export function isPredictionLocked(

    prediction

) {

    return (

        prediction.status ===

        PredictionStatus.LOCKED

    );

}

/*=====================================
        GET MATCH
=====================================*/

export async function getMatch(matchId) {

    try {

        const snapshot = await getDoc(

            doc(db, MATCHES, matchId)

        );

        if (!snapshot.exists()) {

            return null;

        }

        return {

            id: snapshot.id,

            ...snapshot.data()

        };

    }

    catch (error) {

        console.error(

            "Get Match Error",

            error

        );

        return null;

    }

}

/*=====================================
    USER ALREADY PREDICTED
=====================================*/

export async function hasUserPredicted(

    uid,

    predictionId

) {

    try {

        const q = query(

            collection(

                db,

                USER_PREDICTIONS

            ),

            where(

                "userId",

                "==",

                uid

            ),

            where(

                "predictionId",

                "==",

                predictionId

            ),

            limit(1)

        );

        const snapshot =

            await getDocs(q);

        return !snapshot.empty;

    }

    catch (error) {

        console.error(error);

        return false;

    }

}

/*=====================================
    GET USER PREDICTION
=====================================*/

export async function getUserPrediction(

    uid,

    predictionId

) {

    try {

        const q = query(

            collection(

                db,

                USER_PREDICTIONS

            ),

            where(

                "userId",

                "==",

                uid

            ),

            where(

                "predictionId",

                "==",

                predictionId

            ),

            limit(1)

        );

        const snapshot =

            await getDocs(q);

        if (snapshot.empty) {

            return null;

        }

        return {

            id: snapshot.docs[0].id,

            ...snapshot.docs[0].data()

        };

    }

    catch (error) {

        console.error(error);

        return null;

    }

}


/*=====================================
        SUBMIT PREDICTION
=====================================*/

export async function submitPrediction(data) {

    try {

        /* Check Prediction */

        const prediction =

            await getPredictionById(

                data.predictionId

            );

        if (!prediction) {

            throw new Error(

                "Prediction not found."

            );

        }

        /* Check Open */

        if (

            !checkPredictionAvailability(

                prediction

            )

        ) {

            throw new Error(

                "Prediction Closed."

            );

        }

        /* Already Submitted */

        const exists =

            await hasUserPredicted(

                data.userId,

                data.predictionId

            );

        if (exists) {

            throw new Error(

                "Already Predicted."

            );

        }

        if (

            data.selectedOption == null

        ) {

            throw new Error(

                "Please select an option."

            );

        }

        const validOption = prediction.options.some(

            option => option.id === data.selectedOption

        );

        if (!validOption) {

            throw new Error(

                "Invalid prediction option."

            );

        }
        /* Save */

       const predictionRef = await addDoc(

            collection(

                db,

                USER_PREDICTIONS

            ),

            {

                ...data,

                status: "PENDING",

                createdAt:

                    serverTimestamp()

            }

        );

        /* Increase Player Count */

        await updateDoc(

            doc(

                db,

                PREDICTIONS,

                data.predictionId

            ),

            {

                totalPlayers:

                    increment(1)

            }

        );

     return{

    success:true,

    id:predictionRef.id

};

    }

    catch (error) {

        console.error(

            error

        );

        return {

            success: false,

            message: error.message

        };

    }

}
/*=====================================
        CREATE PREDICTION
=====================================*/

export async function createPrediction(prediction) {

    try {

        /* Validate */

        if (

            !prediction.matchId ||

            !prediction.sport ||

            !prediction.question ||

            !prediction.options ||

            prediction.options.length < 2

        ) {

            throw new Error(

                "Invalid Prediction Data."

            );

        }

        /* Default Values */

        const predictionData = {

            status: PredictionStatus.LIVE,

            difficulty:

                prediction.difficulty ||

                Difficulty.EASY,

            totalPlayers: 0,

            topPercentage: 0,

            createdAt: serverTimestamp(),

            updatedAt: serverTimestamp(),

            ...prediction

        };

        const docRef = await addDoc(

            collection(

                db,

                PREDICTIONS

            ),

            predictionData

        );

        return {

            success: true,

            id: docRef.id

        };

    }

    catch (error) {

        console.error(

            "Create Prediction Error:",

            error

        );

        return {

            success: false,

            message: error.message

        };

    }

}

/*=====================================
        UPDATE PREDICTION
=====================================*/

export async function updatePrediction(

    predictionId,

    data

) {

    try {

        await updateDoc(

            doc(

                db,

                PREDICTIONS,

                predictionId

            ),

            {

                ...data,

                updatedAt:

                    serverTimestamp()

            }

        );

        return true;

    }

    catch (error) {

        console.error(

            "Update Prediction Error:",

            error

        );

        return false;

    }

}
/*=====================================
        CLOSE PREDICTION
=====================================*/

export async function closePrediction(

    predictionId

) {

    return updatePrediction(

        predictionId,

        {

            status:

                PredictionStatus.LOCKED

        }

    );

}

/*=====================================
        PUBLISH RESULT
=====================================*/

export async function publishResult(

    predictionId,

    correctOption

) {

    try {

        await runTransaction(

            db,

            async (transaction) => {

                const ref =

                    doc(

                        db,

                        PREDICTIONS,

                        predictionId

                    );

                transaction.update(

                    ref,

                    {

                        status:

                            PredictionStatus.COMPLETED,

                        correctOption,

                        completedAt:

                            serverTimestamp()

                    }

                );

            }

        );

        return true;

    }

    catch (error) {

        console.error(error);

        return false;

    }

}

/*=====================================
    GET PREDICTION USERS
=====================================*/

export async function getPredictionUsers(

    predictionId

) {

    try {

        const q = query(

            collection(

                db,

                USER_PREDICTIONS

            ),

            where(

                "predictionId",

                "==",

                predictionId

            )

        );

        const snapshot =

            await getDocs(q);

        const users = [];

        snapshot.forEach(docSnap => {

            users.push({

                id: docSnap.id,

                ...docSnap.data()

            });

        });

        return users;

    }

    catch (error) {

        console.error(

            "Get Prediction Users Error",

            error

        );

        return [];

    }

}
/*=====================================
    REALTIME LISTENER
=====================================*/

export function listenPredictions(

    matchId,

    sport,

    callback

) {

    const q = query(

        collection(

            db,

            PREDICTIONS

        ),

        where(

            "matchId",

            "==",

            matchId

        ),

        where(

            "sport",

            "==",

            sport

        )

    );

    return onSnapshot(

        q,

        snapshot => {

            snapshot.docChanges()

                .forEach(change => {

                    callback({

                        id: change.doc.id,

                        ...change.doc.data()

                    });

                });

        }

    );

}
/*=====================================
    MATCH REALTIME
=====================================*/

export function listenMatch(

    matchId,

    callback

){

    return onSnapshot(

        doc(

            db,

            MATCHES,

            matchId

        ),

        snapshot=>{

            if(

                snapshot.exists()

            ){

                callback({

                    id:snapshot.id,

                    ...snapshot.data()

                });

            }

        }

    );

}

/*=====================================
    USER PREDICTIONS
=====================================*/

export function listenUserPredictions(

    uid,

    callback

){

    const q=query(

        collection(

            db,

            USER_PREDICTIONS

        ),

        where(

            "userId",

            "==",

            uid

        )

    );

    return onSnapshot(

        q,

        snapshot=>{

            const list=[];

            snapshot.forEach(docSnap=>{

                list.push({

                    id:docSnap.id,

                    ...docSnap.data()

                });

            });

            callback(list);

        }

    );

}

/*=====================================
        GENERATE CLIENT ID
=====================================*/

export function generatePredictionId() {

    return crypto.randomUUID();

}

/*=====================================
    LIVE COUNT
=====================================*/

export async function getLivePredictionCount(

    matchId

){

    const predictions=

        await getPredictionsByMatch(

            matchId

        );

    return predictions.filter(

        prediction=>

        prediction.status===

        PredictionStatus.LIVE

    ).length;

}