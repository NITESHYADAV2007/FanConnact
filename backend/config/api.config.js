require("dotenv").config();

module.exports = {

    provider: process.env.API_PROVIDER,

    apiKey: process.env.CRICBUZZ_API_KEY || "",

    apiHost: process.env.CRICBUZZ_API_HOST || "cricbuzz-cricket2.p.rapidapi.com",

    baseURL: process.env.CRICBUZZ_BASE_URL || "https://cricbuzz-cricket2.p.rapidapi.com"

};