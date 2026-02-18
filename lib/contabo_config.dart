/// Contabo VPS PostgreSQL Configuration
/// 
/// Self-hosted PostgreSQL database on Contabo VPS
/// Cost: ₹9,600/year (much cheaper than Railway!)
class ContaboDatabaseConfig {
  // Contabo VPS connection details
  // Get these from Contabo VPS dashboard
  static const String host = 'YOUR_CONTABO_VPS_IP';
  static const int port = 5432;
  static const String databaseName = 'attendance_db';
  static const String username = 'attendance_user';
  static const String password = 'YOUR_SECURE_PASSWORD';
  
  // Connection string for PostgreSQL
  static String get connectionString => 
    'postgresql://$username:$password@$host:$port/$databaseName';
  
  // VPS Specifications
  // Plan: VPS M
  // - 4 vCPU cores
  // - 8 GB RAM
  // - 400 GB SSD (200GB base + 200GB upgrade)
  // Cost: ₹9,600/year (₹800/month)
  
  // Benefits:
  // - Unlimited database operations (no per-query charges)
  // - Full control over database
  // - Much cheaper than Railway (₹73,488/year vs ₹9,600/year)
  // - 87% cost savings!
}
