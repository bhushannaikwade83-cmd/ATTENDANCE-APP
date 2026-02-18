# Railway Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Create Railway Account (2 minutes)

1. Go to [railway.app](https://railway.app)
2. Click "Start a New Project"
3. Sign up with GitHub (recommended) or email
4. Verify your email

---

### Step 2: Create PostgreSQL Database (1 minute)

1. In Railway dashboard, click **"New"**
2. Select **"Database"** → **"Add PostgreSQL"**
3. Wait ~30 seconds for database to provision
4. ✅ Database created!

---

### Step 3: Get Database Credentials (1 minute)

1. Click on your PostgreSQL database
2. Go to **"Variables"** tab
3. Copy these values:
   - `DATABASE_URL` (full connection string)
   - `PGHOST`
   - `PGPORT`
   - `PGUSER`
   - `PGPASSWORD`
   - `PGDATABASE`

**Example:**
```
DATABASE_URL=postgresql://postgres:abc123@containers-us-west-123.railway.app:5432/railway
PGHOST=containers-us-west-123.railway.app
PGPORT=5432
PGUSER=postgres
PGPASSWORD=abc123
PGDATABASE=railway
```

---

### Step 4: Create Database Schema (1 minute)

**Option A: Using Railway CLI**
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Connect to database
railway connect

# Run SQL script
psql < scripts/create_railway_schema.sql
```

**Option B: Using Railway Web Console**
1. Go to database → **"Query"** tab
2. Copy contents of `scripts/create_railway_schema.sql`
3. Paste and click **"Run"**

**Option C: Using Database GUI**
- Use DBeaver, pgAdmin, or TablePlus
- Connect using `DATABASE_URL`
- Run `scripts/create_railway_schema.sql`

---

### Step 5: Update App Configuration (1 minute)

1. **Open:** `lib/railway_config.dart`
2. **Update with your Railway credentials:**
   ```dart
   static const String databaseHost = 'containers-us-west-123.railway.app';
   static const String databasePassword = 'your_password_here';
   // ... etc
   ```

3. **Update:** `pubspec.yaml`
   ```yaml
   dependencies:
     postgres: ^3.0.0  # Uncomment this line
   ```

4. **Run:**
   ```bash
   flutter pub get
   ```

---

### Step 6: Set Up Authentication

**Choose one:**

#### Option A: Auth0 (Recommended)
1. Sign up: [auth0.com](https://auth0.com)
2. Create application
3. Get credentials
4. Update `railway_config.dart` with Auth0 credentials

#### Option B: Clerk
1. Sign up: [clerk.com](https://clerk.com)
2. Create application
3. Get API keys
4. Update `railway_config.dart` with Clerk credentials

---

### Step 7: Test Connection

**In your app:**
```dart
import 'package:your_app/services/railway_database_service.dart';

// Test connection
final isConnected = await RailwayDatabaseService.testConnection();
print('Database connected: $isConnected');
```

---

## ✅ You're Done!

**Cost:**
- Railway Developer Plan: $20/month (~₹1,650/month)
- **Total per 6 months:** ₹9,900
- **With GCS Coldline:** ₹1,58,400 per 6 months
- **Savings:** ₹52,100 vs Appwrite (25% cheaper)

---

## 📚 Next Steps

1. ✅ Database created and schema set up
2. ✅ App configured
3. ⏭️ Set up authentication (Auth0/Clerk)
4. ⏭️ Migrate data from Appwrite (if needed)
5. ⏭️ Test all features

---

## 🆘 Troubleshooting

### Connection Failed
- Check database credentials in `railway_config.dart`
- Verify database is running in Railway dashboard
- Check firewall/network settings

### Schema Creation Failed
- Make sure you're connected to the database
- Check SQL syntax in `create_railway_schema.sql`
- Verify you have permissions

### Need Help?
- Railway Docs: https://docs.railway.app
- PostgreSQL Docs: https://www.postgresql.org/docs
- Check `RAILWAY_SETUP_GUIDE.md` for detailed instructions

---

## 🎉 Summary

**Railway Setup Complete!**

- ✅ Database: Railway PostgreSQL
- ✅ Schema: Created
- ✅ App: Configured
- ✅ Cost: ₹1,58,400 per 6 months (25% cheaper than Appwrite)

**Next:** Set up authentication and start using Railway! 🚀
