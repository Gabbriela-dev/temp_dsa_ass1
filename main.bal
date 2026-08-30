import ballerina/http;
import ballerina/time;

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

        resource function get institution/[string institution]() returns Asset[] {
        return assetStore.toArray().filter(a => a.institution == institution);
    }

    resource function get site/[string site]() returns Asset[] {
        return assetStore.toArray().filter(a => a.site == site);
    }

        resource function post [string assetTag]/schedules(@http:Payload Schedule newSchedule) returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return http:NOT_FOUND;
        }
        found.schedules.push(newSchedule);
        assetStore[assetTag] = found;
        return found;
    }

        resource function delete [string assetTag]/schedules/[string scheduleId]() returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return http:NOT_FOUND;
        }
        found.schedules = found.schedules.filter(s => s.scheduleId != scheduleId);
        assetStore[assetTag] = found;
        return found;
    }

    resource function get overdue() returns Asset[] {
        time:Utc currentUtc = time:utcNow();
        time:Civil currentCivil = time:utcToCivil(currentUtc);
        string today = string `${currentCivil.year}-${currentCivil.month.toString().padZero(2)}-${currentCivil.day.toString().padZero(2)}`;
        return assetStore.toArray().filter(a => a.schedules.some(s => s.dueDate < today));
    }
}