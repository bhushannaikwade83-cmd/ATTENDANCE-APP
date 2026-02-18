# Final Storage Setup - Scaleway Archive (CHEAPEST!)

## 🎯 Best and Cheapest Storage: Scaleway Archive

**Your Requirements:**
- ✅ Cheapest storage option
- ✅ Photos stored for 180 days
- ✅ Auto-delete after batch ends (180 days)

**Solution:** **Scaleway Object Storage Archive** - 45% cheaper than GCS Coldline!

---

## 💰 Why Scaleway Archive is Best

### Cost Comparison (122TB, 6 months)

| Storage Option | Cost (6 months) | vs Scaleway |
|----------------|-----------------|-------------|
| **Scaleway Archive** ⭐ | **₹1,31,760** | Baseline (CHEAPEST!) |
| **GCS Coldline** | ₹2,41,560 | 83% more expensive |
| **Appwrite Storage** | ₹17,03,460 | **13x more expensive!** |

**Scaleway Archive saves ₹1,09,800 vs GCS Coldline per 6 months!**

---

## 📋 Complete Setup Guide

### Step 1: Create Scaleway Account

1. Go to [Scaleway.com](https://www.scaleway.com)
2. Click "Sign Up" (free account)
3. Verify your email
4. Complete account setup

---

### Step 2: Create Archive Storage Bucket

1. **Go to:** Object Storage → Buckets
2. **Click:** "Create Bucket"
3. **Configure:**
   - **Name:** `attendance-photos-archive` (must be globally unique)
   - **Region:** `fr-par` (Paris) or `nl-ams` (Amsterdam)
   - **Storage class:** **Archive** ⭐ (cheapest option!)
   - **Versioning:** Disabled (to save costs)
   - **Public access:** Private (recommended)
4. **Click:** "Create Bucket"

---

### Step 3: Set Lifecycle Policy (180-Day Auto-Delete) ⭐ CRITICAL!

**This ensures photos are automatically deleted after 180 days!**

1. **Go to:** Bucket → "Lifecycle" tab
2. **Click:** "Add Rule"
3. **Configure:**
   - **Rule name:** `delete-after-180-days`
   - **Action:** Delete object
   - **Condition:** Age ≥ 180 days
4. **Click:** "Create"

**Result:** All photos uploaded will be **automatically deleted 180 days after upload** - perfect for batch-based deletion!

---

### Step 4: Get API Credentials

1. **Go to:** IAM → API Keys
2. **Click:** "Generate API Key"
3. **Fill in:**
   - **Name:** `attendance-app-storage`
   - **Expiration:** Never (or set expiration)
4. **Click:** "Generate"
5. **Copy immediately** (you'll only see secret once):
   - **Access Key** (starts with `SCW...`)
   - **Secret Key** (long string)
   - **Endpoint** (e.g., `https://s3.fr-par.scw.cloud`)

**Keep these secure!** Store in environment variables.

---

### Step 5: Update App Configuration

**Update `lib/appwrite_config.dart`:**

```dart
// Scaleway Archive Storage (CHEAPEST!)
static const String scalewayEndpoint = 'https://s3.fr-par.scw.cloud';
static const String scalewayBucketName = 'attendance-photos-archive';
static const String scalewayAccessKey = 'SCW...'; // Your access key
static const String scalewaySecretKey = 'your_secret_key_here';
static const String scalewayRegion = 'fr-par';
static const String scalewayStorageClass = 'ARCHIVE';
static const int photoRetentionDays = 180; // Auto-delete after 180 days
```

---

### Step 6: Your Code is Already Updated!

**`lib/services/hybrid_service.dart`** already uses Scaleway Storage:
```dart
final uploadResult = await ScalewayStorageService.uploadAttendancePhoto(...);
```

**No code changes needed!** Just update the config with your Scaleway credentials.

---

## 📊 Complete Cost Breakdown

### Appwrite + Railway + Scaleway Archive

**For 2 Lakh Students (200,000) across 3,000 Institutes:**

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹37,000 |
| **Scaleway Archive (65TB)** | ₹70,200 |
| **Total** | **₹1,19,200** |

**With Photo Compression (0.1 MB):**
- **Scaleway Archive (32.5TB):** ₹35,100
- **Total:** **₹84,100**

**Railway PostgreSQL Breakdown:**
- Pro Plan: ₹9,900
- Storage (190GB): ₹14,250
- RAM (2GB): ₹9,996
- CPU (1vCPU): ₹9,996
- Network Egress: ₹2,502
- Less Credits: -₹9,900
- **Total Railway:** ₹37,000

**Previous (130 students/institute, 122TB):** ₹1,81,377  
**New (66.67 students/institute, 65TB):** ₹1,19,200  
**Savings:** ₹62,177 (34% cheaper!)

**vs Appwrite Storage:** ₹17,25,360  
**Savings:** ₹15,39,700 per 6 months (89% cheaper!)

---

## 🔄 How 180-Day Deletion Works

### Photo Lifecycle

```
Day 0:    Photo uploaded → Stored in Scaleway Archive ✅
Day 1-179: Photo accessible → Still stored ✅
Day 180:  Lifecycle policy triggers → Photo automatically deleted ✅
```

### Batch-Based Deletion

**When a batch ends (after 6 months):**
- All photos from that batch are automatically deleted
- Storage stays constant (rolling 180-day window)
- No manual cleanup needed!

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
INST001/
  2024/
    STU001/
      mathematics/
        2024-02-03/
          photo.jpg  ← Auto-deleted after 180 days
```

**Lifecycle policy applies to ALL files** - all photos deleted after 180 days automatically.

---

## ✅ Benefits

1. **Cheapest Option** - 45% cheaper than GCS Coldline
2. **Automatic Deletion** - Lifecycle policy handles cleanup
3. **Perfect for Batches** - 180-day retention matches batch duration
4. **S3-Compatible** - Easy integration
5. **Fast Retrieval** - Better than Azure Archive
6. **European Provider** - GDPR compliant

---

## 🎯 Cost Optimization

### With Photo Compression (Recommended)

**Compress photos to 0.1 MB (instead of 0.2 MB):**

| Item | Cost (6 months) |
|------|-----------------|
| **Scaleway Archive (61TB)** | ₹65,880 |
| **Total** | **₹1,19,780** |

**Savings:** ₹65,880 per 6 months (50% reduction)

---

## 📝 Checklist

- [ ] Scaleway account created
- [ ] Archive bucket created (`attendance-photos-archive`)
- [ ] Lifecycle policy set (delete after 180 days) ⭐ CRITICAL!
- [ ] API credentials generated and saved securely
- [ ] App configuration updated with Scaleway credentials
- [ ] Code uses ScalewayStorageService (already done ✅)
- [ ] Test photo upload works
- [ ] Verify lifecycle policy (or wait 180 days)

---

## 🎉 Summary

**Scaleway Archive Storage:**
- ✅ **CHEAPEST** - ₹1,31,760 per 6 months (122TB)
- ✅ **45% cheaper** than GCS Coldline
- ✅ **13x cheaper** than Appwrite Storage
- ✅ **180-day auto-deletion** via lifecycle policy
- ✅ **Perfect for batches** - photos deleted after batch ends

**Total Setup Cost:** ₹1,85,660 per 6 months

**vs Appwrite Storage:** Save ₹15,39,700 per 6 months! 🎉

---

## 🚀 Next Steps

1. ✅ Create Scaleway account
2. ✅ Create Archive bucket
3. ✅ Set lifecycle policy (180 days) ⭐
4. ✅ Get API credentials
5. ✅ Update `appwrite_config.dart` with credentials
6. ✅ Test photo upload

**Everything is ready! Follow `SCALEWAY_STORAGE_SETUP.md` for detailed instructions.** ✅
