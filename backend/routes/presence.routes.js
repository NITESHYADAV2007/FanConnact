const express = require("express");

const router = express.Router();

const presence =
require("../presence/presenceManager");

router.post("/watch", (req, res) => {

    const {

        matchId,

        userId

    } = req.body;

    presence.watch(

        matchId,

        userId

    );

    res.json({

        success: true

    });

});

router.post("/heartbeat", (req, res) => {

    const {

        matchId,

        userId

    } = req.body;

    presence.heartbeat(

        matchId,

        userId

    );

    res.json({

        success: true

    });

});

router.post("/leave", (req, res) => {

    const {

        matchId,

        userId

    } = req.body;

    presence.leave(

        matchId,

        userId

    );

    res.json({

        success: true

    });

});

// How many users are currently watching a match/community (live badge).
router.get("/online", (req, res) => {

    const matchId = (req.query.matchId || "").toString();

    res.json({

        matchId,

        count: matchId ? presence.getWatchingCount(matchId) : 0

    });

});

// Total active fans across every watched match/community (hero stat).
router.get("/total", (req, res) => {

    res.json({

        count: presence.getTotalCount()

    });

});

module.exports = router;