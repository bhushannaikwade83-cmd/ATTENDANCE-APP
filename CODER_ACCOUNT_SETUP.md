# Coder Account Setup - Quick Guide

## Credentials
- **Email**: `coder001@gmail.com`
- **Password**: `Bhushan@70`

## Quick Setup (Firebase Console)

### Step 1: Create Auth User
1. Go to Firebase Console → Authentication → Users
2. Click **Add user**
3. Email: `coder001@gmail.com`
4. Password: `Bhushan@70`
5. Click **Add user**
6. **Copy the User UID** (you'll need it in Step 2)

### Step 2: Create Coder Document
1. Go to Firebase Console → Firestore Database
2. Navigate to `coders` collection (create if needed)
3. Click **Add document**
4. **Document ID**: Paste the User UID from Step 1
5. Add fields:
   - `uid` (string): Same as Document ID
   - `email` (string): `coder001@gmail.com`
   - `name` (string): `Coder 001`
   - `role` (string): `coder`
   - `createdAt` (timestamp): Current timestamp
6. Click **Save**

### Step 3: Test Login
1. Open app
2. Navigate to `/coder-login` route
3. Login with the credentials above

## Important Notes

✅ **Email Format**: Using proper email format `coder001@gmail.com`

## Verification Checklist

- [ ] User exists in Firebase Authentication
- [ ] Document exists in `coders` collection with matching UID
- [ ] Can login at `/coder-login`
- [ ] Can access `/coder-dashboard` after login
- [ ] Can view error logs

## Troubleshooting

- **"Invalid email format"**: Use a proper email like `coder001@example.com`
- **"Access denied"**: Verify document exists in `coders` collection with correct UID
- **"User not found"**: Check user exists in Firebase Authentication
