const cacheManager = require("../cache/cacheManager");
const cache = require("../cache/cacheMiddleware");
const express = require("express");
const router = express.Router();

const { matches } = require("../providers/cricbuzz");

/* ===========================
      LIVE MATCHES
=========================== */
router.get("/live", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "LIVE_MATCHES",

            30,

            () => matches.getLiveMatches()

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch live matches"

        });

    }

});

/* ===========================
      UPCOMING MATCHES
=========================== */

router.get("/upcoming", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "UPCOMING",

            300,

            () => matches.getUpcomingMatches()

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch upcoming matches"

        });

    }

});

/* ===========================
      RECENT MATCHES
=========================== */

router.get("/recent", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "RECENT",

            600,

            () => matches.getRecentMatches()

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch recent matches"

        });

    }

});


/* ===========================
      MATCH INFO
=========================== */
router.get("/:matchId", async (req, res) => {

    try {

        const key = `MATCH_INFO_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            30,

            () => matches.getMatchInfo(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch match info"

        });

    }

});


/* ===========================
      COMMENTARY
=========================== */

router.get("/:matchId/commentary", async (req, res) => {

    try {

        const key = `COMMENTARY_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            15,

            () => matches.getCommentary(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch commentary"

        });

    }

});

/* ===========================
      H COMMENTARY
=========================== */
router.get("/:matchId/hcommentary", async (req, res) => {

    try {

        const key = `HCOMMENTARY_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            15,

            () => matches.getHCommentary(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch hcommentary"

        });

    }

});

/* ===========================
      SCORECARD
=========================== */

router.get("/:matchId/scorecard", async (req, res) => {

    try {

        const key = `SCORECARD_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            60,

            () => matches.getScorecard(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch scorecard"

        });

    }

});
/* ===========================
      PLAYING XI
=========================== */
router.get("/:matchId/squads", async (req, res) => {

    try {

        const key = `SQUADS_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => matches.getSquads(req.params.matchId)

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
/* ===========================
      OVERS
=========================== */

router.get("/:matchId/overs", async (req, res) => {

    try {

        const key = `OVERS_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            15,

            () => matches.getOvers(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch overs"

        });

    }

});
/* ===========================
      OVER DETAILS
=========================== */
router.get("/:matchId/overs/details", async (req, res) => {

    try {

        const key = `OVER_DETAILS_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            15,

            () => matches.getOversDetails(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success: false,

            message: "Unable to fetch over details"

        });

    }

});


/* ===========================
      HIGHLIGHTS
=========================== */
router.get("/:matchId/highlights", async (req, res) => {

    try {

        const key = `HIGHLIGHTS_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => matches.getHighlights(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,

            message:"Unable to fetch highlights"

        });

    }

});

/* ===========================
      LEANBACK
=========================== */
router.get("/:matchId/leanback", async (req, res) => {

    try {

        const key = `LEANBACK_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => matches.getLeanback(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,

            message:"Unable to fetch leanback"

        });

    }

});

/* ===========================
      H LEANBACK
=========================== */
router.get("/:matchId/hleanback", async (req, res) => {

    try {

        const key = `HLEANBACK_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => matches.getHLeanback(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,

            message:"Unable to fetch hleanback"

        });

    }

});

/* ===========================
      OVERS GRAPH
=========================== */
router.get("/:matchId/oversGraph", async (req, res) => {

    try {

        const key = `OVERS_GRAPH_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => matches.getOversGraph(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,

            message:"Unable to fetch overs graph"

        });

    }

});


/* ===========================
      BALL GRAPH
=========================== */

router.get("/:matchId/ballsGraph", async (req, res) => {

    try {

        const key = `BALLS_GRAPH_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => matches.getBallsGraph(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,

            message:"Unable to fetch balls graph"

        });

    }

});

/* ===========================
      PARTNERSHIP GRAPH
=========================== */

router.get("/:matchId/partnershipGraph", async (req, res) => {

    try {

        const key = `PARTNERSHIP_GRAPH_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            300,

            () => matches.getPartnershipGraph(req.params.matchId)

        );

        res.json(data);

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,

            message:"Unable to fetch partnership graph"

        });

    }

});

module.exports = router;