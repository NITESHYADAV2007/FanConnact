const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");
const { series } = require("../providers/cricbuzz");

/* ==========================================
            SERIES MATCHES
========================================== */

router.get("/:seriesId", async (req, res) => {

    try {

        const key = `SERIES_MATCHES_${req.params.seriesId}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => series.getSeriesMatches(req.params.seriesId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch series"

        });

    }

});

/* ==========================================
            POINTS TABLE
========================================== */

router.get("/:seriesId/points-table", async (req, res) => {

    try {

        const key = `SERIES_POINTS_${req.params.seriesId}`;

        const data = await cacheManager.getOrCreate(

            key,

            600,

            () => series.getPointsTable(req.params.seriesId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch points table"

        });

    }

});

/* ==========================================
            SQUADS
========================================== */

router.get("/:seriesId/squads", async (req, res) => {

    try {

        const key = `SERIES_SQUADS_${req.params.seriesId}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => series.getSquads(req.params.seriesId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch squads"

        });

    }

});

/* ==========================================
            SQUAD DETAILS
========================================== */

router.get("/:seriesId/squads/:squadId", async (req, res) => {

    try {

        const key = `SERIES_SQUAD_${req.params.seriesId}_${req.params.squadId}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => series.getSquadDetails(

                req.params.seriesId,

                req.params.squadId

            )

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch squad details"

        });

    }

});

/* ==========================================
            SERIES STATS
========================================== */

router.get("/:seriesId/stats", async (req, res) => {

    try {

        const type = req.query.type || "mostRuns";

        const key = `SERIES_STATS_${req.params.seriesId}_${type}`;

        const data = await cacheManager.getOrCreate(

            key,

            3600,

            () => series.getStats(

                req.params.seriesId,

                type

            )

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch stats"

        });

    }

});

/* ==========================================
            VENUES
========================================== */

router.get("/:seriesId/venues", async (req, res) => {

    try {

        const key = `SERIES_VENUES_${req.params.seriesId}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => series.getVenues(req.params.seriesId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch venues"

        });

    }

});

/* ==========================================
            SERIES NEWS
========================================== */

router.get("/:seriesId/news", async (req, res) => {

    try {

        const key = `SERIES_NEWS_${req.params.seriesId}`;

        const data = await cacheManager.getOrCreate(

            key,

            1800,

            () => series.getNews(req.params.seriesId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch news"

        });

    }

});

module.exports = router;