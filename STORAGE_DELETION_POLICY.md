# Storage Deletion Policy — 6-Month Batch Photos

## Policy

**Photos from each 6-month batch are automatically deleted after the batch ends.**

This means:
- Storage does **not accumulate indefinitely**
- Storage stays at a **constant ~75 TB** (rolling 6-month window)
- Costs remain **predictable and stable**

---

## Storage Calculation

### Per Batch
- **40 students** × **12 lectures/day** × **130 working days** = **62,400 photos per batch**
- **62,400 photos** × **0.2 MB each** = **~12.5 GB per batch**

### For 3,000 Institutes
- **3,000 institutes** × **2 batches per institute** × **12.5 GB** = **~75 TB total**
- **Storage stays at ~75 TB** (photos from current 6-month period only)

---

## Cost Impact

### With Photo Deletion (Current Policy)

**Storage costs remain constant:**
- **GCS:** ₹1,25,250/month = **₹7,51,500 per 6 months** (stays constant)
- **Firebase Storage:** ₹1,65,000–₹1,80,000/month = **₹9,90,000–₹10,80,000 per 6 months** (stays constant)

**Benefits:**
- ✅ Predictable costs (no accumulation)
- ✅ Lower long-term costs (vs keeping photos forever)
- ✅ Better data privacy (old photos deleted)

### Without Photo Deletion (If Photos Were Kept Forever)

**Storage would accumulate:**
- Year 1: 75 TB
- Year 2: 150 TB (75 TB + 75 TB)
- Year 3: 225 TB (75 TB + 75 TB + 75 TB)
- **Costs would grow indefinitely**

**With deletion policy, costs stay at 75 TB forever.**

---

## Implementation

### Automatic Deletion Options

1. **Firebase Storage Lifecycle Rules**
   - Set TTL (Time To Live) on photos: 6 months
   - Automatic deletion after 6 months

2. **GCS Lifecycle Policies**
   - Set lifecycle rule: delete objects older than 180 days
   - Automatic deletion after 6 months

3. **Appwrite Storage**
   - Use scheduled functions to delete old photos
   - Or use GCS lifecycle policies if storing in GCS

### Manual Deletion (If Needed)

- Delete photos older than 6 months via script
- Run cleanup job monthly/quarterly

---

## Cost Savings

**By deleting photos after 6 months:**

| Year | Storage Without Deletion | Storage With Deletion | Savings |
|------|-------------------------|----------------------|---------|
| Year 1 | 75 TB | 75 TB | ₹0 |
| Year 2 | 150 TB | 75 TB | **₹7,51,500/year** |
| Year 3 | 225 TB | 75 TB | **₹15,03,000/year** |
| Year 5 | 375 TB | 75 TB | **₹30,06,000/year** |

**Over 5 years, you save ₹60+ lakh by deleting photos after 6 months!**

---

## Recommendation

✅ **Keep the deletion policy** — it keeps costs predictable and manageable.

**Storage costs:**
- **GCS:** ₹7,51,500 per 6 months (constant)
- **Firebase Storage:** ₹9,90,000–₹10,80,000 per 6 months (constant)

This makes your backend costs **predictable** and **scalable**.

---

*Note: This policy applies to attendance photos. Metadata (attendance records, reports) can be kept longer if needed for historical reports.*
