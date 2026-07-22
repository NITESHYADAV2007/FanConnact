const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");
const news = require("../providers/cricbuzz/news.provider");

/* ==========================================
            Latest News
========================================== */

router.get("/", async (req, res) => {

    try {

        const key = `NEWS_LATEST_${req.query.lastId || "0"}`;

        const data = await cacheManager.getOrCreate(

            key,

            1800,

            () => news.getLatest(req.query.lastId)

        );

        res.json(data);

    } catch (err) {

        console.error(err.response?.data || err.message);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            Premium
========================================== */

router.get("/premium", async (req, res) => {

    try {

        const key = `NEWS_PREMIUM_${req.query.lastId || "0"}`;

        const data = await cacheManager.getOrCreate(

            key,

            1800,

            () => news.getPremium(req.query.lastId)

        );

        res.json(data);

    } catch (err) {

        console.error(err.response?.data || err.message);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            Topics
========================================== */

router.get("/topics", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "NEWS_TOPICS",

            86400,

            () => news.getTopics()

        );

        res.json(data);

    } catch (err) {

        console.error(err.response?.data || err.message);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            Topic Details
========================================== */

router.get("/topics/:id", async (req, res) => {

    try {

        const key = `NEWS_TOPIC_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => news.getTopic(req.params.id)

        );

        res.json(data);

    } catch (err) {

        console.error(err.response?.data || err.message);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            Categories
========================================== */

router.get("/categories", async (req, res) => {

    try {

        const data = await cacheManager.getOrCreate(

            "NEWS_CATEGORIES",

            86400,

            () => news.getCategories()

        );

        res.json(data);

    } catch (err) {

        console.error(err.response?.data || err.message);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            Category News
========================================== */

router.get("/categories/:id", async (req, res) => {

    try {

        const key = `NEWS_CATEGORY_${req.params.id}_${req.query.lastId || "0"}`;

        const data = await cacheManager.getOrCreate(

            key,

            1800,

            () => news.getCategory(

                req.params.id,

                req.query.lastId

            )

        );

        res.json(data);

    } catch (err) {

        console.error(err.response?.data || err.message);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

/* ==========================================
            News Details
========================================== */

router.get("/:id", async (req, res) => {

    try {

        const key = `NEWS_DETAIL_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => news.getDetail(req.params.id)

        );

        res.json(data);

    } catch (err) {

        console.error(err.response?.data || err.message);

        res.status(500).json({

            success: false,

            error: err.response?.data || err.message

        });

    }

});

module.exports = router;