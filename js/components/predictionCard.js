/**
 * ==========================================
 * FanConnact
 * Universal Prediction Card Component
 * ==========================================
 */
export function renderPredictionCard(prediction){

    const card = createCard();

    card.append(

        renderHeader(prediction),

        renderQuestion(prediction),

        renderOptions(prediction),

        renderUserPrediction(prediction),

        renderFooter(prediction)

    );

    return card;

}
/* ==========================================================
        Render Header
========================================================== */

function renderHeader(prediction){

    const header = document.createElement("div");

    header.className = "prediction-card-header";

    /* Live */

    const live = document.createElement("div");

    live.className = "prediction-live";

    live.innerHTML = `
        <span class="live-dot"></span>
        ${prediction.status.toUpperCase()}
    `;

    /* Difficulty */

    const difficulty = document.createElement("span");

    difficulty.className =
        `difficulty-badge ${prediction.difficulty}`;

    difficulty.textContent =
        prediction.difficulty.toUpperCase();

    /* Left */

    const left = document.createElement("div");

    left.className = "prediction-header-left";

    left.append(

        live,

        difficulty

    );

    /* Timer */

    const timer = document.createElement("div");

    timer.className = "prediction-timer";

    timer.dataset.end = prediction.endTime;

    timer.innerHTML = `
        <i class="fa-regular fa-clock"></i>

        <span class="time-value">

            ${prediction.timeLeft}

        </span>
    `;

    header.append(

        left,

        timer

    );

    return header;

}
/* ==========================================================
        Question
========================================================== */

function renderQuestion(prediction){

    const question = document.createElement("h2");

    question.className = "prediction-question";

    question.textContent = prediction.question;

    return question;

}
/* ==========================================================
   Render Prediction Options
========================================================== */

function renderOptions(prediction) {

    const container = document.createElement("div");
    container.className = "prediction-options";

    prediction.options.forEach(option => {

        const button = document.createElement("button");

        button.className = "prediction-option";

        button.dataset.optionId = option.id;

        /* -------------------------
            Option Image (Optional)
        -------------------------- */

        if (option.image) {

            const imageWrapper = document.createElement("div");
            imageWrapper.className = "option-image";

            const image = document.createElement("img");

            image.src = option.image;

            image.alt = option.text;

            image.loading = "lazy";

            imageWrapper.appendChild(image);

            button.appendChild(imageWrapper);

        }

        /* -------------------------
                Content
        -------------------------- */

        const content = document.createElement("div");
        content.className = "option-content";

        const title = document.createElement("span");
        title.className = "option-title";
        title.textContent = option.text;

        const percent = document.createElement("span");
        percent.className = "option-percent";
        percent.textContent = `${option.percentage}%`;

        content.append(title, percent);

        button.appendChild(content);

        /* -------------------------
             Selected Option
        -------------------------- */

        if (

            prediction.userPrediction === option.id

        ) {

            button.classList.add("active");

        }

        /* -------------------------
              Click Event
        -------------------------- */

        button.addEventListener("click", () => {

            selectPrediction(

                prediction.id,

                option.id,

                container

            );

        });

        container.appendChild(button);

    });

    return container;

}

/* ==========================================================
        Render User Prediction
========================================================== */

function renderUserPrediction(prediction){

    const section = document.createElement("div");

    section.className = "prediction-user";

    /*==============================
            Left
    ==============================*/

    const left = document.createElement("div");

    left.className = "user-left";

    /* Avatar */

    const avatar = document.createElement("img");

    avatar.className = "user-avatar";

    avatar.src =

        prediction.userAvatar ||

        "assets/images/default-avatar.png";

    avatar.alt = "User";

    avatar.loading = "lazy";

    /* Text */

    const info = document.createElement("div");

    info.className = "user-info";

    const label = document.createElement("span");

    label.className = "prediction-label";

    label.textContent = "You Predicted";

    const answer = document.createElement("strong");

    answer.className = "prediction-answer";

    answer.textContent =

        prediction.userPredictionText ||

        "Not Predicted Yet";

    info.append(

        label,

        answer

    );

    left.append(

        avatar,

        info

    );

    /*==============================
            Right
    ==============================*/

    const right = document.createElement("div");

    right.className = "prediction-position";

    right.innerHTML = `

        <i class="fa-solid fa-trophy"></i>

        <span>

            Top ${prediction.topPercentage}%

        </span>

    `;

    section.append(

        left,

        right

    );

    return section;

}

/* ==========================================================
        Select Prediction
========================================================== */

function selectPrediction(

    predictionId,

    optionId,

    container

) {

    container

        .querySelectorAll(".prediction-option")

        .forEach(btn =>

            btn.classList.remove("active")

        );

    const selected =

        container.querySelector(

            `[data-option-id="${optionId}"]`

        );

    if (selected)

        selected.classList.add("active");

    document.dispatchEvent(

        new CustomEvent(

            "prediction-selected",

            {

                detail: {

                    predictionId,

                    optionId

                }

            }

        )

    );

}

/* ==========================================================
    Render Footer
========================================================== */

function renderFooter(prediction) {

    const footer = document.createElement("div");
    footer.className = "prediction-footer";

    /* ===============================
        Reward Section
    =============================== */

    const rewardSection = document.createElement("div");
    rewardSection.className = "reward-section";

    /* XP */

    const xp = document.createElement("div");
    xp.className = "reward-item xp";

    xp.innerHTML = `
        <i class="fa-solid fa-star"></i>
        +${prediction.rewardXP} XP
    `;

    /* Coins */

    const coins = document.createElement("div");
    coins.className = "reward-item coins";

    coins.innerHTML = `
        <i class="fa-solid fa-coins"></i>
        +${prediction.rewardCoins} Coins
    `;

    rewardSection.append(

        xp,

        coins

    );

    /* ===============================
        Right Section
    =============================== */

    const right = document.createElement("div");

    right.className = "prediction-meta";

    /* Players */

    const players = document.createElement("div");

    players.className = "prediction-players";

    players.innerHTML = `
        <i class="fa-solid fa-users"></i>

        <span>

            ${formatNumber(

                prediction.totalPlayers

            )}

            Players

        </span>
    `;

    /* Rank */

    const top = document.createElement("div");

    top.className = "prediction-top";

    top.innerHTML = `
        <i class="fa-solid fa-trophy"></i>

        <span>

            Top ${prediction.topPercentage}%

        </span>
    `;

    right.append(

        players,

        top

    );

    footer.append(

        rewardSection,

        right

    );

    return footer;

}

/* ==========================================================
        Number Formatter
========================================================== */

function formatNumber(value){

    if(value>=1000000){

        return (value/1000000).toFixed(1)+"M";

    }

    if(value>=1000){

        return (value/1000).toFixed(1)+"K";

    }

    return value;

}

/* ==========================================================
        Start Live Countdown
========================================================== */

export function startCountdown(card, prediction) {

    const timer = card.querySelector(".time-value");

    if (!timer) return;

    const interval = setInterval(() => {

        const now = Date.now();

        const end = new Date(prediction.endTime).getTime();

        const diff = end - now;

        if (diff <= 0) {

            clearInterval(interval);

            timer.textContent = "Closed";

            card.classList.add("prediction-closed");

            disablePrediction(card);

            return;

        }

        const minutes = Math.floor(diff / 60000);

        const seconds = Math.floor((diff % 60000) / 1000);

        timer.textContent =
            `${String(minutes).padStart(2,"0")}:${String(seconds).padStart(2,"0")}`;

    },1000);

}

/* ==========================================================
        Disable Prediction
========================================================== */

function disablePrediction(card){

    card
        .querySelectorAll(".prediction-option")
        .forEach(button=>{

            button.disabled = true;

            button.classList.add("disabled");

        });

}

/* ==========================================================
        Update Prediction Card
========================================================== */

export function updatePredictionCard(card,prediction){

    /* Player Count */

    const players = card.querySelector(

        ".prediction-players span"

    );

    if(players){

        players.textContent =

        `${formatNumber(prediction.totalPlayers)} Players`;

    }

    /* Top Percentage */

    const top = card.querySelector(

        ".prediction-top span"

    );

    if(top){

        top.textContent =

        `Top ${prediction.topPercentage}%`;

    }

    /* XP */

    const xp = card.querySelector(

        ".reward-item.xp"

    );

    if(xp){

        xp.innerHTML = `

        <i class="fa-solid fa-star"></i>

        +${prediction.rewardXP} XP

        `;

    }

    /* Coins */

    const coins = card.querySelector(

        ".reward-item.coins"

    );

    if(coins){

        coins.innerHTML = `

        <i class="fa-solid fa-coins"></i>

        +${prediction.rewardCoins} Coins

        `;

    }

    /* Option Percentages */

    const options =

    card.querySelectorAll(

        ".prediction-option"

    );

    options.forEach((button,index)=>{

        const percent =

        button.querySelector(

            ".option-percent"

        );

        if(percent){

            percent.textContent =

            prediction.options[index].percentage + "%";

        }

    });

}

/* ==========================================================
        Highlight Selected Option
========================================================== */

export function highlightPrediction(

    card,

    optionId

){

    card

    .querySelectorAll(".prediction-option")

    .forEach(button=>{

        button.classList.remove("active");

    });

    const selected =

    card.querySelector(

        `[data-option-id="${optionId}"]`

    );

    if(selected){

        selected.classList.add("active");

    }

}