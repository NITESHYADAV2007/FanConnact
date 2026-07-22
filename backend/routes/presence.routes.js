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

module.exports = router;