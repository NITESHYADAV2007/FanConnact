/* ==========================================================
        FanConnact Match Event Dispatcher
========================================================== */

const listeners = new Map();

/* ==========================================================
        Register Event
========================================================== */

export function on(

    event,

    callback

){

    if(

        !listeners.has(event)

    ){

        listeners.set(

            event,

            []

        );

    }

    listeners

    .get(event)

    .push(callback);

}

/* ==========================================================
        Emit Event
========================================================== */

export async function emit(

    event,

    payload

){

    if(

        !listeners.has(event)

    ){

        return;

    }

    const callbacks =

    listeners.get(event);

    for(

        const callback

        of callbacks

    ){

        await callback(payload);

    }

}
/* ==========================================================
        Remove Listener
========================================================== */

export function off(

    event,

    callback

){

    if(

        !listeners.has(event)

    ){

        return;

    }

    const updated =

    listeners

    .get(event)

    .filter(

        item=>item!==callback

    );

    listeners.set(

        event,

        updated

    );

}

/* ==========================================================
        Clear
========================================================== */

export function clearEvents(){

    listeners.clear();

}