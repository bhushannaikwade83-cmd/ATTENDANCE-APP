# Profit & Expense Analysis - Option 1 (Maximum Savings)
## Firebase Auth + Contabo PostgreSQL + Scaleway Archive (Compressed)

**Date:** February 3, 2026  
**Total Students:** 2,00,000 (2 Lakh)  
**Total Institutes:** 3,000  
**Average Students per Institute:** 66.67  
**Total Quotation:** ₹6,50,000 **Per Year**  
**Coverage:** 2 Batches × 6 Months = 12 Months

---

## 💰 Revenue Analysis

### Per Institute Revenue (Per Year)

| Item | Amount |
|------|--------|
| **Setup Fee** | ₹100 (one-time) |
| **Annual Subscription** | ₹117 (covers 2 batches) |
| **Total Revenue per Institute** | **₹217** |

### Total Revenue

| Item | Quantity | Unit Price | Total |
|------|----------|------------|-------|
| **Setup Fee** | 3,000 institutes | ₹100 | ₹3,00,000 |
| **Annual Subscription** | 3,000 institutes | ₹117 | ₹3,51,000 |
| **Total Revenue** | - | - | **₹6,51,000** |

**Rounded Total:** **₹6,50,000 Per Year**

---

## 💸 Expense Analysis

### Infrastructure Costs (Per Year - 12 Months)

#### 1. Firebase Authentication
| Item | Cost (Per Year) |
|------|-----------------|
| **Firebase Auth** | ₹0 (FREE) |
| **Purpose:** Authentication & User Management |
| **Note:** Free for unlimited authentication |

#### 2. Contabo VPS PostgreSQL Database
| Item | Cost (Per Year) |
|------|-----------------|
| **VPS M Plan** | ₹9,600 |
| **Specs:** 4 vCPU, 8GB RAM, 400GB SSD |
| **Purpose:** Database (190GB) |

**Database Details:**
- Students: 200,000 × 1 KB = 200 MB
- Attendance: ~312M records × 0.5 KB = ~156 GB
- Indexes & Overhead: ~30 GB
- **Total:** ~190 GB

**Operations:**
- Writes per day: 3,000 × 66.67 × 12 = 2,400,000 writes/day
- Writes per month: 72M writes/month
- **Contabo:** Unlimited operations (self-hosted)

#### 3. Scaleway Archive Storage (Compressed + 6-Month Deletion)
| Item | Cost (Per Year) |
|------|-----------------|
| **Storage (16.5TB max per batch)** | ₹35,640 |
| **Purpose:** Photo storage with 6-month retention and automatic deletion |

**Storage Calculation (With Compression + 6-Month Deletion):**
- Per student: 78 MB (780 photos × 0.1 MB compressed for 6 months)
- Per institute: 66.67 students × 78 MB = 5.2 GB per batch
- Total per batch: 3,000 × 5.2 GB = 15.6 TB
- With overhead: **~16.5 TB per batch**

**Since photos are deleted after 6 months:**
- Batch 1: 16.5 TB for 6 months, then deleted
- Batch 2: 16.5 TB for 6 months, then deleted
- Maximum storage at any time: 16.5 TB

**Cost Calculation:**
- Per batch: 16.5TB × ₹0.18/GB/month × 6 months = ₹17,820
- Annual (2 batches): ₹17,820 × 2 = **₹35,640**

**Benefits:**
- Photos automatically deleted after 6 months
- Storage doesn't accumulate
- 74% cost reduction vs storing for full year

#### 4. Super Admin Web App Hosting
| Item | Cost (Per Year) |
|------|-----------------|
| **VPS Hosting (A2 Hosting)** | ₹2,988 |
| **Purpose:** Super Admin web app hosting |

**Hosting Details:**
- **Provider:** A2 Hosting
- **Plan:** Starter VPS
- **Specs:** 1 vCPU, 1GB RAM, 25GB SSD, Unlimited Bandwidth
- **Monthly Cost:** ₹249/month
- **Annual Cost:** ₹249 × 12 = **₹2,988**

#### 5. Mobile App Hosting & Services
| Item | Cost (Per Year) |
|------|-----------------|
| **Google Play Store** | ₹2,100 (one-time, amortized over 1 year) |
| **Apple App Store** | ₹8,250 (annual fee) |
| **API Hosting** | ₹0 (included in web app hosting) |
| **Push Notifications** | ₹0 (included in Firebase) |
| **Total Mobile App** | **₹10,350** |

**App Store Costs Breakdown:**
- **Google Play Store:** $25 one-time = ₹2,100 (one-time registration fee)
- **Apple App Store:** $99/year = ₹8,250/year (Apple Developer Program)
- **Total First Year:** ₹10,350
- **Subsequent Years:** ₹8,250/year (only Apple fee)

### Total Infrastructure Costs

| Service | Cost (Per Year) |
|---------|-----------------|
| **Firebase Auth** | ₹0 |
| **Contabo PostgreSQL** | ₹9,600 |
| **Scaleway Archive (Compressed + 6-Month Deletion)** | ₹35,640 |
| **Super Admin Web App Hosting** | ₹2,988 |
| **Mobile App Store Fees** | ₹10,350 |
| **Total Infrastructure** | **₹58,578** |

---

## 📊 Additional Expenses

### Development & Setup Expenses (One-Time)

| Item | Cost |
|------|------|
| **Migration from Appwrite** | ₹15,000 |
| **Migration from Railway** | ₹10,000 |
| **Photo Compression Implementation** | ₹5,000 |
| **Testing & QA** | ₹10,000 |
| **Total Development** | **₹40,000** |

### Operational Expenses (Per Year)

| Item | Cost (Per Year) |
|------|-----------------|
| **Support Staff** | ₹1,60,000 |
| **Marketing** | ₹80,000 |
| **Legal & Compliance** | ₹40,000 |
| **VPS Maintenance** | ₹20,000 |
| **Miscellaneous** | ₹40,000 |
| **Total Operational** | **₹3,40,000** |

**Note:** VPS maintenance includes monitoring, updates, and backup management.

### Contingency (10%)

| Item | Cost (Per Year) |
|------|-----------------|
| **Contingency (10% of infrastructure)** | ₹8,279 |
| **Total Contingency** | **₹8,279** |

---

## 💵 Complete Expense Breakdown

### Total Expenses (Per Year)

| Category | Cost |
|----------|------|
| **Infrastructure** | ₹58,578 |
| **Development & Setup** | ₹40,000 |
| **Operational** | ₹3,40,000 |
| **Contingency** | ₹5,858 |
| **Total Expenses** | **₹4,44,436** |

---

## 💰 Profit Analysis

### Gross Profit

| Item | Amount |
|------|--------|
| **Total Revenue** | ₹6,50,000 |
| **Total Expenses** | ₹4,44,436 |
| **Gross Profit** | **₹2,05,564** |

### Profit Margin

| Metric | Value |
|--------|-------|
| **Profit Margin** | 31.6% |
| **Cost per Institute** | ₹148.15 |
| **Revenue per Institute** | ₹217 |
| **Profit per Institute** | **₹68.52** |

---

## 📈 Per Institute Breakdown

### Revenue per Institute

| Item | Amount |
|------|--------|
| **Setup Fee** | ₹100 |
| **Annual Subscription** | ₹117 |
| **Total Revenue** | **₹217** |

### Cost per Institute

| Item | Amount |
|------|--------|
| **Infrastructure** | ₹19.53 |
| **Development & Setup** | ₹13.33 |
| **Operational** | ₹113.33 |
| **Contingency** | ₹1.96 |
| **Total Cost** | **₹148.15** |

### Profit per Institute

| Item | Amount |
|------|--------|
| **Revenue** | ₹217 |
| **Cost** | ₹148.15 |
| **Profit** | **₹68.52** |
| **Profit Margin** | **31.6%** |

---

## 📊 Cost Comparison

### Current Setup vs Option 1

| Item | Current | Option 1 | Savings |
|------|---------|----------|---------|
| **Authentication** | ₹24,000 | ₹0 | ₹24,000 |
| **Database** | ₹73,488 | ₹9,600 | ₹63,888 |
| **Storage** | ₹1,40,400 | ₹35,640 | ₹1,04,760 |
| **Web Hosting** | ₹2,988 | ₹2,988 | ₹0 |
| **App Store Fees** | ₹0 | ₹10,350 | -₹10,350 |
| **Total Infrastructure** | ₹2,40,876 | ₹58,578 | **₹1,82,298** |

**Infrastructure Savings:** 66% reduction!

### Total Expenses Comparison

| Item | Current | Option 1 | Difference |
|------|---------|----------|------------|
| **Infrastructure** | ₹2,40,876 | ₹58,578 | -₹1,82,298 |
| **Development** | ₹25,000 | ₹40,000 | +₹15,000 |
| **Operational** | ₹3,20,000 | ₹3,40,000 | +₹20,000 |
| **Contingency** | ₹24,088 | ₹5,858 | -₹18,230 |
| **Total** | ₹6,09,964 | ₹4,44,436 | **-₹1,65,528** |

**Total Savings:** ₹1,38,897 per year (23% reduction)

### Profit Comparison

| Item | Current | Option 1 | Improvement |
|------|---------|----------|-------------|
| **Revenue** | ₹6,50,000 | ₹6,50,000 | - |
| **Expenses** | ₹6,09,964 | ₹4,44,436 | -₹1,65,528 |
| **Profit** | ₹40,036 | ₹2,05,564 | **+₹1,65,528** |
| **Profit Margin** | 6.2% | 31.6% | **+25.4%** |

---

## 🎯 Key Improvements

### Infrastructure Cost Reduction

- **Before:** ₹2,40,876/year
- **After:** ₹82,788/year
- **Savings:** ₹1,58,088/year (66% reduction)

### Profit Improvement

- **Before:** ₹40,036/year
- **After:** ₹1,78,933/year
- **Increase:** ₹1,38,897/year (347% increase)

### Profit Margin Improvement

- **Before:** 6.2%
- **After:** 27.5%
- **Increase:** 21.3 percentage points

---

## ✅ Summary

### Revenue

| Item | Amount |
|------|--------|
| **Total Revenue** | **₹6,50,000 Per Year** |
| **Per Institute** | ₹217 |

### Expenses

| Item | Amount |
|------|--------|
| **Infrastructure** | ₹82,788 |
| **Development & Setup** | ₹40,000 |
| **Operational** | ₹3,40,000 |
| **Contingency** | ₹8,279 |
| **Total Expenses** | **₹4,71,067** |

### Profit

| Item | Amount |
|------|--------|
| **Gross Profit** | **₹2,05,564** |
| **Profit Margin** | **31.6%** |
| **Profit per Institute** | **₹68.52** |

---

## 🎉 Benefits of Option 1

1. ✅ **66% infrastructure cost reduction**
2. ✅ **347% profit increase** (from ₹40K to ₹1.79L)
3. ✅ **21.3% profit margin improvement** (from 6.2% to 27.5%)
4. ✅ **Free authentication** (Firebase)
5. ✅ **Cheap database hosting** (Contabo)
6. ✅ **50% storage reduction** (photo compression)
7. ✅ **Self-hosted control** (full database control)

---

**Bottom Line:**  
**Revenue:** ₹6,50,000 Per Year  
**Expenses:** ₹4,44,436  
**Profit:** ₹2,05,564  
**Profit Margin:** 31.6%  

**Excellent profitability with Option 1 + 6-Month Photo Deletion!** ✅

**Key Benefits:**
- Photos automatically deleted after 6 months, saving ₹1,04,760/year
- App Store fees included: Android (₹2,100 one-time) + iOS (₹8,250/year)
