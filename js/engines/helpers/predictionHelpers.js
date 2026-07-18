/* ==========================================================
        FanConnact Prediction Helpers
========================================================== */

export function expiry(match,type){

    const now=Date.now();

    switch(type){

        case "MATCH_WINNER":

        case "TOSS_WINNER":

        case "TOTAL_SCORE":

        case "HIGHEST_SCORER":

            return new Date(match.startTime);

        case "POWERPLAY_SCORE":

            return new Date(now+120000);

        case "NEXT_WICKET":

            return new Date(now+180000);

        case "NEXT_BOUNDARY":

            return new Date(now+90000);

        case "PLAYER_FIFTY":

            return new Date(now+600000);

        case "PLAYER_CENTURY":

            return new Date(now+1200000);

        case "DEATH_OVER":

            return new Date(now+180000);

        case "CHASE":

            return new Date(now+300000);

        default:

            return new Date(now+120000);

    }

}

/* ==========================================================
        Players
========================================================== */

export function players(match){

    return(

        match.topPlayers ||

        []

    ).map(player=>({

        id:player.id,

        text:player.name

    }));

}
/* ==========================================================
        Bowlers
========================================================== */

export function bowlers(match){

    return(

        match.currentBowlers ||

        []

    ).map(player=>({

        id:player.id,

        text:player.name

    }));

}

/* ==========================================================
        Powerplay Options
========================================================== */

export function powerplayOptions(match){

    const avg=

    match.expectedPowerplay||

    60;

    return[

        {

            id:"1",

            text:`${avg-20}-${avg-10}`

        },

        {

            id:"2",

            text:`${avg-9}-${avg}`

        },

        {

            id:"3",

            text:`${avg+1}-${avg+10}`

        },

        {

            id:"4",

            text:`${avg+11}+`

        }

    ];

}

/* ==========================================================
        Total Runs
========================================================== */

export function totalRunsOptions(match){

    const avg=

    match.expectedTotal||

    180;

    return[

        {

            id:"1",

            text:`${avg-30}-${avg-10}`

        },

        {

            id:"2",

            text:`${avg-9}-${avg+10}`

        },

        {

            id:"3",

            text:`${avg+11}-${avg+30}`

        },

        {

            id:"4",

            text:`${avg+31}+`

        }

    ];

}

/* ==========================================================
        Death Over
========================================================== */

export function deathOverOptions(match){

    return[

        {

            id:"1",

            text:"0-8"

        },

        {

            id:"2",

            text:"9-12"

        },

        {

            id:"3",

            text:"13-18"

        },

        {

            id:"4",

            text:"19+"

        }

    ];

}

/* ==========================================================
        Football Goal Options
========================================================== */

export function goalOptions(){

    return[

        {

            id:"1",

            text:"0"

        },

        {

            id:"2",

            text:"1"

        },

        {

            id:"3",

            text:"2"

        },

        {

            id:"4",

            text:"3+"

        }

    ];

}

/* ==========================================================
        Match Winner
========================================================== */

export function footballWinnerOptions(match){

    return[

        {

            id:"home",

            text:match.homeTeam.name

        },

        {

            id:"draw",

            text:"Draw"

        },

        {

            id:"away",

            text:match.awayTeam.name

        }

    ];

}

/* ==========================================================
        BTTS
========================================================== */

export function yesNoOptions(){

    return[

        {

            id:"yes",

            text:"Yes"

        },

        {

            id:"no",

            text:"No"

        }

    ];

}