# Migration Guide: Firebase → Appwrite + GCS Coldline

**Target Backend:** Appwrite Cloud + Google Cloud Storage (Coldline)  
**Reason:** 88–89% cost reduction (₹2.1–2.6 lakh vs ₹18.8–21.2 lakh per 6 months)

---

## Migration Overview

### What Needs to Change

| Component | Firebase | Appwrite + GCS |
|-----------|---------|----------------|
| **Authentication** | Firebase Auth | Appwrite Auth |
| **Database** | Cloud Firestore | Appwrite Database |
| **Storage** | Firebase Storage | GCS Coldline (via Appwrite or direct) |
| **Messaging** | FCM | Appwrite (or keep FCM) |

---

## Step 1: Setup Appwrite Cloud

1. **Create Appwrite Cloud account:**
   - Go to https://cloud.appwrite.io
   - Sign up / Login
   - Create a new project

2. **Get your Appwrite credentials:**
   - Project ID
   - API Endpoint (e.g., `https://cloud.appwrite.io/v1`)
   - API Key (for server-side operations)

3. **Configure GCS Coldline bucket:**
   - Create GCS bucket in Google Cloud Console
   - Set storage class to **Coldline**
   - Set lifecycle policy: delete objects after 180 days (6 months)
   - Get GCS credentials (service account JSON)

---

## Step 2: Update Dependencies

### Remove Firebase Dependencies

```yaml
# Remove these from pubspec.yaml:
# firebase_core: ^4.2.1
# firebase_auth: ^6.1.2
# cloud_firestore: ^6.1.0
# firebase_storage: ^13.0.4
# firebase_messaging: ^16.0.4  # Optional: keep for push notifications
```

### Add Appwrite Dependencies

```yaml
# Add to pubspec.yaml:
dependencies:
  appwrite: ^13.0.0  # Appwrite SDK
  google_cloud_storage: ^5.0.0  # For direct GCS access (optional)
  # OR use Appwrite Storage which can connect to GCS
```

---

## Step 3: Create Appwrite Configuration

Create `lib/appwrite_config.dart`:

```dart
class AppwriteConfig {
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = 'YOUR_PROJECT_ID';
  static const String apiKey = 'YOUR_API_KEY'; // Server-side only
  
  // GCS Coldline bucket
  static const String gcsBucketName = 'YOUR_GCS_BUCKET_NAME';
  static const String gcsRegion = 'us-central1';
}
```

---

## Step 4: Update Main.dart

Replace Firebase initialization with Appwrite:

```dart
import 'package:appwrite/appwrite.dart';
import 'appwrite_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Appwrite Client
  Client client = Client()
    .setEndpoint(AppwriteConfig.endpoint)
    .setProject(AppwriteConfig.projectId);
  
  // Store client globally (via provider/service locator)
  AppwriteService.initialize(client);
  
  // Initialize session manager
  SessionManager.initialize();
  
  runApp(const SmartAttendanceApp());
}
```

---

## Step 5: Migrate Services

### 5.1 Auth Service Migration

**Current:** `lib/services/auth_service.dart` uses `FirebaseAuth` and `FirebaseFirestore`

**New:** Use Appwrite Auth

```dart
import 'package:appwrite/appwrite.dart';

class AuthService {
  final Account _account;
  final Databases _databases;
  
  AuthService(Client client) 
    : _account = Account(client),
      _databases = Databases(client);
  
  // Email auth (first login)
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      final session = await _account.createEmailSession(
        email: email,
        password: password,
      );
      return {'success': true, 'session': session};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // PIN login (subsequent logins)
  Future<Map<String, dynamic>> signInWithPIN(String userId, String pin) async {
    // Implement PIN validation against Appwrite Database
    // PIN stored in Appwrite Database (hashed)
  }
}
```

### 5.2 Database Service Migration

**Current:** `FirebaseFirestore.instance`

**New:** Appwrite Database

```dart
import 'package:appwrite/appwrite.dart';

class DatabaseService {
  final Databases _databases;
  final String databaseId = 'attendance_db';
  
  DatabaseService(Client client) : _databases = Databases(client);
  
  // Create collection: institutes
  // Create collection: batches
  // Create collection: students
  // Create collection: attendance
  
  Future<void> createBatch(String instituteId, Map<String, dynamic> batchData) async {
    await _databases.createDocument(
      databaseId: databaseId,
      collectionId: 'batches',
      documentId: ID.unique(),
      data: batchData,
    );
  }
  
  // Similar methods for other operations
}
```

### 5.3 Storage Service Migration

**Current:** `FirebaseStorage.instance.ref()`

**New:** GCS Coldline (via Appwrite Storage or direct GCS)

**Option A: Use Appwrite Storage (connects to GCS)**
```dart
import 'package:appwrite/appwrite.dart';

class StorageService {
  final Storage _storage;
  final String bucketId = 'photos_bucket';
  
  StorageService(Client client) : _storage = Storage(client);
  
  Future<String> uploadPhoto(Uint8List bytes, String path) async {
    final file = await _storage.createFile(
      bucketId: bucketId,
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes, filename: path),
    );
    return file.$id;
  }
}
```

**Option B: Direct GCS Coldline Access**
```dart
import 'package:google_cloud_storage/google_cloud_storage.dart';

class StorageService {
  final GoogleCloudStorage _gcs;
  final String bucketName = AppwriteConfig.gcsBucketName;
  
  StorageService() : _gcs = GoogleCloudStorage(
    serviceAccountCredentials: 'path/to/service-account.json',
  );
  
  Future<String> uploadPhoto(Uint8List bytes, String path) async {
    await _gcs.bucket(bucketName).writeBytes(
      path,
      bytes,
      metadata: StorageObjectMetadata(
        storageClass: 'COLDLINE', // Coldline storage class
      ),
    );
    return path;
  }
}
```

---

## Step 6: Update All Service Files

Files that need migration:

1. **`lib/services/auth_service.dart`**
   - Replace `FirebaseAuth` → `Appwrite Account`
   - Replace `FirebaseFirestore` → `Appwrite Databases`
   - Add PIN login logic

2. **`lib/services/batch_service.dart`**
   - Replace `FirebaseFirestore` → `Appwrite Databases`

3. **`lib/services/offline_service.dart`**
   - Replace `FirebaseFirestore` → `Appwrite Databases`

4. **`lib/services/error_logger.dart`**
   - Replace `FirebaseFirestore` → `Appwrite Databases`

5. **`lib/data/attendance_repository.dart`**
   - Replace `FirebaseFirestore` → `Appwrite Databases`

6. **All screen files** that use Firebase:
   - `lib/presentation/screens/admin_attendance_screen.dart` (FirebaseStorage)
   - `lib/presentation/screens/attendance_screen.dart` (FirebaseStorage)
   - `lib/presentation/screens/teacher_attendance_screen.dart` (FirebaseStorage)
   - And others...

---

## Step 7: Database Schema Migration

### Appwrite Database Structure

Create these collections in Appwrite:

1. **`institutes`** collection
   - Fields: `name`, `code`, `address`, `createdAt`, etc.

2. **`batches`** collection (under each institute)
   - Fields: `name`, `year`, `timing`, `subjects`, `studentCount`, etc.

3. **`students`** collection (under each institute)
   - Fields: `name`, `rollNumber`, `batchId`, `email`, etc.

4. **`attendance`** collection (under each institute)
   - Fields: `rollNumber`, `subject`, `date`, `photoUrl`, `timestamp`, `batchId`, etc.

5. **`users`** collection
   - Fields: `email`, `role`, `instituteId`, `pinHash`, etc.

6. **`error_logs`** collection
   - Fields: `error`, `stackTrace`, `context`, `timestamp`, etc.

---

## Step 8: Storage Migration

### GCS Coldline Setup

1. **Create GCS bucket:**
   ```bash
   gsutil mb -p YOUR_PROJECT_ID -c COLDLINE -l us-central1 gs://YOUR_BUCKET_NAME
   ```

2. **Set lifecycle policy (delete after 180 days):**
   ```json
   {
     "lifecycle": {
       "rule": [
         {
           "action": {"type": "Delete"},
           "condition": {"age": 180}
         }
       ]
     }
   }
   ```

3. **Update storage paths:**
   - Keep same structure: `institutes/{instituteId}/batches/{batchId}/attendance/{date}/{filename}.jpg`
   - Upload to GCS Coldline bucket instead of Firebase Storage

---

## Step 9: Migration Checklist

### Pre-Migration
- [ ] Create Appwrite Cloud account and project
- [ ] Create GCS Coldline bucket
- [ ] Set GCS lifecycle policy (delete after 180 days)
- [ ] Get Appwrite credentials (endpoint, project ID, API key)
- [ ] Get GCS service account credentials

### Code Migration
- [ ] Update `pubspec.yaml` (remove Firebase, add Appwrite)
- [ ] Create `appwrite_config.dart`
- [ ] Update `main.dart` (Appwrite initialization)
- [ ] Migrate `auth_service.dart`
- [ ] Migrate `batch_service.dart`
- [ ] Migrate `offline_service.dart`
- [ ] Migrate `error_logger.dart`
- [ ] Migrate `attendance_repository.dart`
- [ ] Migrate all screen files using Firebase
- [ ] Create Appwrite database collections
- [ ] Set up Appwrite Storage bucket (or direct GCS)

### Testing
- [ ] Test email authentication (first login)
- [ ] Test PIN login (subsequent logins)
- [ ] Test batch creation/management
- [ ] Test student management
- [ ] Test attendance marking with photo upload
- [ ] Test photo deletion after 6 months
- [ ] Test offline sync (if applicable)

### Deployment
- [ ] Deploy to test environment
- [ ] Migrate existing data (if any)
- [ ] Deploy to production
- [ ] Monitor costs (should see 88–89% reduction)

---

## Step 10: Data Migration (If You Have Existing Data)

If you have existing Firebase data:

1. **Export Firebase data:**
   ```bash
   # Export Firestore
   gcloud firestore export gs://YOUR_BACKUP_BUCKET
   
   # Export Storage
   gsutil -m cp -r gs://firebase-storage-bucket/* gs://your-gcs-bucket/
   ```

2. **Transform and import to Appwrite:**
   - Write script to convert Firestore JSON → Appwrite format
   - Import via Appwrite API

---

## Cost Comparison After Migration

| Backend | Cost (per 6 months) |
|---------|---------------------|
| **Firebase** (old) | ₹18,76,500 – ₹21,16,500 |
| **Appwrite + GCS Coldline** (new) | **₹2,10,500 – ₹2,60,500** |
| **Savings** | **₹16,66,000 – ₹18,56,000** (88–89%) |

**With ₹6 lakh revenue:**
- **Old (Firebase):** Loss of ₹12.8–15.2 lakh
- **New (Appwrite + GCS Coldline):** **Profit of ₹3.4–3.9 lakh!** ✅

---

## Important Notes

1. **PIN Login:** Implement PIN validation in Appwrite Database (store hashed PINs)
2. **Photo Deletion:** GCS lifecycle policy will auto-delete photos after 180 days
3. **Migration Time:** Estimate 2–4 weeks for full migration
4. **Testing:** Thoroughly test all features before production deployment
5. **Rollback Plan:** Keep Firebase project active during migration for rollback if needed

---

## Resources

- **Appwrite Docs:** https://appwrite.io/docs
- **Appwrite Flutter SDK:** https://appwrite.io/docs/getting-started-for-flutter
- **GCS Coldline Docs:** https://cloud.google.com/storage/docs/storage-classes#coldline
- **GCS Lifecycle Policies:** https://cloud.google.com/storage/docs/lifecycle

---

*This migration will significantly reduce your backend costs and make your ₹6 lakh quotation profitable!*
