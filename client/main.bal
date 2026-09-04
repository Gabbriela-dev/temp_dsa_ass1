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
            check globalView();
        } else if choice == "2" {
            check campusView();
        } else if choice == "3" {
            check overdueDashboard();
        } else if choice == "4" {
            check loanAsset();
        } else if choice == "5" {
            check scheduleManager();
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

function globalView() returns error? {
    Asset[] assets = check assetClient->get("/");
    io:println("\n-- All Assets --");
    if assets.length() == 0 {
        io:println("No assets found.");
    }
    foreach Asset a in assets {
        printAsset(a);
    }
}

function campusView() returns error? {
    io:print("Filter by (1) institution or (2) site? ");
    string mode = io:readln();
    io:print("Enter value: ");
    string value = io:readln();

    Asset[] assets;
    if mode == "1" {
        assets = check assetClient->get("/institution/" + value);
    } else {
        assets = check assetClient->get("/site/" + value);
    }

    io:println("\n-- Filtered Assets --");
    if assets.length() == 0 {
        io:println("No matching assets found.");
    }
    foreach Asset a in assets {
        printAsset(a);
    }
}

function overdueDashboard() returns error? {
    Asset[] assets = check assetClient->get("/overdue");
    io:println("\n-- Overdue Assets --");
    if assets.length() == 0 {
        io:println("Nothing overdue.");
    }
    foreach Asset a in assets {
        printAsset(a);
        foreach Schedule s in a.schedules {
            io:println("   - Schedule ", s.scheduleId, " due ", s.dueDate, ": ", s.description);
        }
    }
}

function loanAsset() returns error? {
    io:print("Enter assetTag to loan/book: ");
    string tag = io:readln();

    Asset asset = check assetClient->get("/" + tag);

    io:println("Current status: ", asset.status);
    io:print("New status (LOANED_OUT / AVAILABLE / UNDER_MAINTENANCE / DISPOSED): ");
    string newStatus = io:readln();

    if newStatus != "AVAILABLE" && newStatus != "LOANED_OUT" && newStatus != "UNDER_MAINTENANCE" && newStatus != "DISPOSED" {
        io:println("Invalid status.");
        return;
    }

    asset.status = <AssetStatus>newStatus;
    Asset updated = check assetClient->put("/" + tag, asset);
    io:println("Updated: ", updated.assetTag, " is now ", updated.status);
}

function scheduleManager() returns error? {
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

        Asset updated = check assetClient->post("/" + tag + "/schedules", newSchedule);
        io:println("Schedule added. ", updated.assetTag, " now has ", updated.schedules.length(), " schedule(s).");
    } else if action == "2" {
        io:print("Schedule ID to remove: ");
        string scheduleId = io:readln();
        Asset updated = check assetClient->delete("/" + tag + "/schedules/" + scheduleId);
        io:println("Schedule removed. ", updated.assetTag, " now has ", updated.schedules.length(), " schedule(s).");
    } else {
        io:println("Invalid choice.");
    }
}