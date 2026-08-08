const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");
const playersProvider = require("./players.provider");

class RankingsProvider {

    normalize(data) {

        let list =
            data?.rank ||
            data?.rankings ||
            data?.player ||
            data?.players ||
            data?.values ||
            data?.data ||
            [];

        if (!Array.isArray(list)) list = [];

        return list.map((p, index) => ({

            rank:
                p.rank ??
                p.position ??
                index + 1,

            playerId:
                p.id ??
                p.playerId ??
                p.player_id ??
                p.pid ??
                null,

            name:
                p.name ??
                p.player ??
                p.fullName ??
                "Unknown",

            country:
                p.country ??
                p.team ??
                p.nation ??
                "",

            rating:
                p.rating ??
                p.points ??
                0,

            matches:
                p.matches ??
                p.mat ??
                0,

            runs:
                p.runs ??
                0,

            wkts:
                p.wkts ??
                p.wickets ??
                0,

            avg:
                p.avg ??
                p.average ??
                0,

            econ:
                p.econ ??
                p.economy ??
                p.sr ??
                0

        }));

    }

   
    async getBatsmen(format, women) {

    const { data } =
        await api.get(
            endpoints.RANKING_BATSMEN(format, women)
        );

    const rankings = this.normalize(data);

    for (const player of rankings) {

        try {

            let id = player.playerId;

            if (!id && player.name) {
                id = await playersProvider.resolvePlayerId(player.name);
            }

            if (!id) continue;

            const [stats, profile] = await Promise.all([
                playersProvider.getBattingSummary(id),
                playersProvider.getPlayerProfile(id)
            ]);

            player.playerId = id;

            player.matches = stats.matches;
            player.runs = stats.runs;
            player.avg = stats.avg;
            player.econ = stats.strikeRate;

            player.profile = profile;

        } catch (e) {

            console.log("Player Merge Failed:", player.name);

        }

    }

    return rankings;

}

   async getBowlers(format, women) {

    const { data } =
        await api.get(
            endpoints.RANKING_BOWLERS(format, women)
        );

    const rankings = this.normalize(data);

    for (const player of rankings) {

        try {

            let id = player.playerId;

            if (!id && player.name) {
                id = await playersProvider.resolvePlayerId(player.name);
            }

            if (!id) continue;

            const [stats, profile] = await Promise.all([
                playersProvider.getBowlingSummary(id),
                playersProvider.getPlayerProfile(id)
            ]);

            player.playerId = id;

            player.matches = stats.matches;
            player.wkts = stats.wickets;
            player.econ = stats.economy;
            player.avg = stats.average;

            player.profile = profile;

        } catch (e) {

            console.log("Player Merge Failed:", player.name);

        }

    }

    return rankings;

}

async getAllRounders(format, women) {

    const { data } =
        await api.get(
            endpoints.RANKING_ALLROUNDERS(format, women)
        );

    const rankings = this.normalize(data);

    for (const player of rankings) {

        try {

            let id = player.playerId;

            if (!id && player.name) {
                id = await playersProvider.resolvePlayerId(player.name);
            }

            if (!id) continue;

            const [bat, bowl, profile] = await Promise.all([

                playersProvider.getBattingSummary(id),
                playersProvider.getBowlingSummary(id),
                playersProvider.getPlayerProfile(id)

            ]);

            player.playerId = id;

            player.matches = bat.matches;
            player.runs = bat.runs;
            player.avg = bat.avg;

            player.wkts = bowl.wickets;
            player.econ = bowl.economy;

            player.profile = profile;

        } catch (e) {

            console.log("Player Merge Failed:", player.name);

        }

    }

    return rankings;

}

    async getTeams(format, women) {

        const { data } = await api.get(
            endpoints.RANKING_TEAMS(format, women)
        );

        return this.normalize(data);

    }

}

module.exports = new RankingsProvider();