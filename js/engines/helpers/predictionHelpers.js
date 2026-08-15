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
        match?.competition?.format ??
        match?.series?.format ??
        ""
    ).toLowerCase().trim();

    if(/hundred|the hundred|100\s*ball|100\s*balls/.test(raw)) return "HUNDRED";
    if(/\btest\b|test match/.test(raw)) return "TEST";
    if(/\bt10(?:i)?\b|ten10|ten-10|10\s*over/.test(raw)) return "T10";
    if(/\bt20(?:i)?\b|twenty20|twenty-20|20\s*over/.test(raw)) return "T20";
    if(/\bodi\b|one day|50\s*over/.test(raw)) return "ODI";

    // The Hundred is sometimes supplied by the provider as a competition
    // name while matchType is blank.
    const context = String(
        match?.seriesName ?? match?.series ?? match?.competition?.name ?? ""
    ).toLowerCase();
    if(/hundred/.test(context)) return "HUNDRED";

    return "T20";
}

export function formatConfig(match){
    const format = cricketFormat(match);

    const configs = {
        T10: {
            powerplayStart: 2,
            powerplayEnd: 3,
            deathStart: 8,
            normalSlots: [2, 5, 8],
            matchLimit: 12,
            eventChance: 1,
            eventMinOvers: 0,
            sameEventMinOvers: 0,
            maxActiveLive: 4
        },
        T20: {
            powerplayStart: 3,
            powerplayEnd: 6,
            deathStart: 16,
            normalSlots: [2, 7, 13, 18],
            matchLimit: 20,
            eventChance: 1,
            eventMinOvers: 0,
            sameEventMinOvers: 0,
            maxActiveLive: 5
        },
        ODI: {
            powerplayStart: 4,
            powerplayEnd: 10,
            deathStart: 41,
            normalSlots: [5, 18, 32, 45],
            matchLimit: 30,
            eventChance: 1,
            eventMinOvers: 0,
            sameEventMinOvers: 0,
            maxActiveLive: 6
        },
        HUNDRED: {
            // The Hundred's first 25 balls are the powerplay. Providers may
            // expose decimal/over-style values, so use a 5-ball-over view
            // when an explicit ball count is unavailable.
            powerplayStart: 3,
            powerplayEnd: 5,
            deathStart: 15,
            normalSlots: [2, 5, 9, 13, 17],
            matchLimit: 20,
            eventChance: 1,
            eventMinOvers: 0,
            sameEventMinOvers: 0,
            maxActiveLive: 5
        },
        TEST: {
            powerplayStart: null,
            powerplayEnd: null,
            deathStart: null,
            normalSlots: [10, 25, 40, 60],
            matchLimit: 40,
            eventChance: 1,
            eventMinOvers: 0,
            sameEventMinOvers: 0,
            maxActiveLive: 7
        }
    };

    return configs[format] || configs.T20;
}

export function currentOverNumber(match){
    const raw =
        match?.currentOver ??
        match?.over ??
        match?.currentInnings?.currentOver ??
        match?.currentInnings?.over ??
        match?.score?.currentOver ??
        match?.score?.over ??
        match?.innings?.currentOver ??
        match?.live?.currentOver;

    const n = Number(raw);
    return Number.isFinite(n) ? n : null;
}

export function currentBallNumber(match){
    const raw =
        match?.currentBall ??
        match?.ball ??
        match?.currentInnings?.currentBall ??
        match?.currentInnings?.ball ??
        match?.score?.currentBall ??
        match?.score?.ball;
    const n = Number(raw);
    return Number.isFinite(n) ? n : null;
}

export function isNormalOverSlot(match){
    const raw = currentOverNumber(match);
    if(raw == null || raw < 0) return false;

    const over = Math.floor(raw);
    const slots = formatConfig(match).normalSlots;

    if(slots.includes(over)) return true;
    if(Number.isInteger(raw) && slots.includes(over - 1)) return true;
    return false;
}

export function selectedOverCheckpoint(match){
    const raw = currentOverNumber(match);
    if(raw == null) return null;

    const over = Math.floor(raw);
    const slots = formatConfig(match).normalSlots;
    if(slots.includes(over)) return over;
    if(Number.isInteger(raw) && slots.includes(over - 1)) return over - 1;
    return null;
}

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
    const event = match?.lastEvent || {};
    const explicit = String(
        event?.type ?? event?.eventType ?? event?.name ?? ""
    ).toUpperCase().trim();
    if(explicit.includes("WICKET")) return "WICKET";
    if(explicit.includes("SIX")) return "SIX";
    if(explicit.includes("FOUR") || explicit.includes("BOUNDARY")) return "FOUR";

    if(event?.wicket || event?.isWicket || event?.dismissal) return "WICKET";
    const runs = Number(event?.runs ?? event?.totalRuns ?? event?.batRuns);
    if(runs === 6) return "SIX";
    if(runs === 4 || event?.isBoundary) return "FOUR";
    return "";
}

export function shouldUseEventPrediction(match, salt = "", chance = null){
    const event = eventKey(match) || eventType(match);
    if(!event) return false;
    const rate = chance == null ? 1 : chance;
    return rate >= 1;
}


/* ==========================================================
   Prediction-safe batter / event helpers
   These helpers only improve prediction input mapping; they do
   not modify Match Service cache behaviour.
========================================================== */

function normalizePlayerObject(value){
    if(!value || typeof value !== "object") return null;
    const name = value.name ?? value.playerName ?? value.batsmanName ??
        value.displayName ?? value.batsman ?? "";
    const id = value.id ?? value.playerId ?? value.batsmanId ??
        value.batId ?? value.player_id ?? name;
    const runs = value.runs ?? value.score ?? value.runsScored ??
        value.batRuns ?? value.batsmanRuns;
    return {
        ...value,
        id,
        playerId: value.playerId ?? id,
        name: name || String(id || "Batter"),
        runs
    };
}

export function currentBatter(match){
    const root = match?.data || match || {};
    const current = root?.currentInnings || root?.currentinnings || root?.current || {};

    const explicit =
        root?.currentBatter || root?.currentbatter ||
        current?.currentBatter || current?.currentbatter ||
        root?.striker || current?.striker ||
        root?.onStrikeBatter || current?.onStrikeBatter ||
        root?.strikerBatter || current?.strikerBatter || null;

    if(explicit && typeof explicit === "object"){
        return normalizePlayerObject(explicit);
    }

    const batters = [
        ...(Array.isArray(root?.currentBatters) ? root.currentBatters : []),
        ...(Array.isArray(root?.batsmen) ? root.batsmen : []),
        ...(Array.isArray(current?.currentBatters) ? current.currentBatters : []),
        ...(Array.isArray(current?.batsmen) ? current.batsmen : [])
    ].filter(Boolean);

    const unique = [];
    const seen = new Set();
    for(const raw of batters){
        const b = normalizePlayerObject(raw);
        if(!b) continue;
        const key = String(b.id || b.name).toLowerCase();
        if(seen.has(key)) continue;
        seen.add(key);
        unique.push(b);
    }

    if(unique.length === 1) return unique[0];

    const marked = unique.find(b => {
        const flag = b?.isStriker ?? b?.isOnStrike ?? b?.onStrike ??
            b?.striker ?? b?.isOnstrike;
        if(flag === true || String(flag).toLowerCase() === "true") return true;
        const role = String(b?.battingStatus ?? b?.status ?? b?.role ?? "").toLowerCase();
        return role.includes("striker") || role === "on strike" || role === "onstrike";
    });
    if(marked) return marked;

    const strikerId = String(
        root?.strikerId ?? root?.strikerID ??
        current?.strikerId ?? current?.strikerID ?? ""
    );
    if(strikerId){
        const byId = unique.find(b =>
            String(b.id ?? b.playerId ?? "").toLowerCase() === strikerId.toLowerCase()
        );
        if(byId) return byId;
    }

    const strikerName = String(
        root?.strikerName ?? current?.strikerName ?? ""
    ).trim().toLowerCase();
    if(strikerName){
        const byName = unique.find(b => String(b.name).trim().toLowerCase() === strikerName);
        if(byName) return byName;
    }

    // If the provider exposes only two batsmen and no striker marker,
    // do not invent a striker. Milestone rules simply wait for the next
    // snapshot that exposes enough information.
    return null;
}

export function difficultySeconds(match, difficulty){
    const format = cricketFormat(match);
    const table = {
        T10: { easy:45, medium:60, hard:75 },
        T20: { easy:45, medium:60, hard:90 },
        ODI: { easy:60, medium:90, hard:120 },
        HUNDRED: { easy:45, medium:60, hard:75 },
        TEST: { easy:60, medium:90, hard:120 }
    };
    const row = table[format] || table.T20;
    const key = String(difficulty || "medium").toLowerCase();
    if(key === "expert") return row.hard;
    return row[key] ?? row.medium;
}

export function milestoneExpiry(){
    // Milestone predictions stay LIVE until the target is reached or the
    // user submits. They are resolved by the result engine, not a timer.
    return null;
}

export function expiry(match, type, difficulty = null){
    const now = Date.now();

    if(type === "MATCH_WINNER" || type === "TOSS_WINNER" || type === "TOTAL_SCORE" || type === "HIGHEST_SCORER"){
        const start = new Date(
            match?.startTime ?? match?.startDate ?? match?.matchStartTime ?? ""
        ).getTime();
        if(Number.isFinite(start) && start > now) return new Date(start);
        return new Date(now + 60 * 1000);
    }

    // Powerplay questions stay open until the powerplay window closes.
    if(type === "POWERPLAY_SCORE"){
        const cfg = formatConfig(match);
        const over = currentOverNumber(match);
        if(cfg.powerplayEnd != null && over != null){
            const completed = Math.floor(over);
            const ballsPerOver = cricketFormat(match) === "HUNDRED" ? 5 : 6;
            const remainingBalls = Math.max(1, Math.ceil((cfg.powerplayEnd - completed) * ballsPerOver));
            return new Date(now + Math.max(45, remainingBalls * 8) * 1000);
        }
    }

    const seconds = difficultySeconds(match, difficulty || "medium");
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
                format === "HUNDRED" ? 6 :
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
    const source =
        Array.isArray(match?.topPlayers) ? match.topPlayers :
        Array.isArray(match?.players) ? match.players :
        Array.isArray(match?.squad) ? match.squad :
        [];

    return source
        .filter(Boolean)
        .map(player => ({
            id: player.id ?? player.playerId ?? player.player_id ?? player.name,
            text: player.name ?? player.playerName ?? player.displayName ?? String(player.id ?? player.playerId ?? "Player")
        }))
        .filter(player => player.id && player.text);
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
    const format = cricketFormat(match);
    const avg = Number(
        match?.expectedPowerplay ??
        match?.powerplayExpected ??
        ({ T10: 25, T20: 48, ODI: 52, HUNDRED: 42, TEST: 0 }[format] ?? 48)
    );

    const safe = Math.max(1, Math.round(avg));
    return [
        { id:"1", text:`0-${Math.max(1, safe-10)}` },
        { id:"2", text:`${Math.max(2, safe-9)}-${safe}` },
        { id:"3", text:`${safe+1}-${safe+10}` },
        { id:"4", text:`${safe+11}+` }
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