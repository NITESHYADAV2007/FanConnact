const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");

const players =
require("../providers/cricbuzz/players.provider");

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

module.exports = router;