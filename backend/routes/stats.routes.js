const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");
const stats = require("../providers/cricbuzz/stats.provider");

/* ==========================================
            STATS LIST
========================================== */

router.get("/", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "STATS_LIST",

            86400,

            () => stats.getStatsList()

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
            STATS DETAILS
========================================== */

router.get("/:id", async (req, res) => {

    try {

        const {

            statsType = "",

            opponent = "",

            year = "",

            team = "",

            matchType = ""

        } = req.query;

        const key =
            `STATS_${req.params.id}_${statsType}_${opponent}_${year}_${team}_${matchType}`;

        const data = await cacheManager.getOrCreate(

            key,

            3600,

            () => stats.getStats(

                req.params.id,

                statsType,

                opponent,

                year,

                team,

                matchType

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