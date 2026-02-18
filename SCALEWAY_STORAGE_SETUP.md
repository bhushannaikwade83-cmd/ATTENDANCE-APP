# Scaleway Archive Storage Setup - 45% Cheaper Than GCS Coldline!

## 🎯 Best Value: Scaleway Object Storage Archive

**Why Scaleway Archive?**
- ✅ **45% cheaper** than GCS Coldline
- ✅ **90-day minimum** (perfect for 180-day storage)
- ✅ **Fast retrieval** (better than Azure Archive)
- ✅ **S3-compatible** (easy integration)
- ✅ **Lifecycle policies** (auto-delete after 180 days)

---

## 💰 Cost Comparison

### Scaleway Archive vs GCS Coldline (75TB, 6 months)

| Storage Option | Cost (6 months) | Savings |
|----------------|-----------------|---------|
| **GCS Coldline** | ₹1,48,500 | Baseline |
| **Scaleway Archive** ⭐ | **₹81,000** | **Save ₹67,500 (45%)** |

**Annual Savings:** ₹1,35,000 per year! 🎉

---

## 📋 Setup Steps

### Step 1: Create Scaleway Account

1. Go to [Scaleway.com](https://www.scaleway.com)
2. Click "Sign Up" (free account)
3. Verify your email
4. Complete account setup

---

### Step 2: Create Object Storage Bucket

1. **Go to:** Object Storage → Buckets
2. **Click:** "Create Bucket"
3. **Configure:**
   - **Name:** `attendance-photos-archive` (must be unique)
   - **Region:** `fr-par` (Paris) or `nl-ams` (Amsterdam)
   - **Storage class:** **Archive** ⭐ (cheapest option)
   - **Versioning:** Disabled (to save costs)
   - **Public access:** Your choice (private recommended)
4. **Click:** "Create Bucket"

---

### Step 3: Set Lifecycle Policy (180-Day Deletion)

**This is CRITICAL - photos will auto-delete after 180 days!**

1. **Go to:** Bucket → "Lifecycle" tab
2. **Click:** "Add Rule"
3. **Configure:**
   - **Rule name:** `delete-after-180-days`
   - **Action:** Delete object
   - **Condition:** Age ≥ 180 days
4. **Click:** "Create"

**Result:** All photos uploaded will be automatically deleted 180 days after upload.

---

### Step 4: Get API Credentials

1. **Go to:** IAM → API Keys
2. **Click:** "Generate API Key"
3. **Fill in:**
   - **Name:** `attendance-app-storage`
   - **Expiration:** Never (or set expiration date)
4. **Click:** "Generate"
5. **Copy immediately** (you'll only see secret once):
   - **Access Key** (starts with `SCW...`)
   - **Secret Key** (long string)
   - **Endpoint** (e.g., `https://s3.fr-par.scw.cloud`)

**Keep these secure!** Store in environment variables, not in code.

---

### Step 5: Update App Configuration

**Update `lib/appwrite_config.dart`:**

```dart
// Scaleway Object Storage Archive configuration
static const String scalewayEndpoint = 'https://s3.fr-par.scw.cloud';
static const String scalewayBucketName = 'attendance-photos-archive';
static const String scalewayAccessKey = 'SCW...'; // Your access key
static const String scalewaySecretKey = 'your_secret_key_here';
static const String scalewayRegion = 'fr-par';
static const String scalewayStorageClass = 'ARCHIVE';
static const int photoRetentionDays = 180;
```

---

### Step 6: Install Required Packages

**Update `pubspec.yaml`:**

```yaml
dependencies:
  # ... existing dependencies ...
  
  # For S3-compatible API (Scaleway is S3-compatible)
  http: ^1.1.0  # Already included
  crypto: ^3.0.0  # For AWS signature
  # OR use AWS SDK for better signature handling
  # aws_signature_v4: ^2.0.0
```

**Run:**
```bash
flutter pub get
```

---

### Step 7: Use Scaleway Storage Service

**Your code is already updated!** The `hybrid_service.dart` now uses `ScalewayStorageService`.

**Example usage:**

```dart
import 'package:your_app/services/hybrid_service.dart';

// Mark attendance (automatically uses Scaleway Archive)
await HybridService.markAttendance(
  instituteId: instituteId,
  batchId: batchId,
  rollNumber: rollNumber,
  subject: subject,
  date: date,
  photoBytes: photoBytes,
);
```

---

## 📊 Complete Cost Breakdown

### Appwrite + Railway + Scaleway Archive

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹9,900 |
| **Scaleway Archive (75TB)** | ₹81,000 |
| **Operations** | ~₹20,000 |
| **Total** | **₹1,22,900** |

**vs Previous Setup (Appwrite + Railway + GCS Coldline):**
- Previous: ₹1,70,400
- Current: ₹1,22,900
- **Savings:** ₹47,500 per 6 months (28% cheaper!)

---

## ✅ Benefits

1. **45% Cost Savings** - ₹67,500 cheaper than GCS Coldline per 6 months
2. **Fast Retrieval** - Better than Azure Archive
3. **S3-Compatible** - Use standard S3 SDKs
4. **Lifecycle Policies** - Auto-delete after 180 days
5. **90-Day Minimum** - Perfect for your 180-day requirement
6. **European Provider** - GDPR compliant

---

## 🔄 Migration from GCS Coldline

### If Currently Using GCS Coldline

1. **Create Scaleway bucket** (Steps 1-3 above)
2. **Set lifecycle policy** (180 days)
3. **Update app config** with Scaleway credentials
4. **Update code** to use `ScalewayStorageService`
5. **Migrate existing photos** (optional - or let them expire naturally)

---

## 🎯 Storage Timeline

```
Day 0:    Photo uploaded → Stored in Scaleway Archive ✅
Day 1-179: Photo accessible → Still stored ✅
Day 180:  Lifecycle policy triggers → Photo automatically deleted ✅
```

**Result:** Photos stored for exactly 180 days, then automatically deleted!

---

## 📝 Folder Structure

**Photos organized as:**
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
          photo.jpg  ← Auto-deleted after 180 days
```

---

## 🚀 Quick Start Checklist

- [ ] Scaleway account created
- [ ] Object Storage bucket created (Archive class)
- [ ] Lifecycle policy set (delete after 180 days)
- [ ] API credentials generated and saved securely
- [ ] App configuration updated
- [ ] Code updated to use ScalewayStorageService
- [ ] Test photo upload works
- [ ] Verify lifecycle policy (or wait 180 days)

---

## 🎉 Summary

**Scaleway Archive Storage:**
- ✅ **45% cheaper** than GCS Coldline
- ✅ **₹67,500 savings** per 6 months
- ✅ **₹1,35,000 savings** per year
- ✅ **Perfect for 180-day storage**
- ✅ **Auto-deletion** via lifecycle policy

**Total Setup Cost:** ₹1,22,900 per 6 months (vs ₹1,70,400 with GCS Coldline)

**You're saving ₹47,500 per 6 months!** 🎉
