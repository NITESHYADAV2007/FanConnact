const express = require("express");

const router = express.Router();

const schedule =
require("../providers/cricbuzz/schedule.provider");


router.get("/international", async (req, res) => {

    try {

        res.json(
            await schedule.getInternational(
                req.query.lastTime
            )
        );

    } catch (err) {

        res.status(500).json({
            success: false,
            error: err.response?.data || err.message
        });

    }

});


router.get("/league", async (req, res) => {

    try {

        res.json(
            await schedule.getLeague(
                req.query.lastTime
            )
        );

    } catch (err) {

        res.status(500).json({
            success: false,
            error: err.response?.data || err.message
        });

    }

});


router.get("/domestic", async (req, res) => {

    try {

        res.json(
            await schedule.getDomestic(
                req.query.lastTime
            )
        );

    } catch (err) {

        res.status(500).json({
            success: false,
            error: err.response?.data || err.message
        });

    }

});


router.get("/women", async (req, res) => {

    try {

        res.json(
            await schedule.getWomen(
                req.query.lastTime
            )
        );

    } catch (err) {

        res.status(500).json({
            success: false,
            error: err.response?.data || err.message
        });

    }

});

module.exports = router;