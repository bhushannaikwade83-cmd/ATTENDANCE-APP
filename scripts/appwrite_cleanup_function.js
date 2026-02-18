/**
 * Appwrite Function: Delete Old Photos (180-Day Cleanup)
 * 
 * This function deletes photos older than 180 days from Appwrite Storage
 * 
 * Setup:
 * 1. Go to Appwrite Console → Functions
 * 2. Create new function: "delete-old-photos"
 * 3. Set schedule: Run daily (cron: "0 2 * * *" = 2 AM daily)
 * 4. Paste this code
 * 5. Deploy function
 */

const sdk = require('node-appwrite');

module.exports = async (req, res) => {
  const client = new sdk.Client();
  const storage = new sdk.Storage(client);
  
  // Initialize Appwrite client
  client
    .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://fra.cloud.appwrite.io/v1')
    .setProject(process.env.APPWRITE_PROJECT_ID || '6981f623001657ab0c90')
    .setKey(process.env.APPWRITE_API_KEY); // Set in function environment variables
  
  const bucketId = process.env.STORAGE_BUCKET_ID || 'photos_bucket';
  const retentionDays = parseInt(process.env.PHOTO_RETENTION_DAYS || '180');
  
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);
    const cutoffTimestamp = cutoffDate.getTime() / 1000; // Unix timestamp
    
    console.log(`Deleting photos older than ${retentionDays} days (before ${cutoffDate.toISOString()})`);
    
    let deletedCount = 0;
    let totalFiles = 0;
    let offset = 0;
    const limit = 100; // Process 100 files at a time
    
    // List all files in bucket
    while (true) {
      const files = await storage.listFiles(bucketId, [], limit, offset);
      
      if (files.files.length === 0) {
        break; // No more files
      }
      
      totalFiles += files.files.length;
      
      // Check each file
      for (const file of files.files) {
        // Check if file is older than retention period
        const fileDate = new Date(file.$createdAt);
        const fileTimestamp = fileDate.getTime() / 1000;
        
        if (fileTimestamp < cutoffTimestamp) {
          try {
            await storage.deleteFile(bucketId, file.$id);
            deletedCount++;
            console.log(`Deleted: ${file.name} (${file.$id})`);
          } catch (error) {
            console.error(`Failed to delete ${file.$id}:`, error.message);
          }
        }
      }
      
      offset += limit;
      
      // Safety check: don't process more than 10,000 files per run
      if (offset >= 10000) {
        console.log('Reached safety limit of 10,000 files. Will continue in next run.');
        break;
      }
    }
    
    console.log(`Cleanup complete. Processed ${totalFiles} files, deleted ${deletedCount} old files.`);
    
    res.json({
      success: true,
      message: `Deleted ${deletedCount} files older than ${retentionDays} days`,
      processed: totalFiles,
      deleted: deletedCount,
      cutoffDate: cutoffDate.toISOString(),
    });
    
  } catch (error) {
    console.error('Cleanup function error:', error);
    res.json({
      success: false,
      error: error.message,
    }, 500);
  }
};
