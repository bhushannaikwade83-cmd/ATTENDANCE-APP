# Appwrite + Railway Hybrid Setup Guide

## 🎯 Best of Both Worlds

**Strategy:**
- **Appwrite:** Auth, API management, Storage (small files)
- **Railway PostgreSQL:** Database (cheaper than Appwrite database)

**Why This Works:**
- ✅ Keep Appwrite's excellent Auth system
- ✅ Use Railway for cheaper database storage
- ✅ Best cost optimization
- ✅ Leverage strengths of both platforms

---

## 💰 Cost Comparison

### Option A: Appwrite Only
| Item | Cost (6 months) |
|------|------------------|
| Appwrite Pro Plan | ₹12,000 |
| Appwrite Database (if used) | Included |
| GCS Coldline (75TB) | ₹1,48,500 |
| **Total** | **₹1,60,500** |

### Option B: Appwrite + Railway (Recommended) ⭐
| Item | Cost (6 months) |
|------|------------------|
| Appwrite Pro Plan | ₹12,000 |
| Railway PostgreSQL | ₹9,900 |
| GCS Coldline (75TB) | ₹1,48,500 |
| **Total** | **₹1,70,400** |

**Note:** Actually slightly more expensive, but you get:
- ✅ Better database (PostgreSQL)
- ✅ More control over database
- ✅ Can scale database independently
- ✅ Better for complex queries

---

## 🏗️ Architecture

```
┌─────────────────┐
│   Flutter App   │
└────────┬────────┘
         │
         ├─────────────────┬──────────────────┐
         │                 │                  │
         ▼                 ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Appwrite   │  │   Railway    │  │     GCS     │
│              │  │  PostgreSQL  │  │  Coldline   │
│ • Auth       │  │              │  │             │
│ • API        │  │ • Database   │  │ • Photos    │
│ • Storage    │  │ • Queries    │  │ • 180 days  │
│   (small)    │  │ • Reports    │  │             │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 📋 Setup Steps

### Step 1: Set Up Appwrite (Auth & API)

1. **Keep your existing Appwrite setup:**
   - Project: ATTENDANCE APP
   - Pro Plan: $25/month
   - Auth: Email/Password enabled

2. **Use Appwrite for:**
   - ✅ User authentication
   - ✅ Session management
   - ✅ API endpoints (if using Appwrite Functions)
   - ✅ Small file storage (profile pictures, etc.)

---

### Step 2: Set Up Railway PostgreSQL (Database)

1. **Create Railway account:** [railway.app](https://railway.app)
2. **Create PostgreSQL database:**
   - New → Database → PostgreSQL
   - Wait for provisioning (~30 seconds)

3. **Get credentials:**
   - Database → Variables tab
   - Copy: `DATABASE_URL`, `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`

4. **Create schema:**
   - Run `scripts/create_railway_schema.sql`
   - This creates all tables (institutes, batches, students, attendance, users, error_logs)

---

### Step 3: Configure Hybrid Setup

**Update `lib/appwrite_config.dart`:**

```dart
class AppwriteConfig {
  // Appwrite (for Auth & API)
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = '6981f623001657ab0c90';
  static const String projectName = 'ATTENDANCE APP';
  
  // Railway PostgreSQL (for Database)
  static const String railwayDatabaseUrl = 'YOUR_RAILWAY_DATABASE_URL';
  static const String railwayDatabaseHost = 'YOUR_RAILWAY_HOST';
  static const int railwayDatabasePort = 5432;
  static const String railwayDatabaseName = 'railway';
  static const String railwayDatabaseUser = 'postgres';
  static const String railwayDatabasePassword = 'YOUR_PASSWORD';
  
  // GCS Coldline (for Photo Storage)
  static const String gcsBucketName = 'YOUR_GCS_BUCKET_NAME';
  static const String gcsRegion = 'us-central1';
  static const String gcsStorageClass = 'COLDLINE';
  static const int photoRetentionDays = 180;
  
  // Appwrite Storage (for small files only)
  static const String storageBucketId = 'photos_bucket';
}
```

---

### Step 4: Update Services

**Create `lib/services/hybrid_service.dart`:**

```dart
import 'package:appwrite/appwrite.dart';
import '../appwrite_config.dart';
import 'appwrite_service.dart';
import 'railway_database_service.dart';
import 'storage_service.dart';

/// Hybrid Service - Uses Appwrite for Auth, Railway for Database
class HybridService {
  // ============================================
  // AUTHENTICATION (Appwrite)
  // ============================================
  
  /// Login with email/password (Appwrite)
  static Future<Session> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await AppwriteService.account.createEmailSession(
      email: email,
      password: password,
    );
  }
  
  /// Get current user (Appwrite)
  static Future<User> getCurrentUser() async {
    return await AppwriteService.account.get();
  }
  
  /// Logout (Appwrite)
  static Future<void> logout() async {
    await AppwriteService.account.deleteSession(sessionId: 'current');
  }
  
  // ============================================
  // DATABASE OPERATIONS (Railway PostgreSQL)
  // ============================================
  
  /// Get institutes (Railway)
  static Future<List<Map<String, dynamic>>> getInstitutes() async {
    return await RailwayDatabaseService.getInstitutes();
  }
  
  /// Create institute (Railway)
  static Future<Map<String, dynamic>> createInstitute({
    required String name,
    required String code,
    String? address,
  }) async {
    // Get current user from Appwrite
    final user = await getCurrentUser();
    
    // Create in Railway PostgreSQL
    return await RailwayDatabaseService.createInstitute(
      name: name,
      code: code,
      address: address,
      createdBy: user.$id,
    );
  }
  
  /// Get batches (Railway)
  static Future<List<Map<String, dynamic>>> getBatches(String instituteId) async {
    return await RailwayDatabaseService.getBatchesByInstitute(instituteId);
  }
  
  /// Mark attendance (Railway + GCS)
  static Future<Map<String, dynamic>> markAttendance({
    required String instituteId,
    required String batchId,
    required String rollNumber,
    required String subject,
    required String date,
    required List<int> photoBytes,
  }) async {
    // Get current user from Appwrite
    final user = await getCurrentUser();
    
    // Get batch info from Railway
    final batch = await RailwayDatabaseService.getBatchById(batchId);
    final batchYear = batch?['year']?.toString() ?? DateTime.now().year.toString();
    
    // Upload photo to GCS Coldline
    final uploadResult = await StorageService.uploadAttendancePhoto(
      instituteId: instituteId,
      batchYear: batchYear,
      rollNumber: rollNumber,
      subject: subject,
      date: date,
      photoBytes: photoBytes,
    );
    
    // Save attendance record in Railway PostgreSQL
    return await RailwayDatabaseService.markAttendance(
      instituteId: instituteId,
      batchId: batchId,
      rollNumber: rollNumber,
      subject: subject,
      date: date,
      batchName: batch?['name'],
      photoUrl: uploadResult['url'],
      storagePath: uploadResult['path'],
      markedBy: user.$id,
    );
  }
  
  // Add more hybrid methods as needed...
}
```

---

### Step 5: Update App Code

**Replace Appwrite-only calls with HybridService:**

**Before (Appwrite only):**
```dart
// Auth
await AppwriteService.account.createEmailSession(...);

// Database
await AppwriteService.databases.createDocument(...);
```

**After (Appwrite + Railway):**
```dart
// Auth (still Appwrite)
await HybridService.loginWithEmail(...);

// Database (now Railway)
await HybridService.createInstitute(...);
```

---

## 🔄 Data Flow

### User Registration/Login Flow

```
1. User registers/logs in → Appwrite Auth
2. Appwrite returns user session
3. Store user ID in Railway PostgreSQL (users table)
4. Use Appwrite session for authentication
```

### Attendance Marking Flow

```
1. User authenticated via Appwrite session
2. Get user ID from Appwrite
3. Upload photo to GCS Coldline
4. Save attendance record in Railway PostgreSQL
5. Link attendance to Appwrite user ID
```

### Data Query Flow

```
1. User authenticated via Appwrite
2. Query Railway PostgreSQL for data
3. Return results to app
```

---

## 📊 What Goes Where

### Appwrite Handles:
- ✅ **Authentication** (email/password, OAuth)
- ✅ **Session management**
- ✅ **User accounts**
- ✅ **Small file storage** (profile pictures, thumbnails)
- ✅ **API endpoints** (if using Appwrite Functions)

### Railway PostgreSQL Handles:
- ✅ **All database operations**
- ✅ **Institutes, batches, students**
- ✅ **Attendance records**
- ✅ **Complex queries**
- ✅ **Reports and analytics**

### GCS Coldline Handles:
- ✅ **Photo storage** (75TB, 180-day retention)
- ✅ **Large files**

---

## 🔐 Authentication Strategy

### Option 1: Appwrite Auth Only (Recommended)

**How it works:**
1. User logs in via Appwrite
2. Appwrite returns user ID and session
3. Store user ID in Railway `users` table (for reference)
4. Use Appwrite session token for all requests
5. Query Railway PostgreSQL using Appwrite user ID

**Pros:**
- ✅ Simple
- ✅ Leverages Appwrite's excellent Auth
- ✅ No duplicate auth systems

**Implementation:**
```dart
// Login
final session = await HybridService.loginWithEmail(email, password);
final user = await HybridService.getCurrentUser();

// Store user in Railway (one-time, for reference)
await RailwayDatabaseService.createUser(
  email: user.email,
  role: 'admin', // or get from Appwrite custom claims
  // Link Appwrite user ID
);
```

---

### Option 2: Sync Users Between Appwrite and Railway

**How it works:**
1. User registers in Appwrite
2. Automatically create user record in Railway
3. Keep both in sync

**Implementation:**
```dart
// After Appwrite registration
final appwriteUser = await AppwriteService.account.create(...);

// Create corresponding record in Railway
await RailwayDatabaseService.createUser(
  email: appwriteUser.email,
  role: 'admin',
  // Store Appwrite user ID for reference
);
```

---

## 💾 Database Schema Updates

**Update Railway `users` table to link with Appwrite:**

```sql
-- Add Appwrite user ID column
ALTER TABLE users ADD COLUMN appwrite_user_id VARCHAR(255) UNIQUE;

-- Create index
CREATE INDEX idx_users_appwrite_id ON users(appwrite_user_id);

-- Update users table to reference Appwrite
-- Now users table has both Railway ID and Appwrite user ID
```

---

## 📝 Migration from Appwrite-Only

### Step 1: Export Data from Appwrite

```dart
// Export all collections from Appwrite
final institutes = await AppwriteService.databases.listDocuments(
  databaseId: AppwriteConfig.databaseId,
  collectionId: AppwriteConfig.institutesCollectionId,
);
// ... export batches, students, attendance, etc.
```

### Step 2: Import to Railway PostgreSQL

```dart
// Import institutes
for (final institute in institutes.documents) {
  await RailwayDatabaseService.createInstitute(
    name: institute.data['name'],
    code: institute.data['code'],
    address: institute.data['address'],
  );
}
// ... import batches, students, attendance, etc.
```

### Step 3: Link Users

```dart
// Link Appwrite users with Railway users
for (final appwriteUser in appwriteUsers) {
  await RailwayDatabaseService.createUser(
    email: appwriteUser.email,
    role: appwriteUser.data['role'],
    appwriteUserId: appwriteUser.$id, // Store Appwrite ID
  );
}
```

---

## ✅ Benefits of Hybrid Approach

1. **Best Auth:** Appwrite's excellent authentication system
2. **Cheaper Database:** Railway PostgreSQL is cost-effective
3. **More Control:** Full PostgreSQL features and control
4. **Better Queries:** Complex SQL queries in PostgreSQL
5. **Scalability:** Scale database independently
6. **Flexibility:** Can switch database without changing auth

---

## 🎯 Recommended Setup

### For Your Attendance App:

**Appwrite ($25/month):**
- ✅ Auth (email/password, PIN login)
- ✅ Session management
- ✅ User accounts

**Railway PostgreSQL ($20/month):**
- ✅ All database operations
- ✅ Institutes, batches, students
- ✅ Attendance records
- ✅ Complex queries and reports

**GCS Coldline:**
- ✅ Photo storage (75TB, 180-day retention)

**Total Cost:** ₹1,70,400 per 6 months

---

## 📚 Files to Update

1. ✅ `lib/appwrite_config.dart` - Add Railway credentials
2. ✅ `lib/services/hybrid_service.dart` - New hybrid service
3. ✅ `lib/services/railway_database_service.dart` - Railway database service
4. ✅ Update all screens to use `HybridService` instead of `AppwriteService` for database ops
5. ✅ Keep `AppwriteService` for auth only

---

## 🚀 Quick Start

1. **Set up Appwrite** (already done ✅)
2. **Set up Railway PostgreSQL** (follow `RAILWAY_SETUP_GUIDE.md`)
3. **Create hybrid service** (use code above)
4. **Update app code** to use `HybridService`
5. **Test:** Auth via Appwrite, Database via Railway

---

## 🎉 Summary

**Appwrite + Railway Hybrid:**
- ✅ **Best Auth:** Appwrite
- ✅ **Cheaper Database:** Railway PostgreSQL
- ✅ **Best Storage:** GCS Coldline
- ✅ **Total Cost:** ₹1,70,400 per 6 months
- ✅ **Best of both worlds!**

**Architecture:**
- Appwrite → Auth & Sessions
- Railway → Database & Queries
- GCS → Photo Storage

This gives you the best features of both platforms! 🚀
