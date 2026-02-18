# Migration Status: Firebase → Appwrite + GCS Coldline

**Status:** 🟡 **In Progress** - Initial setup complete, service migration pending

---

## ✅ Completed

1. **Migration Guide Created:** `MIGRATION_TO_APPWRITE_GCS.md`
2. **Setup Steps Created:** `APPWRITE_SETUP_STEPS.md`
3. **Appwrite Config Created:** `lib/appwrite_config.dart`
4. **Appwrite Service Created:** `lib/services/appwrite_service.dart`
5. **Dependencies Updated:** `pubspec.yaml` (Appwrite added, Firebase commented)
6. **Main.dart Updated:** Appwrite initialization added (Firebase commented)

---

## 🔄 Next Steps (In Order)

### Step 1: Setup Appwrite Cloud & GCS
- [ ] Create Appwrite Cloud account
- [ ] Create Appwrite project
- [ ] Get Project ID and API Key
- [ ] Create GCS Coldline bucket
- [ ] Set GCS lifecycle policy (delete after 180 days)
- [ ] Update `lib/appwrite_config.dart` with your credentials

### Step 2: Create Appwrite Database Collections
- [ ] Create `institutes` collection
- [ ] Create `batches` collection
- [ ] Create `students` collection
- [ ] Create `attendance` collection
- [ ] Create `users` collection
- [ ] Create `error_logs` collection
- [ ] Set permissions for each collection

### Step 3: Migrate Auth Service
- [ ] Update `lib/services/auth_service.dart`
  - Replace `FirebaseAuth` → `AppwriteService.account`
  - Replace `FirebaseFirestore` → `AppwriteService.databases`
  - Implement PIN login logic
  - Test email auth (first login)
  - Test PIN login (subsequent logins)

### Step 4: Migrate Batch Service
- [ ] Update `lib/services/batch_service.dart`
  - Replace `FirebaseFirestore` → `AppwriteService.databases`
  - Update all CRUD operations
  - Test batch creation/management

### Step 5: Migrate Storage Service
- [ ] Create new `lib/services/storage_service.dart` (or update existing)
  - Implement GCS Coldline upload
  - Update photo upload paths
  - Test photo upload to GCS Coldline

### Step 6: Migrate Other Services
- [ ] Update `lib/services/offline_service.dart`
- [ ] Update `lib/services/error_logger.dart`
- [ ] Update `lib/data/attendance_repository.dart`

### Step 7: Migrate Screen Files
- [ ] `lib/presentation/screens/admin_attendance_screen.dart` (FirebaseStorage)
- [ ] `lib/presentation/screens/attendance_screen.dart` (FirebaseStorage)
- [ ] `lib/presentation/screens/teacher_attendance_screen.dart` (FirebaseStorage)
- [ ] All other screens using Firebase

### Step 8: Remove Firebase Dependencies
- [ ] Remove Firebase packages from `pubspec.yaml`
- [ ] Remove `firebase_options.dart`
- [ ] Remove Firebase initialization from `main.dart`
- [ ] Clean up unused Firebase imports

### Step 9: Testing
- [ ] Test all authentication flows
- [ ] Test batch management
- [ ] Test student management
- [ ] Test attendance marking with photos
- [ ] Test photo deletion after 6 months
- [ ] Test offline sync (if applicable)

### Step 10: Deployment
- [ ] Deploy to test environment
- [ ] Migrate existing data (if any)
- [ ] Deploy to production
- [ ] Monitor costs (should see 88–89% reduction)

---

## 📋 Files That Need Migration

### Services (Priority Order)
1. `lib/services/auth_service.dart` ⭐ **HIGH PRIORITY**
2. `lib/services/batch_service.dart` ⭐ **HIGH PRIORITY**
3. `lib/services/storage_service.dart` (create new or update) ⭐ **HIGH PRIORITY**
4. `lib/services/offline_service.dart`
5. `lib/services/error_logger.dart`
6. `lib/data/attendance_repository.dart`

### Screens (Update after services)
- `lib/presentation/screens/admin_attendance_screen.dart`
- `lib/presentation/screens/attendance_screen.dart`
- `lib/presentation/screens/teacher_attendance_screen.dart`
- `lib/presentation/screens/add_student_screen.dart`
- `lib/presentation/screens/batch_management_screen.dart`
- `lib/presentation/screens/student_management_screen.dart`
- `lib/presentation/screens/admin_home_screen.dart`
- `lib/presentation/screens/attendance_reports_screen.dart`
- `lib/presentation/screens/coder_dashboard_screen.dart`
- And others...

---

## 🔧 Quick Start Commands

### Install Appwrite Package
```bash
flutter pub get
```

### Update Appwrite Config
Edit `lib/appwrite_config.dart` and replace:
- `YOUR_PROJECT_ID` → Your Appwrite Project ID
- `YOUR_API_KEY` → Your Appwrite API Key
- `YOUR_GCS_BUCKET_NAME` → Your GCS bucket name

### Run App
```bash
flutter run
```

---

## 📚 Documentation

- **Migration Guide:** `MIGRATION_TO_APPWRITE_GCS.md`
- **Setup Steps:** `APPWRITE_SETUP_STEPS.md`
- **Appwrite Docs:** https://appwrite.io/docs
- **GCS Coldline Docs:** https://cloud.google.com/storage/docs/storage-classes#coldline

---

## 💰 Expected Cost Savings

| Metric | Before (Firebase) | After (Appwrite + GCS Coldline) | Savings |
|--------|-------------------|--------------------------------|---------|
| **Backend Cost (6 months)** | ₹18.8–21.2 lakh | ₹2.1–2.6 lakh | **88–89%** |
| **With ₹6L Revenue** | Loss: ₹12.8–15.2L | **Profit: ₹3.4–3.9L** ✅ | — |

---

*Migration is a significant undertaking. Start with Step 1 (Appwrite setup) and work through each step methodically.*
