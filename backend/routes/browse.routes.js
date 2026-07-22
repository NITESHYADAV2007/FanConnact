const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");
const browse = require("../providers/cricbuzz/browse.provider");

/* ==========================================
        INTERNATIONAL
========================================== */

router.get("/international", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "BROWSE_INTERNATIONAL",

            86400,

            () => browse.getInternational()

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
        LEAGUE
========================================== */

router.get("/league", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "BROWSE_LEAGUE",

            86400,

            () => browse.getLeague()

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
        DOMESTIC
========================================== */

router.get("/domestic", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "BROWSE_DOMESTIC",

            86400,

            () => browse.getDomestic()

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
        WOMEN
========================================== */

router.get("/women", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "BROWSE_WOMEN",

            86400,

            () => browse.getWomen()

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