# Railway Self-Hosted PostgreSQL Setup Guide

## 🚀 Railway - Cheapest Database Option

**Cost:** $5-20/month (~₹400-1,650/month)  
**Savings:** ₹52,000-60,000 per 6 months (25-28% cheaper than Appwrite)

---

## Step 1: Create Railway Account

1. Go to [Railway.app](https://railway.app)
2. Sign up with GitHub (recommended) or email
3. Verify your email

---

## Step 2: Create PostgreSQL Database

1. **Click:** "New Project"
2. **Click:** "New" → "Database" → "Add PostgreSQL"
3. **Wait for database to provision** (~30 seconds)
4. **Click on the database** to view details

---

## Step 3: Get Database Credentials

1. **Go to:** Database → "Variables" tab
2. **Copy these values:**
   - `DATABASE_URL` (full connection string)
   - `PGHOST` (host)
   - `PGPORT` (port)
   - `PGUSER` (username)
   - `PGPASSWORD` (password)
   - `PGDATABASE` (database name)

**Example:**
```
DATABASE_URL=postgresql://postgres:password@containers-us-west-123.railway.app:5432/railway
PGHOST=containers-us-west-123.railway.app
PGPORT=5432
PGUSER=postgres
PGPASSWORD=your_password_here
PGDATABASE=railway
```

---

## Step 4: Upgrade Plan (If Needed)

**Free Tier:**
- 512MB RAM
- 1GB storage
- $5 credit/month

**Starter Plan ($5/month):**
- 256MB RAM
- 1GB storage
- Good for testing

**Developer Plan ($20/month):**
- 1GB RAM
- 10GB storage
- **Recommended for production**

**For your app (3,000 institutes):**
- Start with **Developer Plan ($20/month)**
- Upgrade if needed based on usage

---

## Step 5: Set Up Database Schema

### Connect to Railway PostgreSQL

**Option A: Using Railway CLI**
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Connect to database
railway connect
```

**Option B: Using psql**
```bash
psql $DATABASE_URL
```

**Option C: Using Database GUI (DBeaver, pgAdmin, etc.)**
- Use the connection string from Railway

---

## Step 6: Create Database Tables

### Run SQL Script to Create Tables

```sql
-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Institutes table
CREATE TABLE institutes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    address VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255)
);

-- Batches table
CREATE TABLE batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    year VARCHAR(50) NOT NULL,
    timing VARCHAR(100) NOT NULL,
    subjects TEXT[] NOT NULL,
    student_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255)
);

-- Students table
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    roll_number VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    batch_name VARCHAR(255),
    batch_timing VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(institute_id, batch_id, roll_number)
);

-- Attendance table
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    batch_name VARCHAR(255),
    roll_number VARCHAR(50) NOT NULL,
    subject VARCHAR(100) NOT NULL,
    date VARCHAR(50) NOT NULL,
    photo_url VARCHAR(500),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    marked_by VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    UNIQUE(institute_id, batch_id, roll_number, subject, date)
);

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'teacher', 'coder')),
    institute_id UUID REFERENCES institutes(id) ON DELETE SET NULL,
    pin_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Error logs table
CREATE TABLE error_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    error VARCHAR(1000) NOT NULL,
    stack_trace TEXT,
    context VARCHAR(500),
    app_type VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL
);

-- Create indexes for performance
CREATE INDEX idx_batches_institute_id ON batches(institute_id);
CREATE INDEX idx_students_institute_id ON students(institute_id);
CREATE INDEX idx_students_batch_id ON students(batch_id);
CREATE INDEX idx_attendance_institute_id ON attendance(institute_id);
CREATE INDEX idx_attendance_batch_id ON attendance(batch_id);
CREATE INDEX idx_attendance_roll_number ON attendance(roll_number);
CREATE INDEX idx_attendance_date ON attendance(date);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_institute_id ON users(institute_id);
CREATE INDEX idx_error_logs_timestamp ON error_logs(timestamp);
```

---

## Step 7: Set Up Authentication

**Railway doesn't include Auth, so we need to add it:**

### Option A: Auth0 (Recommended)

1. **Sign up:** [Auth0.com](https://auth0.com)
2. **Free tier:** 7,000 MAU free
3. **Create Application:**
   - Application type: Native (for mobile) or Regular Web App
   - Configure callback URLs
4. **Get credentials:**
   - Domain
   - Client ID
   - Client Secret

**Cost:** Free for < 7,000 MAU, then $35/month

### Option B: Clerk

1. **Sign up:** [Clerk.com](https://clerk.com)
2. **Free tier:** 10,000 MAU free
3. **Create Application**
4. **Get API keys**

**Cost:** Free for < 10,000 MAU, then $25/month

### Option C: Supabase Auth (Just Auth)

1. **Sign up:** [Supabase.com](https://supabase.com)
2. **Create project** (free tier available)
3. **Use only Auth** (not database)
4. **Get API keys**

**Cost:** Free tier available

---

## Step 8: Update App Configuration

### Update `lib/appwrite_config.dart` → `lib/railway_config.dart`

```dart
/// Railway PostgreSQL Configuration
class RailwayConfig {
  // Railway PostgreSQL connection
  static const String databaseUrl = 'YOUR_RAILWAY_DATABASE_URL';
  static const String databaseHost = 'YOUR_RAILWAY_HOST';
  static const int databasePort = 5432;
  static const String databaseName = 'railway';
  static const String databaseUser = 'postgres';
  static const String databasePassword = 'YOUR_PASSWORD';
  
  // Auth0/Clerk configuration
  static const String authDomain = 'YOUR_AUTH_DOMAIN';
  static const String authClientId = 'YOUR_CLIENT_ID';
  static const String authClientSecret = 'YOUR_CLIENT_SECRET';
  
  // GCS Coldline bucket configuration (same as before)
  static const String gcsBucketName = 'YOUR_GCS_BUCKET_NAME';
  static const String gcsRegion = 'us-central1';
  static const String gcsStorageClass = 'COLDLINE';
  static const int photoRetentionDays = 180;
}
```

---

## Step 9: Install Required Packages

**Update `pubspec.yaml`:**

```yaml
dependencies:
  # ... existing dependencies ...
  
  # PostgreSQL database
  postgres: ^3.0.0
  # OR
  postgresql: ^2.0.0
  
  # Connection pooling
  connection_pool: ^1.0.0
  
  # Auth (choose one)
  auth0_flutter: ^2.0.0  # If using Auth0
  # OR
  clerk_flutter: ^1.0.0  # If using Clerk
```

---

## Step 10: Create Database Service

**Create `lib/services/railway_database_service.dart`:**

```dart
import 'package:postgres/postgres.dart';
import '../railway_config.dart';

class RailwayDatabaseService {
  static PostgreSQLConnection? _connection;
  
  static Future<PostgreSQLConnection> get connection async {
    if (_connection == null || _connection!.isClosed) {
      _connection = PostgreSQLConnection(
        RailwayConfig.databaseHost,
        RailwayConfig.databasePort,
        RailwayConfig.databaseName,
        username: RailwayConfig.databaseUser,
        password: RailwayConfig.databasePassword,
      );
      await _connection!.open();
    }
    return _connection!;
  }
  
  // Example: Get institutes
  static Future<List<Map<String, dynamic>>> getInstitutes() async {
    final conn = await connection;
    final results = await conn.query('SELECT * FROM institutes');
    return results.map((row) => row.toColumnMap()).toList();
  }
  
  // Example: Create institute
  static Future<Map<String, dynamic>> createInstitute({
    required String name,
    required String code,
    String? address,
  }) async {
    final conn = await connection;
    final result = await conn.query(
      'INSERT INTO institutes (name, code, address) VALUES (@name, @code, @address) RETURNING *',
      parameters: {
        'name': name,
        'code': code,
        'address': address,
      },
    );
    return result.first.toColumnMap();
  }
  
  // Add more methods as needed...
}
```

---

## Step 11: Set Up Environment Variables

**Create `.env` file (DO NOT commit to git!):**

```env
RAILWAY_DATABASE_URL=postgresql://postgres:password@host:5432/railway
RAILWAY_DATABASE_HOST=containers-us-west-123.railway.app
RAILWAY_DATABASE_PORT=5432
RAILWAY_DATABASE_NAME=railway
RAILWAY_DATABASE_USER=postgres
RAILWAY_DATABASE_PASSWORD=your_password

AUTH0_DOMAIN=your-domain.auth0.com
AUTH0_CLIENT_ID=your_client_id
AUTH0_CLIENT_SECRET=your_client_secret

GCS_BUCKET_NAME=your-bucket-name
```

**Add to `.gitignore`:**
```
.env
*.env
```

---

## Step 12: Migration from Appwrite

### Export Data from Appwrite

1. **Use Appwrite Console** to export data
2. **Or use Appwrite API** to fetch all documents
3. **Save as JSON files**

### Import to Railway PostgreSQL

1. **Convert JSON to SQL INSERT statements**
2. **Run SQL script** in Railway database
3. **Verify data** migrated correctly

**Migration Script Example:**

```dart
// lib/scripts/migrate_from_appwrite.dart
// This script reads from Appwrite and writes to Railway PostgreSQL
```

---

## 💰 Cost Breakdown

### Railway Costs (Per 6 Months)

| Item | Cost |
|------|------|
| **Railway Developer Plan** | ₹9,900 ($20/month × 6) |
| **GCS Coldline (75TB)** | ₹1,48,500 |
| **Auth0 Free Tier** | ₹0 (if < 7,000 MAU) |
| **Total** | **₹1,58,400** |

### Savings vs Appwrite

| Option | Cost (6 months) | Savings |
|--------|----------------|---------|
| **Appwrite + GCS** | ₹2,10,500 | Baseline |
| **Railway + GCS** | ₹1,58,400 | **Save ₹52,100 (25%)** |

---

## ✅ Checklist

- [ ] Railway account created
- [ ] PostgreSQL database created
- [ ] Database credentials saved securely
- [ ] Database schema created (tables, indexes)
- [ ] Auth service set up (Auth0/Clerk/Supabase)
- [ ] App configuration updated
- [ ] Database service created
- [ ] Environment variables configured
- [ ] Packages installed
- [ ] Test connection works
- [ ] Data migrated from Appwrite (if applicable)

---

## 🚀 Next Steps

1. **Set up Railway database** (Steps 1-4)
2. **Create database schema** (Step 6)
3. **Set up Auth** (Step 7)
4. **Update app code** (Steps 8-10)
5. **Test connection**
6. **Migrate data** (if needed)

---

## 📚 Resources

- **Railway Docs:** https://docs.railway.app
- **PostgreSQL Docs:** https://www.postgresql.org/docs
- **Auth0 Docs:** https://auth0.com/docs
- **Clerk Docs:** https://clerk.com/docs

---

## 🎉 Summary

**Railway Self-Hosted PostgreSQL:**
- ✅ **25% cheaper** than Appwrite
- ✅ **Full control** over database
- ✅ **PostgreSQL** (powerful features)
- ✅ **Easy setup** with Railway
- ✅ **Save ₹52,100 per 6 months**

**Total Cost:** ₹1,58,400 per 6 months (vs ₹2,10,500 with Appwrite)
