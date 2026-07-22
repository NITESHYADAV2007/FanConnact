const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");

class NewsJob {

    async run() {

        await Promise.all([

            this.refreshLatest(),
            this.refreshPremium(),
            this.refreshTopics(),
            this.refreshCategories()

        ]);

    }

    async refreshLatest() {

        try {

            const data = await providers.news.getLatest();

            cache.set("news:latest", data, 300);

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshPremium() {

        try {

            const data = await providers.news.getPremium();

            cache.set("news:premium", data, 900);

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshTopics() {

        try {

            const data = await providers.news.getTopics();

            cache.set("news:topics", data, 1800);

        } catch (e) {

            console.error(e.message);

        }

    }

    async refreshCategories() {

        try {

            const data = await providers.news.getCategories();

            cache.set("news:categories", data, 1800);

        } catch (e) {

            console.error(e.message);

        }

    }

}

module.exports = new NewsJob();