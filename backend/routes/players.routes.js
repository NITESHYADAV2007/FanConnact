const express = require("express");
const router = express.Router();
const rankingsProvider =
require("../providers/cricbuzz/rankings.provider");

const cacheManager = require("../cache/cacheManager");

const players =
require("../providers/cricbuzz/players.provider");

const { normalizePlayer } =
require("../normalizers/playerNormalizer");


/* ==========================================
        TRENDING PLAYERS
========================================== */

router.get("/trending", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "PLAYERS_TRENDING",

            1800,

            () => players.getTrendingPlayers()

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch players"

        });

    }

});

/* ==========================================
        SEARCH PLAYERS
========================================== */

router.get("/search", async (req, res) => {

    try {

        const search = (req.query.name || "").trim();

        const key = `PLAYER_SEARCH_${search.toLowerCase()}`;

        const data = await cacheManager.getOrCreate(

            key,

            900,

            () => players.searchPlayers(search)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Search failed"

        });

    }

});

router.get(
"/resolve/:name",

async (req,res)=>{

try{

const id=

await players.resolvePlayerId(
req.params.name

);

if(!id){

return res.status(404).json({

success:false

});

}

res.json({

success:true,

id

});

}

catch(err){

res.status(500).json({

success:false,

message:err.message

});

}

});
/* ==========================================
        PLAYER INFO
========================================== */

router.get("/:id", async (req, res) => {

    try {

        const key = `PLAYER_INFO_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            3600,

            () => players.getPlayerInfo(req.params.id)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch player"

        });

    }

});


/* ==========================================
        PLAYER BATTING
========================================== */

router.get("/:id/batting", async (req, res) => {

    try {

        const key = `PLAYER_BATTING_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => players.getPlayerBatting(req.params.id)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch batting stats"

        });

    }

});

/* ==========================================
        PLAYER BOWLING
========================================== */

router.get("/:id/bowling", async (req, res) => {

    try {

        const key = `PLAYER_BOWLING_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => players.getPlayerBowling(req.params.id)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch bowling stats"

        });

    }

});

/* ==========================================
        PLAYER CAREER
========================================== */

router.get("/:id/career", async (req, res) => {

    try {

        const key = `PLAYER_CAREER_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => players.getPlayerCareer(req.params.id)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch career"

        });

    }

});

/* ==========================================
        PLAYER NEWS
========================================== */

router.get("/:id/news", async (req, res) => {

    try {

        const key = `PLAYER_NEWS_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            1800,

            () => players.getPlayerNews(req.params.id)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch player news"

        });

    }

});

router.get("/:id/profile", async (req, res) => {

    try {

    const { id } = req.params;

    const key = `PLAYER_PROFILE_${id}`;

    const player = await cacheManager.getOrCreate(

        key,

        3600,

        async () => {

           const [

info,

batting,

bowling,

career,

news,

profile

] = await Promise.allSettled([

players.getPlayerInfo(id),

players.getPlayerBatting(id),

players.getPlayerBowling(id),

players.getPlayerCareer(id),

players.getPlayerNews(id),

players.getPlayerProfile(id)

]);

const playerData = {

info:
info.status==="fulfilled"
?info.value:{},

batting:
batting.status==="fulfilled"
?batting.value:{},

bowling:
bowling.status==="fulfilled"
?bowling.value:{},

career:
career.status==="fulfilled"
?career.value:{},

news:
news.status==="fulfilled"
?news.value:[],

profile:
profile.status==="fulfilled"
?profile.value:{}

};
        const player = normalizePlayer(playerData);

player.profile = playerData.profile || {};

player.rank =
    player.profile.rank ||
    player.profile.worldRank ||
    player.profile.position ||
    null;

player.rating =
    player.profile.rating ||
    player.profile.points ||
    player.profile.value ||
    null;

player.ranking = {
    rank: player.rank,
    rating: player.rating
};

// Recent matches — merge batting & bowling rows from the raw PLAYER_INFO
// payload by match id: {id, batting, bowling, opponent, format, date}
const recent = [];
const rawInfo = playerData.info || {};
const batRows = (rawInfo.recentBatting && Array.isArray(rawInfo.recentBatting.rows)) ? rawInfo.recentBatting.rows : [];
const bowlRows = (rawInfo.recentBowling && Array.isArray(rawInfo.recentBowling.rows)) ? rawInfo.recentBowling.rows : [];
const bowlById = new Map();
for (const b of bowlRows) {
    const v = (b && b.values) ? b.values : [];
    if (v[0]) bowlById.set(String(v[0]), b);
}
for (const b of batRows) {
    const v = (b && b.values) ? b.values : [];
    if (!v[0]) continue;
    const bw = bowlById.get(String(v[0]));
    const bwv = (bw && bw.values) ? bw.values : [];
    recent.push({
        id: String(v[0]),
        batting: v[1] || "",
        opponent: v[2] || "",
        format: v[3] || "",
        date: v[4] || "",
        bowling: bwv[1] || "",
        url: (b.followUpLinkText || b.followUpLink || "") || ""
    });
}
player.recent = recent;

return player;

        }

    );

    res.json(player);

}

    catch(err){

        console.error(err);

        res.status(500).json({

            success:false,

            message:"Failed to load player profile."

        });

    }

});

module.exports = router;