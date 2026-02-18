# Backblaze B2 Private Bucket Setup (Firebase Functions + Flutter)

## 1) Configure Flutter endpoint
Update `lib/firebase_backend_config.dart`:

```dart
static const String backblazeProxyBaseUrl =
    'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net';
```

## 2) Configure Functions environment variables
Inside `functions/`, create `.env` from `.env.example` and set:

- `B2_KEY_ID`
- `B2_APP_KEY`
- `B2_BUCKET_ID`
- `B2_BUCKET_NAME`

## 3) Install and deploy functions
From project root:

```bash
cd functions
npm install
firebase deploy --only functions
```

This deploys:
- `b2GetUploadUrl`
- `b2GetDownloadUrl`

## 4) Security model
- Flutter sends Firebase ID token to functions.
- Functions verify token and call Backblaze B2 APIs.
- Flutter never stores B2 credentials.
- Firestore stores `verificationSelfie` as B2 object path, not public URL.

## 5) Backward compatibility
Existing records with old HTTP URLs still display.
New records store private object path and use temporary signed URL at view time.
