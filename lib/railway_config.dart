/// Railway PostgreSQL Configuration
/// 
/// Self-hosted PostgreSQL database on Railway
class RailwayConfig {
  // Railway PostgreSQL connection
  // Get these from Railway dashboard → Database → Variables
  static const String databaseUrl = 'YOUR_RAILWAY_DATABASE_URL'; // Full connection string
  static const String databaseHost = 'YOUR_RAILWAY_HOST'; // e.g., containers-us-west-123.railway.app
  static const int databasePort = 5432;
  static const String databaseName = 'railway';
  static const String databaseUser = 'postgres';
  static const String databasePassword = 'YOUR_PASSWORD'; // Get from Railway
  
  // Connection pool settings
  static const int maxConnections = 10;
  static const int connectionTimeoutSeconds = 30;
  
  // Auth configuration (choose one: Auth0, Clerk, or Supabase Auth)
  
  // Option 1: Auth0
  static const String auth0Domain = 'YOUR_AUTH0_DOMAIN'; // e.g., your-app.auth0.com
  static const String auth0ClientId = 'YOUR_AUTH0_CLIENT_ID';
  static const String auth0ClientSecret = 'YOUR_AUTH0_CLIENT_SECRET';
  
  // Option 2: Clerk
  static const String clerkPublishableKey = 'YOUR_CLERK_PUBLISHABLE_KEY';
  static const String clerkSecretKey = 'YOUR_CLERK_SECRET_KEY';
  
  // Option 3: Supabase Auth (just auth, not database)
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // GCS Coldline bucket configuration (for photo storage)
  static const String gcsBucketName = 'YOUR_GCS_BUCKET_NAME';
  static const String gcsRegion = 'us-central1';
  static const String gcsStorageClass = 'COLDLINE';
  static const int photoRetentionDays = 180;
  
  // App configuration
  static const String appName = 'ATTENDANCE APP';
  static const String appVersion = '1.0.0';
}
