function normalizeLiveMatches(apiResponse) {

    const matches = [];

    if (!apiResponse?.typeMatches) {

        return matches;

    }

    apiResponse.typeMatches.forEach(type => {

        if (!type.seriesMatches) return;

        type.seriesMatches.forEach(series => {

            if (!series.seriesAdWrapper?.matches) return;

            series.seriesAdWrapper.matches.forEach(match => {

                const info = match.matchInfo;
                const state = match.matchScore;

                if (!info) return;

                matches.push({

                    id: String(info.matchId),

                    series: info.seriesName,

                    matchType: info.matchFormat,

                    status: info.state,

                    startTime: info.startDate,

                    venue: info.venueInfo?.ground,

                    city: info.venueInfo?.city,

                    homeTeam: {

                        id: info.team1?.teamId,

                        name: info.team1?.teamName,

                        short: info.team1?.teamSName,

                        imageId: info.team1?.imageId

                    },

                    awayTeam: {

                        id: info.team2?.teamId,

                        name: info.team2?.teamName,

                        short: info.team2?.teamSName,

                        imageId: info.team2?.imageId

                    },

                    score: {

                        innings1: state?.team1Score,

                        innings2: state?.team2Score

                    }

                });

            });

        });

    });

    return matches;

}

module.exports = {

    normalizeLiveMatches,

     normalizeUpcomingMatches,

      normalizeRecentMatches,
      
      normalizeMatchDetails


};

function normalizeUpcomingMatches(apiResponse) {

    const matches = [];

    if (!apiResponse?.typeMatches) {

        return matches;

    }

    apiResponse.typeMatches.forEach(type => {

        if (!type.seriesMatches) return;

        type.seriesMatches.forEach(series => {

            if (!series.seriesAdWrapper?.matches) return;

            series.seriesAdWrapper.matches.forEach(match => {

                const info = match.matchInfo;

                if (!info) return;

                matches.push({

                    id: String(info.matchId),

                    series: info.seriesName,

                    matchType: info.matchFormat,

                    status: info.state,

                    startTime: info.startDate,

                    venue: info.venueInfo?.ground,

                    city: info.venueInfo?.city,

                    homeTeam: {

                        id: info.team1?.teamId,

                        name: info.team1?.teamName,

                        short: info.team1?.teamSName,

                        imageId: info.team1?.imageId

                    },

                    awayTeam: {

                        id: info.team2?.teamId,

                        name: info.team2?.teamName,

                        short: info.team2?.teamSName,

                        imageId: info.team2?.imageId

                    }

                });

            });

        });

    });

    return matches;

}

function normalizeRecentMatches(apiResponse) {

    const matches = [];

    if (!apiResponse?.typeMatches) {

        return matches;

    }

    apiResponse.typeMatches.forEach(type => {

        if (!type.seriesMatches) return;

        type.seriesMatches.forEach(series => {

            if (!series.seriesAdWrapper?.matches) return;

            series.seriesAdWrapper.matches.forEach(match => {

                const info = match.matchInfo;
                const state = match.matchScore;

                if (!info) return;

                matches.push({

                    id: String(info.matchId),

                    series: info.seriesName,

                    matchType: info.matchFormat,

                    status: info.state,

                    result: info.status,

                    startTime: info.startDate,

                    venue: info.venueInfo?.ground,

                    city: info.venueInfo?.city,

                    homeTeam: {

                        id: info.team1?.teamId,

                        name: info.team1?.teamName,

                        short: info.team1?.teamSName,

                        imageId: info.team1?.imageId

                    },

                    awayTeam: {

                        id: info.team2?.teamId,

                        name: info.team2?.teamName,

                        short: info.team2?.teamSName,

                        imageId: info.team2?.imageId

                    },

                    score: {

                        innings1: state?.team1Score,

                        innings2: state?.team2Score

                    }

                });

            });

        });

    });

    return matches;

}

function normalizeMatchDetails(apiResponse) {

    if (!apiResponse) return null;

    const info = apiResponse.matchHeader || {};
    const score = apiResponse.scoreCard || {};

    return {

        id: String(info.matchId),

        series: info.seriesName,

        matchType: info.matchFormat,

        status: info.state,

        startTime: info.startDate,

        venue: {

            name: info.venueInfo?.ground,

            city: info.venueInfo?.city,

            timezone: info.venueInfo?.timezone

        },

        teams: {

            home: info.team1,

            away: info.team2

        },

        toss: info.tossResults,

        score,

        players: apiResponse.players || {},

        innings: apiResponse.innings || [],

        currentBatters: apiResponse.batsmen || [],

        currentBowlers: apiResponse.bowlers || [],

        partnership: apiResponse.partnership || {},

        currentRunRate: apiResponse.currentRunRate,

        requiredRunRate: apiResponse.requiredRunRate

    };

}