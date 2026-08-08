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

router.get("/cricket/:key", async (req, res) => {
  try {
    const key = req.params.key;

    const [format, role, gender] = key.split("_");

    const women = gender === "women" ? 1 : 0;

    const cacheKey = `CRICKET_${format}_${role}_${women}`;

    const players = await cacheManager.getOrCreate(

      cacheKey,

      3600, // 1 Hour Cache

      async () => {

    let rankingsData = [];

    switch (role) {

        case "bat":

            rankingsData =
                await rankings.getBatsmen(
                    format,
                    women
                );

            break;

        case "bowl":

            rankingsData =
                await rankings.getBowlers(
                    format,
                    women
                );

            break;

        case "ar":

            rankingsData =
                await rankings.getAllRounders(
                    format,
                    women
                );

            break;

        default:

            rankingsData = [];

    }

    return rankingsData;

}

    );
res.json({

    success: true,

    source: "icc",

    total:

        Array.isArray(players)

            ? players.length

            : 0,

    players:

        Array.isArray(players)

            ? players

            : [],

    cached: true,

    _lastSync: new Date().toISOString()

});

  } catch (err) {

    console.error(err);

    res.status(500).json({
      success: false,
      message: "Unable to fetch rankings"
    });

  }
});
module.exports = router;