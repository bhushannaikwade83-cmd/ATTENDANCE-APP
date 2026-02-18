# Railway Storage Setup Guide

## 🎯 Using Railway Storage Instead of GCS

**Railway Storage Buckets** are S3-compatible object storage, perfect for photo storage.

---

## 💰 Railway Storage Pricing

### Storage Buckets (S3-Compatible)

| Plan | Storage Limit | Price |
|------|---------------|-------|
| **Free** | 10 GB | Free |
| **Hobby** | 1 TB | $0.015 per GB/month |
| **Pro** | Unlimited | $0.015 per GB/month |

**For 75 TB (75,000 GB):**
- **Cost:** 75,000 GB × $0.015 = **$1,125/month** (~₹93,750/month)
- **Per 6 months:** **₹5,62,500**

**Note:** Railway Storage is more expensive than GCS Coldline (₹1,48,500 per 6 months), but you get:
- ✅ Everything in one platform (Railway)
- ✅ S3-compatible API
- ✅ Free egress (no download charges)
- ✅ Simple integration

---

## 📋 Setup Steps

### Step 1: Create Railway Storage Bucket

1. **Go to Railway Dashboard:** [railway.app](https://railway.app)
2. **Select your project** (or create new)
3. **Click:** "New" → "Storage" → "Add Storage Bucket"
4. **Configure:**
   - **Bucket name:** `attendance-photos` (must be unique)
   - **Region:** Choose closest region
   - **Access:** Public or Private (your choice)
5. **Click:** "Create"

---

### Step 2: Get Storage Credentials

1. **Click on your storage bucket**
2. **Go to:** "Settings" or "Variables" tab
3. **Copy these values:**
   - `RAILWAY_STORAGE_ENDPOINT` (e.g., `https://storage.railway.app`)
   - `RAILWAY_STORAGE_ACCESS_KEY`
   - `RAILWAY_STORAGE_SECRET_KEY`
   - `RAILWAY_STORAGE_BUCKET_NAME`

**Example:**
```
RAILWAY_STORAGE_ENDPOINT=https://storage.railway.app
RAILWAY_STORAGE_ACCESS_KEY=your_access_key
RAILWAY_STORAGE_SECRET_KEY=your_secret_key
RAILWAY_STORAGE_BUCKET_NAME=attendance-photos
```

---

### Step 3: Set Up Lifecycle Policy (180-Day Deletion)

**Railway Storage supports lifecycle policies:**

1. **Go to:** Storage Bucket → "Lifecycle" tab
2. **Click:** "Add Rule"
3. **Configure:**
   - **Rule name:** `delete-after-180-days`
   - **Action:** Delete object
   - **Condition:** Age ≥ 180 days
4. **Click:** "Create"

**This will automatically delete photos after 180 days!**

---

### Step 4: Update App Configuration

**Update `lib/appwrite_config.dart`:**

```dart
class AppwriteConfig {
  // ... existing config ...
  
  // Railway Storage configuration (instead of GCS)
  static const String railwayStorageEndpoint = 'YOUR_RAILWAY_STORAGE_ENDPOINT';
  static const String railwayStorageBucketName = 'YOUR_RAILWAY_BUCKET_NAME';
  static const String railwayStorageAccessKey = 'YOUR_RAILWAY_ACCESS_KEY';
  static const String railwayStorageSecretKey = 'YOUR_RAILWAY_SECRET_KEY';
  static const int photoRetentionDays = 180; // Auto-delete after 180 days
}
```

---

### Step 5: Install Required Packages

**Update `pubspec.yaml`:**

```yaml
dependencies:
  # ... existing dependencies ...
  
  # For S3-compatible API (Railway Storage)
  http: ^1.1.0  # Already included
  crypto: ^3.0.0  # For AWS signature
  # OR use AWS SDK
  # aws_s3_upload: ^1.0.0
```

**Run:**
```bash
flutter pub get
```

---

### Step 6: Use Railway Storage Service

**Update your code to use Railway Storage:**

```dart
import 'package:your_app/services/railway_storage_service.dart';

// Upload photo
final result = await RailwayStorageService.uploadAttendancePhoto(
  instituteId: instituteId,
  batchYear: batchYear,
  rollNumber: rollNumber,
  subject: subject,
  date: date,
  photoBytes: photoBytes,
);

final photoUrl = result['url'];
```

---

## 🔄 Update Hybrid Service

**Update `lib/services/hybrid_service.dart`:**

```dart
// Change from StorageService to RailwayStorageService
import 'railway_storage_service.dart'; // Instead of storage_service.dart

// In markAttendance method:
final uploadResult = await RailwayStorageService.uploadAttendancePhoto(
  instituteId: instituteId,
  batchYear: batchYear,
  rollNumber: rollNumber,
  subject: subject,
  date: date,
  photoBytes: photoBytes,
);
```

---

## 📊 Cost Comparison

### Option A: GCS Coldline (Previous)
| Item | Cost (6 months) |
|------|-----------------|
| GCS Coldline (75TB) | ₹1,48,500 |
| GCS Operations | ₹1,00,000 |
| **Total** | **₹2,48,500** |

### Option B: Railway Storage (Current)
| Item | Cost (6 months) |
|------|-----------------|
| Railway Storage (75TB) | ₹5,62,500 |
| Railway Operations | ₹0 (free egress) |
| **Total** | **₹5,62,500** |

**Note:** Railway Storage is **2.3x more expensive** than GCS Coldline, but:
- ✅ Everything in Railway (simpler)
- ✅ Free egress (no download charges)
- ✅ S3-compatible (easy integration)

---

## 🎯 Complete Architecture

```
┌─────────────────┐
│   Flutter App   │
└────────┬────────┘
         │
         ├─────────────────┬──────────────────┐
         │                 │                  │
         ▼                 ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Appwrite   │  │   Railway    │  │   Railway    │
│              │  │  PostgreSQL  │  │   Storage    │
│ • Auth       │  │              │  │              │
│ • API        │  │ • Database   │  │ • Photos     │
│              │  │ • Queries    │  │ • 180 days   │
└──────────────┘  └──────────────┘  └──────────────┘
```

**Everything in Railway + Appwrite!**

---

## ✅ Benefits of Railway Storage

1. **Unified Platform:** Database and storage in one place
2. **S3-Compatible:** Use standard S3 SDKs and tools
3. **Free Egress:** No download charges
4. **Lifecycle Policies:** Auto-delete after 180 days
5. **Simple Setup:** Everything in Railway dashboard

---

## ⚠️ Cost Consideration

**Railway Storage is more expensive than GCS Coldline:**
- Railway: ₹5,62,500 per 6 months
- GCS Coldline: ₹1,48,500 per 6 months
- **Difference:** ₹4,14,000 more expensive

**But you get:**
- ✅ Simpler architecture (everything in Railway)
- ✅ Free egress (saves on download costs)
- ✅ Unified billing

---

## 📝 Updated Total Cost

### Appwrite + Railway (Database + Storage)

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹9,900 |
| **Railway Storage (75TB)** | ₹5,62,500 |
| **Total** | **₹5,84,400** |

**vs Previous Setup (Appwrite + Railway + GCS):**
- Previous: ₹1,70,400
- Current: ₹5,84,400
- **Increase:** ₹4,14,000 (2.4x more expensive)

---

## 🎉 Summary

**Railway Storage Setup:**
- ✅ **S3-compatible** object storage
- ✅ **Lifecycle policies** for 180-day deletion
- ✅ **Everything in Railway** (simpler)
- ✅ **Free egress** (no download charges)
- ⚠️ **More expensive** than GCS Coldline (₹4.14 lakh more)

**If cost is a concern, consider:**
- Using GCS Coldline for storage (much cheaper)
- Or optimizing storage usage
- Or using Railway Volumes (limited to 1TB on Pro plan)

---

## 🚀 Next Steps

1. ✅ Create Railway Storage Bucket
2. ✅ Get storage credentials
3. ✅ Set up lifecycle policy (180 days)
4. ✅ Update app configuration
5. ✅ Update code to use RailwayStorageService
6. ✅ Test photo upload

**Everything is now in Railway + Appwrite!** 🎉
