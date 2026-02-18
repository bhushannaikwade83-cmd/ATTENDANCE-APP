# GCS Coldline Setup - 180 Day Photo Storage

## ✅ Perfect Match: GCS Coldline for 180-Day Storage

**GCS Coldline is PERFECT for your 180-day requirement:**
- ✅ **90-day minimum** - Your 180 days exceeds this requirement
- ✅ **85% cheaper** than Appwrite Storage
- ✅ **Automatic deletion** via lifecycle policies
- ✅ **Cost:** ₹2,97,000/year for 75TB (vs ₹20,97,000 with Appwrite Storage)

---

## 📋 Step-by-Step Setup

### Step 1: Create GCS Coldline Bucket

1. Go to [Google Cloud Console](https://console.cloud.google.com/storage)
2. Click **"Create Bucket"**
3. **Bucket Details:**
   - **Name:** `attendance-photos-coldline` (must be globally unique)
   - **Location type:** **Region**
   - **Region:** `us-central1` (Iowa) - **cheapest option**
   - **Storage class:** **Coldline** ⭐
   - **Access control:** **Uniform** (recommended)
4. Click **"Create"**

---

### Step 2: Set Lifecycle Policy (Auto-delete after 180 days)

**This is the KEY step - photos will automatically delete after 180 days!**

1. **In your bucket** → Click **"Lifecycle"** tab
2. **Click:** "Add a rule"
3. **Rule Configuration:**
   - **Rule name:** `delete-after-180-days`
   - **Action:** Select **"Delete object"**
   - **Condition:**
     - **Age:** `180` days
     - ✅ **Matches creation time** (delete 180 days after upload)
4. **Click:** "Create"

**Result:** All photos uploaded to this bucket will be **automatically deleted 180 days after upload**.

---

### Step 3: Create Service Account (for App Access)

**To upload photos from your app, you need a service account:**

1. **Go to:** **IAM & Admin** → **Service Accounts**
2. **Click:** "Create Service Account"
3. **Fill in:**
   - **Service account name:** `attendance-app-storage`
   - **Service account ID:** (auto-generated)
   - **Description:** `Service account for Attendance App GCS storage access`
4. **Click:** "Create and Continue"
5. **Grant access:**
   - **Role:** Select **"Storage Object Admin"** (or "Storage Admin" for full access)
6. **Click:** "Continue" → "Done"
7. **Create Key:**
   - Click on the service account you just created
   - **Go to "Keys" tab** → **"Add Key"** → **"Create new key"**
   - **Key type:** **JSON**
   - **Click:** "Create"
   - **Download the JSON file** — **KEEP THIS SECURE!** (contains private key)

---

### Step 4: Update App Configuration

**Update `lib/appwrite_config.dart`:**

```dart
class AppwriteConfig {
  // ... existing config ...
  
  // GCS Coldline bucket configuration
  static const String gcsBucketName = 'attendance-photos-coldline'; // Your bucket name
  static const String gcsRegion = 'us-central1';
  static const String gcsStorageClass = 'COLDLINE';
  
  // GCS Service Account (load from secure storage, not hardcoded!)
  // static const String gcsServiceAccountJson = '...'; // Load from secure storage
}
```

---

### Step 5: Install Required Packages

**Add to `pubspec.yaml`:**

```yaml
dependencies:
  # ... existing dependencies ...
  
  # GCS Storage
  google_cloud_storage: ^5.0.0  # Or use http package with OAuth2
  # OR use google_sign_in for OAuth2 authentication
```

---

## 🔧 Implementation Options

### Option A: Direct GCS Upload (Recommended)

**Use `google_cloud_storage` package:**

```dart
import 'package:google_cloud_storage/google_cloud_storage.dart';

// Initialize GCS client
final gcs = GoogleCloudStorage.authenticated(
  serviceAccountCredentials: serviceAccountJson,
);

// Upload photo
final file = await gcs.bucket(bucketName).writeBytes(
  objectName: storagePath,
  bytes: photoBytes,
  metadata: {
    'storageClass': 'COLDLINE',
    'contentType': 'image/jpeg',
  },
);
```

### Option B: HTTP API with OAuth2

**Use `http` package with OAuth2:**

```dart
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;

// Get OAuth2 token
final credentials = oauth2.ClientCredentials(
  serviceAccount['client_id'],
  serviceAccount['client_secret'],
);

// Upload via REST API
final response = await http.post(
  Uri.parse('https://storage.googleapis.com/upload/storage/v1/b/$bucketName/o?uploadType=media&name=$objectName&storageClass=COLDLINE'),
  headers: {
    'Authorization': 'Bearer ${credentials.accessToken}',
    'Content-Type': 'image/jpeg',
  },
  body: photoBytes,
);
```

---

## 📊 Cost Breakdown (180-Day Storage)

### GCS Coldline Pricing

| Item | Cost |
|------|------|
| **Storage (75TB)** | ₹24,750/month = **₹2,97,000/year** |
| **Operations (writes)** | ~₹50,000/year |
| **Operations (reads)** | ~₹50,000/year |
| **Total** | **~₹3,97,000/year** |

### Comparison

| Storage Option | Annual Cost | Savings |
|----------------|------------|---------|
| **Appwrite Storage** | ₹20,97,000 | Baseline |
| **GCS Coldline (180 days)** | ₹2,97,000 | **Save ₹18 lakh/year (85%)** |

---

## ✅ Lifecycle Policy Verification

### Verify Lifecycle Policy is Active

1. **Go to:** Google Cloud Console → Storage → Your Bucket
2. **Click:** "Lifecycle" tab
3. **Verify rule exists:**
   - Rule name: `delete-after-180-days`
   - Action: Delete object
   - Condition: Age ≥ 180 days

### Test Lifecycle Policy

1. **Upload a test photo**
2. **Check creation date** in bucket
3. **Wait 180 days** (or modify policy temporarily to 1 day for testing)
4. **Verify photo is deleted** automatically

---

## 🔒 Security Best Practices

### 1. Secure Service Account Key

**DO NOT commit service account JSON to git!**

```dart
// ✅ GOOD: Load from secure storage
final serviceAccountJson = await SecureStorage.read('gcs_service_account');

// ❌ BAD: Hardcode in code
static const String gcsServiceAccountJson = '{"private_key": "..."}';
```

### 2. Use Environment Variables

```dart
// Load from environment variables
final bucketName = Platform.environment['GCS_BUCKET_NAME'] ?? 'default-bucket';
```

### 3. Restrict Service Account Permissions

- Use **"Storage Object Admin"** (not "Storage Admin")
- Limit to specific bucket only
- Use IAM conditions if possible

---

## 📝 Storage Path Structure

**Photos are organized as:**
```
institute_id/
  batch_year/
    rollNumber/
      subject/
        YYYY-MM-DD/
          photo.jpg
```

**Example:**
```
6981f623001657ab0c90/
  2024/
    STU001/
      mathematics/
        2024-02-03/
          photo.jpg
```

**Lifecycle policy applies to ALL files in bucket** - all photos deleted after 180 days automatically.

---

## 🎯 Benefits of 180-Day Storage

### ✅ Perfect for Your Use Case

1. **6-month batches** - Photos kept for entire batch duration
2. **Automatic cleanup** - No manual deletion needed
3. **Cost savings** - 85% cheaper than Appwrite Storage
4. **Compliance** - Old photos automatically removed
5. **Predictable costs** - Storage stays at ~75TB (rolling window)

### 📊 Storage Timeline

| Day | Action | Storage |
|-----|--------|---------|
| **Day 0** | Photo uploaded | Photo stored |
| **Day 1-179** | Photo accessible | Photo stored |
| **Day 180** | **Lifecycle policy triggers** | **Photo automatically deleted** |

**Result:** Storage stays constant at ~75TB (photos from last 180 days only)

---

## 🚀 Migration from Appwrite Storage

### If Currently Using Appwrite Storage

1. **Set up GCS Coldline bucket** (Steps 1-3 above)
2. **Update code** to use GCS instead of Appwrite Storage
3. **Migrate existing photos** (optional - or let them expire naturally)
4. **Update `storage_service.dart`** to use GCS

### Code Changes Required

**Before (Appwrite Storage):**
```dart
final file = await AppwriteService.storage.createFile(...);
```

**After (GCS Coldline):**
```dart
final result = await GCSStorageService.uploadAttendancePhoto(...);
```

---

## ✅ Checklist

- [ ] GCS Coldline bucket created
- [ ] Lifecycle policy set to delete after 180 days
- [ ] Service account created with Storage Object Admin role
- [ ] Service account JSON key downloaded (keep secure!)
- [ ] `appwrite_config.dart` updated with GCS bucket name
- [ ] Code updated to use GCS instead of Appwrite Storage
- [ ] Test upload works
- [ ] Test lifecycle policy (or wait 180 days)
- [ ] Service account key stored securely (not in code)

---

## 📞 Support

**If you need help:**
- GCS Documentation: https://cloud.google.com/storage/docs
- Lifecycle Policies: https://cloud.google.com/storage/docs/lifecycle
- Service Accounts: https://cloud.google.com/iam/docs/service-accounts

---

## 🎉 Summary

**GCS Coldline + 180-Day Lifecycle Policy = Perfect Solution!**

- ✅ **85% cost savings** vs Appwrite Storage
- ✅ **Automatic deletion** after 180 days
- ✅ **Perfect fit** for 6-month batches
- ✅ **No manual cleanup** needed
- ✅ **Predictable costs** (~₹2.97 lakh/year for 75TB)

**Your photos will be stored for exactly 180 days, then automatically deleted!** 🎯
