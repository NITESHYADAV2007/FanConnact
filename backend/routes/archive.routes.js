const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");
const archive = require("../providers/cricbuzz/archive.provider");

/* ==========================
    INTERNATIONAL
========================== */

router.get("/international", async (req, res) => {

    try {

        const lastId = req.query.lastId || "0";

        const data = await cacheManager.getOrCreate(

            `ARCHIVE_INTL_${lastId}`,

            1800,

            () => archive.getInternational(lastId)

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

/* ==========================
        LEAGUE
========================== */

router.get("/league", async (req, res) => {

    try {

        const lastId = req.query.lastId || "0";

        const data = await cacheManager.getOrCreate(

            `ARCHIVE_LEAGUE_${lastId}`,

            1800,

            () => archive.getLeague(lastId)

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

/* ==========================
        DOMESTIC
========================== */

router.get("/domestic", async (req, res) => {

    try {

        const lastId = req.query.lastId || "0";

        const data = await cacheManager.getOrCreate(

            `ARCHIVE_DOMESTIC_${lastId}`,

            1800,

            () => archive.getDomestic(lastId)

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

/* ==========================
        WOMEN
========================== */

router.get("/women", async (req, res) => {

    try {

        const lastId = req.query.lastId || "0";

        const data = await cacheManager.getOrCreate(

            `ARCHIVE_WOMEN_${lastId}`,

            1800,

            () => archive.getWomen(lastId)

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