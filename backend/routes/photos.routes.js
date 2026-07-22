const express = require("express");
const router = express.Router();

const cacheManager = require("../cache/cacheManager");
const photos = require("../providers/cricbuzz/photos.provider");

/* ==========================================
            PHOTOS LIST
========================================== */

router.get("/", async (req, res) => {

    try {

        const lastId = req.query.lastId || "0";

        const key = `PHOTOS_${lastId}`;

        const data = await cacheManager.getOrCreate(

            key,

            1800,

            () => photos.getPhotos(lastId)

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
            PHOTO DETAILS
========================================== */

router.get("/:id", async (req, res) => {

    try {

        const key = `PHOTO_${req.params.id}`;

        const data = await cacheManager.getOrCreate(

            key,

            86400,

            () => photos.getPhoto(req.params.id)

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