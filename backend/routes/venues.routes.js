const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");
const venues = require("../providers/cricbuzz/venues.provider");

/* ==========================================
            VENUE INFO
========================================== */

router.get("/:id", async (req, res) => {

    try {

        const key = `VENUE_INFO_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => venues.getVenue(req.params.id)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch venue"

        });

    }

});

/* ==========================================
            VENUE MATCHES
========================================== */

router.get("/:id/matches", async (req, res) => {

    try {

        const key = `VENUE_MATCHES_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            1800,

            () => venues.getVenueMatches(req.params.id)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch venue matches"

        });

    }

});

/* ==========================================
            VENUE STATS
========================================== */

router.get("/:id/stats", async (req, res) => {

    try {

        const key = `VENUE_STATS_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => venues.getVenueStats(req.params.id)

        );

        res.json(data);

    }

    catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch venue stats"

        });

    }

});

module.exports = router;