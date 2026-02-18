# Profit & Expense Analysis - 2 Lakh Students

**Date:** February 3, 2026  
**Total Students:** 2,00,000 (2 Lakh)  
**Total Institutes:** 3,000  
**Average Students per Institute:** 66.67

---

## 💰 Revenue Analysis

### Per Institute Revenue

| Item | Amount |
|------|--------|
| **Setup Fee** | ₹500 |
| **6-Month Subscription** | ₹1,200 |
| **Total Revenue per Institute** | **₹1,700** |

### Total Revenue

| Item | Quantity | Unit Price | Total |
|------|----------|------------|-------|
| **Setup Fee** | 3,000 institutes | ₹500 | ₹15,00,000 |
| **6-Month Subscription** | 3,000 institutes | ₹1,200 | ₹36,00,000 |
| **Total Revenue** | - | - | **₹51,00,000** |

---

## 💸 Expense Analysis

### Infrastructure Costs (6 Months)

#### 1. Appwrite Pro Plan
| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Purpose:** Authentication & User Management |

#### 2. Railway PostgreSQL Database
| Item | Cost (6 months) |
|------|-----------------|
| **Pro Plan** | ₹9,900 |
| **Storage (190GB)** | ₹14,250 |
| **RAM (2GB)** | ₹9,996 |
| **CPU (1vCPU)** | ₹9,996 |
| **Network Egress** | ₹2,502 |
| **Less: Credits** | -₹9,900 |
| **Total Railway PostgreSQL** | **₹36,744** |

**Database Size Calculation:**
- Students: 200,000 × 1 KB = 200 MB
- Attendance: ~312M records × 0.5 KB = ~156 GB
- Indexes & Overhead: ~30 GB
- **Total:** ~190 GB

**Operations:**
- Writes per day: 3,000 × 66.67 × 12 = 2,400,000 writes/day
- Writes per month: 72M writes/month
- **Railway:** Unlimited operations (FREE)

#### 3. Scaleway Archive Storage
| Item | Cost (6 months) |
|------|-----------------|
| **Storage (65TB)** | ₹70,200 |
| **Purpose:** Photo storage with 180-day retention |

**Storage Calculation:**
- Per student: 312 MB (1,560 photos × 0.2 MB)
- Per institute: 66.67 students × 312 MB = 20.8 GB
- Total: 3,000 × 20.8 GB = 62.4 TB
- With overhead: **~65 TB**

**Monthly Cost:** 65TB × ₹0.18/GB/month = ₹11,700/month  
**6-Month Cost:** ₹11,700 × 6 = **₹70,200**

#### 4. Super Admin Web App Hosting
| Item | Cost (6 months) |
|------|-----------------|
| **VPS Hosting (A2 Hosting)** | ₹1,494 |
| **Purpose:** Super Admin web app hosting |

**Hosting Details:**
- **Provider:** A2 Hosting (Cheapest Option)
- **Plan:** Starter VPS
- **Specs:** 1 vCPU, 1GB RAM, 25GB SSD, Unlimited Bandwidth
- **Monthly Cost:** ₹249/month
- **6-Month Cost:** ₹249 × 6 = **₹1,494**

**Alternative Options:**
- Hostinger: ₹349/month = ₹2,094 (6 months)
- MilesWeb: ₹429/month = ₹2,574 (6 months)

**Selected:** A2 Hosting (cheapest at ₹249/month)

### Total Infrastructure Costs

| Service | Cost (6 months) |
|---------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹36,744 |
| **Scaleway Archive** | ₹70,200 |
| **Super Admin Web App Hosting** | ₹1,494 |
| **Total Infrastructure** | **₹1,20,438** |

---

## 📊 Additional Expenses

### Operational Expenses (Estimated)

| Item | Cost (6 months) |
|------|-----------------|
| **Support Staff** | ₹1,00,000 |
| **Marketing** | ₹50,000 |
| **Legal & Compliance** | ₹25,000 |
| **Miscellaneous** | ₹25,000 |
| **Total Operational** | **₹2,00,000** |

### Contingency (10%)

| Item | Cost (6 months) |
|------|-----------------|
| **Contingency (10% of infrastructure)** | ₹12,044 |
| **Total Contingency** | **₹12,044** |

---

## 💵 Complete Expense Breakdown

### Total Expenses (6 Months)

| Category | Cost |
|----------|------|
| **Infrastructure** | ₹1,20,438 |
| **Operational** | ₹2,00,000 |
| **Contingency** | ₹12,044 |
| **Total Expenses** | **₹3,32,482** |

---

## 💰 Profit Analysis

### Gross Profit

| Item | Amount |
|------|--------|
| **Total Revenue** | ₹51,00,000 |
| **Total Expenses** | ₹3,32,482 |
| **Gross Profit** | **₹47,67,518** |

### Profit Margin

| Metric | Value |
|--------|-------|
| **Profit Margin** | 93.5% |
| **Cost per Institute** | ₹110.83 |
| **Revenue per Institute** | ₹1,700 |
| **Profit per Institute** | **₹1,589.17** |

---

## 📈 Per Institute Breakdown

### Revenue per Institute

| Item | Amount |
|------|--------|
| **Setup Fee** | ₹500 |
| **6-Month Subscription** | ₹1,200 |
| **Total Revenue** | **₹1,700** |

### Cost per Institute

| Item | Amount |
|------|--------|
| **Infrastructure** | ₹40.15 |
| **Operational** | ₹66.67 |
| **Contingency** | ₹4.01 |
| **Total Cost** | **₹110.83** |

### Profit per Institute

| Item | Amount |
|------|--------|
| **Revenue** | ₹1,700 |
| **Cost** | ₹110.83 |
| **Profit** | **₹1,589.17** |
| **Profit Margin** | **93.5%** |

---

## 🎯 Maximum Expenses (Worst Case Scenario)

### Scenario 1: Maximum Infrastructure Costs

**If storage/database usage increases by 20%:**

| Item | Base Cost | +20% | Total |
|------|-----------|------|-------|
| **Railway PostgreSQL** | ₹36,744 | ₹7,349 | ₹44,093 |
| **Scaleway Archive** | ₹70,200 | ₹14,040 | ₹84,240 |
| **Appwrite Pro** | ₹12,000 | - | ₹12,000 |
| **Web App Hosting** | ₹1,494 | - | ₹1,494 |
| **Total Infrastructure** | ₹1,20,438 | ₹21,389 | **₹1,41,827** |

### Scenario 2: Maximum Operational Costs

**If operational expenses increase by 50%:**

| Item | Base Cost | +50% | Total |
|------|-----------|------|-------|
| **Support Staff** | ₹1,00,000 | ₹50,000 | ₹1,50,000 |
| **Marketing** | ₹50,000 | ₹25,000 | ₹75,000 |
| **Legal & Compliance** | ₹25,000 | ₹12,500 | ₹37,500 |
| **Miscellaneous** | ₹25,000 | ₹12,500 | ₹37,500 |
| **Total Operational** | ₹2,00,000 | ₹1,00,000 | **₹3,00,000** |

### Scenario 3: Upgrade Web App Hosting

**If web app needs more resources:**

| Option | Monthly | 6 Months |
|--------|---------|-----------|
| **A2 Hosting (Current)** | ₹249 | ₹1,494 |
| **Hostinger (Upgrade)** | ₹349 | ₹2,094 |
| **MilesWeb (Premium)** | ₹429 | ₹2,574 |

**Maximum Web App Hosting:** ₹2,574 (if upgraded)

### Worst Case Total Expenses

| Category | Base | Maximum | Difference |
|----------|------|---------|------------|
| **Infrastructure** | ₹1,20,438 | ₹1,44,401 | +₹23,963 |
| **Operational** | ₹2,00,000 | ₹3,00,000 | +₹1,00,000 |
| **Contingency** | ₹12,044 | ₹14,440 | +₹2,396 |
| **Total Expenses** | ₹3,32,482 | **₹4,58,841** | +₹1,26,359 |

### Worst Case Profit

| Item | Amount |
|------|--------|
| **Total Revenue** | ₹51,00,000 |
| **Maximum Expenses** | ₹4,58,841 |
| **Minimum Profit** | **₹46,41,159** |
| **Minimum Profit Margin** | **91.0%** |

---

## 📊 Cost Optimization Options

### Option 1: Photo Compression

**Reduce photo size from 0.2 MB to 0.1 MB:**

| Item | Current | With Compression | Savings |
|------|---------|-----------------|---------|
| **Storage** | 65 TB | 32.5 TB | 50% |
| **Scaleway Cost** | ₹70,200 | ₹35,100 | ₹35,100 |
| **New Total Expenses** | ₹3,32,482 | ₹2,97,382 | ₹35,100 |
| **New Profit** | ₹47,67,518 | **₹50,02,618** | +₹35,100 |

### Option 2: Selective Photo Storage

**Store photos only for key subjects (6 out of 12):**

| Item | Current | Selective Storage | Savings |
|------|---------|------------------|---------|
| **Storage** | 65 TB | 32.5 TB | 50% |
| **Scaleway Cost** | ₹70,200 | ₹35,100 | ₹35,100 |
| **New Total Expenses** | ₹3,32,482 | ₹2,97,382 | ₹35,100 |
| **New Profit** | ₹47,67,518 | **₹50,02,618** | +₹35,100 |

### Option 3: Use Free Web Hosting (Not Recommended)

**Use free hosting like Vercel/Netlify (limited):**

| Item | Current | Free Hosting | Savings |
|------|---------|--------------|---------|
| **Web App Hosting** | ₹1,494 | ₹0 | ₹1,494 |
| **New Total Expenses** | ₹3,32,482 | ₹3,30,988 | ₹1,494 |
| **New Profit** | ₹47,67,518 | **₹47,69,012** | +₹1,494 |

**Note:** Free hosting has limitations (bandwidth, build minutes, etc.) - Not recommended for production.

---

## ✅ Summary

### Revenue

| Item | Amount |
|------|--------|
| **Total Revenue** | **₹51,00,000** |
| **Per Institute** | ₹1,700 |

### Expenses

| Item | Amount |
|------|--------|
| **Infrastructure** | ₹1,20,438 |
| **Operational** | ₹2,00,000 |
| **Contingency** | ₹12,044 |
| **Total Expenses** | **₹3,32,482** |
| **Maximum Expenses** | **₹4,58,841** |

### Profit

| Item | Amount |
|------|--------|
| **Gross Profit** | **₹47,67,518** |
| **Minimum Profit (Worst Case)** | **₹46,41,159** |
| **Profit Margin** | **91.0% - 93.5%** |
| **Profit per Institute** | **₹1,487.05 - ₹1,589.17** |

---

## 🎯 Key Insights

1. **Excellent Profit Margin:** 91-94% profit margin
2. **Low Infrastructure Cost:** Only ₹1.2 lakh for 2 lakh students
3. **Web App Hosting:** Very cheap at ₹249/month (₹1,494 for 6 months)
4. **High Revenue:** ₹51 lakh revenue from 3,000 institutes
5. **Room for Optimization:** Can save ₹35,100 with photo compression

---

## 💡 Recommendations

1. **Implement Photo Compression:** Save ₹35,100 (increase profit to ₹50 lakh)
2. **Use A2 Hosting:** Cheapest option at ₹249/month for web app
3. **Monitor Infrastructure:** Track usage to optimize costs
4. **Scale Gradually:** Start with fewer institutes, scale up

---

## 📊 Infrastructure Cost Breakdown

### Detailed Infrastructure Costs (6 Months)

| Service | Monthly | 6 Months | Purpose |
|---------|---------|-----------|---------|
| **Appwrite Pro** | ₹2,000 | ₹12,000 | Authentication |
| **Railway PostgreSQL** | ₹6,124 | ₹36,744 | Database (190GB) |
| **Scaleway Archive** | ₹11,700 | ₹70,200 | Photo Storage (65TB) |
| **Web App Hosting** | ₹249 | ₹1,494 | Super Admin Web App |
| **Total** | ₹20,073 | **₹1,20,438** | - |

---

**Bottom Line:**  
**Revenue:** ₹51,00,000  
**Expenses:** ₹3,32,482 (Base) to ₹4,58,841 (Maximum)  
**Profit:** ₹46,41,159 to ₹47,67,518  
**Profit Margin:** 91.0% to 93.5%  

**Excellent profitability with Super Admin Web App included!** ✅
