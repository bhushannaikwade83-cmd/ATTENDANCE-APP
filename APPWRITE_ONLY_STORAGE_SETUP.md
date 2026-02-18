# Appwrite Only Storage Setup - Complete Guide

## 🎯 Using ONLY Appwrite Storage

**Your Requirement:** Use Appwrite Storage only (no external storage like GCS, Scaleway, or Railway)

**Setup:** Appwrite Pro Plan + Appwrite Storage

---

## 💰 Appwrite Storage Pricing

### Pro Plan Includes:
- **150GB storage** free
- **Additional storage:** $2.8 per 100GB/month (~₹233 per 100GB/month)

### Your Storage Needs (125-130 students per institute)

**Per Institute:**
- 130 students × 12 lectures/day × 130 days = 2,028,000 photos
- 2,028,000 photos × 0.2 MB = **~406 GB per institute**

**For 3,000 Institutes:**
- 3,000 × 406 GB = **1,218,000 GB** = **~1,190 TB** (with 180-day retention, rolling window = **~610 TB**)

**Wait!** With 180-day deletion, storage stays at ~**122 TB** (not 1,190 TB) because old photos are deleted.

---

## 💵 Cost Calculation (122TB Storage)

### Appwrite Storage Cost

| Item | Calculation | Cost |
|------|------------|------|
| **Free tier** | 150GB | ₹0 |
| **Additional storage** | 122,000GB - 150GB = 121,850GB | 121,850GB × ₹233/100GB = **₹2,83,910/month** |
| **Per 6 months** | ₹2,83,910 × 6 | **₹17,03,460** |

**Total Cost (6 months):**
- Appwrite Pro Plan: ₹12,000
- Appwrite Storage (122TB): ₹17,03,460
- **Total: ₹17,15,460 per 6 months**

---

## ⚠️ Cost Comparison

| Storage Option | Cost (6 months) |
|----------------|-----------------|
| **Appwrite Storage** | ₹17,03,460 |
| **Scaleway Archive** | ₹1,31,760 |
| **GCS Coldline** | ₹2,41,560 |

**Appwrite Storage is 13x more expensive than Scaleway Archive!**

---

## 📋 Setup Steps

### Step 1: Create Storage Bucket in Appwrite

1. **Go to:** [Appwrite Console](https://cloud.appwrite.io)
2. **Select project:** ATTENDANCE APP
3. **Go to:** Storage → Create Bucket
4. **Configure:**
   - **Name:** `Attendance Photos Bucket`
   - **Bucket ID:** `photos_bucket`
   - **File size limit:** 10 MB (or as needed)
   - **Allowed extensions:** `jpg`, `jpeg`, `png`
   - **Compression:** `none` (or `gzip` if preferred)
5. **Permissions:**
   - ✅ Read: `users` (any authenticated user)
   - ✅ Create: `users` (any authenticated user)
   - ✅ Update: `users` (any authenticated user)
   - ✅ Delete: `users` (any authenticated user)
6. **Click:** "Create"

---

### Step 2: Set Up Lifecycle Policy (180-Day Deletion)

**Appwrite doesn't have built-in lifecycle policies, so we need to:**

**Option A: Use Appwrite Functions (Scheduled)**
1. **Go to:** Functions → Create Function
2. **Name:** `delete-old-photos`
3. **Schedule:** Run daily
4. **Code:** Delete files older than 180 days
5. **Deploy function**

**Option B: Manual Cleanup Script**
- Run periodically to delete old photos
- Use Appwrite SDK to list and delete files older than 180 days

**Option C: Store deletion date in database**
- Add `deleteAfter` field to attendance records
- Run cleanup job based on database records

---

### Step 3: Update App Configuration

**Update `lib/appwrite_config.dart`:**

```dart
class AppwriteConfig {
  // Appwrite Storage only (no external storage)
  static const String storageBucketId = 'photos_bucket';
  static const int photoRetentionDays = 180; // Photos stored for 180 days
  
  // Remove external storage configs (GCS, Scaleway, Railway Storage)
}
```

---

### Step 4: Use Appwrite Storage Service

**Your existing `storage_service.dart` already uses Appwrite Storage!**

**No changes needed** - it's already set up to use:
```dart
AppwriteService.storage.createFile(
  bucketId: AppwriteConfig.storageBucketId,
  ...
)
```

---

## 📊 Complete Cost Breakdown

### Appwrite Only Setup (6 Months)

| Item | Cost |
|------|------|
| **Appwrite Pro Plan** | ₹12,000 |
| **Appwrite Storage (122TB)** | ₹17,03,460 |
| **Total** | **₹17,15,460** |

**vs Appwrite + Railway + Scaleway:**
- Previous: ₹1,85,660
- Appwrite Only: ₹17,15,460
- **Increase:** ₹15,29,800 (9.2x more expensive!)

---

## 💡 Cost Optimization Tips

### With Appwrite Storage Only:

1. **Photo Compression** (Critical!)
   - Reduce from 0.2 MB to 0.1 MB
   - **Storage reduction:** 50% (122TB → 61TB)
   - **Cost reduction:** ₹8,51,730 per 6 months
   - **New cost:** ₹8,51,730 per 6 months

2. **Selective Photo Storage**
   - Store photos for 6 key subjects only
   - **Storage reduction:** 50%
   - **Cost reduction:** ₹8,51,730 per 6 months

3. **Lower Photo Quality**
   - Reduce to 0.15 MB per photo
   - **Storage reduction:** 25%
   - **Cost reduction:** ₹4,25,865 per 6 months

---

## ⚠️ Important Considerations

### Why Appwrite Storage is Expensive

1. **Designed for small files** - Not optimized for large archives
2. **Premium pricing** - $2.8 per 100GB/month (vs $0.004 for GCS Coldline)
3. **No lifecycle policies** - Need custom functions for auto-deletion
4. **Best for:** Small files, frequent access, convenience

### Recommendations

**If you MUST use Appwrite Storage only:**

1. ✅ **Enable photo compression** - Critical to reduce costs
2. ✅ **Set up cleanup function** - Auto-delete after 180 days
3. ✅ **Monitor storage usage** - Set up alerts
4. ✅ **Consider:** Limiting photo storage to key subjects only

---

## 🎯 Optimized Cost (With Compression)

### Appwrite Storage with Photo Compression (0.1 MB)

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro Plan** | ₹12,000 |
| **Appwrite Storage (61TB)** | ₹8,51,730 |
| **Total** | **₹8,63,730** |

**Still expensive, but manageable with compression.**

---

## 📝 Implementation

### Your Code Already Uses Appwrite Storage!

**`lib/services/storage_service.dart`** already uses:
```dart
AppwriteService.storage.createFile(
  bucketId: AppwriteConfig.storageBucketId,
  fileId: fileId,
  file: InputFile.fromBytes(...),
)
```

**No code changes needed!** Just:
1. Create bucket in Appwrite Console
2. Update `storageBucketId` in config
3. Set up cleanup function for 180-day deletion

---

## 🔄 Update Hybrid Service

**Update `lib/services/hybrid_service.dart`** to use Appwrite Storage:

```dart
// Change from ScalewayStorageService back to StorageService
import 'storage_service.dart'; // Appwrite Storage

// In markAttendance method:
final uploadResult = await StorageService.uploadAttendancePhoto(
  instituteId: instituteId,
  batchYear: batchYear,
  rollNumber: rollNumber,
  subject: subject,
  date: date,
  photoBytes: photoBytes,
);
```

---

## ✅ Checklist

- [ ] Appwrite Storage bucket created (`photos_bucket`)
- [ ] Bucket permissions set (users can read/create/update/delete)
- [ ] Cleanup function created (delete files older than 180 days)
- [ ] Photo compression enabled (reduce to 0.1 MB)
- [ ] Storage monitoring set up
- [ ] Budget alerts configured

---

## 🎉 Summary

**Appwrite Only Storage:**
- ✅ **Simple** - Everything in Appwrite
- ✅ **Convenient** - No external services
- ⚠️ **Expensive** - ₹17,03,460 per 6 months (122TB)
- ✅ **With compression** - ₹8,51,730 per 6 months (61TB)

**Recommendation:** Enable photo compression to reduce costs by 50%!

**Total Cost:** ₹8,63,730 per 6 months (with compression)

---

## 💰 Profitability Check

**With ₹200 per institute revenue:**

| Item | Value |
|------|-------|
| **Revenue (3,000 institutes)** | ₹6,00,000 |
| **Backend cost (with compression)** | ₹8,63,730 |
| **Your profit/loss** | **Loss: ₹2,63,730** ❌ |

**You need to charge more!**

**Break-even:** ₹287.91 per institute  
**Recommended:** ₹500-600 per institute to make profit

---

## 🚀 Next Steps

1. ✅ Create Appwrite Storage bucket
2. ✅ Set up cleanup function (180-day deletion)
3. ✅ Enable photo compression in your app
4. ✅ Update pricing to ₹500-600 per institute
5. ✅ Monitor storage usage

**Everything is ready for Appwrite-only storage!** ✅
