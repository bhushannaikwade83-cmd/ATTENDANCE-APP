# Storage Cost Comparison — Firebase Storage vs GCS

**Your storage needs:** ~75 TB (photos, deleted after 6-month batch ends)

---

## Storage Pricing Comparison

### Firebase Storage

| Item | Price |
|------|-------|
| **Free tier** | 5 GB (one-time, not monthly) |
| **Storage (beyond free tier)** | **$0.026 per GB per month** (~₹2.17 per GB per month) |
| **For 75 TB (75,000 GB)** | ₹1,62,750 per month = **₹9,76,500 per 6 months** |

### Google Cloud Storage (GCS) — Standard Storage

| Item | Price |
|------|-------|
| **Free tier** | 5 GB-months (monthly) |
| **Standard Storage (us-central1)** | **$0.020 per GB per month** (~₹1.67 per GB per month) |
| **For 75 TB (75,000 GB)** | ₹1,25,250 per month = **₹7,51,500 per 6 months** |

**GCS Standard is 23% cheaper than Firebase Storage**

---

## GCS Storage Classes (Cheaper Options)

Since photos are **deleted after 6 months**, you can use cheaper GCS storage classes:

### GCS Nearline Storage

| Item | Price |
|------|-------|
| **Storage** | **$0.010 per GB per month** (~₹0.83 per GB per month) |
| **Minimum storage duration** | 30 days |
| **For 75 TB (75,000 GB)** | ₹62,250 per month = **₹3,73,500 per 6 months** |

**Nearline is 62% cheaper than Firebase Storage!**

### GCS Coldline Storage

| Item | Price |
|------|-------|
| **Storage** | **$0.004 per GB per month** (~₹0.33 per GB per month) |
| **Minimum storage duration** | 90 days |
| **For 75 TB (75,000 GB)** | ₹24,750 per month = **₹1,48,500 per 6 months** |

**Coldline is 85% cheaper than Firebase Storage!**

### GCS Archive Storage (Cheapest)

| Item | Price |
|------|-------|
| **Storage** | **$0.0012 per GB per month** (~₹0.10 per GB per month) |
| **Minimum storage duration** | 365 days (1 year) |
| **For 75 TB (75,000 GB)** | ₹7,500 per month = **₹45,000 per 6 months** |

**Archive is 95% cheaper than Firebase Storage!**

**Note:** Archive has 365-day minimum, but your photos are kept for 6 months (180 days) — **Archive won't work** (minimum is 1 year).

---

## Cost Comparison Summary (75 TB, per 6 months)

| Storage Option | Cost (per 6 months) | Savings vs Firebase |
|----------------|-------------------|---------------------|
| **Firebase Storage** | ₹9,76,500 | Baseline |
| **GCS Standard** | ₹7,51,500 | **Save ₹2,25,000 (23%)** |
| **GCS Nearline** | ₹3,73,500 | **Save ₹6,03,000 (62%)** |
| **GCS Coldline** | ₹1,48,500 | **Save ₹8,28,000 (85%)** |
| **GCS Archive** | ❌ Not suitable | (365-day minimum, photos deleted at 180 days) |

---

## Recommended: GCS Coldline Storage

**Why Coldline is best for your use case:**

1. ✅ **85% cheaper** than Firebase Storage
2. ✅ **90-day minimum** — matches your 6-month batch (180 days > 90 days)
3. ✅ **Suitable for photos** — accessed occasionally (not daily)
4. ✅ **Massive savings:** ₹8.28 lakh per 6 months vs Firebase

**Cost:** ₹1,48,500 per 6 months (vs ₹9,76,500 with Firebase)

---

## Alternative: GCS Nearline Storage

**If Coldline doesn't work for your access pattern:**

- **Cost:** ₹3,73,500 per 6 months
- **62% cheaper** than Firebase Storage
- **30-day minimum** — definitely works for 6-month batches
- **Good for** frequently accessed photos

---

## Updated Backend Costs with GCS Coldline

### Option A: Firebase (Current)

| Item | Cost (per 6 months) |
|------|---------------------|
| Firebase Firestore (writes) | ₹7,80,000 – ₹9,00,000 |
| **Firebase Storage (75 TB)** | **₹9,76,500** |
| Firebase Firestore (reads) | ₹1,20,000 – ₹2,40,000 |
| **Total Firebase** | **₹18,76,500 – ₹21,16,500** |

### Option B: Appwrite + GCS Coldline (Recommended)

| Item | Cost (per 6 months) |
|------|---------------------|
| Appwrite Pro Plan | ₹12,000 |
| **GCS Coldline Storage (75 TB)** | **₹1,48,500** |
| GCS Operations | ₹50,000 – ₹1,00,000 |
| **Total Appwrite + GCS Coldline** | **₹2,10,500 – ₹2,60,500** |

**Savings vs Firebase:** ₹16.5–18.6 lakh per 6 months (88–89% reduction!)

---

## Final Recommendation

### ✅ BEST: Appwrite + GCS Coldline Storage

**Why:**
1. **85% cheaper storage** than Firebase (₹1.48 lakh vs ₹9.76 lakh per 6 months)
2. **Total backend cost:** ₹2.1–2.6 lakh per 6 months (vs ₹18.8–21.2 lakh with Firebase)
3. **88–89% total cost reduction**
4. **Perfect fit:** 90-day minimum matches your 6-month batch (180 days)

**With ₹6 lakh revenue:**
- **Firebase:** Loss of ₹12.8–15.2 lakh
- **Appwrite + GCS Coldline:** **Profit of ₹3.4–3.9 lakh!** ✅

---

## Cost Breakdown (per 6 months)

| Backend Option | Storage Cost | Total Backend Cost |
|----------------|--------------|-------------------|
| **Firebase** | ₹9,76,500 | ₹18,76,500 – ₹21,16,500 |
| **Appwrite + GCS Standard** | ₹7,51,500 | ₹8,13,500 – ₹9,13,500 |
| **Appwrite + GCS Nearline** | ₹3,73,500 | ₹4,35,500 – ₹4,85,500 |
| **Appwrite + GCS Coldline** ⭐ | **₹1,48,500** | **₹2,10,500 – ₹2,60,500** |

---

## Summary

**Cheapest storage option:** **GCS Coldline Storage**

- **Cost:** ₹1,48,500 per 6 months (for 75 TB)
- **85% cheaper** than Firebase Storage
- **Perfect for your use case** (photos kept for 6 months, deleted after batch ends)

**Best overall backend:** **Appwrite + GCS Coldline**

- **Total cost:** ₹2.1–2.6 lakh per 6 months
- **With ₹6 lakh revenue:** **Profit of ₹3.4–3.9 lakh** ✅

---

*Note: GCS Coldline has a 90-day minimum storage duration. Since your photos are kept for 6 months (180 days), this is perfect. Archive storage (cheapest) requires 365-day minimum, so it won't work for your 6-month deletion policy.*
