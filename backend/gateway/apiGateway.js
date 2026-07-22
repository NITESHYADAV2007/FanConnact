const axios = require("axios");
const http = require("http");
const https = require("https");

const config = require("../config/api.config");

console.log("🌐 BASE URL :", config.baseURL);
console.log("📡 API HOST :", config.apiHost);
console.log("🔑 API KEY  :", config.apiKey ? "Loaded ✅" : "Missing ❌");

const api = axios.create({

    baseURL: config.baseURL,

    timeout: 10000,

    httpAgent: new http.Agent({

        keepAlive: true,
        maxSockets: 100

    }),

    httpsAgent: new https.Agent({

        keepAlive: true,
        maxSockets: 100

    }),

    headers: {

        "x-rapidapi-key": config.apiKey,

        "x-rapidapi-host": config.apiHost,

        "Content-Type": "application/json",

        "Accept-Encoding": "gzip"

    }

});


/* ==========================================
            REQUEST LOGGING
========================================== */

api.interceptors.request.use(

    request => {

        console.log(

            `📤 ${request.method.toUpperCase()} ${request.url}`

        );

        request.metadata = {

            start: Date.now()

        };

        return request;

    }

);


/* ==========================================
            RESPONSE LOGGING
========================================== */

api.interceptors.response.use(

    response => {

        const time = Date.now() - response.config.metadata.start;

        console.log(

            `✅ ${response.config.url} (${time} ms)`

        );

        return response;

    },

    async error => {

        const configReq = error.config;

        if (!configReq) {

            console.error(error.message);

            throw error;

        }

        configReq.__retryCount = configReq.__retryCount || 0;

        const shouldRetry =

            !error.response ||

            error.code === "ECONNABORTED" ||

            (error.response && error.response.status >= 500);

        if (shouldRetry && configReq.__retryCount < 3) {

            configReq.__retryCount++;

            console.log(

                `🔁 Retry ${configReq.__retryCount}/3 -> ${configReq.url}`

            );

            await new Promise(resolve =>

                setTimeout(resolve, 1000)

            );

            return api(configReq);

        }

        console.error(

            "❌ API ERROR",

            {

                url: configReq.url,

                status: error.response?.status,

                message: error.message

            }

        );

        throw error;

    }

);

module.exports = api;