const cache = require("./cacheEngine");

// Prevent duplicate API requests for same cache key
const pendingRequests = new Map();

class CacheManager {

    get(key) {
        return cache.get(key);
    }

    set(key, value, ttl) {
        cache.set(key, value, ttl);
    }

    has(key) {
        return cache.has(key);
    }

    delete(key) {
        pendingRequests.delete(key);
        cache.del(key);
    }

    clear() {
        pendingRequests.clear();
        cache.flush();
    }

    /**
     * Smart Cache + Request Deduplication
     */

    async getOrCreate(cacheKey, ttl, fetchFunction) {

        // 1️⃣ Cache Check
        const cached = this.get(cacheKey);

        if (cached !== undefined && cached !== null) {

            console.log(`🟢 CACHE HIT  : ${cacheKey}`);

            return cached;

        }

        // 2️⃣ Existing Request Check
        if (pendingRequests.has(cacheKey)) {

            console.log(`🟡 WAIT       : ${cacheKey}`);

            return pendingRequests.get(cacheKey);

        }

        console.log(`🔴 API CALL   : ${cacheKey}`);

        // 3️⃣ Only one API request
        const promise = (async () => {

            try {

                const data = await fetchFunction();

                this.set(cacheKey, data, ttl);

                console.log(`💾 CACHE SAVE : ${cacheKey}`);

                return data;

            }

            catch(err){

                console.error(`❌ API ERROR  : ${cacheKey}`);

                console.error(err.message);

                throw err;

            }

            finally{

                pendingRequests.delete(cacheKey);

            }

        })();

        pendingRequests.set(cacheKey, promise);

        return promise;

    }

}

module.exports = new CacheManager();