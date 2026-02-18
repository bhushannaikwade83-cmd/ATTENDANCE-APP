# Authentication Policy — Email Auth + PIN Login

## Authentication Flow

1. **First Login (Initial Setup):**
   - User registers/logs in with **email + password** (email authentication)
   - This is a **one-time** authentication per user

2. **Subsequent Logins:**
   - User logs in with **PIN** (4–6 digits)
   - PIN login does **not** count as email authentication MAU
   - Faster and simpler for daily use

---

## Cost Impact

### Email Authentication Usage

**For 3,000 institutes:**
- **Admins/Teachers:** ~3 per institute = **9,000 users**
- **Email auth:** Used **once** per user (initial setup)
- **Ongoing:** Minimal (only if user needs to re-authenticate via email)

**Auth MAU (Monthly Active Users):**
- **Initial onboarding:** ~9,000 users (spread over onboarding period)
- **Ongoing:** Very minimal (PIN login doesn't count)
- **Total:** Well within free tiers

---

## Cost Savings

### Firebase Auth

**Free Tier:** 50,000 MAU (email/password authentication)

**With PIN login:**
- **Email auth MAU:** ~9,000 one-time + minimal ongoing
- **Cost:** **$0** (well within 50K MAU free tier)
- **PIN login:** Doesn't count as MAU → **no cost**

**Without PIN login (if all logins used email):**
- **Email auth MAU:** ~9,000 users × daily logins = much higher
- **Cost:** Could exceed free tier → **additional charges**

**Savings:** PIN login saves Auth costs by keeping email auth MAU low.

### Appwrite Auth

**Pro Plan:** 200K monthly active users (email auth)

**With PIN login:**
- **Email auth MAU:** ~9,000 one-time + minimal ongoing
- **Cost:** **Included in Pro Plan** ($25/month)
- **PIN login:** Doesn't count as MAU → **no additional cost**

**Without PIN login:**
- **Email auth MAU:** Much higher (daily logins)
- **Cost:** Could exceed 200K MAU → **additional charges**

**Savings:** PIN login keeps Auth costs predictable and within Pro Plan limits.

---

## Implementation

### PIN Login Flow

1. **User sets PIN** after initial email authentication
2. **PIN stored securely** (hashed, encrypted)
3. **PIN validation** happens on backend (Appwrite/Firebase)
4. **PIN can be reset** via email if forgotten

### Security Considerations

- **PIN length:** 4–6 digits (balance between security and usability)
- **PIN hashing:** Store hashed PINs, not plain text
- **Rate limiting:** Prevent brute force attacks
- **PIN reset:** Via email authentication (one-time use)

---

## Cost Summary

### With Email Auth + PIN Login

| Backend | Auth Cost | Notes |
|---------|-----------|-------|
| **Firebase** | **$0** | ~9,000 email auth MAU (one-time) + PIN login → well within 50K free tier |
| **Appwrite Cloud** | **Included** | ~9,000 email auth MAU (one-time) + PIN login → well within 200K Pro Plan limit |

### Auth Costs in Total Backend Costs

**Firebase:**
- Auth: **$0** (free tier)
- Total backend: ₹18,90,000 – ₹22,20,000 per 6 months (Firestore + Storage)

**Appwrite + GCS:**
- Auth: **Included** in Pro Plan (₹12,000 per 6 months)
- Total backend: ₹8,13,500 – ₹9,13,500 per 6 months (Appwrite + GCS Storage)

---

## Benefits of PIN Login

1. ✅ **Lower Auth costs** — Email auth MAU stays low
2. ✅ **Better UX** — Faster login (PIN vs typing email/password)
3. ✅ **Reduced friction** — Easier for daily use
4. ✅ **Cost predictability** — Auth costs remain constant

---

## Recommendation

✅ **Keep PIN login** — It significantly reduces Auth costs and improves user experience.

**Auth costs are minimal** with this approach:
- **Firebase:** $0 (within free tier)
- **Appwrite:** Included in Pro Plan

This makes your backend costs even more predictable and affordable.

---

*Note: PIN login is implemented on your backend (Appwrite/Firebase), not as a separate service. PIN validation counts as regular API calls, not Auth MAU.*
