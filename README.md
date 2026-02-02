# Smart Attendance App

A Flutter-based attendance management system with face recognition, offline support, and comprehensive error logging.

## Features

- **Face Recognition**: Automatic student identification using ML Kit
- **Offline Mode**: Works without internet, syncs when online
- **Daily Attendance Summary**: Quick overview with analytics
- **Student Search & Filters**: Easy navigation
- **Attendance Reports**: Track and analyze attendance data
- **Multi-class Support**: Manage multiple subjects/classes
- **Error Logging Dashboard**: Centralized error tracking for developers

## Coder Dashboard

The app includes a separate coder dashboard for viewing all errors from both admin and student apps.

### Access Coder Dashboard

1. Create a coder account (see setup instructions below)
2. Navigate to `/coder-login` route
3. Login with coder credentials
4. View all errors with detailed information

### Creating Coder Account

To create a coder account, you need to:

1. Create a Firebase Auth user with email/password
2. Add document to `coders` collection in Firestore:
   ```json
   {
     "uid": "coder_user_uid",
     "email": "coder001@gmail.com",
     "name": "Coder 001",
     "role": "coder",
     "createdAt": "timestamp"
   }
   ```

Or use the script: `scripts/create_coder_account.dart`

## Error Handling

- **Users see**: Friendly, non-technical error messages
- **Developers see**: Detailed error logs in coder dashboard with:
  - Error type and code
  - Full stack trace
  - Context (where error occurred)
  - User information
  - Timestamp
  - Additional debugging data

All errors are automatically logged to Firestore `error_logs` collection.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
