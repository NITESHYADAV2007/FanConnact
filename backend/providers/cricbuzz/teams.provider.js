const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class TeamsProvider {

    async getInternationalTeams() {
        const { data } = await api.get(endpoints.TEAM_INTERNATIONAL);
        return data;
    }

    async getLeagueTeams() {
        const { data } = await api.get(endpoints.TEAM_LEAGUE);
        return data;
    }

    async getDomesticTeams() {
        const { data } = await api.get(endpoints.TEAM_DOMESTIC);
        return data;
    }

    async getWomenTeams() {
        const { data } = await api.get(endpoints.TEAM_WOMEN);
        return data;
    }

    async getTeamSchedule(teamId) {
        const { data } = await api.get(
            endpoints.TEAM_SCHEDULE(teamId)
        );
        return data;
    }

    async getTeamResults(teamId) {
        const { data } = await api.get(
            endpoints.TEAM_RESULTS(teamId)
        );
        return data;
    }

    async getTeamPlayers(teamId) {
        const { data } = await api.get(
            endpoints.TEAM_PLAYERS(teamId)
        );
        return data;
    }

    async getTeamStats(teamId) {
        const { data } = await api.get(
            endpoints.TEAM_STATS(teamId)
        );
        return data;
    }

    async getTeamNews(teamId) {
        const { data } = await api.get(
            endpoints.TEAM_NEWS(teamId)
        );
        return data;
    }

}

module.exports = new TeamsProvider();