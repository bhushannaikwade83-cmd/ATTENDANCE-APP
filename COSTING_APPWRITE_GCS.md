# Cost Comparison: Appwrite + GCS vs Firebase

**Deployment:** 3,000 institutes, 12 lectures/day per student, 2 batches per institute, 40 students per batch

**Important:**
- Photos are **deleted after each 6-month batch ends** — storage does not accumulate indefinitely.
- **Email authentication only at first login**, then **PIN login** is used — reduces Auth costs significantly.

**Usage:**
- Firestore/Database writes: ~2,880,000/day
- Storage: ~75 TB (photos, rolling 6-month window — deleted after batch ends)
- Reads: High volume (reports, attendance lists)
- Auth: Email auth only at initial setup (~9,000 users), then PIN login → minimal Auth costs

---

## Option 1: Firebase (Current)

### Costs (per 6 months)

| Item | Cost (per 6 months) |
|------|---------------------|
| Firebase Firestore (writes) | ₹7,80,000 – ₹9,00,000 |
| Firebase Storage (75 TB) | ₹9,90,000 – ₹10,80,000 |
| Firebase Firestore (reads) | ₹1,20,000 – ₹2,40,000 |
| **Total Firebase** | **₹18,90,000 – ₹22,20,000** |

---

## Option 2: Appwrite Cloud + GCS

### Appwrite Cloud Pricing (2025)

**Pro Plan:** $25/month (~₹2,000/month)
- 2TB bandwidth/month
- 150GB storage included
- 3.5M executions/month
- 200K monthly active users (email auth) — PIN login doesn't count
- Unlimited databases, buckets, functions

**Note:** With PIN login after initial email auth, Auth MAU is minimal (~9,000 one-time during onboarding, then PIN login) — well within 200K MAU limit.

**Additional costs:**
- Bandwidth over 2TB: $15 per 100GB (~₹1,250 per 100GB)
- Storage over 150GB: $2.8 per 100GB (~₹233 per 100GB per month)

### Google Cloud Storage (GCS) Pricing

**Storage Options (for 75 TB, per 6 months):**

| Storage Class | Price per GB/month | Cost (per 6 months) | Minimum Duration | Suitable? |
|---------------|-------------------|---------------------|-------------------|-----------|
| **Standard** | $0.020 (~₹1.67) | ₹7,51,500 | None | ✅ Yes |
| **Nearline** | $0.010 (~₹0.83) | ₹3,73,500 | 30 days | ✅ Yes (62% cheaper) |
| **Coldline** ⭐ | $0.004 (~₹0.33) | **₹1,48,500** | 90 days | ✅ **Best** (85% cheaper) |
| **Archive** | $0.0012 (~₹0.10) | ₹45,000 | 365 days | ❌ No (photos deleted at 180 days) |

**Recommended: GCS Coldline Storage** — 85% cheaper than Firebase Storage, 90-day minimum matches your 6-month batch (180 days > 90 days).

**Note:** Storage stays at ~75 TB (rolling 6-month window) since photos are deleted after each batch ends — costs remain constant, not growing.

**Operations:**
- Class A (writes): $0.05 per 10,000 operations
- Class B (reads): $0.004 per 10,000 operations

### Appwrite + GCS Costs (per 6 months)

| Item | Cost (per 6 months) |
|------|---------------------|
| **Appwrite Pro Plan** | ₹12,000 (₹2,000/month × 6) |
| **GCS Coldline Storage (75 TB)** ⭐ | **₹1,48,500** (85% cheaper than Firebase) |
| **GCS Operations** (writes/reads) | ₹50,000 – ₹1,00,000 |
| **Additional Appwrite storage** (if needed) | ₹0 (using GCS instead) |
| **Additional Appwrite bandwidth** (if >2TB/month) | ₹0 – ₹50,000 |
| **Total Appwrite + GCS Coldline** | **₹2,10,500 – ₹2,60,500** |

**Alternative with GCS Standard:** ₹8,13,500 – ₹9,13,500 (if Coldline doesn't fit access pattern)

---

## Option 3: Self-Hosted Appwrite + GCS

### Self-Hosted Appwrite Infrastructure

**Server requirements (estimated):**
- Database server (PostgreSQL/MariaDB): 8GB RAM, 4 vCPU
- Appwrite server: 4GB RAM, 2 vCPU
- Load balancer (optional)

**Cloud provider options:**

**Option A: Google Cloud Platform (GCP)**
- Compute Engine (e2-standard-4): ~$100/month (~₹8,300/month)
- Database (Cloud SQL): ~$150/month (~₹12,500/month)
- **Total infrastructure:** ~₹20,800/month = **₹1,24,800 per 6 months**

**Option B: AWS EC2**
- EC2 instance (t3.xlarge): ~$120/month (~₹10,000/month)
- RDS (PostgreSQL): ~$140/month (~₹11,700/month)
- **Total infrastructure:** ~₹21,700/month = **₹1,30,200 per 6 months**

**Option C: DigitalOcean / Vultr**
- Droplet (8GB RAM, 4 vCPU): ~$48/month (~₹4,000/month)
- Managed Database: ~$60/month (~₹5,000/month)
- **Total infrastructure:** ~₹9,000/month = **₹54,000 per 6 months**

### Self-Hosted Appwrite + GCS Costs (per 6 months)

| Item | Cost (per 6 months) |
|------|---------------------|
| **Infrastructure (GCP)** | ₹1,24,800 |
| **GCS Storage (75 TB)** | ₹7,51,500 |
| **GCS Operations** | ₹50,000 – ₹1,00,000 |
| **Maintenance/DevOps time** | ₹0 (your time) or ₹50,000 – ₹1,00,000 (if outsourced) |
| **Total Self-Hosted + GCS** | **₹9,26,300 – ₹10,26,300** (GCP) |
| **Total Self-Hosted + GCS** | **₹8,55,500 – ₹9,55,500** (DigitalOcean) |

---

## Cost Comparison Summary

| Option | Cost (per 6 months) | Savings vs Firebase |
|--------|---------------------|---------------------|
| **Firebase** | ₹18,76,500 – ₹21,16,500 | Baseline |
| **Appwrite Cloud + GCS Coldline** ⭐ | **₹2,10,500 – ₹2,60,500** | **Save ₹16,66,000 – ₹18,56,000** (88–89%) |
| **Appwrite Cloud + GCS Standard** | ₹8,13,500 – ₹9,13,500 | **Save ₹10,63,000 – ₹12,03,000** (57–60%) |
| **Self-Hosted Appwrite + GCS Coldline** | ₹2,52,500 – ₹3,02,500 | **Save ₹16,24,000 – ₹18,14,000** (87–88%) |

---

## Profit Analysis with Appwrite + GCS

### At ₹6 Lakh Revenue (Current Quotation)

| Option | Revenue | Backend Cost | **Profit/Loss** |
|--------|---------|--------------|-----------------|
| **Firebase** | ₹6,00,000 | ₹18,90,000 – ₹22,20,000 | **Loss: ₹12.9–16.2 lakh** |
| **Appwrite Cloud + GCS** | ₹6,00,000 | ₹8,13,500 – ₹9,13,500 | **Loss: ₹2.1–3.1 lakh** |
| **Self-Hosted + GCS** | ₹6,00,000 | ₹8,55,500 – ₹10,26,300 | **Loss: ₹2.6–4.3 lakh** |

**Still a loss, but much smaller!**

### To Break Even with Appwrite + GCS

| Option | Break-Even Revenue | Per Institute |
|--------|-------------------|---------------|
| **Appwrite Cloud + GCS** | ₹8.5–9.5 lakh | ₹2,833 – ₹3,167 |
| **Self-Hosted + GCS** | ₹9–10.5 lakh | ₹3,000 – ₹3,500 |

### To Make Profit with Appwrite + GCS

| Option | Recommended Revenue | Per Institute | Profit |
|--------|-------------------|---------------|--------|
| **Appwrite Cloud + GCS** | ₹15–20 lakh | ₹5,000 – ₹6,667 | ₹5.5–11.5 lakh |
| **Self-Hosted + GCS** | ₹15–20 lakh | ₹5,000 – ₹6,667 | ₹4.5–11 lakh |

---

## Recommendations

### Best Option: Appwrite Cloud + GCS Coldline ⭐

**Why:**
1. **88–89% cost savings** vs Firebase (₹2.1–2.6 lakh vs ₹18.8–21.2 lakh)
2. **No infrastructure management** (Appwrite handles it)
3. **Similar features** to Firebase (Auth, Database, Storage, Functions)
4. **Easier migration** than self-hosting
5. **Scalable** Pro plan handles your usage
6. **GCS Coldline** — 85% cheaper storage than Firebase

**Cost:** ₹2.1–2.6 lakh per 6 months (vs ₹18.8–21.2 lakh with Firebase)

**With ₹6 lakh revenue:** **Profit of ₹3.4–3.9 lakh!** ✅

### Alternative: Self-Hosted Appwrite + GCS (DigitalOcean)

**Why:**
1. **49–57% cost savings** vs Firebase
2. **More control** over infrastructure
3. **Lower cost** than GCP/AWS
4. **Requires DevOps** expertise

**Cost:** ₹8.6–9.6 lakh per 6 months

---

## Migration Considerations

### From Firebase to Appwrite + GCS

**Effort:** Medium
- Appwrite has similar APIs to Firebase
- Need to migrate:
  - Auth (users, sessions)
  - Database (Firestore → Appwrite Database)
  - Storage (Firebase Storage → GCS)
- Estimated migration time: 2–4 weeks

**Benefits:**
- **Save ₹9.8–13.1 lakh per 6 months**
- More control over data
- Open-source (self-hosted option available)

---

## Final Recommendation

**Switch to Appwrite Cloud + GCS Coldline:**
- **Saves ₹16.7–18.6 lakh per 6 months** (88–89% reduction)
- **Break-even at ₹2.1–2.6 lakh** revenue (vs ₹18.8–21.2 lakh with Firebase)
- **With ₹6 lakh revenue:** **Profit of ₹3.4–3.9 lakh!** ✅ (vs loss of ₹12.8–15.2 lakh with Firebase)
- **To make profit:** Need ₹2.5–3 lakh revenue (₹833–₹1,000 per institute) — **much more achievable!**

**This makes your ₹6 lakh quotation much more viable!**

---

*Note: All costs are estimates based on 3,000 institutes, 12 lectures/day per student, 2 batches per institute, 40 students per batch, 75 TB storage. Actual costs may vary based on usage patterns.*
