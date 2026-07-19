const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");
const provider = require("../providers/cricbuzz/matchcenter.provider");

/* ===============================
            HOME
================================ */

router.get("/home", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "MCENTER_HOME",

            30,

            () => provider.getHome()

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

/* ===============================
         MATCH INFO
================================ */

router.get("/:matchId", async (req, res) => {

    try {

        const key = `MCENTER_${req.params.matchId}`;

        const data = await cacheManager.getOrCreate(

            key,

            30,

            () => provider.getMatchInfo(req.params.matchId)

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