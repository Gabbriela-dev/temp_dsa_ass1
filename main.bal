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
    
    resource function get [string assetTag] () returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return http:NOT_FOUND;
        }
        return found;
    }

    resource function get .() returns Asset[] {
        return assetStore.toArray();
    }

        resource function put [string assetTag](@http:Payload Asset updatedAsset) returns Asset|http:NotFound {
        if !assetStore.hasKey(assetTag) {
            return http:NOT_FOUND;
        }
        assetStore[assetTag] = updatedAsset;
        return updatedAsset;
    }

        resource function delete [string assetTag]() returns CreateResponse|http:NotFound {
        if !assetStore.hasKey(assetTag) {
            return http:NOT_FOUND;
        }
        Asset removed = assetStore.remove(assetTag);
        return {message: "Asset deleted successfully", asset: removed};
    }
}