const api = require("../../gateway/apiGateway");
const endpoints = require("./endpoints");

class PhotosProvider {

    async getPhotos(lastId = 5921) {

        const { data } = await api.get(
            endpoints.PHOTOS(lastId)
        );

        return data;
    }

    async getPhoto(id) {

        const { data } = await api.get(
            endpoints.PHOTO_DETAIL(id)
        );

        return data;
    }

}

module.exports = new PhotosProvider();