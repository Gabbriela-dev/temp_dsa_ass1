import ballerina/http;

map<Asset> assetStore = {};

service /assets on new http:Listener(8080) {

    resource function post .(@http:Payload Asset newAsset) returns CreateResponse|http:Conflict {
        if assetStore.hasKey(newAsset.assetTag) {
            return http:CONFLICT;
        }
        assetStore[newAsset.assetTag] = newAsset;
        return {message: "Asset created successfully", asset: newAsset};
    }
}