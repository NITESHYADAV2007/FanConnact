module.exports = {

    /* ==========================
            MATCHES
    ========================= */

    live: id => `live_${id}`,

    upcoming: "upcoming",

    recent: "recent",

    match: id => `match_${id}`,

    /* ==========================
        MATCH CENTER
    ========================= */

    commentary: id => `commentary_${id}`,

    hcommentary: id => `hcommentary_${id}`,

    scorecard: id => `scorecard_${id}`,

    squads: id => `squads_${id}`,

    overs: id => `overs_${id}`,

    overDetails: id => `overdetails_${id}`,

    highlights: id => `highlights_${id}`,

    leanback: id => `leanback_${id}`,

    hleanback: id => `hleanback_${id}`,

    oversGraph: id => `oversgraph_${id}`,

    ballsGraph: id => `ballsgraph_${id}`,

    partnershipGraph: id => `partnershipgraph_${id}`,

    /* ==========================
            SERIES
    ========================= */

    series: id => `series_${id}`,

    /* ==========================
            TEAM
    ========================= */

    team: id => `team_${id}`,

    /* ==========================
            PLAYER
    ========================= */

    player: id => `player_${id}`,

    /* ==========================
            VENUE
    ========================= */

    venue: id => `venue_${id}`,

    /* ==========================
            NEWS
    ========================= */

    news: id => `news_${id}`,

    /* ==========================
            PHOTOS
    ========================= */

    photos: id => `photos_${id}`,

    /* ==========================
            RANKINGS
    ========================= */

    rankings: id => `rankings_${id}`,

    /* ==========================
            AUCTION
    ========================= */

    auction: id => `auction_${id}`,

    /* ==========================
            SCHEDULE
    ========================= */

    schedule: id => `schedule_${id}`,

    /* ==========================
            ARCHIVE
    ========================= */

    archive: id => `archive_${id}`,

    /* ==========================
        BROWSE SERIES
    ========================= */

    browse: id => `browse_${id}`,

    /* ==========================
            STATS
    ========================= */

    stats: id => `stats_${id}`

};