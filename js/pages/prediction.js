/* ==========================================================
    FanConnact - Prediction Page Controller
========================================================== */

import {

renderPredictionCard,

startCountdown,

updatePredictionCard

}
from "../components/predictionCard.js";

import * as predictionService from "../services/predictionService.js";

import * as userService from "../services/userService.js";

import {
    listenUser
} from "./services/userService.js";

import {
    auth
} from "./firebase-config.js";

/* ==========================================================
        Global State
========================================================== */

const state = {

    matchId: null,

    sport: null,

    match: null,

    user: null,

    predictions: [],

    cards: new Map()

};

/* ==========================================================
        DOM Cache
========================================================== */

const ui = {

    matchHeader: document.getElementById("matchHeader"),

    predictionContainer: document.getElementById("predictionContainer"),

    statsPanel: document.getElementById("statsPanel"),

    loading: document.getElementById("loading"),

    emptyState: document.getElementById("emptyState")

};

/* ==========================================================
        Page Load
========================================================== */

document.addEventListener("DOMContentLoaded", init);

/* ==========================================================
        Init
========================================================== */

async function init(){

    try{

        getURLParameters();

       await loadCurrentUser();

startUserRealtime();

        await loadMatch();

        await loadPredictions();

        attachEvents();

        listenRealtime();

    }

    catch(error){

        console.error(error);

    }

}

/* ==========================================================
        URL Parameters
========================================================== */

function getURLParameters(){

    const params = new URLSearchParams(window.location.search);

    state.matchId = params.get("matchId");

    state.sport = params.get("sport");

}
/* ==========================================================
        Current User
========================================================== */

async function loadCurrentUser(){

    state.user =

        await userService.getCurrentUser();

}

/*==================================================
        USER REALTIME
==================================================*/

function startUserRealtime(){

    if(!state.user){

        return;

    }

  listenUser(

    state.user.uid,

    user=>{

        state.user=user;

        updateUserUI(user);

    }

)

}
/* ==========================================================
        Match
========================================================== */

async function loadMatch(){

    state.match =

        await predictionService.getMatch(

            state.matchId

        );

}

/* ==========================================================
        Load Predictions
========================================================== */

async function loadPredictions() {

    try {

        showLoading(true);

        state.predictions =
            await predictionService.getLivePredictions(

                state.matchId,

                state.sport

            );

        showLoading(false);

        if (!state.predictions.length) {

            showEmptyState(true);

            return;

        }

       renderPredictionContent();

    }

    catch (error) {

        console.error("Prediction Load Error :", error);

        showLoading(false);

        showEmptyState(true);

    }

}

/* ==========================================================
        Render Prediction Cards
========================================================== */

function renderPredictions() {
    

    ui.predictionContainer.innerHTML = "";

    state.cards.clear();

    state.predictions.forEach(prediction => {

        const card =
            renderPredictionCard(prediction);

        ui.predictionContainer.appendChild(card);

        state.cards.set(

            prediction.id,

            card

        );

        startCountdown(

            card,

            prediction

        );

    });

}
/* ==========================================================
        Attach Events
========================================================== */

function attachEvents(){

    document.addEventListener(

        "prediction-selected",

        handlePredictionSelection

    );

}
/* ==========================================================
        Prediction Selected
========================================================== */

async function handlePredictionSelection(event){

    const {

        predictionId,

        optionId

    } = event.detail;

    const prediction =

        state.predictions.find(

            p=>p.id===predictionId

        );

    if(!prediction){

        return;

    }

    if(prediction.isClosed){

        showToast(

            "Prediction Closed",

            "warning"

        );

        return;

    }

    const confirmPrediction = confirm(

        "Submit this prediction?\n\nYou cannot change it later."

    );

    if(!confirmPrediction){

        return;

    }

    await submitPrediction(

        prediction,

        optionId

    );

}

/* ==========================================================
        Submit Prediction
========================================================== */

async function submitPrediction(

    prediction,

    optionId

){

    try{

        showLoading(true);

        await predictionService.submitPrediction({

            userId:state.user.uid,

            predictionId:prediction.id,

            optionId,

            matchId:state.matchId,

            sport:state.sport

        });

        showLoading(false);

        showToast(

            "Prediction Submitted Successfully",

            "success"

        );

    }

    catch(error){

        console.error(error);

        showLoading(false);

        showToast(

            "Unable to Submit Prediction",

            "error"

        );

    }

}


/* ==========================================================
        Loading
========================================================== */

function showLoading(show) {

    if (!ui.loading) return;

    ui.loading.style.display =

        show ? "block" : "none";

}

/* ==========================================================
        Empty State
========================================================== */

function showEmptyState(show) {

    if (!ui.emptyState) return;

    ui.emptyState.style.display =

        show ? "flex" : "none";

}
/* ==========================================================
        Toast
========================================================== */

function showToast(

    message,

    type="success"

){

    console.log(

        `[${type}]`,

        message

    );

}

/* ==========================================================
        Realtime Listener
========================================================== */

function listenRealtime(){

    predictionService.listenPredictions(

        state.matchId,

        state.sport,

        handleRealtimeUpdate

    );

}
/* ==========================================================
        Handle Live Updates
========================================================== */

function handleRealtimeUpdate(

    updatedPrediction

){

    const index =

    state.predictions.findIndex(

        prediction =>

        prediction.id===updatedPrediction.id

    );

    if(index===-1){

        return;

    }

    state.predictions[index]=updatedPrediction;

    const card =

    state.cards.get(updatedPrediction.id);

    if(card){

      updatePredictionCard(

    card,

    updatedPrediction

);

renderPredictionContent();

    }

}

/*==================================================
        UPDATE USER UI
==================================================*/

function updateUserUI(user){

    state.user=user;

    const set=(id,value)=>{

        const el=document.getElementById(id);

        if(el){

            el.textContent=value;

        }

    };

    if(user.photoURL){

        const img=

        document.getElementById(

            "user-profile-img"

        );

        if(img){

            img.src=user.photoURL;

        }

    }

    set(

        "user-name-display",

        user.username ||

        user.fullName ||

        "User"

    );

    set(

        "user-level-display",

        "LVL "+(

            user.level||0

        )

    );

    set(

        "headerCoins",

        (

            user.coins||0

        ).toLocaleString()

    );

    set(

        "totalPredictions",

        user.totalPredictions||0

    );

    set(

        "correctPredictions",

        user.correctPredictions||0

    );

    const accuracy=

    user.accuracy ||

    0;

    set(

        "accuracy",

        accuracy+"%"

    );

    set(

        "bestStreak",

        user.bestStreak||0

    );

    set(

        "level",

        user.level||0

    );

    set(

        "rank",

        "#"+(

            user.predictionRank||

            "-"

        )

    );

    set(

        "userXP",

        (

            user.xp||0

        )+" XP"

    );

   
}


/*==================================================
        RENDER REALTIME STATS
==================================================*/

function renderRealtimeStats() {

    if (!state.user) {

        return;

    }

    const user = state.user;

    const set = (id, value) => {

        const el = document.getElementById(id);

        if (el) {

            el.textContent = value;

        }

    };

    /* Header */

    set(

        "headerCoins",

        (user.coins || 0).toLocaleString()

    );

    set(

        "user-name-display",

        user.username ||

        user.fullName ||

        "User"

    );

    set(

        "user-level-display",

        "LVL " + (user.level || 0)

    );

    /* Right Stats */

    set(

        "totalPredictions",

        user.totalPredictions || 0

    );

    set(

        "correctPredictions",

        user.correctPredictions || 0

    );

    set(

        "accuracy",

        (user.accuracy || 0) + "%"

    );

    set(

        "bestStreak",

        user.bestStreak || 0

    );

    set(

        "level",

        user.level || 0

    );

    set(

        "rank",

        "#" + (

            user.predictionRank || "-"

        )

    );

    set(

        "userXP",

        (user.xp || 0) + " XP"

    );

}