# Smart Attendance App — 6-Month Batch Costing

This document estimates the **cost to run your Smart Attendance App** for one **6-month batch** (e.g. one class/cohort running for 6 months), using Firebase (Auth, Firestore, Storage) and your current architecture.

**Deployment scale:** The app will be deployed for **3,000 institutes** across Maharashtra, with **12 lectures per day per student** (daily attendance for each lecture).

---

## 1. What “6-month batch” means here

- **One batch** = one class/cohort (e.g. “Morning Batch 2025”) with a fixed set of students.
- **6 months** = ~26 weeks ≈ **130 working days** (5 days/week).
- **Usage**: Daily attendance (with optional photo) per student per lecture — **12 lectures per day per student**, stored in Firestore + Cloud Storage.

---

## 2. Assumptions for costing

| Item | Value |
|------|--------|
| Institutes | 1 (or 3,000 for full deployment) |
| Batches | 1 (6-month batch) per institute |
| Students per batch | 40 |
| Working days in 6 months | 130 |
| **Lectures per student per day** | **12** |
| Attendance marks per day | 40 students × 12 lectures = **480/day** |
| Photo per mark | Yes (JPEG, ~200 KB each) |
| Admins/teachers (monthly active) | 3 per institute |
| **Authentication** | **Email auth only at first login, then PIN login** (reduces Auth costs) |
| Face recognition | On-device (ML Kit) — **no cloud cost** |

---

## 3. Usage over 6 months (one batch)

| Resource | How it’s used | 6-month total |
|----------|----------------|----------------|
| **Firestore writes** | 1 write per attendance mark + setup (batches, students, etc.) | ~480/day × 130 days ≈ **62,400** (+ minor setup) |
| **Firestore reads** | Loading batches, students, attendance lists, reports | ~5,000–10,000/day → **~650K–1.3M** over 6 months |
| **Firestore storage** | Institutes, batches, students, attendance metadata | Well under **1 GB** per batch |
| **Cloud Storage uploads** | 1 photo per attendance mark | **62,400** uploads per batch |
| **Cloud Storage stored** | Photos: 480/day × 0.2 MB × 130 days | **~12.5 GB** at end of 6 months per batch |
| **Auth (MAU)** | Email auth only at first login, then PIN login | **~9,000 one-time** (3,000 institutes × 3 admins) + **minimal ongoing** (PIN login doesn't count as email auth MAU) |

---

## 4. Firebase free tier (Spark / Blaze)

Your app uses:

- **Firebase Auth** (email/password)
- **Cloud Firestore**
- **Cloud Storage** (`*.firebasestorage.app` bucket)
- **FCM** (no cost)
- **ML Kit** on-device (no Firebase/cloud cost)

Relevant **free limits** (Blaze plan; Spark is similar for Firestore/Auth, but Storage free tier for `firebasestorage.app` applies on Blaze):

| Product | Free tier (Blaze) |
|---------|--------------------|
| **Auth** | 50,000 MAU (email/password) — PIN login doesn't count as MAU |
| **Firestore** | 20,000 writes/day, 50,000 reads/day, 1 GiB stored, 10 GiB/month egress |
| **Cloud Storage** (`firebasestorage.app`) | 5 GB-months stored, 100 GB/month download, 5,000 upload ops/month, 50,000 download ops/month |

*(Exact quotas: [Firebase Pricing](https://firebase.google.com/pricing).)*

---

## 5. Cost for one 6-month batch

### 5.1 Firestore

- **Writes**: 62,400 total over 6 months → **~480 writes/day** on average → under 20,000/day → **$0** (for one batch).
- **Reads**: 650K–1.3M over 6 months → **~5,000–10,000 reads/day** → under 50,000/day → **$0** (for one batch).
- **Storage**: &lt; 1 GiB → **$0**.

### 5.2 Cloud Storage

- **Stored**: ~12.5 GB at end of 6 months → **over 5 GB** → **~₹2,000–₹3,000 per 6 months** (for one batch, exceeds free tier).
- **Upload operations**: 62,400 over 6 months → **~10,400/month** → **over 5,000/month** → **~₹500–₹1,000 per 6 months** (exceeds free tier).
- **Download**: Viewing reports/photos; assumed moderate → typically within 100 GB/month → **$0**.

### 5.3 Auth

- **Email auth**: Only at first login (initial setup), then PIN login is used
- **MAU**: For one batch, ~3 admins/teachers use email auth once → **~3 one-time** + **minimal ongoing** (PIN login doesn't count as email auth MAU)
- **Cost**: **$0** (well within 50,000 MAU free tier)

### 5.4 Total for one 6-month batch

| Scenario | Firestore | Storage | Auth | **Total (6 months)** |
|----------|-----------|---------|------|----------------------|
| **Single 6-month batch (40 students, 12 lectures/day, with photos)** | $0 | ~₹2,500–₹4,000 | $0 | **~₹2,500–₹4,000** |

So for **one 6-month batch** (40 students, 12 lectures/day), you exceed Storage free tier; **cost ≈ ₹2,500–₹4,000** for the 6 months (mainly Storage).

---

## 6. When you might start paying (multiple batches / institutes)

If you add more batches or institutes, usage scales roughly like this:

| Scale | Firestore writes/day | Storage (end of 6 months) | Storage uploads/month | Likely cost (6 months) |
|------|----------------------|----------------------------|------------------------|-------------------------|
| 1 batch, 40 students | ~60 | ~2 GB | ~1,700 | **$0** |
| 3 batches, 40 each | ~180 | ~6 GB | ~5,100 | **$0** (storage might go slightly over 5 GB; small charge) |
| 5 batches, 50 each | ~420 | ~13 GB | ~8,500 | **~\$1–5** (Storage + possible Firestore if reads grow) |
| 10 institutes, 3 batches each, 40 students | ~1,800 | ~60 GB | ~17K | **~\$15–40** (Storage + Firestore) |

Rough Blaze overage (for reference):

- **Firestore**: above free tier → ~\$0.18/100K writes, ~\$0.06/100K reads.
- **Storage**: above 5 GB → ~\$0.026/GB/month (region-dependent); upload/download ops and egress have separate pricing.

---

## 7. What I can charge them — pricing

**Short answer:** charge **₹10,000 per 6-month batch** + **₹3,000 per year for Main Admin web app**. Use the table below when talking to institutes.

### Amount to charge (per institute)

| What you're offering | Charge this (INR) | When to use |
|----------------------|-------------------|-------------|
| **1 batch, 6 months** (up to 50 students, attendance + photos + reports + face recognition) | **₹10,000** | Standard — most institutes. |
| **Main Admin web app** (for their main admin — batches, students, reports on web) | **₹3,000 per year** | **You charge for this.** Per institute, per year. |
| **1 batch, 6 months** (small institute, up to 30 students) | **₹6,000 – ₹8,000** | Budget — small academies, tuition classes. |
| **2–3 batches, 6 months** | **₹18,000 – ₹22,000** | Multi-batch — larger institutes. |
| **Per student (6 months)** | **₹150 – ₹300 per student** | Alternative — e.g. 40 students × ₹200 = ₹8,000. |

**One line you can say:**  
*“₹10,000 per 6-month batch + ₹3,000 per year for Main Admin web app — your main admin manages batches, students, and reports from the web (attendance, photos, reports, face recognition).”*

*(**Main Admin web app** = for **their main admin** to manage their institute on the web — you **charge** for it: **₹2,000 – ₹5,000 per year** per institute; recommended **₹3,000/year**. **Super Admin web app** = for you to manage all institutes; you don’t charge institutes for it.)*

---

### Suggested pricing (6-month batch) — full table

| Option | Amount (INR) | Amount (USD) | What it includes |
|--------|--------------|--------------|-------------------|
| **Per 6-month batch (flat)** | **₹8,000 – ₹15,000** | **$95 – $180** | One batch, up to 50 students, 6 months, all features (attendance, photos, reports, face recognition, offline). |
| **Per student (6 months)** | **₹150 – ₹300 per student** | **$2 – $4 per student** | Same as above; institute pays per enrolled student. (e.g. 40 students × ₹200 = ₹8,000) |
| **Budget (small institutes)** | **₹5,000 – ₹8,000** | **$60 – $95** | One batch, up to 30 students, 6 months. |
| **Premium (multiple batches)** | **₹12,000 – ₹25,000** | **$145 – $300** | Up to 3 batches, 6 months, priority support. |

### One amount you can give them (simple quote)

- **Single 6-month batch:**  
  **₹10,000** (or **$120**) — one batch, up to 50 students, 6 months, all features.

- **Multiple batches (e.g. 3 batches, 6 months):**  
  **₹18,000** (or **$215**).

Use the range (₹8,000–₹15,000) to adjust by institute size, location, or negotiation.

---

## 8. 3,000 institutes, same Firebase — how much you GET (per 6-month batch each)

**Per batch, 6 months each, per institute — all 3,000 institutes on the SAME Firebase.**

### What you will GET (revenue)

| You charge per institute (6-month batch) | 3,000 institutes × that price | You GET per 6 months (INR) |
|------------------------------------------|-------------------------------|-----------------------------|
| ₹8,000                                   | 3,000 × ₹8,000                | **₹2,40,00,000** (₹2.4 cr)  |
| **₹10,000**                               | 3,000 × ₹10,000               | **₹3,00,00,000** (₹3 cr)   |
| ₹12,000                                   | 3,000 × ₹12,000               | **₹3,60,00,000** (₹3.6 cr) |

So at **₹10,000 per institute per 6-month batch**, with **3,000 institutes on the same Firebase**, you will get:

- **₹3,00,00,000 (₹3 crore)** per 6 months  
- **₹50,00,000 (₹50 lakh)** per month (revenue).

### What you will PAY (same Firebase, 3,000 institutes, 12 lectures/day per student)

**Assumptions:** 3,000 institutes, avg 2 batches per institute, 40 students per batch, 12 lectures/day per student.

**Important:**
- Photos are **deleted after each 6-month batch ends** — storage does not accumulate indefinitely.
- **Email authentication only at first login**, then **PIN login** is used — reduces Auth costs significantly.

**Usage:**
- **Firestore writes/day:** 3,000 institutes × 2 batches × 480 writes/day = **2,880,000 writes/day** (exceeds 20K free tier)
- **Storage:** 3,000 institutes × 2 batches × 12.5 GB = **~75 TB** (rolling 6-month window — photos deleted after batch ends, storage stays constant)
- **Auth (email):** ~9,000 users (3,000 institutes × 3 admins) use email auth **once** at initial setup, then PIN login → **minimal Auth costs** (well within 50K MAU free tier)

| Item              | Per month (approx) | Per 6 months (approx) |
|-------------------|--------------------|------------------------|
| Firebase Firestore (writes) | ₹1,30,000 – ₹1,50,000 | ₹7,80,000 – ₹9,00,000 |
| Firebase Storage (75 TB) | ₹1,65,000 – ₹1,80,000 | ₹9,90,000 – ₹10,80,000 |
| Firebase Firestore (reads) | ₹20,000 – ₹40,000 | ₹1,20,000 – ₹2,40,000 |
| **Total Firebase (Blaze)** | **₹3,15,000 – ₹3,70,000** | **₹18,90,000 – ₹22,20,000** |

### What you KEEP (net)

| You charge | You GET (6 months) | You PAY Firebase (6 months) | You KEEP net (6 months) |
|------------|--------------------|-----------------------------|---------------------------|
| ₹10,000/institute | **₹3,00,00,000**   | ₹18,90,000 – ₹22,20,000     | **₹2,77,80,000 – ₹2,81,10,000** |

So with **3,000 institutes, same Firebase, per batch 6 month each at ₹10,000, 12 lectures/day per student**: you **get ₹3 crore** per 6 months; after Firebase (₹18.9–22.2 lakh) you **keep about ₹2.78–2.81 crore** per 6 months.

**Note:** With 12 lectures/day per student, Storage costs are significant (~75 TB total). However, since photos are **deleted after each 6-month batch ends**, storage stays constant at ~75 TB (rolling window) rather than accumulating indefinitely. This keeps storage costs predictable. Consider optimizing photo storage (compression, lower resolution) to further reduce costs.

---

## 9. Market: 3,000+ institutes all over Maharashtra (MH)

Your **target market** is **3,000+ institutes across Maharashtra**. Use this for planning revenue and infrastructure.

### 9.1 Revenue potential (MH, 6-month batch pricing)

Assume **₹10,000 per institute per 6-month batch** (one batch, up to 50 students). Revenue depends on how many institutes you onboard.

| Adoption | Institutes onboarded | Revenue per 6 months (INR) | Revenue per 6 months (USD) |
|----------|----------------------|-----------------------------|-----------------------------|
| 1% of MH | 30 institutes | **₹3,00,000** | ~$3,600 |
| 5% of MH | 150 institutes | **₹15,00,000** | ~$18,000 |
| 10% of MH | 300 institutes | **₹30,00,000** | ~$36,000 |
| 25% of MH | 750 institutes | **₹75,00,000** | ~$90,000 |
| 50% of MH | 1,500 institutes | **₹1,50,00,000** | ~$180,000 |
| 100% (all MH) | 3,000 institutes | **₹3,00,00,000** | ~$360,000 |

*If you charge **₹8,000** (budget): multiply above by 0.8. If you charge **₹12,000**: multiply by 1.2.*

### 9.2 Your infrastructure cost at scale (Firebase)

As institutes grow, Firestore writes and Storage go up. Rough estimates (per month, Blaze plan):

**Updated for 12 lectures/day per student:**

| Scale | Institutes | Avg batches/institute | Students/batch | Lectures/day/student | Firestore (writes/day) | Storage (approx) | Est. monthly cost (INR) | Est. monthly cost (USD) |
|-------|------------|------------------------|----------------|---------------------|-------------------------|------------------|--------------------------|--------------------------|
| Small | 30 | 2 | 40 | 12 | ~28,800 | ~750 GB | ₹15,000 – ₹25,000 | $180 – $300 |
| Medium | 150 | 2 | 40 | 12 | ~144,000 | ~3.75 TB | ₹75,000 – ₹1,00,000 | $900 – $1,200 |
| Large | 300 | 2 | 40 | 12 | ~288,000 | ~7.5 TB | ₹1,50,000 – ₹2,00,000 | $1,800 – $2,400 |
| Very large | 750 | 2 | 40 | 12 | ~720,000 | ~18.75 TB | ₹3,75,000 – ₹5,00,000 | $4,500 – $6,000 |
| **3,000 institutes** | **3,000** | **2** | **40** | **12** | **~2,880,000** | **~75 TB** | **₹3,15,000 – ₹3,70,000** | **$3,780 – $4,440** |

So at **3,000 institutes with 12 lectures/day per student**, your **revenue** (₹3 crore per 6 months) is still much higher than your **infrastructure cost** (roughly ₹3.15–3.7L per month = ₹18.9–22.2L per 6 months). You **keep about ₹2.78–2.81 crore** per 6 months after Firebase costs.

**Important:** Storage is the main cost driver (~75 TB). Consider photo optimization (compression, lower resolution, or optional photos) to reduce Storage costs.

### 9.3 Pricing for MH institutes (amount to give them)

Keep it simple across MH — one clear amount:

| Plan | Amount (INR) | Who it’s for (all over MH) |
|------|--------------|-----------------------------|
| **Standard (1 batch, 6 months)** | **₹10,000** | Most institutes — single batch, up to 50 students. |
| **Budget (small institute)** | **₹6,000 – ₹8,000** | Small academies, tuition classes, 1 batch, up to 30 students. |
| **Multi-batch (2–3 batches, 6 months)** | **₹18,000 – ₹22,000** | Larger institutes, multiple batches. |

**One line you can use:**  
*“₹10,000 per 6-month batch for institutes across Maharashtra — one batch, up to 50 students, all features (attendance, photos, reports, face recognition).”*

### 9.4 When you grow (100+ institutes)

1. **Firebase Blaze** — Set a monthly budget (e.g. ₹5,000–₹10,000) and alerts so you don’t get surprises.
2. **Billing alerts** — Firebase Console → Billing → Budgets.
3. **Optional:** Pass a small **platform fee** per institute in later years to cover rising cloud cost as you add more institutes across MH.

---

## 10. Web apps: Super Admin (you) + Main Admin web app (for their institute)

There are **two** web apps:

| Web app | Who uses it | Purpose |
|---------|-------------|---------|
| **Super Admin web app** | **You** (platform owner) | Handle **all** 3,000+ institutes — create institutes, view all, analytics. |
| **Main Admin web app** | **Each institute’s main admin** | Manage **their own** institute — batches, students, attendance, reports — on the web. |

---

### 10.1 Main Admin web app — for their main admin (per institute)

The **web app is for their main admin**: each institute’s main admin gets a **per-year web app** to run their institute (batches, students, reports, settings) on desktop/laptop.

**What their main admin can do on the web app:**

| Function | Description |
|----------|-------------|
| **Batches** | Create / edit batches, subjects, timing. |
| **Students** | Add / edit / remove students, assign to batches. |
| **Attendance & reports** | View attendance, reports, summaries. |
| **Institute settings** | GPS/attendance settings, users (optional). |

**You charge for the Main Admin web app (per institute, per year):**

| Charge | Amount (INR) | Note |
|--------|--------------|------|
| **Recommended** | **₹3,000 per year** | Main Admin web app access for their main admin. |
| **Budget** | **₹2,000 – ₹2,500 per year** | Small institutes. |
| **Premium** | **₹4,000 – ₹5,000 per year** | Larger institutes or multi-batch. |
**Total per institute (example):** 6-month batch ₹10,000 + Main Admin web app ₹3,000/year = **₹13,000 first year**.

**One line you can say:**  
*“₹10,000 per 6-month batch + ₹3,000 per year for the Main Admin web app — your main admin to manage batches, students, and reports from the web.”*

---

### 10.2 Super Admin web app — for you (platform owner)

| Function | Description |
|---------|-------------|
| **Institute management** | Create / edit / deactivate institutes (institute code, name, contact). |
| **View all institutes** | List and search all institutes across MH (filters, status). |
| **Overview & analytics** | Total institutes, batches, students; revenue summary; usage by region. |
| **Support & operations** | See which institutes are active; basic audit (who created what, when). |
| **Same Firebase** | Uses the same Firestore/Storage/Auth project; no separate backend. |

*Note: In your app, institutes are today created by “super admin” only (e.g. via Firestore). The Super Admin **web app** is the yearly web interface to do this at scale for all 3,000+ institutes.*

### 10.3 Per-year = how you use it (Super Admin)

- **Per year** = the Super Admin web app is licensed / used **per year** (yearly access for you/your team to manage all institutes).
- It can be:
  - **Your internal tool** — no extra charge to you; cost is only hosting (see below).
  - **Or** part of a **yearly platform fee** if you ever charge institutes per year (e.g. “platform + support” per year).

### 10.4 Cost to run the Super Admin web app (per year, same Firebase)

| Item | Per year (INR) | Per year (USD) |
|------|----------------|----------------|
| **Hosting (e.g. Firebase Hosting)** | ₹0 – ₹2,000 | $0 – $24 |
| **Backend** | **Same Firebase** (Firestore, Auth) — already counted for institutes | — |
| **Domain (optional)** | ₹500 – ₹1,500 | $6 – $18 |
| **Total (only web app)** | **₹0 – ₹3,500** | **$0 – $42** |

So the **Super Admin web app** adds almost **no extra cost per year** if you host it on the same Firebase project (e.g. Flutter web on Firebase Hosting). The heavy cost is already in Section 8/9 (Firebase for 3,000 institutes).

### 10.5 Summary: mobile app + Main Admin web app + Super Admin (same Firebase)

| What | Who uses it | Billing |
|------|-------------|---------|
| **Institute mobile app** | Each institute (admins/teachers) | You charge **per 6-month batch** (e.g. ₹10,000 per batch). |
| **Main Admin web app** | **Each institute’s main admin** | **You charge: ₹3,000 per year** (range ₹2,000–₹5,000/year). |
| **Super Admin web app** | **You** / your team | Your internal tool; cost = hosting only (~₹0–₹3,500/year). |

So: **Main Admin web app** = you **charge** each institute **â‚¹3,000/year** for their main admin. **Super Admin web app** = for you to manage all 3,000 institutes; same Firebase.

---

## 11. Summary (your cost)

- **One 6-month batch** (e.g. 40 students, 12 lectures/day, daily attendance with photo): **~₹2,500–₹4,000** for 6 months (exceeds Storage free tier).
- **Multiple 6-month batches** (e.g. 3–5 batches): **~₹7,500–₹20,000** total for 6 months (Storage costs scale with batches).
- **3,000 institutes** (2 batches each, 12 lectures/day per student): **~₹18.9–22.2 lakh per 6 months** (Firestore writes + Storage ~75 TB).
- **Many institutes/batches**: consider the “When you might start paying” table and enable **Blaze** with a budget alert (e.g. \$10–20/month) so you don’t get surprises.

### Recommendations

1. Use **Firebase Blaze** (pay-as-you-go) so that the free tier applies to your `firebasestorage.app` bucket; set a **monthly budget** (e.g. \$5–10) and alerts.
2. Optional: **Claim \$300 Google Cloud credits** (if eligible) for when you scale.
3. Monitor in **Firebase Console** → Usage and billing, especially **Firestore** and **Storage**, as you add batches or institutes.

---

*Based on Smart Attendance App (Flutter + Firebase Auth, Firestore, Storage). Pricing reference: [Firebase Pricing](https://firebase.google.com/pricing) (Feb 2025).*
