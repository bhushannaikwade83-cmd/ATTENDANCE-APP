# Appwrite + GCS Coldline Setup Steps

## Step 1: Create Appwrite Cloud Account

1. Go to **https://cloud.appwrite.io**
2. Sign up / Login
3. Click **"Create Project"**
4. Name: `Smart Attendance App` (or your preferred name)
5. Copy your **Project ID** (you'll need this)

---

## Step 2: Get Appwrite Credentials

1. In Appwrite Console → **Settings** → **API Keys**
2. Create a new API Key (or use existing)
3. Copy:
   - **Project ID**
   - **API Endpoint** (usually `https://cloud.appwrite.io/v1`)
   - **API Key** (keep this secret!)

---

## Step 3: Create Appwrite Database

1. In Appwrite Console → **Databases**
2. Click **"Create Database"**
3. Name: `Attendance Database`
4. Database ID: `attendance_db` (or update in `appwrite_config.dart`)

### Create Collections

Create these collections in your database:

#### 1. `institutes` Collection
- **Collection ID:** `institutes`
- **Permissions:** 
  - Read: `users` (authenticated)
  - Create: `users` (authenticated)
  - Update: `users` (authenticated)
- **Attributes:**
  - `name` (String, required)
  - `code` (String, required, unique)
  - `address` (String, optional)
  - `createdAt` (DateTime, required)

#### 2. `batches` Collection
- **Collection ID:** `batches`
- **Permissions:** Same as institutes
- **Attributes:**
  - `instituteId` (String, required)
  - `name` (String, required)
  - `year` (String, required)
  - `timing` (String, required)
  - `subjects` (String[], required)
  - `studentCount` (Integer, default: 0)
  - `createdAt` (DateTime, required)

#### 3. `students` Collection
- **Collection ID:** `students`
- **Permissions:** Same as institutes
- **Attributes:**
  - `instituteId` (String, required)
  - `batchId` (String, required)
  - `name` (String, required)
  - `rollNumber` (String, required)
  - `email` (String, optional)
  - `createdAt` (DateTime, required)

#### 4. `attendance` Collection
- **Collection ID:** `attendance`
- **Permissions:** Same as institutes
- **Attributes:**
  - `instituteId` (String, required)
  - `batchId` (String, required)
  - `rollNumber` (String, required)
  - `subject` (String, required)
  - `date` (String, required) // Format: YYYY-MM-DD
  - `photoUrl` (String, optional) // GCS URL
  - `timestamp` (DateTime, required)
  - `markedBy` (String, required) // User ID

#### 5. `users` Collection
- **Collection ID:** `users`
- **Permissions:** Same as institutes
- **Attributes:**
  - `email` (String, required, unique)
  - `role` (String, required) // 'admin', 'teacher', 'coder'
  - `instituteId` (String, optional)
  - `pinHash` (String, optional) // Hashed PIN for PIN login
  - `createdAt` (DateTime, required)

#### 6. `error_logs` Collection
- **Collection ID:** `error_logs`
- **Permissions:** 
  - Read: `users` (authenticated)
  - Create: `users` (authenticated)
- **Attributes:**
  - `error` (String, required)
  - `stackTrace` (String, optional)
  - `context` (String, optional)
  - `appType` (String, optional) // 'admin' or 'student'
  - `timestamp` (DateTime, required)

---

## Step 4: Create GCS Coldline Bucket

1. Go to **Google Cloud Console** → **Cloud Storage**
2. Click **"Create Bucket"**
3. **Name:** `smart-attendance-photos` (or your preferred name)
4. **Location type:** Region
5. **Region:** `us-central1` (or your preferred region)
6. **Storage class:** **Coldline** ⭐
7. **Access control:** Uniform
8. Click **"Create"**

### Set Lifecycle Policy (Auto-delete after 180 days)

1. In bucket → **Lifecycle** tab
2. Click **"Add a rule"**
3. **Action:** Delete object
4. **Condition:** Age ≥ 180 days
5. Save

---

## Step 5: Configure Appwrite Storage (Option A)

### Option A: Use Appwrite Storage (connects to GCS)

1. In Appwrite Console → **Storage**
2. Click **"Create Bucket"**
3. **Name:** `photos_bucket`
4. **Bucket ID:** `photos_bucket`
5. **File size limit:** 10 MB (or as needed)
6. **Allowed file extensions:** `jpg`, `jpeg`, `png`
7. **Permissions:** Same as other collections

**Note:** Appwrite Storage can be configured to use GCS as backend (enterprise feature) or you can use direct GCS access (Option B).

---

## Step 6: Configure Direct GCS Access (Option B - Recommended)

### Create GCS Service Account

1. Go to **Google Cloud Console** → **IAM & Admin** → **Service Accounts**
2. Click **"Create Service Account"**
3. **Name:** `appwrite-storage-access`
4. **Role:** Storage Admin (or Storage Object Admin)
5. Click **"Create Key"** → **JSON**
6. Download the JSON file (keep it secure!)

### Use Direct GCS in Your App

- Use `google_cloud_storage` package
- Initialize with service account JSON
- Upload directly to GCS Coldline bucket

---

## Step 7: Update Your Code

1. **Update `lib/appwrite_config.dart`:**
   - Replace `YOUR_PROJECT_ID` with your actual Appwrite Project ID
   - Replace `YOUR_API_KEY` with your Appwrite API Key (server-side only)
   - Replace `YOUR_GCS_BUCKET_NAME` with your GCS bucket name

2. **Update `lib/main.dart`:**
   - Already updated to initialize Appwrite instead of Firebase

3. **Migrate Services:**
   - Follow `MIGRATION_TO_APPWRITE_GCS.md` for detailed steps
   - Start with `auth_service.dart`
   - Then `batch_service.dart`
   - Then storage services
   - Then all screen files

---

## Step 8: Test

1. **Test Appwrite connection:**
   - Run app
   - Check if Appwrite initializes without errors

2. **Test Authentication:**
   - Try email/password login (first login)
   - Try PIN login (subsequent logins)

3. **Test Database:**
   - Create an institute
   - Create a batch
   - Add a student

4. **Test Storage:**
   - Upload a photo
   - Verify it's in GCS Coldline bucket
   - Check storage class is Coldline

---

## Step 9: Deploy

1. **Test environment first:**
   - Deploy to test/staging
   - Test all features

2. **Production deployment:**
   - Deploy to production
   - Monitor costs (should see 88–89% reduction!)

---

## Cost Verification

After migration, verify costs:

- **Appwrite Pro Plan:** $25/month = ₹2,000/month = ₹12,000 per 6 months
- **GCS Coldline (75 TB):** ₹1,48,500 per 6 months
- **GCS Operations:** ₹50,000 – ₹1,00,000 per 6 months
- **Total:** ₹2,10,500 – ₹2,60,500 per 6 months

**Expected savings:** ₹16.7–18.6 lakh per 6 months (88–89% reduction)

---

## Support

- **Appwrite Docs:** https://appwrite.io/docs
- **Appwrite Discord:** https://discord.gg/appwrite
- **GCS Docs:** https://cloud.google.com/storage/docs

---

*Good luck with the migration! This will make your ₹6 lakh quotation profitable.* ✅
