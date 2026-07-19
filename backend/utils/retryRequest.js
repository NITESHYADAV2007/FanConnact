const axiosClient = require("./axiosClient");

async function retryRequest(config, retries = 3) {

    for (let i = 0; i < retries; i++) {

        try {

            return await axiosClient(config);

        }

        catch (err) {

            if (i === retries - 1) {

                throw err;

            }

            console.log(`Retry ${i + 1}/${retries}`);

            await new Promise(resolve => setTimeout(resolve, 1000));

        }

    }

}

module.exports = retryRequest;