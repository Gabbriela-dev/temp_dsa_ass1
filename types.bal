type AssetStatus "AVAILABLE"|"LOANED_OUT"|"UNDER_MAINTENANCE"|"DISPOSED";

type Component record {
    string compId;
    string name;
    string description;
};

type ScheduleType "MAINTENANCE"|"BOOKING";

type Schedule record {
    string scheduleId;
    ScheduleType 'type;
    string dueDate;
    string description;
};

type Task record {
    string taskId;
    string description;
};

type WorkOrderStatus "OPEN"|"IN_PROGRESS"|"CLOSED";

type WorkOrder record {
    string orderId;
    WorkOrderStatus status;
    string description;
    Task[] tasks;
};

type Asset record {
    string assetTag;
    string name;
    string description;
    string institution;
    string site;
    AssetStatus status;
    string dateAcquired;
    Component[] components;
    Schedule[] schedules;
    WorkOrder[] workOrders;
};

type CreateResponse record {
    string message;
    Asset asset;
};