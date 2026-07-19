const axios = require("axios");

const axiosClient = axios.create({

    timeout:10000,

    headers:{

        Accept:"application/json"

    }

});

module.exports = axiosClient;