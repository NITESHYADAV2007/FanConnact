const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class BrowseProvider {

    async getInternational() {

        const { data } =
        await api.get(

            endpoints.BROWSE_INTERNATIONAL

        );

        return data;

    }

    async getLeague() {

        const { data } =
        await api.get(

            endpoints.BROWSE_LEAGUE

        );

        return data;

    }

    async getDomestic() {

        const { data } =
        await api.get(

            endpoints.BROWSE_DOMESTIC

        );

        return data;

    }

    async getWomen() {

        const { data } =
        await api.get(

            endpoints.BROWSE_WOMEN

        );

        return data;

    }

}

module.exports = new BrowseProvider();