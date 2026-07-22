const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class AuctionProvider {

    async getSeasons() {

        const { data } = await api.get(
            endpoints.AUCTION_SEASONS
        );

        return data;

    }

    async getTeams(currency, tournament, year) {

        const { data } = await api.get(

            endpoints.AUCTION_TEAMS(
                currency,
                tournament,
                year
            )

        );

        return data;

    }

    async getCompleted(currency, tournament, year) {

        const { data } = await api.get(

            endpoints.AUCTION_COMPLETED(
                currency,
                tournament,
                year
            )

        );

        return data;

    }

    async getUpcoming(currency, tournament, year) {

        const { data } = await api.get(

            endpoints.AUCTION_UPCOMING(
                currency,
                tournament,
                year
            )

        );

        return data;

    }

    async getLive(currency, tournament, year) {

        const { data } = await api.get(

            endpoints.AUCTION_LIVE(
                currency,
                tournament,
                year
            )

        );

        return data;

    }

}

module.exports = new AuctionProvider();