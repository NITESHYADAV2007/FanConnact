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


// Resolve the actual striker without assuming batsmen[0] is always on strike.
// This is prediction-only data mapping; match/cache behaviour is unchanged.
function resolveCurrentBatter(root, current, currentBatters) {
    const explicit =
        root?.currentBatter || root?.currentbatter ||
        current?.currentBatter || current?.currentbatter ||
        root?.striker || current?.striker ||
        root?.onStrikeBatter || current?.onStrikeBatter ||
        root?.strikerBatter || current?.strikerBatter ||
        root?.currentStriker || current?.currentStriker || null;

    if (explicit && typeof explicit === 'object') return explicit;

    const list = Array.isArray(currentBatters) ? currentBatters.filter(Boolean) : [];
    if (!list.length) return null;

    // Normalize the common provider field names without changing the
    // original match/cache payload.
    const normalized = list.map(b => ({
        ...b,
        id: b?.id ?? b?.playerId ?? b?.batsmanId ?? b?.batId ?? b?.player_id,
        name: b?.name ?? b?.playerName ?? b?.batsmanName ?? b?.displayName ?? "",
        runs: b?.runs ?? b?.score ?? b?.runsScored ?? b?.batRuns ?? b?.batsmanRuns
    }));

    if (normalized.length === 1) return normalized[0];

    const strikerId = String(
        root?.strikerId ?? root?.strikerID ?? current?.strikerId ?? current?.strikerID ?? ''
    );
    const strikerName = String(
        root?.strikerName ?? current?.strikerName ?? ''
    ).trim().toLowerCase();

    const marked = normalized.find(b => {
        const flag = b?.isStriker ?? b?.isOnStrike ?? b?.onStrike ?? b?.striker ?? b?.isOnstrike;
        if (flag === true || String(flag).toLowerCase() === 'true') return true;
        const role = String(b?.battingStatus ?? b?.status ?? b?.role ?? '').toLowerCase();
        return role.includes('striker') || role === 'on strike' || role === 'onstrike';
    });
    if (marked) return marked;

    if (strikerId) {
        const byId = normalized.find(b => String(b?.id ?? b?.playerId ?? b?.batsmanId ?? b?.batId ?? '') === strikerId);
        if (byId) return byId;
    }
    if (strikerName) {
        const byName = normalized.find(b => String(b?.name ?? b?.playerName ?? b?.batsmanName ?? '').trim().toLowerCase() === strikerName);
        if (byName) return byName;
    }

    // Do not guess from [0] when two active batters exist.
    return null;
}

function normalizeMatchDetails(apiResponse) {
    if (!apiResponse) return null;

    // Cricbuzz responses may arrive either as a flat object or wrapped in
    // matchInfo/matchScore/data. Keep both shapes intact for the Match Center.
    const root = apiResponse?.data || apiResponse;
    const info = root?.matchInfo || root?.matchinfo || root;
    const score = root?.matchScore || root?.score || {};
    const current = root?.currentInnings || root?.currentinnings || root?.current || {};
    const innings = Array.isArray(root?.innings)
        ? root.innings
        : (Array.isArray(score?.innings) ? score.innings
        : (Array.isArray(root?.scoreCard?.scorecard) ? root.scoreCard.scorecard
        : (Array.isArray(root?.scorecard?.scorecard) ? root.scorecard.scorecard : [])));

    const venueInfo =
        root?.venueinfo || root?.venueInfo ||
        info?.venueinfo || info?.venueInfo || {};

    const team1 = root?.team1 || info?.team1 || {};
    const team2 = root?.team2 || info?.team2 || {};

    const officials = root?.officials || info?.officials || {};
    const umpires =
        root?.umpires || info?.umpires ||
        officials?.umpires || officials?.Umpires || [];

    return {
        id: String(root?.matchid ?? info?.matchId ?? root?.id ?? ''),
        series: root?.seriesname ?? info?.seriesName ?? root?.series ?? '',
        tournament: root?.tournament || info?.tournament || '',
        matchType: root?.matchformat ?? info?.matchFormat ?? root?.format ?? '',
        state: root?.state ?? info?.state ?? '',
        status: root?.status ?? info?.status ?? '',
        statusText: root?.statusText ?? info?.statusText ?? root?.status ?? info?.status ?? '',
        result: root?.result ?? info?.result ?? root?.status ?? info?.status ?? '',
        winner:
            root?.winner || root?.winningTeam || root?.winnerTeam ||
            info?.winner || info?.winningTeam || info?.winnerTeam || '',
        startTime: root?.startdate ?? info?.startDate ?? root?.startTime ?? info?.startTime ?? '',
        day: root?.day ?? root?.matchDay ?? current?.day ?? current?.dayNumber ?? '',
        dayNumber: root?.dayNumber ?? current?.dayNumber ?? '',
        session: root?.session ?? root?.sessionName ?? current?.session ?? current?.sessionName ?? '',
        playState: root?.playState ?? root?.stateText ?? root?.statusText ?? info?.statusText ?? root?.status ?? '',
        venue: {
            name: venueInfo?.ground ?? venueInfo?.name ?? '',
            city: venueInfo?.city ?? '',
            timezone: venueInfo?.timezone ?? ''
        },
        teams: {
            home: team1,
            away: team2
        },
        team1,
        team2,
        toss: root?.tossstatus ?? root?.toss ?? info?.tossstatus ?? info?.toss ?? '',

        // Preserve every common official field. The engine also recursively scans
        // the returned object, so nested Cricbuzz official shapes remain usable.
        officials,
        umpires,
        umpire1:
            root?.umpire1 || root?.umpireOne ||
            info?.umpire1 || info?.umpireOne ||
            officials?.umpire1 || officials?.umpireOne || null,
        umpire2:
            root?.umpire2 || root?.umpireTwo ||
            info?.umpire2 || info?.umpireTwo ||
            officials?.umpire2 || officials?.umpireTwo || null,
        thirdUmpire:
            root?.thirdUmpire || root?.thirdumpire || root?.third_umpire ||
            info?.thirdUmpire || info?.thirdumpire || info?.third_umpire ||
            officials?.thirdUmpire || officials?.thirdumpire || officials?.third_umpire || null,
        referee:
            root?.referee || root?.matchReferee ||
            info?.referee || info?.matchReferee ||
            officials?.referee || officials?.matchReferee || null,

        broadcast: root?.broadcast || root?.broadcastInfo || info?.broadcast || '',
        gender: root?.gender ?? root?.isWomen ?? info?.gender ?? info?.isWomen ?? '',
        score: root?.scoreCard || root?.scorecard || root?.scoreCard || score || {},
        players: root?.players || {},
        innings,
        currentInnings: current,
        currentBatters: root?.batsmen || root?.currentBatters || current?.batsmen || [],
        currentBatter: resolveCurrentBatter(
            root,
            current,
            root?.batsmen || root?.currentBatters || current?.batsmen || []
        ),
        currentBowlers: root?.bowlers || root?.currentBowlers || current?.bowlers || [],
        partnership: root?.partnership || root?.currentPartnership || current?.partnership || {},
        currentRunRate: root?.currentRunRate ?? root?.currentrunrate ?? current?.currentRunRate ?? current?.runrate ?? current?.crr,
        requiredRunRate: root?.requiredRunRate ?? root?.requiredrunrate ?? current?.requiredRunRate ?? current?.rrr,
        target: root?.target ?? root?.targetscore ?? current?.target ?? current?.targetscore,
        requiredRuns: root?.requiredRuns ?? root?.requiredruns ?? current?.requiredRuns ?? current?.requiredruns,
        requiredBalls: root?.requiredBalls ?? root?.requiredballs ?? current?.requiredBalls ?? current?.requiredballs,
        revisedTarget: root?.revisedTarget ?? root?.revisedtarget ?? current?.revisedTarget ?? current?.revisedtarget,
        followOn: root?.followOn ?? root?.followon ?? current?.followOn ?? current?.followon,
        superOver: root?.superOver ?? root?.superover ?? current?.superOver ?? current?.superover
    };
}

