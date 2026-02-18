# Cost Calculation - 2 Lakh Students (200,000) for 3,000 Institutes

## 📊 Updated Assumptions

**Previous Assumptions:**
- 125-130 students per institute
- Total: ~390,000 students

**New Assumptions:**
- **2 lakh (200,000) students total**
- **3,000 institutes**
- **Average: 66.67 students per institute**

**This is LOWER than previous estimates, so costs will be REDUCED!**

---

## 📈 Storage Calculation

### Per Student Storage (6-Month Batch)

| Item | Value |
|------|-------|
| **Lectures per day** | 12 |
| **Working days** | 130 days (6 months) |
| **Photos per student** | 12 × 130 = **1,560 photos** |
| **Photo size** | 0.2 MB each |
| **Storage per student** | 1,560 × 0.2 MB = **312 MB** |

### Per Institute Storage

**With 66.67 students per institute:**
- 66.67 students × 312 MB = **20.8 GB per institute**

**Rounded:** **~21 GB per institute**

### Total Storage (3,000 Institutes)

**Calculation:**
- 3,000 institutes × 21 GB = **63 TB**

**With overhead and indexes:** **~65 TB** (rolling 6-month window)

---

## 💰 Storage Costs (Per 6 Months)

### Scaleway Archive (Recommended)

| Storage | Monthly Cost | 6-Month Cost |
|---------|--------------|--------------|
| **63 TB** | ₹11,340 | **₹68,040** |
| **65 TB** | ₹11,700 | **₹70,200** |

**Average:** **₹69,120 per 6 months**

### GCS Coldline (For Comparison)

| Storage | Monthly Cost | 6-Month Cost |
|---------|--------------|--------------|
| **63 TB** | ₹20,790 | **₹1,24,740** |
| **65 TB** | ₹21,450 | **₹1,28,700** |

**Average:** **₹1,26,720 per 6 months**

**Scaleway is 45% cheaper!**

---

## 💾 Database Storage Calculation

### Database Size Estimate

**For 3,000 institutes × 66.67 students:**

| Table | Records | Size per Record | Total Size |
|-------|---------|-----------------|------------|
| **Institutes** | 3,000 | ~1 KB | ~3 MB |
| **Batches** | ~6,000 | ~2 KB | ~12 MB |
| **Students** | ~200,000 | ~1 KB | ~200 MB |
| **Attendance** | ~312M | ~0.5 KB | ~156 GB |
| **Users** | ~9,000 | ~1 KB | ~9 MB |
| **Error Logs** | ~100K | ~2 KB | ~200 MB |
| **Indexes** | - | - | ~30 GB |
| **Total** | - | - | **~186 GB** |

**Rounded:** **~190 GB**

---

## 💵 Railway PostgreSQL Costs

### Resource Requirements

**Recommended for your scale:**
- **RAM:** 2GB (for good query performance)
- **CPU:** 1 vCPU (sufficient for 2.4M writes/day)
- **Storage:** 190 GB

### Monthly Costs

| Item | Calculation | Monthly Cost |
|------|------------|--------------|
| **Pro Plan Subscription** | $20/month | ₹1,650 |
| **Storage (190 GB)** | 190 × ₹12.50 | ₹2,375 |
| **RAM (2 GB)** | 2 × ₹833 | ₹1,666 |
| **CPU (1 vCPU)** | 1 × ₹1,667 | ₹1,667 |
| **Network Egress (~10 GB)** | 10 × ₹4.17 | ₹417 |
| **Subtotal** | - | **₹7,775** |
| **Less: Pro Plan Credits** | -₹1,650 | **-₹1,650** |
| **Total Monthly** | - | **₹6,125** |

### 6-Month Costs

| Item | Cost (6 months) |
|------|-----------------|
| **Pro Plan** | ₹9,900 |
| **Storage (190 GB)** | ₹14,250 |
| **RAM (2 GB)** | ₹9,996 |
| **CPU (1 vCPU)** | ₹9,996 |
| **Network Egress** | ₹2,502 |
| **Less: Credits** | -₹9,900 |
| **Total Railway PostgreSQL** | **₹36,744** |

**Rounded:** **₹37,000 per 6 months**

---

## 🔄 Database Operations

### Writes Per Day

**Calculation:**
- 3,000 institutes × 66.67 students × 12 lectures = **2,400,000 writes/day**

**Previous (130 students):** 4,680,000 writes/day  
**New (66.67 students):** 2,400,000 writes/day  
**Reduction:** 49% fewer writes!

### Operations Cost

✅ **Railway PostgreSQL includes:**
- Unlimited SELECT queries - FREE
- Unlimited INSERT operations - FREE
- Unlimited UPDATE operations - FREE
- Unlimited DELETE operations - FREE

**Your 2.4M writes/day = FREE!**  
**Your millions of reads = FREE!**

---

## 📊 Complete Cost Breakdown

### Appwrite + Railway + Scaleway Archive

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹37,000 |
| **Scaleway Archive (65TB)** | ₹70,200 |
| **Total** | **₹1,19,200** |

### Comparison with Previous Estimates

| Scenario | Students/Institute | Total Students | Cost (6 months) |
|----------|-------------------|----------------|-----------------|
| **Previous** | 130 | ~390,000 | ₹1,81,377 |
| **New** | 66.67 | **200,000** | **₹1,19,200** |
| **Savings** | - | - | **₹62,177 (34% cheaper!)** |

---

## 💡 Cost Optimization Options

### Option 1: Photo Compression

**Reduce photo size from 0.2 MB to 0.1 MB:**
- **Storage reduction:** 50%
- **New storage:** 32.5 TB (instead of 65 TB)
- **Cost:** ₹35,100 per 6 months (instead of ₹70,200)
- **Savings:** ₹35,100 per 6 months

**Total with compression:** ₹84,100 per 6 months

### Option 2: Selective Photo Storage

**Store photos only for key subjects (e.g., 6 out of 12):**
- **Storage reduction:** 50%
- **New storage:** 32.5 TB
- **Cost:** ₹35,100 per 6 months
- **Savings:** ₹35,100 per 6 months

### Option 3: Lower Photo Quality

**Reduce quality from 0.2 MB to 0.15 MB:**
- **Storage reduction:** 25%
- **New storage:** 48.75 TB
- **Cost:** ₹52,650 per 6 months
- **Savings:** ₹17,550 per 6 months

---

## 📊 Per Institute Cost Breakdown

### Without Optimization

| Item | Cost Per Institute (6 months) |
|------|-------------------------------|
| **Appwrite Pro** | ₹4.00 |
| **Railway PostgreSQL** | ₹12.33 |
| **Scaleway Archive** | ₹23.40 |
| **Total** | **₹39.73** |

### With Photo Compression (0.1 MB)

| Item | Cost Per Institute (6 months) |
|------|-------------------------------|
| **Appwrite Pro** | ₹4.00 |
| **Railway PostgreSQL** | ₹12.33 |
| **Scaleway Archive** | ₹11.70 |
| **Total** | **₹28.03** |

---

## 💰 Revenue vs Cost Analysis

### Per Institute

| Item | Value |
|------|-------|
| **Revenue per institute** | ₹200 (6 months) |
| **Cost per institute** | ₹39.73 (without optimization) |
| **Cost per institute** | ₹28.03 (with compression) |
| **Profit per institute** | **₹160.27 - ₹171.97** |

### Total (3,000 Institutes)

| Item | Value |
|------|-------|
| **Total Revenue** | ₹6,00,000 (6 months) |
| **Total Cost** | ₹1,19,200 (without optimization) |
| **Total Cost** | ₹84,100 (with compression) |
| **Total Profit** | **₹4,80,800 - ₹5,15,900** |

**Profit Margin:** 80-86% ✅

---

## 🎯 Cost Comparison Summary

### Storage Costs (Per 6 Months)

| Storage Option | 65TB Cost | vs Previous (122TB) |
|----------------|-----------|---------------------|
| **Scaleway Archive** | ₹70,200 | ₹61,560 cheaper (47% less) |
| **GCS Coldline** | ₹1,28,700 | ₹1,12,860 cheaper (47% less) |
| **Railway Storage** | ₹5,85,000 | ₹3,30,000 cheaper (36% less) |

### Complete Setup Costs

| Setup | Cost (6 months) | vs Previous |
|-------|-----------------|-------------|
| **Appwrite + Railway + Scaleway** | **₹1,19,200** | ₹62,177 cheaper (34% less) |
| **With Photo Compression** | **₹84,100** | ₹97,277 cheaper (54% less) |

---

## ✅ Summary

### With 2 Lakh Students (200,000) for 3,000 Institutes:

**Key Metrics:**
- **Average students per institute:** 66.67
- **Total storage:** 65 TB (vs 122 TB previously)
- **Database size:** 190 GB (vs 235 GB previously)
- **Writes per day:** 2.4M (vs 4.68M previously)

**Costs (6 Months):**
- **Appwrite Pro:** ₹12,000
- **Railway PostgreSQL:** ₹37,000
- **Scaleway Archive:** ₹70,200
- **Total:** **₹1,19,200**

**With Photo Compression:**
- **Total:** **₹84,100** (30% cheaper)

**Per Institute:**
- **Cost:** ₹39.73 (or ₹28.03 with compression)
- **Revenue:** ₹200
- **Profit:** ₹160.27 - ₹171.97 per institute

**Total Profit:** ₹4,80,800 - ₹5,15,900 per 6 months

---

## 🎉 Recommendations

1. **Use Scaleway Archive** - Still cheapest option
2. **Implement Photo Compression** - Save ₹35,100 per 6 months
3. **Monitor Railway PostgreSQL** - 2.4M writes/day is manageable
4. **Profit Margin:** 80-86% - Excellent!

**Much better costs with 2 lakh students!** ✅
