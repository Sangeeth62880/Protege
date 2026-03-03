---
description: How to debug and fix syllabus generation issues
---

# Debugging Syllabus Generation

## Quick Diagnosis

### 1. Check Backend is Running
```bash
curl http://localhost:8000/health
```
Expected: `{"status":"healthy"}`

### 2. Check Your IP (for physical devices)
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```
Update `lib/core/constants/api_constants.dart` with the correct IP.

### 3. Test Syllabus Endpoint
```bash
curl -X POST http://localhost:8000/api/v1/learning/generate-syllabus-test \
  -H "Content-Type: application/json" \
  -d '{"topic":"Test","goal":"hobby","experience_level":"beginner","daily_time_minutes":30}' \
  --max-time 120
```

### 4. Test Python Imports
```bash
cd protege_backend
python3 -c "from app.api.routes.learning import router; print('OK')"
```

## Common Issues

| Error | Cause | Fix |
|-------|-------|-----|
| Connection timed out | IP changed | Update `_physicalDeviceUrl` in `api_constants.dart` |
| 'Null' is not a subtype of 'String' | Backend returns null | Add null checks in model `.fromJson()` |
| Import error / SyntaxError | Broken Python file | Check for duplicate docstrings or missing quotes |
| 404 Not Found | Router not registered | Check `main.py` imports and `include_router` calls |

## Starting Backend
// turbo
```bash
cd protege_backend && python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Running Flutter on Device
```bash
cd protege_app && flutter run -d <device_id>
```

Get device ID with:
// turbo
```bash
flutter devices
```
