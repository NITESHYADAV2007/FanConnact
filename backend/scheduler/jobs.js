const matchList = require("./jobs/matchList.job");
const matchCenter = require("./jobs/matchCenter.job");

const series = require("./jobs/series.job");
const teams = require("./jobs/teams.job");
const players = require("./jobs/players.job");
const venues = require("./jobs/venues.job");

const rankings = require("./jobs/rankings.job");
const news = require("./jobs/news.job");
const photos = require("./jobs/photos.job");

const auction = require("./jobs/auction.job");
const schedule = require("./jobs/schedule.job");
const archive = require("./jobs/archive.job");
const browse = require("./jobs/browse.job");
const stats = require("./jobs/stats.job");

module.exports = {

    refreshMatchList: () =>
        matchList.run(),

    refreshMatchCenter: () =>
        matchCenter.run(),

    refreshSeries: () =>
        series.run(),

    refreshTeams: () =>
        teams.run(),

    refreshPlayers: () =>
        players.run(),

    refreshVenues: () =>
        venues.run(),

    refreshRankings: () =>
        rankings.run(),

    refreshNews: () =>
        news.run(),

    refreshPhotos: () =>
        photos.run(),

    refreshAuction: () =>
        auction.run(),

    refreshSchedule: () =>
        schedule.run(),

    refreshArchive: () =>
        archive.run(),

    refreshBrowse: () =>
        browse.run(),

    refreshStats: () =>
        stats.run()

};