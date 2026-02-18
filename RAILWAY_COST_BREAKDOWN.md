# Railway PostgreSQL & Operations Cost Breakdown

## 💰 Railway Pricing Structure

Railway uses **usage-based pricing** - you pay for what you use, by the second.

---

## 📊 Railway Plans

| Plan | Monthly Fee | Includes Credits | Best For |
|------|-------------|------------------|----------|
| **Free** | $0/month | $5 credits (30-day trial) | Testing |
| **Hobby** | $5/month | $5 usage credits | Small apps |
| **Pro** ⭐ | **$20/month** | **$20 usage credits** | **Production (Recommended)** |
| **Enterprise** | Custom | Custom | Large scale |

**For your app:** **Pro Plan ($20/month)** is recommended.

---

## 💾 Railway PostgreSQL Costs

### Database Storage Pricing

| Resource | Price |
|----------|-------|
| **Volume Storage** | **$0.15 per GB/month** (~₹12.50 per GB/month) |
| **RAM** | $10 per GB/month (~₹833 per GB/month) |
| **CPU** | $20 per vCPU/month (~₹1,667 per vCPU/month) |

**PostgreSQL uses:** Storage (volume) + RAM + CPU

---

## 📈 Your Database Usage (3,000 Institutes, 130 Students Each)

### Storage Requirements

**Database size estimate:**
- Institutes: 3,000 records × ~1 KB = ~3 MB
- Batches: 6,000 records × ~2 KB = ~12 MB
- Students: 390,000 records × ~1 KB = ~390 MB
- Attendance: ~468M records × ~0.5 KB = ~234 GB
- Users: ~9,000 records × ~1 KB = ~9 MB
- Error logs: ~100K records × ~2 KB = ~200 MB

**Total database storage:** ~**235 GB** (with indexes and overhead)

### RAM & CPU Requirements

**Recommended:**
- **RAM:** 2GB (for good performance)
- **CPU:** 1 vCPU (sufficient for queries)

---

## 💵 Railway PostgreSQL Cost Calculation

### Storage Cost (235 GB)

| Item | Calculation | Cost |
|------|------------|------|
| **Volume Storage** | 235 GB × ₹12.50/GB/month | **₹2,937.50/month** |
| **Per 6 months** | ₹2,937.50 × 6 | **₹17,625** |

### RAM Cost (2GB)

| Item | Calculation | Cost |
|------|------------|------|
| **RAM** | 2 GB × ₹833/GB/month | **₹1,666/month** |
| **Per 6 months** | ₹1,666 × 6 | **₹9,996** |

### CPU Cost (1 vCPU)

| Item | Calculation | Cost |
|------|------------|------|
| **CPU** | 1 vCPU × ₹1,667/vCPU/month | **₹1,667/month** |
| **Per 6 months** | ₹1,667 × 6 | **₹9,996** |

### Pro Plan Subscription

| Item | Cost |
|------|------|
| **Pro Plan** | $20/month = ₹1,650/month |
| **Per 6 months** | ₹1,650 × 6 = **₹9,900** |
| **Includes:** $20 usage credits/month (can offset some costs)

---

## 📊 Total Railway PostgreSQL Cost (6 Months)

| Item | Cost (6 months) |
|------|-----------------|
| **Pro Plan Subscription** | ₹9,900 |
| **Storage (235 GB)** | ₹17,625 |
| **RAM (2 GB)** | ₹9,996 |
| **CPU (1 vCPU)** | ₹9,996 |
| **Less: Usage Credits** | -₹9,900 (offset) |
| **Total Railway PostgreSQL** | **₹37,617** |

**Note:** Usage credits ($20/month = ₹1,650/month) can offset RAM/CPU costs.

**Optimized Cost (with credits):** ~**₹27,717 per 6 months**

---

## 🔄 Operations Costs

### Database Operations (Railway PostgreSQL)

**Railway PostgreSQL charges:**
- ✅ **No per-query charges** - Unlimited queries included
- ✅ **No per-write charges** - Unlimited writes included
- ✅ **No per-read charges** - Unlimited reads included

**You only pay for:**
- Storage (volume size)
- RAM (allocated)
- CPU (allocated)
- Network egress (if applicable)

---

## 🌐 Network Egress Costs

### If You Exceed Free Tier

| Item | Price |
|------|-------|
| **Network Egress** | $0.05 per GB (~₹4.17 per GB) |

**Your Usage:**
- Database queries: Minimal egress (mostly internal)
- Estimated egress: < 10 GB/month
- **Cost:** ~₹417/month = **₹2,502 per 6 months**

---

## 📊 Complete Railway Cost Breakdown

### Railway PostgreSQL (6 Months)

| Item | Cost |
|------|------|
| **Pro Plan Subscription** | ₹9,900 |
| **Storage (235 GB)** | ₹17,625 |
| **RAM (2 GB)** | ₹9,996 |
| **CPU (1 vCPU)** | ₹9,996 |
| **Network Egress** | ₹2,502 |
| **Less: Usage Credits** | -₹9,900 |
| **Total** | **₹40,119** |

**Optimized (minimal egress):** ~**₹37,617 per 6 months**

---

## 💡 Cost Optimization Tips

### 1. Use Pro Plan Credits

**Pro Plan includes $20/month credits:**
- Can offset RAM/CPU costs
- **Savings:** ₹9,900 per 6 months

### 2. Optimize Storage

**Reduce database size:**
- Archive old attendance records
- Compress data
- **Potential savings:** 30-50%

### 3. Right-Size Resources

**Start small, scale up:**
- Start with 1GB RAM, 0.5 vCPU
- Monitor and upgrade if needed
- **Potential savings:** ₹5,000-10,000 per 6 months

---

## 📊 Updated Complete Costs

### Appwrite + Railway + Scaleway Archive

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹37,617 |
| **Scaleway Archive (122TB)** | ₹1,31,760 |
| **Total** | **₹1,81,377** |

**vs Previous Estimate:** ₹1,85,660  
**Difference:** More accurate Railway costs included

---

## 🎯 Railway PostgreSQL Cost Summary

### Monthly Cost

| Item | Monthly Cost |
|------|--------------|
| **Pro Plan** | ₹1,650 |
| **Storage (235 GB)** | ₹2,937.50 |
| **RAM (2 GB)** | ₹1,666 |
| **CPU (1 vCPU)** | ₹1,667 |
| **Network Egress** | ₹417 |
| **Less: Credits** | -₹1,650 |
| **Total Monthly** | **₹6,687** |

### 6-Month Cost

**Railway PostgreSQL:** **₹40,119 per 6 months**

**With optimization:** **₹27,717 - ₹37,617 per 6 months**

---

## ✅ What's Included

**Railway PostgreSQL includes:**
- ✅ Unlimited database queries (no per-query charges)
- ✅ Unlimited writes (no per-write charges)
- ✅ Unlimited reads (no per-read charges)
- ✅ Automated backups
- ✅ High availability
- ✅ Automatic scaling

**You only pay for:**
- Storage used
- RAM allocated
- CPU allocated
- Network egress (if applicable)

---

## 🎉 Summary

**Railway PostgreSQL Costs:**
- **Monthly:** ₹6,687/month
- **6 Months:** ₹40,119 (or ₹27,717-37,617 with optimization)
- **No per-operation charges** - Unlimited queries included!

**Total Setup Cost:**
- **Appwrite + Railway + Scaleway:** ₹1,81,377 per 6 months

**Still much cheaper than Appwrite Storage!** ✅
