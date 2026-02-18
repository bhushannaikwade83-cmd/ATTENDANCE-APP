# Complete Setup Guide: Appwrite Cloud + GCS Coldline

**Step-by-step instructions to set up both Appwrite and GCS Coldline for your Smart Attendance App.**

---

## Part 1: Setup Appwrite Cloud

### Step 1.1: Create Appwrite Cloud Account

1. **Go to:** https://cloud.appwrite.io
2. **Click:** "Sign Up" (or "Log In" if you already have an account)
3. **Sign up with:**
   - Email: `naikwadebhushan@gmail.com` (or your email)
   - Password: (create a strong password)
4. **Verify your email** (check inbox)

---

### Step 1.2: Create Appwrite Project

1. **After login**, you'll see the Appwrite Console dashboard
2. **Click:** "Create Project" button (top right or center)
3. **Fill in:**
   - **Project Name:** `Smart Attendance App` (or any name)
   - **Project ID:** Will auto-generate (or customize it, e.g., `smart-attendance`)
4. **Click:** "Create"
5. **Copy your Project ID** — you'll need this! (e.g., `smart-attendance` or `67abc123def456`)

---

### Step 1.3: Get Appwrite API Key (Optional - for server-side)

**Note:** API Key is only needed for server-side operations. For client-side Flutter app, you don't need it.

1. In your project → **Settings** (left sidebar)
2. Click **"API Keys"** tab
3. Click **"Create API Key"**
4. **Name:** `Server Key` (or any name)
5. **Scopes:** Select all (or specific ones you need)
6. **Click:** "Create"
7. **Copy the API Key** — **keep this secret!** (you'll only see it once)

---

### Step 1.4: Create Appwrite Database

1. In your project → **Databases** (left sidebar)
2. Click **"Create Database"**
3. **Name:** `Attendance Database`
4. **Database ID:** `attendance_db` (or auto-generated)
5. **Click:** "Create Database"

---

### Step 1.5: Create Collections in Appwrite Database

Create these collections one by one:

#### Collection 1: `institutes`

1. In your database → Click **"Create Collection"**
2. **Collection ID:** `institutes`
3. **Name:** `Institutes`
4. **Click:** "Create Collection"
5. **Go to "Settings" tab** → **Permissions:**
   - **Read:** `users` (any authenticated user)
   - **Create:** `users` (any authenticated user)
   - **Update:** `users` (any authenticated user)
   - **Delete:** `users` (any authenticated user)
6. **Go to "Attributes" tab** → **Add these attributes:**
   - Click **"+ Add Attribute"**
   - **`name`** (String, 255 chars, required)
   - **`code`** (String, 50 chars, required, unique)
   - **`address`** (String, 500 chars, optional)
   - **`createdAt`** (DateTime, required)
   - **`createdBy`** (String, 255 chars, optional)

#### Collection 2: `batches`

1. **Create Collection** → **Collection ID:** `batches`
2. **Permissions:** Same as institutes
3. **Attributes:**
   - **`instituteId`** (String, 255 chars, required)
   - **`name`** (String, 255 chars, required)
   - **`year`** (String, 50 chars, required)
   - **`timing`** (String, 100 chars, required)
   - **`subjects`** (String[], required) — **Type:** String Array
   - **`studentCount`** (Integer, default: 0)
   - **`createdAt`** (DateTime, required)
   - **`createdBy`** (String, 255 chars, optional)

#### Collection 3: `students`

1. **Create Collection** → **Collection ID:** `students`
2. **Permissions:** Same as institutes
3. **Attributes:**
   - **`instituteId`** (String, 255 chars, required)
   - **`batchId`** (String, 255 chars, required)
   - **`name`** (String, 255 chars, required)
   - **`rollNumber`** (String, 50 chars, required)
   - **`email`** (String, 255 chars, optional)
   - **`batchName`** (String, 255 chars, optional) — for backward compatibility
   - **`batchTiming`** (String, 100 chars, optional) — for backward compatibility
   - **`createdAt`** (DateTime, required)

#### Collection 4: `attendance`

1. **Create Collection** → **Collection ID:** `attendance`
2. **Permissions:** Same as institutes
3. **Attributes:**
   - **`instituteId`** (String, 255 chars, required)
   - **`batchId`** (String, 255 chars, required)
   - **`batchName`** (String, 255 chars, optional)
   - **`rollNumber`** (String, 50 chars, required)
   - **`subject`** (String, 100 chars, required)
   - **`date`** (String, 50 chars, required) — Format: YYYY-MM-DD
   - **`photoUrl`** (String, 500 chars, optional) — GCS URL
   - **`timestamp`** (DateTime, required)
   - **`markedBy`** (String, 255 chars, required) — User ID
   - **`latitude`** (Double, optional)
   - **`longitude`** (Double, optional)

#### Collection 5: `users`

1. **Create Collection** → **Collection ID:** `users`
2. **Permissions:** Same as institutes
3. **Attributes:**
   - **`email`** (String, 255 chars, required, unique)
   - **`role`** (String, 50 chars, required) — Values: 'admin', 'teacher', 'coder'
   - **`instituteId`** (String, 255 chars, optional)
   - **`pinHash`** (String, 255 chars, optional) — Hashed PIN for PIN login
   - **`createdAt`** (DateTime, required)

#### Collection 6: `error_logs`

1. **Create Collection** → **Collection ID:** `error_logs`
2. **Permissions:**
   - **Read:** `users` (any authenticated user)
   - **Create:** `users` (any authenticated user)
   - **Update:** None (read-only after creation)
   - **Delete:** `users` (any authenticated user)
3. **Attributes:**
   - **`error`** (String, 1000 chars, required)
   - **`stackTrace`** (String, 5000 chars, optional)
   - **`context`** (String, 500 chars, optional)
   - **`appType`** (String, 50 chars, optional) — Values: 'admin', 'student'
   - **`timestamp`** (DateTime, required)
   - **`userId`** (String, 255 chars, optional)

---

### Step 1.6: Enable Appwrite Authentication

1. In your project → **Auth** (left sidebar)
2. **Enable Email/Password authentication:**
   - Toggle **"Email/Password"** to **ON**
   - **Email verification:** Optional (you can disable for now)
3. **Save**

---

### Step 1.7: Create Appwrite Storage Bucket (Optional - if using Appwrite Storage)

**Note:** You can use direct GCS instead (recommended for Coldline).

1. In your project → **Storage** (left sidebar)
2. Click **"Create Bucket"**
3. **Bucket ID:** `photos_bucket`
4. **Name:** `Attendance Photos`
5. **File size limit:** 10 MB (or as needed)
6. **Allowed file extensions:** `jpg`, `jpeg`, `png`
7. **Permissions:** Same as collections
8. **Click:** "Create"

---

### Step 1.8: Copy Your Appwrite Credentials

**You'll need these values:**

- **Endpoint:** `https://cloud.appwrite.io/v1` (standard)
- **Project ID:** (copy from your project settings, e.g., `smart-attendance`)
- **Database ID:** `attendance_db` (or whatever you named it)
- **API Key:** (only if needed for server-side, optional)

---

## Part 2: Setup Google Cloud Storage (GCS) Coldline

### Step 2.1: Create Google Cloud Account

1. **Go to:** https://console.cloud.google.com
2. **Sign in** with your Google account (or create one)
3. **Create a new project:**
   - Click **"Select a project"** → **"New Project"**
   - **Project Name:** `Smart Attendance App` (or any name)
   - **Project ID:** Will auto-generate (e.g., `smart-attendance-123456`)
   - **Click:** "Create"
4. **Select your project** from the dropdown

---

### Step 2.2: Enable Billing

1. **Go to:** **Billing** (left sidebar)
2. **Link a billing account** (add credit card)
3. **Note:** You'll only pay for what you use (GCS Coldline is very cheap)

---

### Step 2.3: Enable Cloud Storage API

1. **Go to:** **APIs & Services** → **Library**
2. **Search:** "Cloud Storage API"
3. **Click:** "Cloud Storage API"
4. **Click:** "Enable"

---

### Step 2.4: Create GCS Coldline Bucket

1. **Go to:** **Cloud Storage** → **Buckets** (left sidebar)
2. **Click:** "Create Bucket"
3. **Fill in:**

   **Name:**
   - **Bucket name:** `smart-attendance-photos` (must be globally unique)
   - Try variations if name is taken: `smart-attendance-photos-2025`, `digitrix-attendance-photos`, etc.

   **Choose where to store your data:**
   - **Location type:** **Region**
   - **Region:** `us-central1` (Iowa) — **recommended** (cheapest)

   **Choose a storage class:**
   - **Storage class:** **Coldline** ⭐ (this is the cheapest option)

   **Choose how to control access to objects:**
   - **Access control:** **Uniform** (recommended)

   **Choose how to protect object data:**
   - **Protection tools:** Leave defaults (or enable versioning if needed)

4. **Click:** "Create"

---

### Step 2.5: Set Lifecycle Policy (Auto-delete after 180 days)

1. **In your bucket** → Click **"Lifecycle"** tab
2. **Click:** "Add a rule"
3. **Rule name:** `delete-after-180-days`
4. **Action:** Select **"Delete object"**
5. **Condition:**
   - **Age:** `180` days
6. **Click:** "Create"

**This will automatically delete photos 180 days (6 months) after upload.**

---

### Step 2.6: Create Service Account (for Direct GCS Access)

**If you want to upload directly to GCS from your app:**

1. **Go to:** **IAM & Admin** → **Service Accounts**
2. **Click:** "Create Service Account"
3. **Fill in:**
   - **Service account name:** `appwrite-storage-access`
   - **Service account ID:** (auto-generated)
   - **Description:** `Service account for Smart Attendance App storage access`
4. **Click:** "Create and Continue"
5. **Grant access:**
   - **Role:** Select **"Storage Admin"** (or "Storage Object Admin" for limited access)
6. **Click:** "Continue" → "Done"
7. **Create Key:**
   - Click on the service account you just created
   - **Go to "Keys" tab** → **"Add Key"** → **"Create new key"**
   - **Key type:** **JSON**
   - **Click:** "Create"
   - **Download the JSON file** — **keep this secure!** (you'll need it in your app)

---

### Step 2.7: Copy Your GCS Credentials

**You'll need these values:**

- **Bucket Name:** (e.g., `smart-attendance-photos`)
- **Region:** `us-central1`
- **Service Account JSON:** (the file you downloaded)

---

## Part 3: Update Your App Configuration

### Step 3.1: Update Appwrite Config

1. **Open:** `lib/appwrite_config.dart`
2. **Replace these values:**

```dart
class AppwriteConfig {
  // Replace with your Appwrite endpoint (usually this is correct)
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  
  // Replace with your Appwrite Project ID (from Step 1.2)
  static const String projectId = 'YOUR_PROJECT_ID'; // ← Change this!
  
  // Replace with your Appwrite API Key (from Step 1.3, optional)
  static const String apiKey = 'YOUR_API_KEY'; // ← Change this (optional)
  
  // Replace with your GCS bucket name (from Step 2.4)
  static const String gcsBucketName = 'YOUR_GCS_BUCKET_NAME'; // ← Change this!
  
  // Region (usually correct)
  static const String gcsRegion = 'us-central1';
  
  // Database ID (from Step 1.4)
  static const String databaseId = 'attendance_db'; // ← Change if different!
  
  // Collection IDs (from Step 1.5)
  static const String institutesCollectionId = 'institutes';
  static const String batchesCollectionId = 'batches';
  static const String studentsCollectionId = 'students';
  static const String attendanceCollectionId = 'attendance';
  static const String usersCollectionId = 'users';
  static const String errorLogsCollectionId = 'error_logs';
  
  // Storage bucket ID (from Step 1.7, if using Appwrite Storage)
  static const String storageBucketId = 'photos_bucket';
}
```

**Example after filling:**
```dart
static const String projectId = 'smart-attendance';
static const String gcsBucketName = 'smart-attendance-photos';
static const String databaseId = 'attendance_db';
```

---

### Step 3.2: Add GCS Service Account JSON (if using direct GCS)

1. **Create folder:** `assets/` (if not exists)
2. **Copy** your service account JSON file to `assets/gcs-service-account.json`
3. **Update `pubspec.yaml`** to include the asset:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/gcs-service-account.json
```

---

## Part 4: Verify Setup

### Step 4.1: Test Appwrite Connection

1. **Update `lib/appwrite_config.dart`** with your credentials
2. **Run:** `flutter pub get`
3. **Run:** `flutter run`
4. **Check console** for any Appwrite connection errors

### Step 4.2: Test GCS Bucket

1. **In Google Cloud Console** → **Cloud Storage** → **Buckets**
2. **Click your bucket** → **"Upload files"**
3. **Upload a test file**
4. **Verify:**
   - File appears in bucket
   - Storage class shows **"Coldline"**
   - Lifecycle rule is active

---

## Quick Reference: What You Need

### Appwrite Credentials
- ✅ **Endpoint:** `https://cloud.appwrite.io/v1`
- ✅ **Project ID:** (from Appwrite Console)
- ✅ **Database ID:** `attendance_db` (or your custom name)
- ✅ **Collection IDs:** `institutes`, `batches`, `students`, `attendance`, `users`, `error_logs`
- ✅ **API Key:** (optional, for server-side)

### GCS Credentials
- ✅ **Bucket Name:** (e.g., `smart-attendance-photos`)
- ✅ **Region:** `us-central1`
- ✅ **Storage Class:** `COLDLINE`
- ✅ **Service Account JSON:** (for direct GCS access)

---

## Troubleshooting

### Appwrite Issues

**Problem:** "Project not found"
- **Solution:** Check your Project ID in `appwrite_config.dart` matches Appwrite Console

**Problem:** "Unauthorized"
- **Solution:** Check your API endpoint and Project ID are correct

**Problem:** "Collection not found"
- **Solution:** Make sure you created all collections in Appwrite Console

### GCS Issues

**Problem:** "Bucket not found"
- **Solution:** Check bucket name in `appwrite_config.dart` matches GCS Console

**Problem:** "Permission denied"
- **Solution:** Check service account has "Storage Admin" or "Storage Object Admin" role

**Problem:** "Storage class not Coldline"
- **Solution:** Recreate bucket with Coldline storage class, or change storage class in bucket settings

---

## Next Steps After Setup

1. ✅ **Update `lib/appwrite_config.dart`** with your credentials
2. ✅ **Test Appwrite connection** (run app, check for errors)
3. ✅ **Start migrating services** (follow `MIGRATION_TO_APPWRITE_GCS.md`)
4. ✅ **Begin with `auth_service.dart`** migration

---

## Cost Verification

After setup, monitor costs:

- **Appwrite Pro Plan:** $25/month = ₹2,000/month
- **GCS Coldline (75 TB):** ₹1,25,250/month = ₹7,51,500 per 6 months
- **Total:** ~₹2.1–2.6 lakh per 6 months (vs ₹18.8–21.2 lakh with Firebase)

**Expected savings:** ₹16.7–18.6 lakh per 6 months (88–89% reduction)

---

*Follow these steps in order, and you'll have both Appwrite and GCS Coldline set up!*
