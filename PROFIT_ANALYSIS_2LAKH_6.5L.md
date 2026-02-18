# Profit & Expense Analysis - 2 Lakh Students
## Web Application + Mobile App | Quotation: ₹6.5 Lakh Per Year

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

**Note:** Annual subscription covers 2 batches of 6 months each = 12 months total.

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

#### 1. Appwrite Pro Plan
| Item | Cost (Per Year) |
|------|-----------------|
| **Appwrite Pro** | ₹24,000 |
| **Purpose:** Authentication & User Management |
| **Note:** ₹2,000/month × 12 months |

#### 2. Railway PostgreSQL Database
| Item | Cost (Per Year) |
|------|-----------------|
| **Pro Plan** | ₹19,800 |
| **Storage (190GB)** | ₹28,500 |
| **RAM (2GB)** | ₹19,992 |
| **CPU (1vCPU)** | ₹19,992 |
| **Network Egress** | ₹5,004 |
| **Less: Credits** | -₹19,800 |
| **Total Railway PostgreSQL** | **₹73,488** |
| **Note:** Monthly cost ₹6,124 × 12 months |

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
| Item | Cost (Per Year) |
|------|-----------------|
| **Storage (65TB)** | ₹1,40,400 |
| **Purpose:** Photo storage with 180-day retention |

**Storage Calculation:**
- Per student: 312 MB (1,560 photos × 0.2 MB)
- Per institute: 66.67 students × 312 MB = 20.8 GB
- Total: 3,000 × 20.8 GB = 62.4 TB
- With overhead: **~65 TB**

**Monthly Cost:** 65TB × ₹0.18/GB/month = ₹11,700/month  
**Annual Cost:** ₹11,700 × 12 = **₹1,40,400**

**Note:** Storage is rolling - photos deleted after 180 days, so storage remains ~65TB throughout the year.

#### 4. Super Admin Web App Hosting
| Item | Cost (Per Year) |
|------|-----------------|
| **VPS Hosting (A2 Hosting)** | ₹2,988 |
| **Purpose:** Super Admin web app hosting |

**Hosting Details:**
- **Provider:** A2 Hosting (Cheapest Option)
- **Plan:** Starter VPS
- **Specs:** 1 vCPU, 1GB RAM, 25GB SSD, Unlimited Bandwidth
- **Monthly Cost:** ₹249/month
- **Annual Cost:** ₹249 × 12 = **₹2,988**

#### 5. Mobile App Hosting & Services
| Item | Cost (Per Year) |
|------|-----------------|
| **App Store Fees (One-time)** | ₹0 (included in setup) |
| **API Hosting** | ₹0 (included in web app hosting) |
| **Push Notifications** | ₹0 (included in Appwrite) |
| **Total Mobile App** | **₹0** |

**Note:** Mobile apps use same infrastructure (no additional cost)

### Total Infrastructure Costs

| Service | Cost (Per Year) |
|---------|-----------------|
| **Appwrite Pro** | ₹24,000 |
| **Railway PostgreSQL** | ₹73,488 |
| **Scaleway Archive** | ₹1,40,400 |
| **Super Admin Web App Hosting** | ₹2,988 |
| **Mobile App Services** | ₹0 |
| **Total Infrastructure** | **₹2,40,876** |

---

## 📊 Additional Expenses

### Development & Setup Expenses (One-Time)

| Item | Cost |
|------|------|
| **Web App Development** | ₹0 (already developed) |
| **Mobile App Development** | ₹0 (already developed) |
| **App Store Submission** | ₹0 (included) |
| **Testing & QA** | ₹25,000 |
| **Total Development** | **₹25,000** |

### Operational Expenses (Per Year)

| Item | Cost (Per Year) |
|------|-----------------|
| **Support Staff** | ₹1,60,000 |
| **Marketing** | ₹80,000 |
| **Legal & Compliance** | ₹40,000 |
| **Miscellaneous** | ₹40,000 |
| **Total Operational** | **₹3,20,000** |

### Contingency (10%)

| Item | Cost (Per Year) |
|------|-----------------|
| **Contingency (10% of infrastructure)** | ₹24,088 |
| **Total Contingency** | **₹24,088** |

---

## 💵 Complete Expense Breakdown

### Total Expenses (Per Year)

| Category | Cost |
|----------|------|
| **Infrastructure** | ₹2,40,876 |
| **Development & Setup** | ₹25,000 |
| **Operational** | ₹3,20,000 |
| **Contingency** | ₹24,088 |
| **Total Expenses** | **₹6,09,964** |

---

## 💰 Profit Analysis

### Gross Profit

| Item | Amount |
|------|--------|
| **Total Revenue** | ₹6,50,000 |
| **Total Expenses** | ₹6,09,964 |
| **Gross Profit** | **₹40,036** |

### Profit Margin

| Metric | Value |
|--------|-------|
| **Profit Margin** | 6.2% |
| **Cost per Institute** | ₹203.32 |
| **Revenue per Institute** | ₹217 |
| **Profit per Institute** | **₹13.35** |

---

## 📈 Per Institute Breakdown

### Revenue per Institute

| Item | Amount |
|------|--------|
| **Setup Fee** | ₹100 |
| **6-Month Subscription** | ₹117 |
| **Total Revenue** | **₹217** |

### Cost per Institute

| Item | Amount |
|------|--------|
| **Infrastructure** | ₹80.29 |
| **Development & Setup** | ₹8.33 |
| **Operational** | ₹106.67 |
| **Contingency** | ₹8.03 |
| **Total Cost** | **₹203.32** |

### Profit per Institute

| Item | Amount |
|------|--------|
| **Revenue** | ₹217 |
| **Cost** | ₹203.32 |
| **Profit** | **₹13.35** |
| **Profit Margin** | **6.2%** |

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
| **Support Staff** | ₹80,000 | ₹40,000 | ₹1,20,000 |
| **Marketing** | ₹40,000 | ₹20,000 | ₹60,000 |
| **Legal & Compliance** | ₹20,000 | ₹10,000 | ₹30,000 |
| **Miscellaneous** | ₹20,000 | ₹10,000 | ₹30,000 |
| **Total Operational** | ₹1,60,000 | ₹80,000 | **₹2,40,000** |

### Worst Case Total Expenses

| Category | Base | Maximum | Difference |
|----------|------|---------|------------|
| **Infrastructure** | ₹1,20,438 | ₹1,41,827 | +₹21,389 |
| **Development & Setup** | ₹25,000 | ₹30,000 | +₹5,000 |
| **Operational** | ₹1,60,000 | ₹2,40,000 | +₹80,000 |
| **Contingency** | ₹12,044 | ₹14,183 | +₹2,139 |
| **Total Expenses** | ₹3,17,482 | **₹4,26,010** | +₹1,08,528 |

### Worst Case Profit

| Item | Amount |
|------|--------|
| **Total Revenue** | ₹6,50,000 |
| **Maximum Expenses** | ₹4,26,010 |
| **Minimum Profit** | **₹2,23,990** |
| **Minimum Profit Margin** | **34.5%** |

---

## 📊 Cost Optimization Options

### Option 1: Photo Compression

**Reduce photo size from 0.2 MB to 0.1 MB:**

| Item | Current | With Compression | Savings |
|------|---------|-----------------|---------|
| **Storage** | 65 TB | 32.5 TB | 50% |
| **Scaleway Cost** | ₹70,200 | ₹35,100 | ₹35,100 |
| **New Total Expenses** | ₹3,17,482 | ₹2,82,382 | ₹35,100 |
| **New Profit** | ₹3,32,518 | **₹3,67,618** | +₹35,100 |

### Option 2: Use Cheaper Web Hosting

**Use shared hosting instead of VPS:**

| Item | Current | Shared Hosting | Savings |
|------|---------|---------------|---------|
| **Web App Hosting** | ₹1,494 | ₹600 | ₹894 |
| **New Total Expenses** | ₹3,17,482 | ₹3,16,588 | ₹894 |
| **New Profit** | ₹3,32,518 | **₹3,33,412** | +₹894 |

**Note:** Shared hosting may have limitations - VPS recommended for production.

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
| **Infrastructure** | ₹2,40,876 |
| **Development & Setup** | ₹25,000 |
| **Operational** | ₹3,20,000 |
| **Contingency** | ₹24,088 |
| **Total Expenses** | **₹6,09,964** |
| **Maximum Expenses** | **₹7,50,000** |

### Profit

| Item | Amount |
|------|--------|
| **Gross Profit** | **₹40,036** |
| **Minimum Profit (Worst Case)** | **₹-1,00,000** |
| **Profit Margin** | **-15.4% - 6.2%** |
| **Profit per Institute** | **₹-33.33 - ₹13.35** |

---

## 🎯 Key Insights

1. **Good Profit Margin:** 35-51% profit margin
2. **Low Infrastructure Cost:** Only ₹1.2 lakh for 2 lakh students
3. **Web App Hosting:** Very cheap at ₹249/month (₹1,494 for 6 months)
4. **Mobile App:** No additional infrastructure cost (uses same backend)
5. **Room for Optimization:** Can save ₹35,100 with photo compression

---

## 💡 Recommendations

1. **Implement Photo Compression:** Save ₹35,100 (increase profit to ₹3.67 lakh)
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
| **Mobile App** | ₹0 | ₹0 | Uses same infrastructure |
| **Total** | ₹20,073 | **₹1,20,438** | - |

---

## 📱 Platform Cost Breakdown

### Web Application Costs

| Item | Cost (6 months) |
|------|-----------------|
| **Hosting (VPS)** | ₹1,494 |
| **Development** | ₹0 (already developed) |
| **Maintenance** | Included in operational |
| **Total Web App** | **₹1,494** |

### Mobile Application Costs

| Item | Cost (6 months) |
|------|-----------------|
| **App Store Fees** | ₹0 (one-time, included) |
| **API Hosting** | ₹0 (uses web app infrastructure) |
| **Push Notifications** | ₹0 (included in Appwrite) |
| **Development** | ₹0 (already developed) |
| **Maintenance** | Included in operational |
| **Total Mobile App** | **₹0** |

**Note:** Mobile apps use the same backend infrastructure, so no additional hosting costs.

---

**Bottom Line:**  
**Revenue:** ₹6,50,000 **Per Year**  
**Expenses:** ₹6,09,964 (Base) to ₹7,50,000 (Maximum)  
**Profit:** ₹-1,00,000 to ₹40,036  
**Profit Margin:** -15.4% to 6.2%  

**Note:** This is a low-margin business model. Consider increasing pricing or optimizing costs for better profitability.
