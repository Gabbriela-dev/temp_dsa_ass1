@echo off
echo Creating institution...
curl -s -X POST http://localhost:8080/assets/institutions -H "Content-Type: application/json" -d "{\"name\": \"NUST\"}"
echo.
echo.

echo Creating asset...
curl -s -X POST http://localhost:8080/assets -H "Content-Type: application/json" -d "{\"assetTag\": \"NUST-LIB-3DP-001\", \"name\": \"Pro-Series 3D Printer\", \"description\": \"High-precision printer\", \"institution\": \"NUST\", \"site\": \"Main Campus\", \"status\": \"AVAILABLE\", \"dateAcquired\": \"2024-03-10\", \"components\": [], \"schedules\": [], \"workOrders\": []}"
echo.
echo.

echo Adding schedule...
curl -s -X POST http://localhost:8080/assets/NUST-LIB-3DP-001/schedules -H "Content-Type: application/json" -d "{\"scheduleId\": \"SCH-001\", \"type\": \"MAINTENANCE\", \"dueDate\": \"2026-01-01\", \"description\": \"Overdue calibration\"}"
echo.
echo.

echo Adding component...
curl -s -X POST http://localhost:8080/assets/NUST-LIB-3DP-001/components -H "Content-Type: application/json" -d "{\"compId\": \"C101\", \"name\": \"Stepper Motor\", \"description\": \"X-axis motor\"}"
echo.
echo.

echo Adding work order...
curl -s -X POST http://localhost:8080/assets/NUST-LIB-3DP-001/workorders -H "Content-Type: application/json" -d "{\"orderId\": \"WO-001\", \"status\": \"OPEN\", \"description\": \"Nozzle heat-bed failure\", \"tasks\": []}"
echo.
echo.

echo Adding task to work order...
curl -s -X POST http://localhost:8080/assets/NUST-LIB-3DP-001/workorders/WO-001/tasks -H "Content-Type: application/json" -d "{\"taskId\": \"T1\", \"description\": \"Check thermal sensor connectivity\"}"
echo.
echo.

echo Done. Final state:
curl -s http://localhost:8080/assets/NUST-LIB-3DP-001
echo.