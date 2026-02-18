# Updated Storage Calculation - 125-130 Students Per Institute

## 📊 Storage Requirements Update

### Previous Assumptions
- **40 students per batch**
- **2 batches per institute** = 80 students total
- **Storage per institute:** ~250 GB
- **Total storage (3,000 institutes):** ~75 TB

### New Assumptions
- **125-130 students per institute** (total)
- **Storage per institute:** ~406 GB
- **Total storage (3,000 institutes):** **~122 TB**

---

## 📈 Detailed Calculation

### Per Student Storage (6-Month Batch)

| Item | Value |
|------|-------|
| **Lectures per day** | 12 |
| **Working days** | 130 days (6 months) |
| **Photos per student** | 12 × 130 = **1,560 photos** |
| **Photo size** | 0.2 MB each |
| **Storage per student** | 1,560 × 0.2 MB = **312 MB** |

### Per Institute Storage

**With 130 students:**
- 130 students × 312 MB = **40.56 GB per institute**

**With 125 students:**
- 125 students × 312 MB = **39 GB per institute**

**Average (127.5 students):**
- ~**40 GB per institute**

### Total Storage (3,000 Institutes)

**With 130 students each:**
- 3,000 institutes × 40.56 GB = **121.68 TB** ≈ **122 TB**

**With 125 students each:**
- 3,000 institutes × 39 GB = **117 TB**

**Average:** **~120 TB** (rolling 6-month window)

---

## 💰 Updated Storage Costs

### Scaleway Archive (Recommended)

| Storage | Monthly Cost | 6-Month Cost |
|---------|--------------|--------------|
| **120 TB** | ₹21,600 | **₹1,29,600** |
| **122 TB** | ₹21,960 | **₹1,31,760** |

### GCS Coldline (For Comparison)

| Storage | Monthly Cost | 6-Month Cost |
|---------|--------------|--------------|
| **120 TB** | ₹39,600 | **₹2,37,600** |
| **122 TB** | ₹40,260 | **₹2,41,560** |

**Scaleway is still 45% cheaper!**

---

## 📊 Cost Comparison Summary

### Storage Costs (Per 6 Months)

| Storage Option | 75TB (Previous) | 122TB (New) | Increase |
|----------------|------------------|-------------|----------|
| **Scaleway Archive** | ₹81,000 | **₹1,31,760** | ₹50,760 (63%) |
| **GCS Coldline** | ₹1,48,500 | **₹2,41,560** | ₹93,060 (63%) |
| **Railway Storage** | ₹5,62,500 | **₹9,15,000** | ₹3,52,500 (63%) |

---

## 🎯 Updated Complete Costs

### Appwrite + Railway + Scaleway Archive

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹9,900-15,000 |
| **Scaleway Archive (122TB)** | ₹1,31,760 |
| **Operations** | ₹32,000 |
| **Total** | **₹1,85,660 - ₹1,90,760** |

**vs Previous (80 students):** ₹1,22,900  
**Increase:** ₹62,760-67,860 (51% increase)

---

## 💡 Cost Optimization Strategies

### Option 1: Photo Compression

**Reduce photo size from 0.2 MB to 0.1 MB:**
- **Storage reduction:** 50%
- **New storage:** 61 TB (instead of 122 TB)
- **Cost:** ₹65,880 per 6 months (instead of ₹1,31,760)
- **Savings:** ₹65,880 per 6 months

### Option 2: Selective Photo Storage

**Store photos only for key subjects (e.g., 6 out of 12):**
- **Storage reduction:** 50%
- **New storage:** 61 TB
- **Cost:** ₹65,880 per 6 months
- **Savings:** ₹65,880 per 6 months

### Option 3: Lower Photo Quality

**Reduce quality from 0.2 MB to 0.15 MB:**
- **Storage reduction:** 25%
- **New storage:** 91.5 TB
- **Cost:** ₹98,820 per 6 months
- **Savings:** ₹32,940 per 6 months

---

## 📝 Updated Recommendations

### Best Setup (With Optimization)

**Use photo compression (0.1 MB instead of 0.2 MB):**

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹9,900 |
| **Scaleway Archive (61TB)** | ₹65,880 |
| **Operations** | ₹20,000 |
| **Total** | **₹1,07,780** |

**Savings:** ₹77,880 vs uncompressed (42% cheaper)

---

## ✅ Summary

**With 125-130 Students Per Institute:**

1. **Storage increases** from 75TB to 122TB (63% increase)
2. **Costs increase** from ₹1,22,900 to ₹1,85,660 per 6 months
3. **Still profitable** - ₹200 per institute revenue vs ₹61.89 cost
4. **Optimization recommended** - compress photos to reduce costs

**Recommendation:** Use Scaleway Archive + Photo Compression = ₹1,07,780 per 6 months
