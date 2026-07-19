const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class PhotosJob {

    async run() {

        try {

            const data = await providers.photos.getPhotos();

            cache.set("photos:list", data, 1800);

        } catch (e) {

            console.error(e.message);

        }

    }

}

module.exports = new PhotosJob();