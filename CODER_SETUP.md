# Coder Account Setup Instructions

## Coder Login Credentials
- **Email**: `coder001@gmail.com`
- **Password**: `Bhushan@70`

## Method 1: Using Firebase Console (Recommended)

### Step 1: Create Firebase Auth User
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `smartattendanceapp-bc2fe`
3. Navigate to **Authentication** → **Users**
4. Click **Add user**
5. Enter:
   - **Email**: `coder001@gmail.com`
   - **Password**: `Bhushan@70`
6. Click **Add user**

### Step 2: Get User UID
1. After creating the user, copy the **User UID** (it will be shown in the users list)

### Step 3: Create Coder Document in Firestore
1. Go to **Firestore Database** in Firebase Console
2. Navigate to `coders` collection (create it if it doesn't exist)
3. Click **Add document**
4. Set **Document ID** to the **User UID** you copied
5. Add the following fields:
   ```json
   {
     "uid": "paste_user_uid_here",
     "email": "coder001@gmail.com",
     "name": "Coder 001",
     "role": "coder",
     "createdAt": "2025-01-XX" (or use timestamp)
   }
   ```
6. Click **Save**

### Step 4: Test Login
1. Open the app
2. Navigate to `/coder-login` route
3. Login with:
   - Email: `coder001@gmail.com`
   - Password: `Bhushan@70`

## Method 2: Using Flutter Script (Requires Admin Access)

If you have admin access, you can run the script:

```bash
cd scripts
flutter run create_coder_account.dart
```

**Note**: This method requires you to be authenticated as an admin user first.

## Method 3: Using Firebase Admin SDK (For Server-Side)

If you have Firebase Admin SDK set up, you can create the account programmatically:

```dart
// Using Firebase Admin SDK
await admin.auth().createUser({
  email: 'coder001@gmail.com',
  password: 'Bhushan@70',
});

await admin.firestore().collection('coders').doc(uid).set({
  'uid': uid,
  'email': 'coder001@gmail.com',
  'name': 'Coder 001',
  'role': 'coder',
  'createdAt': FieldValue.serverTimestamp(),
});
```

## Verification

After setup, verify:
1. User exists in Firebase Authentication
2. Document exists in `coders` collection with matching UID
3. Can login at `/coder-login` route
4. Can access `/coder-dashboard` after login

## Troubleshooting

- **"Access denied"**: Make sure the document exists in `coders` collection with the correct UID
- **"User not found"**: Verify the user exists in Firebase Authentication
- **"Permission denied"**: Check Firestore rules allow coders to read `error_logs` collection
