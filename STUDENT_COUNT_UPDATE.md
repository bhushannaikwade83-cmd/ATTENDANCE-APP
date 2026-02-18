# Student Count Update - 125-130 Students Per Institute

## 📊 Updated Assumptions

**Previous:** 40 students per batch × 2 batches = 80 students per institute  
**New:** **125-130 students per institute** (total)

---

## 📈 Impact Summary

### Storage Impact

| Metric | Previous (80 students) | New (130 students) | Change |
|--------|------------------------|---------------------|--------|
| **Storage per institute** | ~250 GB | ~406 GB | +63% |
| **Total storage (3,000 institutes)** | 75 TB | **122 TB** | +63% |
| **Storage cost (Scaleway)** | ₹81,000/6mo | **₹1,31,760/6mo** | +₹50,760 |

### Database Impact

| Metric | Previous | New | Change |
|--------|----------|-----|--------|
| **Writes per day** | 2.88M | **4.68M** | +63% |
| **Database cost** | ₹9,900/6mo | ₹9,900-15,000/6mo | May need upgrade |

---

## 💰 Updated Complete Costs

### Appwrite + Railway + Scaleway Archive

| Item | Cost (6 months) |
|------|-----------------|
| **Appwrite Pro** | ₹12,000 |
| **Railway PostgreSQL** | ₹9,900-15,000 |
| **Scaleway Archive (122TB)** | ₹1,31,760 |
| **Operations** | ₹32,000 |
| **Total** | **₹1,85,660 - ₹1,90,760** |

**vs Previous:** ₹1,22,900  
**Increase:** ₹62,760-67,860 per 6 months

---

## 💡 Cost Optimization Recommendations

### With 130 Students, Consider:

1. **Photo Compression** (Recommended)
   - Reduce from 0.2 MB to 0.1 MB
   - **Savings:** ₹65,880 per 6 months
   - **New total:** ₹1,19,780 per 6 months

2. **Selective Photo Storage**
   - Store photos for 6 key subjects (instead of all 12)
   - **Savings:** ₹65,880 per 6 months

3. **Lower Photo Quality**
   - Reduce to 0.15 MB per photo
   - **Savings:** ₹32,940 per 6 months

---

## ✅ Still Profitable!

**With ₹200 per institute revenue:**

| Item | Value |
|------|-------|
| **Revenue (3,000 institutes)** | ₹6,00,000 |
| **Backend cost** | ₹1,85,660-1,90,760 |
| **Your profit** | **₹4,09,240 - ₹4,14,340** ✅ |

**Per institute:**
- Revenue: ₹200
- Cost: ₹61.89-63.59
- **Profit: ₹136.41-138.11** ✅

---

## 📝 Updated Storage Structure

**Folder structure remains the same:**
```
institute_id/
  batch_year/
    rollNumber/  (125-130 students)
      subject/
        YYYY-MM-DD/
          photo.jpg
```

**All 125-130 students organized under their institute and batch year.**

---

## 🎯 Recommendations

1. ✅ **Use Scaleway Archive** - Still cheapest option
2. ✅ **Enable photo compression** - Reduce storage by 50%
3. ✅ **Monitor Railway PostgreSQL** - May need upgrade with 4.68M writes/day
4. ✅ **Set lifecycle policy** - Auto-delete after 180 days

---

## 🎉 Summary

**With 125-130 Students Per Institute:**
- Storage: 122TB (vs 75TB previously)
- Cost: ₹1,85,660 per 6 months (vs ₹1,22,900)
- **Still profitable:** ₹4+ lakh profit per 6 months
- **Recommendation:** Enable photo compression to reduce costs further

**Everything is updated and ready!** ✅
