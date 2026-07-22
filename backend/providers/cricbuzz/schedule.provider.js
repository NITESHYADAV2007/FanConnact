const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class ScheduleProvider {

    async getInternational(lastTime = Date.now()) {

        const { data } = await api.get(
            endpoints.SCHEDULE_INTERNATIONAL(lastTime)
        );

        return data;
    }

    async getLeague(lastTime = Date.now()) {

        const { data } = await api.get(
            endpoints.SCHEDULE_LEAGUE(lastTime)
        );

        return data;
    }

    async getDomestic(lastTime = Date.now()) {

        const { data } = await api.get(
            endpoints.SCHEDULE_DOMESTIC(lastTime)
        );

        return data;
    }

    async getWomen(lastTime = Date.now()) {

        const { data } = await api.get(
            endpoints.SCHEDULE_WOMEN(lastTime)
        );

        return data;
    }

}

module.exports = new ScheduleProvider();