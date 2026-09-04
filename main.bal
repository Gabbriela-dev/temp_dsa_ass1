import ballerina/http;
import ballerina/time;

map<Asset> assetStore = {};
map<Institution> institutionStore = {};

function notFoundError(string message) returns http:NotFound {
    return {body: {message: message}};
}

function conflictError(string message) returns http:Conflict {
    return {body: {message: message}};
}

function badRequestError(string message) returns http:BadRequest {
    return {body: {message: message}};
}

function isValidDate(string date) returns boolean {
    return date.matches(re `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`);
}

service /assets on new http:Listener(8080) {

    resource function post .(@http:Payload Asset newAsset) returns CreateResponse|http:Conflict|http:BadRequest {
        if !isValidDate(newAsset.dateAcquired) {
            return badRequestError("Invalid dateAcquired format, expected YYYY-MM-DD");
        }
        if assetStore.hasKey(newAsset.assetTag) {
            return conflictError("Asset with this assetTag already exists");
        }
        assetStore[newAsset.assetTag] = newAsset;
        return {message: "Asset created successfully", asset: newAsset};
    }

    resource function get [string assetTag] () returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return notFoundError("Asset not found");
        }
        return found;
    }

    resource function get .() returns Asset[] {
        return assetStore.toArray();
    }

    resource function put [string assetTag](@http:Payload Asset updatedAsset) returns Asset|http:NotFound {
        if !assetStore.hasKey(assetTag) {
            return notFoundError("Asset not found");
        }
        assetStore[assetTag] = updatedAsset;
        return updatedAsset;
    }

    resource function delete [string assetTag]() returns CreateResponse|http:NotFound {
        if !assetStore.hasKey(assetTag) {
            return notFoundError("Asset not found");
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

    resource function post [string assetTag]/schedules(@http:Payload Schedule newSchedule) returns Asset|http:NotFound|http:Conflict|http:BadRequest {
        Asset? found = assetStore[assetTag];
        if found is () {
            return notFoundError("Asset not found");
        }
        if !isValidDate(newSchedule.dueDate) {
            return badRequestError("Invalid dueDate format, expected YYYY-MM-DD");
        }
        if found.schedules.some(s => s.scheduleId == newSchedule.scheduleId) {
            return conflictError("Schedule with this scheduleId already exists");
        }
        found.schedules.push(newSchedule);
        assetStore[assetTag] = found;
        return found;
    }

    resource function delete [string assetTag]/schedules/[string scheduleId]() returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return notFoundError("Asset not found");
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

    resource function post institutions(@http:Payload Institution newInstitution) returns Institution|http:Conflict {
        if institutionStore.hasKey(newInstitution.name) {
            return conflictError("Institution already exists");
        }
        institutionStore[newInstitution.name] = newInstitution;
        return newInstitution;
    }

    resource function delete institutions/[string name]() returns Institution|http:NotFound {
        Institution? found = institutionStore[name];
        if found is () {
            return notFoundError("Institution not found");
        }
        _ = institutionStore.remove(name);
        return found;
    }

    resource function get institutions() returns Institution[] {
        return institutionStore.toArray();
    }

    resource function post [string assetTag]/components(@http:Payload Component newComponent) returns Asset|http:NotFound|http:Conflict {
        Asset? found = assetStore[assetTag];
        if found is () {
            return notFoundError("Asset not found");
        }
        if found.components.some(c => c.compId == newComponent.compId) {
            return conflictError("Component with this compId already exists");
        }
        found.components.push(newComponent);
        assetStore[assetTag] = found;
        return found;
    }

    resource function delete [string assetTag]/components/[string compId]() returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return notFoundError("Asset not found");
        }
        found.components = found.components.filter(c => c.compId != compId);
        assetStore[assetTag] = found;
        return found;
    }

    resource function post [string assetTag]/workorders(@http:Payload WorkOrder newOrder) returns Asset|http:NotFound|http:Conflict {
        Asset? found = assetStore[assetTag];
        if found is () {
            return notFoundError("Asset not found");
        }
        if found.workOrders.some(wo => wo.orderId == newOrder.orderId) {
            return conflictError("Work order with this orderId already exists");
        }
        found.workOrders.push(newOrder);
        assetStore[assetTag] = found;
        return found;
    }

    resource function put [string assetTag]/workorders/[string orderId](@http:Payload WorkOrder updatedOrder) returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return notFoundError("Asset not found");
        }
        found.workOrders = found.workOrders.map(wo => wo.orderId == orderId ? updatedOrder : wo);
        assetStore[assetTag] = found;
        return found;
    }

    resource function delete [string assetTag]/workorders/[string orderId]() returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return notFoundError("Asset not found");
        }
        found.workOrders = found.workOrders.filter(wo => wo.orderId != orderId);
        assetStore[assetTag] = found;
        return found;
    }

    resource function post [string assetTag]/workorders/[string orderId]/tasks(@http:Payload Task newTask) returns Asset|http:NotFound {
        Asset? found = assetStore[assetTag];
        if found is () {
            return notFoundError("Asset not found");
        }
        WorkOrder[] updatedOrders = [];
        foreach WorkOrder wo in found.workOrders {
            if wo.orderId == orderId {
                wo.tasks.push(newTask);
            }
            updatedOrders.push(wo);
        }
        found.workOrders = updatedOrders;
        assetStore[assetTag] = found;
        return found;
    }
}