# How to Run the Attendance App

This guide explains how to run both the **Main Attendance App** and the **Super Admin App**.

## Prerequisites

1. **Flutter SDK** installed (version 3.10.3 or higher)
   - Check: `flutter --version`
   - Install: https://flutter.dev/docs/get-started/install

2. **Firebase Project** configured
   - Both apps use Firebase project: `smartattendanceapp-bc2fe`
   - Firebase options files are already configured

3. **Development Tools**
   - For mobile: Android Studio / Xcode
   - For web: Chrome browser
   - For desktop: Windows/macOS/Linux support

---

## 🚀 Running the Main Attendance App

The main app is located in the **root directory** of the project.

### Step 1: Navigate to Root Directory
```bash
cd C:\Users\naikw\OneDrive\Desktop\ATTENDANCE-APP-main
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Run the App

**For Web (Chrome):**
```bash
flutter run -d chrome
```

**For Mobile (Android):**
```bash
flutter run
# or specify device
flutter run -d <device-id>
```

**For Mobile (iOS - macOS only):**
```bash
flutter run -d ios
```

**For Desktop (Windows):**
```bash
flutter run -d windows
```

**List available devices:**
```bash
flutter devices
```

---

## 🔐 Running the Super Admin App

The super admin app is located in the **`super_admin_app/`** directory.

### Step 1: Navigate to Super Admin Directory
```bash
cd C:\Users\naikw\OneDrive\Desktop\ATTENDANCE-APP-main\super_admin_app
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Run the App

**For Web (Chrome) - Recommended:**
```bash
flutter run -d chrome
```

**For Mobile:**
```bash
flutter run
```

**For Desktop:**
```bash
flutter run -d windows
```

---

## 📱 Running Both Apps Simultaneously

You can run both apps at the same time by opening **two terminal windows**:

### Terminal 1 - Main App
```bash
cd C:\Users\naikw\OneDrive\Desktop\ATTENDANCE-APP-main
flutter pub get
flutter run -d chrome
```

### Terminal 2 - Super Admin App
```bash
cd C:\Users\naikw\OneDrive\Desktop\ATTENDANCE-APP-main\super_admin_app
flutter pub get
flutter run -d chrome
```

**Note:** If running on the same device, they will use different ports automatically.

---

## 🔧 Troubleshooting

### Issue: "Flutter command not found"
**Solution:** Add Flutter to your PATH or use the full path to Flutter executable.

### Issue: "Firebase not initialized"
**Solution:** 
- Verify `firebase_options.dart` files exist in both apps
- Check Firebase project configuration
- Run `flutter pub get` again

### Issue: "Dependencies not found"
**Solution:**
```bash
flutter clean
flutter pub get
```

### Issue: "Port already in use"
**Solution:** 
- Close other Flutter apps
- Or specify a different port: `flutter run -d chrome --web-port 8080`

### Issue: "No devices found"
**Solution:**
- For web: Ensure Chrome is installed
- For mobile: Connect device or start emulator
- Check: `flutter devices`

---

## 📋 Quick Reference Commands

### Main App
```bash
# Navigate
cd C:\Users\naikw\OneDrive\Desktop\ATTENDANCE-APP-main

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on connected device
flutter run
```

### Super Admin App
```bash
# Navigate
cd C:\Users\naikw\OneDrive\Desktop\ATTENDANCE-APP-main\super_admin_app

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on connected device
flutter run
```

---

## 🎯 What Each App Does

### Main Attendance App
- Teacher login and attendance marking
- GPS verification
- Photo capture for attendance
- Student management
- Institute setup
- Attendance reports

### Super Admin App
- Super admin login (coders/{uid} with isSuperAdmin=true)
- View all institutes
- Institute details (Overview, Students, Attendance, GPS config)
- Student history with photo previews
- Multi-institute management

---

## 🔐 Authentication

### Main App
- Regular teacher/admin login
- PIN-based login
- Institute-specific access

### Super Admin App
- Super admin login via Firebase
- PIN authentication available
- Access to all institutes

---

## 📝 Notes

1. **First Time Setup:** Run `flutter pub get` in both directories before first run
2. **Hot Reload:** Press `r` in terminal to hot reload, `R` for hot restart
3. **Web Development:** Chrome is recommended for web development
4. **Firebase:** Both apps share the same Firebase project (`smartattendanceapp-bc2fe`)
5. **Backend:** Both apps use Firebase (Auth, Firestore) and Cloud Functions

---

## 🆘 Need Help?

- Check `SETUP_CHECKLIST.md` for backend setup
- Review `README.md` for architecture details
- Verify Firebase configuration in `firebase_options.dart` files
