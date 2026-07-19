const cacheManager=require("./cacheManager");
const CACHE = require("./cache.config");
const KEYS = require("./cacheKeys");

module.exports = (policy, keyName) => {

    return (req, res, next) => {

        const ttl = CACHE[policy];

        const key =

            typeof KEYS[keyName] === "function"

            ? KEYS[keyName](

                req.params.matchId ||

                req.params.id ||

                req.query.id ||

                "default"

            )

            : KEYS[keyName];

        const cached=cacheManager.get(key);

        if (cached) {

            console.log("🟢 CACHE HIT:", key);

            return res.json(cached);

        }

        console.log("🔴 CACHE MISS:", key);

        const original = res.json;

        res.json = function (body) {
            
cacheManager.set(

                key,

                body,

                ttl

            );

            return original.call(

                this,

                body

            );

        };

        next();

    };

};