# Super Admin App

Separate Flutter app for super admin operations.

## Folder
- `super_admin_app/`

## Uses same backend
- Firebase project: `smartattendanceapp-bc2fe`
- B2 secure file view via Cloud Functions:
  - `b2GetDownloadUrl`

## Features
- Super admin login (`coders/{uid}` with `isSuperAdmin=true` or role `super_admin`)
- All institutes list
- Institute detail tabs:
  - Overview
  - Students
  - Attendance (with photo thumbnails)
  - GPS config save/lock
- Student history:
  - Subject-wise folders
  - Daily attendance entries
  - Photo preview per day

## Run
```bash
cd super_admin_app
flutter pub get
flutter run -d chrome
# or mobile
flutter run
```
