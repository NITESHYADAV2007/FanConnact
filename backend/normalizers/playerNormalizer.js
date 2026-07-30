function normalizePlayer(data) {

    return {

        basic: {

            id: data.info?.id || "",

            name:
                data.info?.fullName ||
                data.info?.name ||
                data.profile?.name ||
                "",

            image:
                data.info?.image ||
                data.profile?.image ||
                "",

            country:
                data.info?.intlTeam ||
                data.info?.country ||
                data.profile?.country ||
                "",

            team:
                data.info?.teams ||
                "",

            role:
                data.info?.role ||
                data.profile?.role ||
                "",

            battingStyle:
                data.info?.bat ||
                data.info?.battingStyle ||
                data.profile?.battingStyle ||
                "",

            bowlingStyle:
                data.info?.bowl ||
                data.info?.bowlingStyle ||
                data.profile?.bowlingStyle ||
                "",

            jersey:
                data.info?.jersey ||
                data.profile?.jersey ||
                "",

            height:
                data.info?.height ||
                data.profile?.height ||
                "",

            weight:
                data.info?.weight ||
                data.profile?.weight ||
                "",

            born:
                data.info?.DoBFormat ||
                data.info?.DoB ||
                data.profile?.birthDate ||
                "",

            age:
                data.info?.age ||
                ""

        },

        batting: data.batting || {},

        bowling: data.bowling || {},

        career: data.career || {},

        profile: data.profile || {},

        ranking: {

            rank:
                data.profile?.rank ??
                null,

            rating:
                data.profile?.rating ??
                null

        },

        news: data.news || []

    };

}

module.exports = {
    normalizePlayer
};