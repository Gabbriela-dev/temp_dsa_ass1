import ballerina/http;
import ballerina/io;

final http:Client assetClient = check new ("http://localhost:8080/assets");

public function main() returns error? {
    boolean running = true;
    while running {
        io:println("\n=== Library & Resource Management System ===");
        io:println("1. Global View (all assets)");
        io:println("2. Campus View (filter by institution/site)");
        io:println("3. Overdue Dashboard");
        io:println("4. Loan/Book an Asset");
        io:println("5. Schedule Manager");
        io:println("6. Exit");
        io:print("Choose an option: ");
        string choice = io:readln();

        if choice == "1" {
            globalView();
        } else if choice == "2" {
            campusView();
        } else if choice == "3" {
            overdueDashboard();
        } else if choice == "4" {
            loanAsset();
        } else if choice == "5" {
            scheduleManager();
        } else if choice == "6" {
            running = false;
            io:println("Goodbye.");
        } else {
            io:println("Invalid option, try again.");
        }
    }
}

function printAsset(Asset a) {
    io:println(a.assetTag, " | ", a.name, " | ", a.institution, " | ", a.site, " | ", a.status);
}

function globalView() {
    Asset[]|error result = assetClient->get("/");
    if result is error {
        io:println("Could not reach the service.");
        return;
    }
    io:println("\n-- All Assets --");
    if result.length() == 0 {
        io:println("No assets found.");
    }
    foreach Asset a in result {
        printAsset(a);
    }
}

function campusView() {
    io:print("Filter by (1) institution or (2) site? ");
    string mode = io:readln();
    io:print("Enter value: ");
    string value = io:readln();

    Asset[]|error result;
    if mode == "1" {
        result = assetClient->get("/institution/" + value);
    } else {
        result = assetClient->get("/site/" + value);
    }

    if result is error {
        io:println("Could not reach the service.");
        return;
    }

    io:println("\n-- Filtered Assets --");
    if result.length() == 0 {
        io:println("No matching assets found.");
    }
    foreach Asset a in result {
        printAsset(a);
    }
}

function overdueDashboard() {
    Asset[]|error result = assetClient->get("/overdue");
    if result is error {
        io:println("Could not reach the service.");
        return;
    }
    io:println("\n-- Overdue Assets --");
    if result.length() == 0 {
        io:println("Nothing overdue.");
    }
    foreach Asset a in result {
        printAsset(a);
        foreach Schedule s in a.schedules {
            io:println("   - Schedule ", s.scheduleId, " due ", s.dueDate, ": ", s.description);
        }
    }
}

function loanAsset() {
    io:print("Enter assetTag to loan/book: ");
    string tag = io:readln();

    Asset|error result = assetClient->get("/" + tag);
    if result is error {
        io:println("Asset not found. Please check the assetTag and try again.");
        return;
    }
    Asset asset = result;

    io:println("Current status: ", asset.status);
    io:print("New status (LOANED_OUT / AVAILABLE / UNDER_MAINTENANCE / DISPOSED): ");
    string newStatus = io:readln();

    if newStatus != "AVAILABLE" && newStatus != "LOANED_OUT" && newStatus != "UNDER_MAINTENANCE" && newStatus != "DISPOSED" {
        io:println("Invalid status.");
        return;
    }

    asset.status = <AssetStatus>newStatus;
    Asset|error updated = assetClient->put("/" + tag, asset);
    if updated is error {
        io:println("Failed to update asset.");
        return;
    }
    io:println("Updated: ", updated.assetTag, " is now ", updated.status);
}

function scheduleManager() {
    io:println("1. Add schedule  2. Remove schedule");
    io:print("Choose: ");
    string action = io:readln();

    io:print("Enter assetTag: ");
    string tag = io:readln();

    if action == "1" {
        io:print("Schedule ID: ");
        string scheduleId = io:readln();
        io:print("Type (MAINTENANCE/BOOKING): ");
        string scheduleType = io:readln();
        io:print("Due date (YYYY-MM-DD): ");
        string dueDate = io:readln();
        io:print("Description: ");
        string description = io:readln();

        Schedule newSchedule = {
            scheduleId: scheduleId,
            'type: <ScheduleType>scheduleType,
            dueDate: dueDate,
            description: description
        };

        Asset|error updated = assetClient->post("/" + tag + "/schedules", newSchedule);
        if updated is error {
            io:println("Failed to add schedule. Check the assetTag and try again.");
            return;
        }
        io:println("Schedule added. ", updated.assetTag, " now has ", updated.schedules.length(), " schedule(s).");
    } else if action == "2" {
        io:print("Schedule ID to remove: ");
        string scheduleId = io:readln();
        Asset|error updated = assetClient->delete("/" + tag + "/schedules/" + scheduleId);
        if updated is error {
            io:println("Failed to remove schedule. Check the assetTag and try again.");
            return;
        }
        io:println("Schedule removed. ", updated.assetTag, " now has ", updated.schedules.length(), " schedule(s).");
    } else {
        io:println("Invalid choice.");
    }
}