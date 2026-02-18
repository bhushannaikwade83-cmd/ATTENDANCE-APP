# Quick Setup Checklist: Appwrite + GCS Coldline

**Follow this checklist step by step to set up both services.**

---

## ✅ Part 1: Appwrite Cloud Setup

### Account & Project
- [ ] Go to https://cloud.appwrite.io
- [ ] Sign up / Login
- [ ] Create new project: "Smart Attendance App"
- [ ] Copy **Project ID** (e.g., `smart-attendance`)

### Database Setup
- [ ] Create database: "Attendance Database"
- [ ] Database ID: `attendance_db`

### Collections (Create all 6)
- [ ] **`institutes`** collection
  - [ ] Attributes: name, code, address, createdAt
  - [ ] Permissions: users (read, create, update, delete)
- [ ] **`batches`** collection
  - [ ] Attributes: instituteId, name, year, timing, subjects[], studentCount, createdAt
  - [ ] Permissions: users (read, create, update, delete)
- [ ] **`students`** collection
  - [ ] Attributes: instituteId, batchId, name, rollNumber, email, createdAt
  - [ ] Permissions: users (read, create, update, delete)
- [ ] **`attendance`** collection
  - [ ] Attributes: instituteId, batchId, rollNumber, subject, date, photoUrl, timestamp, markedBy
  - [ ] Permissions: users (read, create, update, delete)
- [ ] **`users`** collection
  - [ ] Attributes: email, role, instituteId, pinHash, createdAt
  - [ ] Permissions: users (read, create, update, delete)
- [ ] **`error_logs`** collection
  - [ ] Attributes: error, stackTrace, context, appType, timestamp
  - [ ] Permissions: users (read, create)

### Authentication
- [ ] Go to **Auth** → Enable **Email/Password**
- [ ] (Optional) Create API Key in **Settings** → **API Keys**

### Storage (Optional)
- [ ] Create storage bucket: `photos_bucket` (if using Appwrite Storage)
- [ ] Or use direct GCS (recommended)

---

## ✅ Part 2: GCS Coldline Setup

### Google Cloud Account
- [ ] Go to https://console.cloud.google.com
- [ ] Sign in / Create account
- [ ] Create new project: "Smart Attendance App"
- [ ] Enable billing (add credit card)

### Enable APIs
- [ ] Enable **Cloud Storage API**

### Create Bucket
- [ ] Go to **Cloud Storage** → **Buckets**
- [ ] Click **"Create Bucket"**
- [ ] **Name:** `smart-attendance-photos` (or unique name)
- [ ] **Location:** Region → `us-central1`
- [ ] **Storage class:** **Coldline** ⭐
- [ ] **Access control:** Uniform
- [ ] Click **"Create"**

### Lifecycle Policy
- [ ] In bucket → **Lifecycle** tab
- [ ] Click **"Add a rule"**
- [ ] **Action:** Delete object
- [ ] **Condition:** Age ≥ 180 days
- [ ] **Save**

### Service Account (for Direct GCS Access)
- [ ] Go to **IAM & Admin** → **Service Accounts**
- [ ] Create service account: `appwrite-storage-access`
- [ ] **Role:** Storage Admin (or Storage Object Admin)
- [ ] Create key → **JSON**
- [ ] Download JSON file → Save as `assets/gcs-service-account.json`

---

## ✅ Part 3: Update App Configuration

### Update appwrite_config.dart
- [ ] Open `lib/appwrite_config.dart`
- [ ] Replace `YOUR_PROJECT_ID` → Your Appwrite Project ID
- [ ] Replace `YOUR_API_KEY` → Your Appwrite API Key (optional)
- [ ] Replace `YOUR_GCS_BUCKET_NAME` → Your GCS bucket name
- [ ] Verify `databaseId` matches your Appwrite database ID

### Add GCS Service Account (if using direct GCS)
- [ ] Create `assets/` folder (if not exists)
- [ ] Copy service account JSON to `assets/gcs-service-account.json`
- [ ] Update `pubspec.yaml` to include asset:
  ```yaml
  flutter:
    assets:
      - assets/gcs-service-account.json
  ```

### Install Dependencies
- [ ] Run: `flutter pub get`

---

## ✅ Part 4: Test Setup

### Test Appwrite
- [ ] Run: `flutter run`
- [ ] Check console for Appwrite connection errors
- [ ] If errors, verify Project ID in `appwrite_config.dart`

### Test GCS
- [ ] In GCS Console → Upload a test file
- [ ] Verify storage class shows **"Coldline"**
- [ ] Verify lifecycle rule is active

---

## 📋 Quick Reference: Your Credentials

**After setup, fill these in:**

### Appwrite
- **Endpoint:** `https://cloud.appwrite.io/v1`
- **Project ID:** `_________________` (fill this)
- **Database ID:** `attendance_db` (or your custom name)
- **API Key:** `_________________` (optional)

### GCS
- **Bucket Name:** `_________________` (fill this)
- **Region:** `us-central1`
- **Storage Class:** `COLDLINE`
- **Service Account JSON:** `assets/gcs-service-account.json`

---

## 🎯 Next Steps After Setup

1. ✅ **Update `lib/appwrite_config.dart`** with your credentials
2. ✅ **Test connection** (run app)
3. ✅ **Start migrating services** (follow `MIGRATION_TO_APPWRITE_GCS.md`)
4. ✅ **Begin with `auth_service.dart`**

---

## 📚 Detailed Guides

- **Complete Setup Guide:** `SETUP_GUIDE_APPWRITE_GCS.md` (detailed step-by-step)
- **Migration Guide:** `MIGRATION_TO_APPWRITE_GCS.md` (code migration steps)
- **Migration Status:** `MIGRATION_STATUS.md` (what's done, what's next)

---

**Estimated setup time:** 30–60 minutes  
**Estimated migration time:** 2–4 weeks (for full code migration)

*Follow this checklist and the detailed guides, and you'll have both services set up!*
