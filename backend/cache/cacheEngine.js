const NodeCache=require("node-cache");

class CacheEngine{

    constructor(){

        this.cache=new NodeCache({

            stdTTL:30,

            checkperiod:60,

            useClones:false

        });

    }

    get(key){

        return this.cache.get(key);

    }

    set(key,value,ttl){

        this.cache.set(

            key,

            value,

            ttl

        );

    }

    has(key){

        return this.cache.has(key);

    }

    del(key){

        this.cache.del(key);

    }

    flush(){

        this.cache.flushAll();

    }

}

module.exports=new CacheEngine();