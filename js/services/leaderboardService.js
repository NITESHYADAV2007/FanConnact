import { db } from "../firebase-config.js";

import {
    collection,
    query,
    orderBy,
    onSnapshot,
    limit
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

const USERS = "users";

/*=====================================
    NORMALIZE USER
=====================================*/

function normalizeUser(docSnap, rank) {

    const data = docSnap.data();

    return {

        uid: docSnap.id,

        rank,

        name:
            data.username ||
            data.fullName ||
            "Unknown User",

        username:
            data.username ||
            "",

        fullName:
            data.fullName ||
            "",

        level:
            data.level || 0,

        xp:
            data.xp || 0,

        coins:
            data.coins || 0,

        img:
            data.photoURL ||
            "https://ui-avatars.com/api/?name=" +
            encodeURIComponent(
                data.username ||
                data.fullName ||
                "User"
            ),

        photoURL:
            data.photoURL ||
            "https://ui-avatars.com/api/?name=" +
            encodeURIComponent(
                data.username ||
                data.fullName ||
                "User"
            )

    };

}

/*=====================================
    LIVE LEADERBOARD
=====================================*/

export function listenLeaderboard(
    callback,
    count = 100
) {

    const q = query(

        collection(db, USERS),

        orderBy("xp", "desc"),

        limit(count)

    );

    return onSnapshot(

        q,

        (snapshot) => {

            const users = [];

            let rank = 1;

            snapshot.forEach(docSnap => {

                users.push(

                    normalizeUser(

                        docSnap,

                        rank++

                    )

                );

            });

            callback(users);

        },

        (error) => {

            console.error(

                "Leaderboard Error:",

                error

            );

        }

    );

}

/*=====================================
    TOP 3
=====================================*/

export function getTopThree(users) {

    return users.slice(0, 3);

}

/*=====================================
    TOP EARNERS
=====================================*/

export function getTopEarners(
    users,
    count = 5
) {

    return users.slice(0, count);

}

/*=====================================
    ROWS
=====================================*/

export function getLeaderboardRows(
    users,
    start = 3
) {

    return users.slice(start);

}

/*=====================================
    CURRENT USER
=====================================*/

export function getCurrentUserRank(
    users,
    uid
) {

    return users.find(

        user => user.uid === uid

    );

}