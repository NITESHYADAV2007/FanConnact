const express = require("express");
const router = express.Router();

const rankings =
require("../providers/cricbuzz/rankings.provider");

const cacheManager = require("../cache/cacheManager");

router.get("/batsmen", async (req, res) => {

    try {

        const format = req.query.format || "t20";
        const women = req.query.women || 0;

        const key = `RANKINGS_BATSMEN_${format}_${women}`;

        const data = await cacheManager.getOrCreate(

            key,

            3600,

            () => rankings.getBatsmen(format, women)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch batsmen rankings"

        });

    }

});


router.get("/bowlers", async (req, res) => {

    try {

        const format = req.query.format || "t20";
        const women = req.query.women || 0;

        const key = `RANKINGS_BOWLERS_${format}_${women}`;

        const data = await cacheManager.getOrCreate(

            key,

            3600,

            () => rankings.getBowlers(format, women)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch bowlers rankings"

        });

    }

});

router.get("/allrounders", async (req, res) => {

    try {

        const format = req.query.format || "t20";
        const women = req.query.women || 0;

        const key = `RANKINGS_ALLROUNDERS_${format}_${women}`;

        const data = await cacheManager.getOrCreate(

            key,

            3600,

            () => rankings.getAllRounders(format, women)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch all-rounders rankings"

        });

    }

});
router.get("/teams", async (req, res) => {

    try {

        const format = req.query.format || "t20";
        const women = req.query.women || 0;

        const key = `RANKINGS_TEAMS_${format}_${women}`;

        const data = await cacheManager.getOrCreate(

            key,

            3600,

            () => rankings.getTeams(format, women)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch team rankings"

        });

    }

});

module.exports = router;