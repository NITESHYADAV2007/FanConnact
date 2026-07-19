const providers = require("../../providers/cricbuzz");
const cache = require("../../cache/cacheManager");
const activeUsers = require("../activeUsers");

class MatchCenterJob {

    async run() {

        try {

            activeUsers.cleanup();

            if (!activeUsers.hasActiveUsers()) {
                return;
            }

            const matches =
                activeUsers.getWatchingMatches();

            for (const matchId of matches) {

                await this.refreshMatch(matchId);

            }

        } catch (err) {

            console.error(
                "MatchCenter Job Error:",
                err.message
            );

        }

    }

    async refreshMatch(matchId) {

        try {

            await Promise.all([

                this.refreshMatchInfo(matchId),

                this.refreshCommentary(matchId),

                this.refreshHCommentary(matchId),

                this.refreshScorecard(matchId),

                this.refreshSquads(matchId),

                this.refreshOvers(matchId),

                this.refreshOverDetails(matchId),

                this.refreshHighlights(matchId),

                this.refreshLeanback(matchId),

                this.refreshHLeanback(matchId),

                this.refreshOversGraph(matchId),

                this.refreshBallsGraph(matchId),

                this.refreshPartnershipGraph(matchId)

            ]);

        } catch (err) {

            console.error(
                `Refresh Failed ${matchId}`,
                err.message
            );

        }

    }

    async refreshMatchInfo(matchId){

        const data =
        await providers.matches.getMatchInfo(matchId);

        cache.set(
            `match:${matchId}:info`,
            data,
            30
        );

    }

    async refreshCommentary(matchId){

        const data =
        await providers.matches.getCommentary(matchId);

        cache.set(
            `match:${matchId}:commentary`,
            data,
            10
        );

    }

    async refreshHCommentary(matchId){

        const data =
        await providers.matches.getHCommentary(matchId);

        cache.set(
            `match:${matchId}:hcommentary`,
            data,
            10
        );

    }

    async refreshScorecard(matchId){

        const data =
        await providers.matches.getScorecard(matchId);

        cache.set(
            `match:${matchId}:scorecard`,
            data,
            15
        );

    }

    async refreshSquads(matchId){

        const data =
        await providers.matches.getSquads(matchId);

        cache.set(
            `match:${matchId}:squads`,
            data,
            300
        );

    }

    async refreshOvers(matchId){

        const data =
        await providers.matches.getOvers(matchId);

        cache.set(
            `match:${matchId}:overs`,
            data,
            10
        );

    }

    async refreshOverDetails(matchId){

        const data =
        await providers.matches.getOversDetails(matchId);

        cache.set(
            `match:${matchId}:overdetails`,
            data,
            10
        );

    }

    async refreshHighlights(matchId){

        const data =
        await providers.matches.getHighlights(matchId);

        cache.set(
            `match:${matchId}:highlights`,
            data,
            30
        );

    }

    async refreshLeanback(matchId){

        const data =
        await providers.matches.getLeanback(matchId);

        cache.set(
            `match:${matchId}:leanback`,
            data,
            30
        );

    }

    async refreshHLeanback(matchId){

        const data =
        await providers.matches.getHLeanback(matchId);

        cache.set(
            `match:${matchId}:hleanback`,
            data,
            30
        );

    }

    async refreshOversGraph(matchId){

        const data =
        await providers.matches.getOversGraph(matchId);

        cache.set(
            `match:${matchId}:oversgraph`,
            data,
            30
        );

    }

    async refreshBallsGraph(matchId){

        const data =
        await providers.matches.getBallsGraph(matchId);

        cache.set(
            `match:${matchId}:ballsgraph`,
            data,
            30
        );

    }

    async refreshPartnershipGraph(matchId){

        const data =
        await providers.matches.getPartnershipGraph(matchId);

        cache.set(
            `match:${matchId}:partnershipgraph`,
            data,
            30
        );

    }

}

module.exports = new MatchCenterJob();