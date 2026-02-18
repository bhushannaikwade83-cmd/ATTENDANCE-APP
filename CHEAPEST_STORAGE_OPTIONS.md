# Cheapest Storage Options - Cheaper Than GCS Coldline

## 🎯 Your Requirement: 75TB Storage for 180 Days

**GCS Coldline Cost:** ₹1,48,500 per 6 months ($0.004/GB/month)

**Looking for:** Storage cheaper than GCS Coldline

---

## 📊 Complete Storage Comparison

### Option 1: GCS Archive (Cheapest, BUT...)

**Pricing:**
- **$0.0012 per GB/month** (~₹0.10 per GB/month)
- **75TB cost:** ₹7,500/month = **₹45,000 per 6 months**

**BUT:**
- ❌ **365-day minimum** storage duration
- ❌ Your photos are deleted at 180 days
- ❌ **Won't work** - violates minimum duration requirement

**Verdict:** ❌ **Not suitable** (minimum is 1 year, you need 180 days)

---

### Option 2: Backblaze B2 (Slightly More Expensive)

**Pricing:**
- **$6 per TB/month** = **$0.006 per GB/month** (~₹0.50 per GB/month)
- **75TB cost:** ₹37,500/month = **₹2,25,000 per 6 months**

**Features:**
- ✅ **Free egress** up to 3x monthly storage
- ✅ **No minimum duration**
- ✅ **S3-compatible API**
- ✅ **90-day minimum** for some features (but storage itself has no minimum)

**Cost vs GCS Coldline:**
- GCS Coldline: ₹1,48,500 per 6 months
- Backblaze B2: ₹2,25,000 per 6 months
- **Difference:** ₹76,500 MORE expensive (52% more)

**Verdict:** ❌ **More expensive** than GCS Coldline

---

### Option 3: Wasabi (Slightly More Expensive)

**Pricing:**
- **$6.99 per TB/month** = **$0.0059 per GB/month** (~₹0.49 per GB/month)
- **75TB cost:** ₹36,750/month = **₹2,20,500 per 6 months**

**Features:**
- ✅ **Free egress** (within reasonable rate)
- ⚠️ **90-day minimum** storage duration (matches your 180 days!)
- ✅ **S3-compatible API**
- ✅ **No egress charges**

**Cost vs GCS Coldline:**
- GCS Coldline: ₹1,48,500 per 6 months
- Wasabi: ₹2,20,500 per 6 months
- **Difference:** ₹72,000 MORE expensive (48% more)

**Verdict:** ❌ **More expensive** than GCS Coldline

---

### Option 4: Storj (Decentralized - Potentially Cheaper)

**Pricing:**
- **$4 per TB/month** = **$0.004 per GB/month** (~₹0.33 per GB/month)
- **75TB cost:** ₹24,750/month = **₹1,48,500 per 6 months**

**Features:**
- ✅ **Same price as GCS Coldline**
- ✅ **No minimum duration**
- ✅ **S3-compatible API**
- ✅ **Decentralized** (more resilient)
- ⚠️ **Egress charges:** $0.007/GB

**Cost vs GCS Coldline:**
- GCS Coldline: ₹1,48,500 per 6 months
- Storj Storage: ₹1,48,500 per 6 months
- **Same price!** But egress charges may add cost

**Verdict:** ⚠️ **Same price**, but egress charges may make it more expensive

---

### Option 5: IDrive e2 (Cheaper Option!)

**Pricing:**
- **$4 per TB/month** = **$0.004 per GB/month** (~₹0.33 per GB/month)
- **75TB cost:** ₹24,750/month = **₹1,48,500 per 6 months**

**Features:**
- ✅ **Same price as GCS Coldline**
- ✅ **S3-compatible API**
- ✅ **Free egress** (first 1TB/month)
- ✅ **No minimum duration**

**Cost vs GCS Coldline:**
- GCS Coldline: ₹1,48,500 per 6 months
- IDrive e2: ₹1,48,500 per 6 months
- **Same price!**

**Verdict:** ⚠️ **Same price** as GCS Coldline

---

### Option 6: Azure Archive (Cheapest, BUT...)

**Pricing:**
- **$0.00099 per GB/month** (~₹0.08 per GB/month)
- **75TB cost:** ₹6,000/month = **₹36,000 per 6 months**

**Features:**
- ✅ **Cheapest option!**
- ❌ **180-day minimum** storage duration (perfect match!)
- ✅ **Automatic tiering** available
- ⚠️ **Retrieval time:** Hours (not seconds)

**Cost vs GCS Coldline:**
- GCS Coldline: ₹1,48,500 per 6 months
- Azure Archive: ₹36,000 per 6 months
- **Savings:** ₹1,12,500 (76% cheaper!)

**BUT:**
- ⚠️ **Retrieval time:** Hours (vs 3 seconds for Coldline)
- ⚠️ **Retrieval cost:** Additional charges

**Verdict:** ✅ **Cheapest**, but slow retrieval

---

### Option 7: Scaleway Object Storage Archive (Cheapest!)

**Pricing:**
- **€0.002 per GB/month** (~₹0.18 per GB/month)
- **75TB cost:** ₹13,500/month = **₹81,000 per 6 months**

**Features:**
- ✅ **45% cheaper** than GCS Coldline
- ✅ **90-day minimum** (matches your 180 days)
- ✅ **S3-compatible API**
- ✅ **Fast retrieval** (better than Azure Archive)

**Cost vs GCS Coldline:**
- GCS Coldline: ₹1,48,500 per 6 months
- Scaleway Archive: ₹81,000 per 6 months
- **Savings:** ₹67,500 (45% cheaper!)

**Verdict:** ✅ **45% cheaper** than GCS Coldline!

---

## 🏆 Winner: Scaleway Object Storage Archive

### Cost Comparison (75TB, 6 months)

| Storage Option | Cost (6 months) | Savings vs GCS Coldline |
|----------------|-----------------|-------------------------|
| **GCS Coldline** | ₹1,48,500 | Baseline |
| **Scaleway Archive** ⭐ | **₹81,000** | **Save ₹67,500 (45%)** |
| **Azure Archive** | ₹36,000 | Save ₹1,12,500 (76%) but slow |
| **Storj** | ₹1,48,500 | Same price |
| **IDrive e2** | ₹1,48,500 | Same price |
| **Backblaze B2** | ₹2,25,000 | More expensive |
| **Wasabi** | ₹2,20,500 | More expensive |

---

## 🎯 Recommended: Scaleway Object Storage Archive

### Why Scaleway Archive?

1. ✅ **45% cheaper** than GCS Coldline (₹67,500 savings per 6 months)
2. ✅ **90-day minimum** - matches your 180-day requirement
3. ✅ **Fast retrieval** - better than Azure Archive
4. ✅ **S3-compatible** - easy integration
5. ✅ **European provider** - GDPR compliant
6. ✅ **Lifecycle policies** - auto-delete after 180 days

### Cost Breakdown

| Item | Cost (6 months) |
|------|-----------------|
| **Scaleway Archive (75TB)** | ₹81,000 |
| **Operations** | ~₹20,000 |
| **Total** | **~₹1,01,000** |

**vs GCS Coldline:** ₹1,48,500  
**Savings:** **₹47,500 per 6 months** (32% cheaper)

---

## 📋 Scaleway Setup Guide

### Step 1: Create Scaleway Account

1. Go to [Scaleway.com](https://www.scaleway.com)
2. Sign up (free account)
3. Verify email

### Step 2: Create Object Storage Bucket

1. **Go to:** Object Storage → Buckets
2. **Click:** "Create Bucket"
3. **Configure:**
   - **Name:** `attendance-photos-archive`
   - **Region:** `fr-par` (Paris) or `nl-ams` (Amsterdam)
   - **Storage class:** **Archive** ⭐
   - **Versioning:** Disabled (for cost savings)
4. **Click:** "Create Bucket"

### Step 3: Set Lifecycle Policy

1. **Go to:** Bucket → "Lifecycle" tab
2. **Click:** "Add Rule"
3. **Configure:**
   - **Rule name:** `delete-after-180-days`
   - **Action:** Delete object
   - **Condition:** Age ≥ 180 days
4. **Click:** "Create"

### Step 4: Get API Credentials

1. **Go to:** IAM → API Keys
2. **Click:** "Generate API Key"
3. **Copy:**
   - `Access Key`
   - `Secret Key`
   - `Endpoint` (e.g., `https://s3.fr-par.scw.cloud`)

### Step 5: Update App Configuration

**Update `lib/appwrite_config.dart`:**

```dart
// Scaleway Object Storage Archive configuration
static const String scalewayEndpoint = 'https://s3.fr-par.scw.cloud';
static const String scalewayBucketName = 'attendance-photos-archive';
static const String scalewayAccessKey = 'YOUR_SCALEWAY_ACCESS_KEY';
static const String scalewaySecretKey = 'YOUR_SCALEWAY_SECRET_KEY';
static const String scalewayRegion = 'fr-par';
static const int photoRetentionDays = 180;
```

---

## 💰 Complete Cost Comparison

### For Your Setup (Appwrite + Railway + Storage)

| Storage Option | Storage Cost (6 months) | Total Cost (6 months) |
|----------------|------------------------|----------------------|
| **GCS Coldline** | ₹1,48,500 | ₹1,70,400 |
| **Scaleway Archive** ⭐ | **₹81,000** | **₹1,02,900** |
| **Azure Archive** | ₹36,000 | ₹57,900 (but slow) |

**Best Option:** **Scaleway Archive** - 45% cheaper than GCS Coldline!

---

## ✅ Benefits of Scaleway Archive

1. **45% Cost Savings** - ₹67,500 cheaper per 6 months
2. **Fast Retrieval** - Better than Azure Archive
3. **S3-Compatible** - Easy integration
4. **Lifecycle Policies** - Auto-delete after 180 days
5. **90-Day Minimum** - Perfect for your 180-day requirement
6. **European Provider** - GDPR compliant

---

## 🚀 Implementation

**Create `lib/services/scaleway_storage_service.dart`:**

```dart
import 'package:aws_s3_upload/aws_s3_upload.dart'; // Or use http with S3 API

class ScalewayStorageService {
  static const String endpoint = 'https://s3.fr-par.scw.cloud';
  static const String bucketName = 'attendance-photos-archive';
  
  // Use S3-compatible API (Scaleway is S3-compatible)
  // Similar to Railway Storage service, but with Scaleway credentials
}
```

---

## 🎉 Summary

**Cheapest Storage Options:**

1. **Scaleway Archive** ⭐ - ₹81,000 per 6 months (45% cheaper)
2. **Azure Archive** - ₹36,000 per 6 months (76% cheaper, but slow)
3. **GCS Coldline** - ₹1,48,500 per 6 months (baseline)

**Recommendation:** **Scaleway Archive** - Best balance of price and performance!

**Savings:** ₹67,500 per 6 months (₹1,35,000 per year) 🎉
