const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class ArchiveProvider {

    async getInternational(lastId = 8686) {

        const { data } = await api.get(

            endpoints.ARCHIVE_INTERNATIONAL(lastId)

        );

        return data;

    }

    async getLeague(lastId = 7492) {

        const { data } = await api.get(

            endpoints.ARCHIVE_LEAGUE(lastId)

        );

        return data;

    }

    async getDomestic(lastId = 7441) {

        const { data } = await api.get(

            endpoints.ARCHIVE_DOMESTIC(lastId)

        );

        return data;

    }

    async getWomen(lastId = 8732) {

        const { data } = await api.get(

            endpoints.ARCHIVE_WOMEN(lastId)

        );

        return data;

    }

}

module.exports = new ArchiveProvider();