const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");
const auction = require("../providers/cricbuzz/auction.provider");

/* ==========================================
            AUCTION SEASONS
========================================== */

router.get("/seasons", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "AUCTION_SEASONS",

            86400,

            () => auction.getSeasons()

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            AUCTION TEAMS
========================================== */

router.get("/teams", async (req, res) => {

    try {

        const currency = req.query.currency || "";
        const tournament = req.query.tournament || "";
        const year = req.query.year || "";

        const key =
            `AUCTION_TEAMS_${currency}_${tournament}_${year}`;

        const data = await cacheManager.getOrCreate(

            key,

            3600,

            () => auction.getTeams(

                currency,

                tournament,

                year

            )

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            COMPLETED AUCTION
========================================== */

router.get("/completed", async (req, res) => {

    try {

        const currency = req.query.currency || "";
        const tournament = req.query.tournament || "";
        const year = req.query.year || "";

        const key =
            `AUCTION_COMPLETED_${currency}_${tournament}_${year}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => auction.getCompleted(

                currency,

                tournament,

                year

            )

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            UPCOMING AUCTION
========================================== */

router.get("/upcoming", async (req, res) => {

    try {

        const currency = req.query.currency || "";
        const tournament = req.query.tournament || "";
        const year = req.query.year || "";

        const key =
            `AUCTION_UPCOMING_${currency}_${tournament}_${year}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => auction.getUpcoming(

                currency,

                tournament,

                year

            )

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            LIVE AUCTION
========================================== */

router.get("/live", async (req, res) => {

    try {

        const currency = req.query.currency || "";
        const tournament = req.query.tournament || "";
        const year = req.query.year || "";

        const key =
            `AUCTION_LIVE_${currency}_${tournament}_${year}`;

        const data = await cacheManager.getOrCreate(

            key,

            30,

            () => auction.getLive(

                currency,

                tournament,

                year

            )

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

module.exports = router;