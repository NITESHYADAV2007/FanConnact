const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class VenuesProvider {

    async getVenue(id) {

        const { data } =
        await api.get(endpoints.VENUE_INFO(id));

        return data;

    }

    async getVenueMatches(id) {

        const { data } =
        await api.get(endpoints.VENUE_MATCHES(id));

        return data;

    }

    async getVenueStats(id) {

        const { data } =
        await api.get(endpoints.VENUE_STATS(id));

        return data;

    }

}

module.exports = new VenuesProvider();