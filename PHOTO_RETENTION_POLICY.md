# Photo Retention Policy - 6 Month Automatic Deletion

## 📸 Photo Storage & Deletion Policy

### Retention Period

**Photos are stored for exactly 6 months (180 days) and then automatically deleted.**

---

## 🔄 How It Works

### Batch-Based Deletion

**Your Setup:**
- **2 Batches per Year**
- **Each Batch:** 6 months duration
- **Total:** 12 months (1 year)

### Photo Lifecycle

#### Batch 1 (Months 1-6)

| Timeline | Action |
|----------|--------|
| **Month 1-6** | Photos stored in Scaleway Archive |
| **End of Month 6** | **Automatic deletion** - All Batch 1 photos deleted |
| **After Deletion** | Storage space freed up for Batch 2 |

#### Batch 2 (Months 7-12)

| Timeline | Action |
|----------|--------|
| **Month 7-12** | Photos stored in Scaleway Archive |
| **End of Month 12** | **Automatic deletion** - All Batch 2 photos deleted |
| **After Deletion** | Storage space freed up for next year's Batch 1 |

---

## ⚙️ Technical Implementation

### Scaleway Lifecycle Policy

**Configuration:**
- **Storage Class:** Archive
- **Retention Period:** 180 days (6 months)
- **Deletion:** Automatic via lifecycle policy
- **No Manual Action Required**

### How Photos Are Organized

**Folder Structure:**
```
institute_id/
  batch_year/
    rollNumber/
      subject/
        YYYY-MM-DD/
          photo.jpg
```

**Example:**
```
INST001/
  2024/
    STU001/
      mathematics/
        2024-02-03/
          photo.jpg  ← Deleted after 6 months
```

### Automatic Deletion Process

1. **Photos Uploaded** → Stored in Scaleway Archive
2. **180 Days Pass** → Scaleway lifecycle policy triggers
3. **Automatic Deletion** → Photos permanently deleted
4. **Storage Freed** → Space available for next batch

**No manual intervention needed!**

---

## 📊 Storage Calculation

### Per Batch Storage

**With Photo Compression (0.1 MB per photo):**

| Item | Value |
|------|-------|
| **Students per institute** | 66.67 |
| **Photos per student** | 780 photos (6 months) |
| **Storage per student** | 78 MB (780 × 0.1 MB) |
| **Storage per institute** | 5.2 GB (66.67 × 78 MB) |
| **Total storage (3,000 institutes)** | **15.6 TB per batch** |

**With overhead:** **~16.5 TB per batch**

### Rolling Storage (6-Month Window)

**Since photos are deleted after 6 months:**

| Time Period | Storage Used |
|-------------|--------------|
| **Month 1-6** | 16.5 TB (Batch 1 photos) |
| **End of Month 6** | **0 TB** (Batch 1 deleted) |
| **Month 7-12** | 16.5 TB (Batch 2 photos) |
| **End of Month 12** | **0 TB** (Batch 2 deleted) |

**Maximum Storage at Any Time:** 16.5 TB  
**Average Storage:** ~8.25 TB  
**Annual Storage Cost:** Based on 16.5 TB maximum

---

## 💰 Cost Impact

### Storage Costs (With 6-Month Deletion)

**Per Batch (6 months):**
- Storage: 16.5 TB
- Cost: ₹16.5TB × ₹0.18/GB/month × 6 months = **₹17,820 per batch**

**Per Year (2 batches):**
- Batch 1: ₹17,820 (6 months, then deleted)
- Batch 2: ₹17,820 (6 months, then deleted)
- **Total:** ₹35,640 per year

**Note:** Since photos are deleted after 6 months, storage doesn't accumulate. Each batch uses storage for 6 months only.

### Updated Annual Storage Cost

**Previous Calculation (Without Deletion):**
- 65 TB × ₹0.18/GB/month × 12 months = ₹1,40,400/year

**New Calculation (With 6-Month Deletion):**
- 16.5 TB × ₹0.18/GB/month × 6 months × 2 batches = ₹35,640/year

**Savings:** ₹1,04,760/year (74% reduction!)

---

## ✅ Benefits of 6-Month Deletion

1. ✅ **Lower Storage Costs** - Only store photos for 6 months
2. ✅ **Automatic Cleanup** - No manual deletion needed
3. ✅ **Consistent Storage** - Storage doesn't accumulate
4. ✅ **Cost-Effective** - Pay only for active batch storage
5. ✅ **Compliance** - Photos deleted as per policy

---

## ⚠️ Important Notes

### Photo Access

- **During 6 Months:** Photos accessible via app and reports
- **After 6 Months:** Photos permanently deleted
- **No Recovery:** Deleted photos cannot be recovered

### Reports

- **Attendance Reports:** Available even after photos deleted
- **Photo Links:** Broken after deletion (photos no longer exist)
- **Historical Data:** Attendance records remain, photos removed

### Backup

- **No Photo Backup:** Photos are not backed up (deleted after 6 months)
- **Database Backup:** Attendance records backed up (photos not included)
- **Export:** Export photos before deletion if needed

---

## 📋 User Communication

### What Users Should Know

**Before Batch Starts:**
- Photos will be stored for 6 months
- Photos will be automatically deleted after batch completion
- Export photos if needed before deletion

**During Batch:**
- Photos accessible via app
- Can download photos anytime
- Photos included in reports

**After Batch Completion:**
- Photos automatically deleted
- Cannot access deleted photos
- Attendance records remain (without photos)

---

## 🔧 Configuration

### Scaleway Lifecycle Policy

**Policy Configuration:**
```json
{
  "Rules": [
    {
      "Id": "DeleteAfter180Days",
      "Status": "Enabled",
      "Filter": {
        "Prefix": ""
      },
      "Expiration": {
        "Days": 180
      }
    }
  ]
}
```

**This ensures:**
- All photos deleted after 180 days (6 months)
- Automatic deletion (no manual action)
- Cost-effective storage

---

## 📊 Updated Cost Analysis

### With 6-Month Photo Deletion

| Item | Cost (Per Year) |
|------|-----------------|
| **Firebase Auth** | ₹0 |
| **Contabo PostgreSQL** | ₹9,600 |
| **Scaleway Archive (16.5TB max)** | ₹35,640 |
| **Web App Hosting** | ₹2,988 |
| **Total Infrastructure** | **₹48,228** |

**Previous (Without Deletion):** ₹82,788/year  
**New (With Deletion):** ₹48,228/year  
**Additional Savings:** ₹34,560/year (42% more savings!)

---

## ✅ Summary

**Photo Retention Policy:**
- ✅ **Storage Period:** 6 months (180 days)
- ✅ **Deletion:** Automatic after each batch
- ✅ **Frequency:** After every batch completion
- ✅ **No Manual Action:** Fully automated
- ✅ **Cost Savings:** ₹34,560/year additional savings

**Total Infrastructure Cost:** ₹48,228/year (vs ₹82,788 without deletion)  
**Total Savings:** ₹1,92,648/year (80% reduction from original!)

---

**Photos are automatically deleted after 6 months - no manual intervention needed!** ✅
