# 180-Day Photo Storage Setup - Complete Summary

## ✅ Perfect Solution: GCS Coldline with 180-Day Lifecycle Policy

**Your Requirement:** Store photos for **180 days**, then automatically delete them.

**Solution:** **GCS Coldline** with **lifecycle policy** set to delete after 180 days.

---

## 🎯 Why GCS Coldline is Perfect

| Requirement | GCS Coldline | Status |
|------------|--------------|--------|
| **Store for 180 days** | ✅ Yes (90-day minimum, can store longer) | ✅ Perfect |
| **Automatic deletion** | ✅ Lifecycle policy | ✅ Automatic |
| **Cost effective** | ✅ ₹2.97 lakh/year (85% cheaper) | ✅ Best price |
| **Reliable** | ✅ Google Cloud infrastructure | ✅ Enterprise-grade |

---

## 💰 Cost Comparison (180-Day Storage)

### GCS Coldline (Recommended)

| Item | Cost |
|------|------|
| **Storage (75TB)** | ₹24,750/month = **₹2,97,000/year** |
| **Operations** | ~₹1,00,000/year |
| **Total** | **~₹3,97,000/year** |

### Appwrite Storage (For Comparison)

| Item | Cost |
|------|------|
| **Storage (75TB)** | ₹1,74,500/month = **₹20,97,000/year** |
| **Total** | **₹20,97,000/year** |

### Savings with GCS Coldline

- **Annual Savings:** ₹20,97,000 - ₹3,97,000 = **₹17,00,000/year**
- **Percentage:** **81% cost reduction**

---

## 📋 Quick Setup Steps

### 1. Create GCS Coldline Bucket
- Go to Google Cloud Console → Storage
- Create bucket with **Coldline** storage class
- Region: `us-central1` (cheapest)

### 2. Set Lifecycle Policy (CRITICAL!)
- Go to bucket → **Lifecycle** tab
- Add rule: **Delete objects older than 180 days**
- This ensures photos are automatically deleted after 180 days

### 3. Create Service Account
- IAM & Admin → Service Accounts
- Create service account with **Storage Object Admin** role
- Download JSON key (keep secure!)

### 4. Update Your Code
- Use `GCSStorageService` instead of Appwrite Storage
- Upload photos to GCS Coldline bucket
- Photos will automatically delete after 180 days

---

## 🔄 How It Works

### Photo Lifecycle

```
Day 0:    Photo uploaded → Stored in GCS Coldline
Day 1-179: Photo accessible → Still stored
Day 180:  Lifecycle policy triggers → Photo automatically deleted ✅
```

### Storage Pattern

- **Rolling 180-day window**
- Storage stays constant at ~75TB
- Old photos automatically removed
- New photos continuously added

---

## 📁 Folder Structure

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
          photo.jpg  ← Deleted automatically after 180 days
```

---

## ✅ Benefits

1. **Automatic Cleanup** - No manual deletion needed
2. **Cost Savings** - 81% cheaper than Appwrite Storage
3. **Compliance** - Old photos automatically removed
4. **Predictable Costs** - Storage stays at ~75TB
5. **Perfect Fit** - 180 days matches your requirement exactly

---

## 📝 Files Created

1. **`lib/services/gcs_storage_service.dart`** - GCS upload service
2. **`GCS_180_DAY_SETUP.md`** - Detailed setup guide
3. **`180_DAY_STORAGE_SUMMARY.md`** - This summary

---

## 🚀 Next Steps

1. ✅ **Create GCS Coldline bucket** (see `GCS_180_DAY_SETUP.md`)
2. ✅ **Set lifecycle policy** to delete after 180 days
3. ✅ **Create service account** and download JSON key
4. ✅ **Update code** to use GCS instead of Appwrite Storage
5. ✅ **Test upload** and verify lifecycle policy works

---

## 📊 Storage Timeline Example

**Batch starts:** January 1, 2024
**Photos uploaded:** January 1 - June 30, 2024 (180 days)

| Date | Action | Storage |
|------|--------|---------|
| **Jan 1** | First photos uploaded | 0 → 12.5 GB |
| **Jan 15** | More photos uploaded | 12.5 → 25 GB |
| **June 30** | Batch ends, all photos uploaded | 75 TB |
| **July 1** | Photos from Jan 1 start deleting | 75 TB → 74.99 TB |
| **July 2** | Photos from Jan 2 start deleting | 74.99 TB → 74.98 TB |
| **...** | Continuous deletion | Rolling window |
| **Dec 28** | Last photos from June 30 deleted | 0 TB |

**Result:** Storage cycles - stays at ~75TB during active batches, drops to 0 between batches.

---

## 🎉 Summary

**GCS Coldline + 180-Day Lifecycle Policy = Perfect Solution!**

- ✅ **Stores photos for exactly 180 days**
- ✅ **Automatically deletes after 180 days**
- ✅ **81% cost savings** vs Appwrite Storage
- ✅ **No manual cleanup** needed
- ✅ **Perfect for 6-month batches**

**Your photos will be stored for 180 days, then automatically deleted!** 🎯
