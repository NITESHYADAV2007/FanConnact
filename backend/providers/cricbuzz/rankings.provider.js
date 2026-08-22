const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");
const playersProvider = require("./players.provider");

class RankingsProvider {

    normalize(data) {

        let list =
            data?.rank ||
            data?.rankings ||
            data?.player ||
            data?.players ||
            data?.values ||
            data?.data ||
            [];

        if (!Array.isArray(list)) list = [];

        return list.map((p, index) => ({

            rank:
                p.rank ??
                p.position ??
                index + 1,

            playerId:
                p.id ??
                p.playerId ??
                p.player_id ??
                p.pid ??
                null,

            name:
                p.name ??
                p.player ??
                p.fullName ??
                "Unknown",

            country:
                p.country ??
                p.team ??
                p.nation ??
                "",

            rating:
                p.rating ??
                p.points ??
                0,

            matches:
                p.matches ??
                p.mat ??
                0,

            runs:
                p.runs ??
                0,

            wkts:
                p.wkts ??
                p.wickets ??
                0,

            avg:
                p.avg ??
                p.average ??
                0,

            econ:
                p.econ ??
                p.economy ??
                p.sr ??
                0

        }));

    }

   
    async getBatsmen(format, women) {

    const { data } =
        await api.get(
            endpoints.RANKING_BATSMEN(format, women)
        );

    const rankings = this.normalize(data);

    for (const player of rankings) {

        try {

            let id = player.playerId;

            if (!id && player.name) {
                id = await playersProvider.resolvePlayerId(player.name);
            }

            if (!id) continue;

            player.playerId = id;

            try {
                const profile = await playersProvider.getPlayerProfile(id);
                player.profile = profile;
                player.image =
                    profile?.basic?.image ||
                    profile?.image ||
                    player.image ||
                    '';
            } catch (e) {
                console.log("Profile Merge Failed:", player.name);
            }

            try {
                const stats = await playersProvider.getBattingSummary(id);
                player.matches = stats.matches;
                player.runs = stats.runs;
                player.avg = stats.avg;
                player.econ = stats.strikeRate;
            } catch (e) {
                console.log("Stats Merge Failed:", player.name);
            }

        } catch (e) {

            console.log("Player Merge Failed:", player.name);

        }

    }

    return rankings;

}

   async getBowlers(format, women) {

    const { data } =
        await api.get(
            endpoints.RANKING_BOWLERS(format, women)
        );

    const rankings = this.normalize(data);

    for (const player of rankings) {

        try {

            let id = player.playerId;

            if (!id && player.name) {
                id = await playersProvider.resolvePlayerId(player.name);
            }

            if (!id) continue;

            player.playerId = id;

            try {
                const profile = await playersProvider.getPlayerProfile(id);
                player.profile = profile;
                player.image =
                    profile?.basic?.image ||
                    profile?.image ||
                    player.image ||
                    '';
            } catch (e) {
                console.log("Profile Merge Failed:", player.name);
            }

            try {
                const stats = await playersProvider.getBowlingSummary(id);
                player.matches = stats.matches;
                player.wkts = stats.wickets;
                player.econ = stats.economy;
                player.avg = stats.average;
            } catch (e) {
                console.log("Stats Merge Failed:", player.name);
            }

        } catch (e) {

            console.log("Player Merge Failed:", player.name);

        }

    }

    return rankings;

}

async getAllRounders(format, women) {

    const { data } =
        await api.get(
            endpoints.RANKING_ALLROUNDERS(format, women)
        );

    const rankings = this.normalize(data);

    for (const player of rankings) {

        try {

            let id = player.playerId;

            if (!id && player.name) {
                id = await playersProvider.resolvePlayerId(player.name);
            }

            if (!id) continue;

            player.playerId = id;

            try {
                const profile = await playersProvider.getPlayerProfile(id);
                player.profile = profile;
                player.image =
                    profile?.basic?.image ||
                    profile?.image ||
                    player.image ||
                    '';
            } catch (e) {
                console.log("Profile Merge Failed:", player.name);
            }

            try {
                const bat = await playersProvider.getBattingSummary(id);
                player.matches = bat.matches;
                player.runs = bat.runs;
                player.avg = bat.avg;
            } catch (e) {
                console.log("Batting Merge Failed:", player.name);
            }

            try {
                const bowl = await playersProvider.getBowlingSummary(id);
                player.wkts = bowl.wickets;
                player.econ = bowl.economy;
            } catch (e) {
                console.log("Bowling Merge Failed:", player.name);
            }

        } catch (e) {

            console.log("Player Merge Failed:", player.name);

        }

    }

    return rankings;

}
// ===============================
// TEAM RANKINGS NORMALIZER
// ===============================
normalizeTeams(data) {

    let list =
        data?.rank ||
        data?.rankings ||
        data?.teams ||
        data?.values ||
        data?.data ||
        [];

    if (!Array.isArray(list)) {
        list = [];
    }

    // --------------------------------
    // TEAM -> COUNTRY FLAG CODE
    // --------------------------------
    const FLAG_CODES = {
        "Australia": "au",
        "South Africa": "za",
        "New Zealand": "nz",
        "India": "in",
        "England": "gb-eng",
        "Sri Lanka": "lk",
        "Pakistan": "pk",
        "West Indies": "wi",
        "Bangladesh": "bd",
        "Zimbabwe": "zw",

        "Afghanistan": "af",
        "Ireland": "ie",
        "Scotland": "gb-sct",
        "Nepal": "np",
        "Netherlands": "nl",
        "Namibia": "na",
        "United Arab Emirates": "ae",
        "USA": "us",
        "United States": "us",
        "Oman": "om",
        "Canada": "ca",
        "Papua New Guinea": "pg",
        "Uganda": "ug",
        "Jersey": "je",
        "Hong Kong": "hk",
        "Italy": "it",
        "Germany": "de",
        "Kenya": "ke",
        "Malaysia": "my",
        "Tanzania": "tz",

                "West Indies": "wi",

        "United States of America": "us",
        "United States": "us",

        "Cayman Islands": "ky",
        "Bermuda": "bm",
        "Saudi Arabia": "sa",
        "Guernsey": "gg",

        "Denmark": "dk",
        "Portugal": "pt",
        "Germany": "de",
        "Japan": "jp",
        "Singapore": "sg",
        "Austria": "at",
        "Sweden": "se",
        "Belgium": "be",
        "Finland": "fi",
        "Norway": "no",
        "Argentina": "ar",

        "Nigeria": "ng",
        "Kenya": "ke",
        "Tanzania": "tz",

        "Oman": "om",
        "Namibia": "na",
        "Nepal": "np",
        "Ireland": "ie",
        "Netherlands": "nl",
        "Scotland": "gb-sct",

        // Women
        "United States of America Women": "us",
        "Cayman Islands Women": "ky",
        "Bermuda Women": "bm",
        "Thailand Women": "th",
        "Japan Women": "jp",
        "Singapore Women": "sg",
        "Nigeria Women": "ng",
        "Uganda Women": "ug",
        "Kenya Women": "ke",
        "Tanzania Women": "tz",
        "Namibia Women": "na",
        "Nepal Women": "np",
        "Ireland Women": "ie",
        "Netherlands Women": "nl",
        "Scotland Women": "gb-sct",
        "Oman Women": "om",

        // Women
        "Australia Women": "au",
        "England Women": "gb-eng",
        "India Women": "in",
        "South Africa Women": "za",
        "New Zealand Women": "nz",
        "Sri Lanka Women": "lk",
        "Pakistan Women": "pk",
        "West Indies Women": "wi",
        "Bangladesh Women": "bd",
        "Ireland Women": "ie",
        "Scotland Women": "gb-sct",
        "Zimbabwe Women": "zw",
        "United Arab Emirates Women": "ae",
        "Thailand Women": "th",
        "Papua New Guinea Women": "pg"
    };


    // --------------------------------
    // PREVIOUS RANK CACHE
    // --------------------------------
    const cacheKey = "TEAM_RANKING_PREVIOUS";

    let previousRanks = {};

    try {
        const cached = this.cache?.get?.(cacheKey);

        if (cached) {
            previousRanks =
                typeof cached === "string"
                    ? JSON.parse(cached)
                    : cached;
        }
    } catch (e) {
        previousRanks = {};
    }


    const currentRanks = {};


    const rankings = list.map((p, index) => {

        // -----------------------------
        // TEAM OBJECT
        // -----------------------------
        const team =
            typeof p.team === "object"
                ? p.team
                : null;


        // -----------------------------
        // TEAM NAME
        // -----------------------------
        const teamName =
            typeof p.team === "string"
                ? p.team
                : p.name ||
                  p.teamName ||
                  team?.name ||
                  team?.displayName ||
                  "Unknown";


        // -----------------------------
        // RANK
        // -----------------------------
        const rank = Number(
            p.rank ??
            p.position ??
            index + 1
        );


        currentRanks[teamName] = rank;


        // -----------------------------
        // CODE
        // -----------------------------
        const code =
            p.code ||
            p.abbreviation ||
            p.teamCode ||
            team?.code ||
            team?.abbreviation ||
            FLAG_CODES[teamName] ||
            "";


        // -----------------------------
        // FLAG
        // -----------------------------
        let flag =
            p.flag ||
            p.logo ||
            p.image ||
            p.teamLogo ||
            team?.flag ||
            team?.logo ||
            "";


       if (!flag && FLAG_CODES[teamName]) {

    if (teamName === "West Indies") {

        flag =
            "https://commons.wikimedia.org/wiki/Special:Redirect/file/West%20Indies%20Cricket%20Flag.png";

    } else {

        flag =
            `https://flagcdn.com/w40/${FLAG_CODES[teamName]}.png`;

    }
}

        // -----------------------------
        // MATCHES
        // -----------------------------
        const matches =
            p.matches ??
            p.mat ??
            p.played ??
            null;


        // -----------------------------
        // WINS
        // -----------------------------
        const wins =
            p.wins ??
            p.win ??
            p.won ??
            p.wonMatches ??
            p.stats?.wins ??
            p.stats?.won ??
            null;


        // -----------------------------
        // WIN %
        // -----------------------------
        let winPct =
            p.winPct ??
            p.winPercentage ??
            p.winPercent ??
            p.winRate ??
            p.stats?.winPct ??
            p.stats?.winPercentage ??
            null;


        if (
            winPct == null &&
            wins != null &&
            matches != null &&
            Number(matches) > 0
        ) {
            winPct =
                (Number(wins) / Number(matches)) * 100;
        }


        // -----------------------------
        // TREND
        // -----------------------------
        let trend = null;
let trendVal = null;


        // -----------------------------
        // PREVIOUS RANK -> TREND
        // -----------------------------
        if (
            !trend &&
            previousRanks[teamName] != null
        ) {

            const previousRank =
                Number(previousRanks[teamName]);

            const change =
                previousRank - rank;


            if (change > 0) {

                trend = "up";
                trendVal = change;

            }
            else if (change < 0) {

                trend = "down";
                trendVal = Math.abs(change);

            }
            else {

                trend = "neutral";
                trendVal = 0;

            }
        }


        // -----------------------------
        // RETURN NORMALIZED TEAM
        // -----------------------------
        return {

            rank,

            team: teamName,

            code,

            flag,

            matches,

            wins,

            winPct,

            rating:
                p.rating ??
                p.points ??
                p.score ??
                0,

            points:
                p.points ??
                0,

            trend,

            trendVal,

            lastUpdatedOn:
                p.lastUpdatedOn ??
                null,

            imageId:
                p.imageId ??
                null

        };

    });


    // --------------------------------
    // SAVE CURRENT RANKS
    // --------------------------------
    try {

        if (this.cache?.set) {

            this.cache.set(
                cacheKey,
                JSON.stringify(currentRanks)
            );

        }

    } catch (e) {

        // cache unavailable
    }


    return rankings;
}


   async getTeams(format, women) {

    const { data } = await api.get(
        endpoints.RANKING_TEAMS(format, women)
    );

    console.log("REAL TEAM RANKING API =", data);

    return this.normalizeTeams(data);
}

}

module.exports = new RankingsProvider();