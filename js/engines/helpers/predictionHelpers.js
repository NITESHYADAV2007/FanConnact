/* ==========================================================
        FanConnact Prediction Helpers
        Cricket-only prediction timing / format rules
========================================================== */

/*
 * Normalize the provider's many cricket-format spellings into one value.
 * Unknown cricket competitions intentionally use T20-style pacing until a
 * dedicated format is identified.
 */
export function cricketFormat(match){
    const raw = String(
        match?.matchType ??
        match?.matchFormat ??
        match?.format ??
        match?.matchInfo?.matchType ??
        ""
    ).toLowerCase().trim();

    if(/\btest\b|test match/.test(raw)) return "TEST";
    if(/\bt10(?:i)?\b|ten10|ten-10|10\s*over/.test(raw)) return "T10";
    if(/\bt20(?:i)?\b|twenty20|twenty-20|20\s*over/.test(raw)) return "T20";
    if(/\bodi\b|one day|50\s*over/.test(raw)) return "ODI";

    return "T20";
}

/*
 * normalSlots are the only normal over checkpoints.
 * They are deliberately sparse:
 *   T10  -> 3 normal checkpoints
 *   T20  -> 4
 *   ODI  -> 4
 *   TEST -> 4
 *
 * Event predictions are separate and occasional. They are still subject to
 * the engine's per-match cap and active-prediction limit.
 */
export function formatConfig(match){
    const format = cricketFormat(match);

    const configs = {
        T10: {
            powerplayEnd: 3,
            deathStart: 8,
            normalSlots: [2, 5, 8],
            matchLimit: 4,
            eventChance: 0.15
        },
        T20: {
            powerplayEnd: 6,
            deathStart: 16,
            normalSlots: [2, 7, 13, 18],
            matchLimit: 5,
            eventChance: 0.18
        },
        ODI: {
            powerplayEnd: 10,
            deathStart: 41,
            normalSlots: [5, 18, 32, 45],
            matchLimit: 5,
            eventChance: 0.15
        },
        TEST: {
            powerplayEnd: null,
            deathStart: null,
            normalSlots: [10, 25, 40, 60],
            matchLimit: 5,
            eventChance: 0.10
        }
    };

    return configs[format] || configs.T20;
}

/*
 * Read an over number from the normalized match, including common provider
 * nesting. A value such as 12.4 means "over 12 is currently in progress".
 */
export function currentOverNumber(match){
    const raw =
        match?.currentOver ??
        match?.over ??
        match?.currentInnings?.over ??
        match?.currentInnings?.currentOver ??
        match?.score?.currentOver ??
        match?.score?.over ??
        match?.innings?.currentOver ??
        match?.live?.currentOver;

    const n = Number(raw);
    return Number.isFinite(n) ? n : null;
}

/*
 * Normal over predictions are only eligible at selected checkpoints.
 * They never run merely because 30/45 seconds passed.
 *
 * We allow a small integer-over compatibility window because some providers
 * report the current over as an integer while others report ball notation
 * such as 12.3. The selected checkpoint itself remains sparse.
 */
export function isNormalOverSlot(match){
    const raw = currentOverNumber(match);
    if(raw == null || raw <= 0) return false;

    const over = Math.floor(raw);
    const slots = formatConfig(match).normalSlots;

    if(slots.includes(over)) return true;

    // Some feeds expose completed overs as an integer. In that case a
    // checkpoint can be observed one poll late without creating a question
    // on every intervening over.
    if(Number.isInteger(raw)){
        return slots.includes(over - 1);
    }

    return false;
}

/*
 * The selected checkpoint used by the question/result layer.
 */
export function selectedOverCheckpoint(match){
    const raw = currentOverNumber(match);
    if(raw == null) return null;

    const over = Math.floor(raw);
    const slots = formatConfig(match).normalSlots;

    if(slots.includes(over)) return over;
    if(Number.isInteger(raw) && slots.includes(over - 1)) return over - 1;

    return null;
}

/*
 * Event key must stay stable for the same provider event. This prevents the
 * 30-second lifecycle poll from turning one wicket/six into repeated questions.
 */
export function eventKey(match){
    return String(
        match?.lastEvent?.id ??
        match?.lastEvent?.eventId ??
        match?.lastEvent?.timestamp ??
        match?.lastEvent?.ballId ??
        match?.lastEvent?.key ??
        ""
    );
}

export function eventType(match){
    return String(
        match?.lastEvent?.type ??
        match?.lastEvent?.eventType ??
        match?.lastEvent?.name ??
        ""
    ).toUpperCase();
}

/*
 * Deterministic probability gate for occasional event predictions.
 */
export function shouldUseEventPrediction(match, salt = "", chance = null){
    const event = eventKey(match) || eventType(match);
    if(!event) return false;

    const rate = chance == null
        ? formatConfig(match).eventChance
        : chance;

    const seed = `${match?.id || ""}:${event}:${salt}`;
    let hash = 0;

    for(let i = 0; i < seed.length; i++){
        hash = ((hash << 5) - hash + seed.charCodeAt(i)) | 0;
    }

    const normalized = Math.abs(hash % 1000) / 1000;
    return normalized < Math.max(0, Math.min(1, rate));
}

/*
 * Difficulty controls the answer window. Format also affects pacing so a
 * quick T10 question does not stay open as long as a Test question.
 */
export function difficultySeconds(match, difficulty){
    const format = cricketFormat(match);
    const table = {
        T10:   { easy:45, medium:60, hard:75 },
        T20:   { easy:45, medium:60, hard:90 },
        ODI:   { easy:60, medium:90, hard:120 },
        TEST:  { easy:60, medium:90, hard:120 }
    };

    const row = table[format] || table.T20;
    const key = String(difficulty || "medium").toLowerCase();

    if(key === "expert") return row.hard;
    return row[key] ?? row.medium;
}

export function expiry(match, type, difficulty = null){
    const now = Date.now();

    if(
        type === "MATCH_WINNER" ||
        type === "TOSS_WINNER" ||
        type === "TOTAL_SCORE" ||
        type === "HIGHEST_SCORER"
    ){
        const start = new Date(
            match?.startTime ??
            match?.startDate ??
            match?.matchStartTime ??
            ""
        ).getTime();

        if(Number.isFinite(start) && start > now){
            return new Date(start);
        }

        // Never create an already-expired pre-match prediction when the
        // provider omitted a usable start timestamp.
        return new Date(now + 60 * 1000);
    }

    const seconds = difficultySeconds(
        match,
        difficulty || (
            type === "NEXT_SIX" ||
            type === "NEXT_BOUNDARY"
                ? "easy"
                : type === "CHASE" ||
                  type === "DEATH_OVER" ||
                  type === "PLAYER_FIFTY" ||
                  type === "PLAYER_CENTURY"
                    ? "hard"
                    : "medium"
        )
    );

    return new Date(now + seconds * 1000);
}

export function nextOverRunsOptions(match){
    const format = cricketFormat(match);
    const expected =
        Number(
            match.expectedOverRuns ??
            match.currentOverRunsExpected ??
            (
                format === "T10" ? 8 :
                format === "ODI" ? 5 :
                format === "TEST" ? 3.5 :
                7.5
            )
        );

    const avg = Math.max(0, Math.round(expected));

    return [
        { id:"1", text:`0-${Math.max(1, avg-2)}` },
        { id:"2", text:`${Math.max(2, avg-1)}-${avg+1}` },
        { id:"3", text:`${avg+2}-${avg+4}` },
        { id:"4", text:`${avg+5}+` }
    ];
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