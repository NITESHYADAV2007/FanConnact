const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class NewsProvider {

    async getLatest(lastId = 132054) {

        const { data } = await api.get(
            endpoints.LATEST_NEWS(lastId)
        );

        return data;
    }

    async getDetail(id) {

        const { data } = await api.get(
            endpoints.NEWS_DETAIL(id)
        );

        return data;
    }

    async getPremium(lastId = 129328) {

        const { data } = await api.get(
            endpoints.PREMIUM_NEWS(lastId)
        );

        return data;
    }

    async getTopics() {

        const { data } = await api.get(
            endpoints.NEWS_TOPICS
        );

        return data;
    }

    async getTopic(id) {

        const { data } = await api.get(
            endpoints.NEWS_TOPIC(id)
        );

        return data;
    }

    async getCategories() {

        const { data } = await api.get(
            endpoints.NEWS_CATEGORY
        );

        return data;
    }

    async getCategory(id,lastId=114370) {

        const { data } = await api.get(
            endpoints.NEWS_CATEGORY_DETAIL(
                id,
                lastId
            )
        );

        return data;
    }

}

module.exports = new NewsProvider();