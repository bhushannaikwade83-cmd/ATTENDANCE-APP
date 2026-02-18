# Updated Cost Calculation - 125-130 Students Per Institute

## 📊 Updated Assumptions

**Previous Assumptions:**
- 40 students per batch
- 2 batches per institute
- Total: 80 students per institute

**New Assumptions:**
- **125-130 students per institute** (total)
- Could be: 1 batch with 125-130 students, or multiple batches totaling 125-130

---

## 📈 Impact on Costs

### Storage Calculation (Per Institute)

**Previous (40 students per batch, 2 batches = 80 students):**
- 80 students × 12 lectures/day × 130 days = 1,248,000 photos per institute
- 1,248,000 photos × 0.2 MB = ~249.6 GB per institute

**New (125-130 students per institute):**
- 130 students × 12 lectures/day × 130 days = 2,028,000 photos per institute
- 2,028,000 photos × 0.2 MB = **~405.6 GB per institute**

**Increase:** 62% more storage per institute!

---

## 💰 Updated Storage Costs (3,000 Institutes)

### Previous Calculation (80 students per institute)

| Item | Value |
|------|-------|
| Students per institute | 80 (2 batches × 40) |
| Storage per institute | ~250 GB |
| Total storage (3,000 institutes) | ~75 TB |

### New Calculation (130 students per institute)

| Item | Value |
|------|-------|
| Students per institute | 130 |
| Storage per institute | ~406 GB |
| Total storage (3,000 institutes) | **~122 TB** |

**Storage Increase:** 75 TB → 122 TB (63% increase)

---

## 💵 Updated Cost Breakdown

### Storage Costs (Per 6 Months)

#### Scaleway Archive (Recommended)

| Storage | Cost (6 months) |
|---------|-----------------|
| **Previous (75TB)** | ₹81,000 |
| **New (122TB)** | **₹1,31,760** |
| **Increase** | ₹50,760 (63% more) |

#### GCS Coldline (For Comparison)

| Storage | Cost (6 months) |
|---------|-----------------|
| **Previous (75TB)** | ₹1,48,500 |
| **New (122TB)** | **₹2,41,560** |
| **Increase** | ₹93,060 (63% more) |

---

## 📊 Complete Updated Costs

### Appwrite + Railway + Scaleway Archive

| Item | Previous (80 students) | New (130 students) | Increase |
|------|------------------------|---------------------|----------|
| **Appwrite Pro** | ₹12,000 | ₹12,000 | - |
| **Railway PostgreSQL** | ₹9,900 | ₹9,900 | - |
| **Scaleway Archive** | ₹81,000 | **₹1,31,760** | ₹50,760 |
| **Operations** | ₹20,000 | ₹32,000 | ₹12,000 |
| **Total** | **₹1,22,900** | **₹1,85,660** | **₹62,760** |

**Cost Increase:** ₹62,760 per 6 months (51% increase)

---

## 📈 Database Operations Impact

### Writes Per Day (3,000 Institutes)

**Previous (80 students per institute):**
- 3,000 institutes × 80 students × 12 lectures = **2,880,000 writes/day**

**New (130 students per institute):**
- 3,000 institutes × 130 students × 12 lectures = **4,680,000 writes/day**

**Increase:** 63% more database writes!

### Database Cost Impact

**Railway PostgreSQL:**
- Still within limits (no per-write charges)
- May need to upgrade plan if queries become slow
- Estimated: ₹9,900 - ₹15,000 per 6 months (still affordable)

---

## 🎯 Updated Total Cost Summary

### For 3,000 Institutes (130 Students Each)

| Backend Option | Cost (6 months) |
|----------------|-----------------|
| **Appwrite + Railway + Scaleway Archive** | **₹1,85,660** |
| **Appwrite + Railway + GCS Coldline** | ₹2,95,360 |
| **Firebase (for comparison)** | ₹28,50,000 - ₹33,30,000 |

**Best Option:** Appwrite + Railway + Scaleway Archive
- **Cost:** ₹1,85,660 per 6 months
- **vs Firebase:** Save ₹26.6-31.4 lakh per 6 months!

---

## 💡 Cost Optimization Tips

### With 130 Students Per Institute:

1. **Photo Compression:**
   - Reduce photo size from 0.2 MB to 0.1 MB
   - **Savings:** 50% storage reduction = ₹65,880 per 6 months

2. **Selective Photo Storage:**
   - Store photos only for certain subjects
   - **Savings:** 30-50% storage reduction

3. **Batch Organization:**
   - If multiple batches, organize better
   - May reduce duplicate storage

---

## 📝 Updated Storage Structure

**With 130 students per institute, folder structure remains:**

```
institute_id/
  batch_year/
    rollNumber/  (130 students)
      subject/
        YYYY-MM-DD/
          photo.jpg
```

**Example:**
```
INST001/
  2024/
    STU001/  (student 1 of 130)
      mathematics/
        2024-02-03/
          photo.jpg
    STU002/  (student 2 of 130)
      ...
    STU130/  (student 130)
      ...
```

---

## ✅ Updated Recommendations

### Storage: Scaleway Archive (Still Best)

**Why:**
- ✅ Still 45% cheaper than GCS Coldline
- ✅ Handles 122TB easily
- ✅ Lifecycle policies for 180-day deletion
- ✅ **Cost:** ₹1,31,760 per 6 months (vs ₹2,41,560 for GCS)

### Database: Railway PostgreSQL (Still Good)

**Why:**
- ✅ Handles 4.68M writes/day (may need monitoring)
- ✅ No per-write charges
- ✅ May need upgrade if performance degrades
- ✅ **Cost:** ₹9,900-15,000 per 6 months

---

## 🎉 Summary

**Updated Costs with 130 Students Per Institute:**

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹9,900-15,000 |
| **Scaleway Archive (122TB)** | ₹1,31,760 |
| **Operations** | ₹32,000 |
| **Total** | **₹1,85,660 - ₹1,90,760** |

**vs Previous (80 students):** ₹1,22,900  
**Increase:** ₹62,760-67,860 per 6 months

**Still Much Cheaper Than Firebase!** 🎉

---

## 📊 Per Institute Cost

**With 130 students per institute:**

| Backend Option | Cost Per Institute (6 months) |
|----------------|-------------------------------|
| **Appwrite + Railway + Scaleway** | **₹61.89** |
| **Firebase** | ₹950-1,110 |

**Your Revenue:** ₹200 per institute  
**Your Cost:** ₹61.89 per institute  
**Your Profit:** **₹138.11 per institute** ✅

**Much better than before!** 🎉
