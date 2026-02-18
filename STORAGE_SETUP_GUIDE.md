# Appwrite Storage Setup Guide

## Storage Folder Structure

Photos are organized in the following hierarchical structure:

```
institute_id/
  batch_year/
    rollNumber/
      subject/
        YYYY-MM-DD/
          photo.jpg
```

### Example:
```
6981f623001657ab0c90/
  2024/
    STU001/
      mathematics/
        2024-02-03/
          photo.jpg
      physics/
        2024-02-03/
          photo.jpg
    STU002/
      mathematics/
        2024-02-03/
          photo.jpg
```

---

## Step 1: Create Storage Bucket in Appwrite Console

### Manual Setup (Recommended)

1. Go to [Appwrite Console](https://cloud.appwrite.io)
2. Select your project: **ATTENDANCE APP**
3. Go to **Storage** (left sidebar)
4. Click **"Create Bucket"**
5. Fill in the details:
   - **Name:** `Attendance Photos Bucket`
   - **Bucket ID:** `photos_bucket`
   - **File size limit:** `10 MB` (or as needed)
   - **Allowed file extensions:** `jpg`, `jpeg`, `png`
   - **Compression:** `none` (or `gzip` if preferred)
   - **Encryption:** `false` (or enable if needed)
   - **Antivirus:** `false` (or enable if needed)
6. **Permissions:**
   - ✅ Read: `users` (any authenticated user)
   - ✅ Create: `users` (any authenticated user)
   - ✅ Update: `users` (any authenticated user)
   - ✅ Delete: `users` (any authenticated user)
7. Click **"Create"**

### Automated Setup (Requires API Key with Storage Scopes)

If you have an API key with `buckets.write` scope:

```bash
dart scripts/setup_appwrite_storage.dart
```

**Note:** You'll need to create a new API key with storage scopes:
- Go to **Settings** → **API Keys**
- Create new key with scopes: `buckets.read`, `buckets.write`, `files.read`, `files.write`

---

## Step 2: Storage Service Usage

The `StorageService` class handles all photo uploads with the proper folder structure.

### Upload Attendance Photo

```dart
import 'package:your_app/services/storage_service.dart';

// Upload photo
final uploadResult = await StorageService.uploadAttendancePhoto(
  instituteId: 'institute_123',
  batchYear: '2024',
  rollNumber: 'STU001',
  subject: 'Mathematics',
  date: '2024-02-03',
  photoBytes: imageBytes,
);

final photoUrl = uploadResult['url'];
final storagePath = uploadResult['path'];
```

### Get Photo URL

```dart
final photoUrl = StorageService.getPhotoUrl(fileId);
```

### List Student Photos

```dart
final photos = await StorageService.listStudentPhotos(
  instituteId: 'institute_123',
  batchYear: '2024',
  rollNumber: 'STU001',
  subject: 'Mathematics', // Optional filter
  date: '2024-02-03',     // Optional filter
);
```

### Delete Photo

```dart
await StorageService.deleteAttendancePhoto(fileId);
```

---

## Step 3: Integration with Attendance Screen

The `admin_attendance_screen.dart` has been updated to use the new storage structure:

```dart
// Get batch year from selected batch
final batchYear = selectedBatch?['year']?.toString() ?? DateTime.now().year.toString();

// Upload using StorageService
final uploadResult = await StorageService.uploadAttendancePhoto(
  instituteId: instituteId!,
  batchYear: batchYear,
  rollNumber: selectedRollNumber!,
  subject: selectedSubject!,
  date: today,
  photoBytes: bytes,
);
```

---

## Storage Path Generation

The `generatePhotoPath()` method creates paths following this pattern:

```
{instituteId}/{batchYear}/{rollNumber}/{subject}/{date}/photo.jpg
```

**Path Cleaning:**
- Subject names: Spaces → underscores, special chars removed, lowercase
- Roll numbers: Special chars removed
- Dates: Format `YYYY-MM-DD`

**Example:**
- Input: `instituteId='INST001'`, `batchYear='2024'`, `rollNumber='STU-001'`, `subject='Mathematics & Physics'`, `date='2024-02-03'`
- Output: `INST001/2024/STU001/mathematics_physics/2024-02-03/photo.jpg`

---

## File Naming Convention

### File ID Format
File IDs are generated from the storage path:
- Path: `INST001/2024/STU001/mathematics/2024-02-03/photo.jpg`
- File ID: `INST001_2024_STU001_mathematics_2024-02-03_photo_jpg`

This ensures:
- ✅ Unique file IDs
- ✅ Easy path reconstruction
- ✅ Searchable by pattern

---

## Benefits of This Structure

1. **Organized by Institute:** Easy to manage per-institute storage
2. **Organized by Batch Year:** Photos grouped by academic year
3. **Organized by Student:** All photos for a student in one place
4. **Organized by Subject:** Easy to find subject-specific photos
5. **Organized by Date:** Daily attendance photos grouped together
6. **Easy Cleanup:** Can delete entire batch year folders after batch ends
7. **Efficient Queries:** Can list photos by any level (institute, batch, student, subject, date)

---

## Storage Lifecycle Management

### Auto-Deletion After Batch Ends

To automatically delete photos after a batch ends (e.g., 6 months):

1. **Option A: Appwrite Functions (Scheduled)**
   - Create a scheduled function
   - Run monthly/quarterly
   - Delete files older than batch end date

2. **Option B: GCS Lifecycle Policies** (if using GCS backend)
   - Set lifecycle rule: delete objects older than 180 days
   - Applies automatically to all files

3. **Option C: Manual Script**
   ```dart
   // List all files for a batch year
   // Delete files older than batch end date
   ```

---

## Storage Costs

### Estimated Storage per Student per Batch

- **Photos per day:** 12 (one per subject)
- **Working days:** 130 days per 6-month batch
- **Total photos:** 12 × 130 = 1,560 photos per student
- **Photo size:** ~0.2 MB each
- **Storage per student:** 1,560 × 0.2 MB = ~312 MB

### For 40 Students per Batch

- **Storage per batch:** 40 × 312 MB = ~12.5 GB

### For 3,000 Institutes (2 batches each)

- **Total storage:** 3,000 × 2 × 12.5 GB = ~75 TB
- **With auto-deletion:** Stays at ~75 TB (rolling 6-month window)

---

## Troubleshooting

### Error: "Bucket not found"
- Verify bucket ID in `appwrite_config.dart` matches console
- Check bucket exists in Appwrite Console → Storage

### Error: "Permission denied"
- Verify storage permissions allow `users` to create/read files
- Check user is authenticated

### Error: "File size limit exceeded"
- Check file size is under bucket limit (default: 10 MB)
- Compress images before upload if needed

### Photos not organizing correctly
- Verify `batchYear` field exists in batch document
- Check `StorageService.generatePhotoPath()` output
- Verify file ID generation matches expected pattern

---

## Next Steps

1. ✅ Create storage bucket in Appwrite Console
2. ✅ Verify bucket permissions
3. ✅ Test photo upload with new structure
4. ✅ Verify photos are organized correctly
5. ✅ Set up auto-deletion (if needed)
6. ✅ Monitor storage usage

---

## Related Files

- `lib/services/storage_service.dart` - Storage service implementation
- `lib/presentation/screens/admin_attendance_screen.dart` - Updated to use new structure
- `scripts/setup_appwrite_storage.dart` - Automated bucket creation script
- `lib/appwrite_config.dart` - Storage bucket configuration
