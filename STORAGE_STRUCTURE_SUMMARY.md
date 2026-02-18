# Storage Structure Summary

## ✅ What Has Been Set Up

### 1. Storage Service Created
- **File:** `lib/services/storage_service.dart`
- **Purpose:** Handles photo uploads with organized folder structure
- **Structure:** `institute_id/batch_year/rollNumber/subject/YYYY-MM-DD/photo.jpg`

### 2. Attendance Screen Updated
- **File:** `lib/presentation/screens/admin_attendance_screen.dart`
- **Changes:** Now uses `StorageService` for photo uploads
- **Path Generation:** Automatically creates organized paths based on batch year

### 3. Storage Setup Script
- **File:** `scripts/setup_appwrite_storage.dart`
- **Purpose:** Automated bucket creation (requires API key with storage scopes)

### 4. Documentation
- **File:** `STORAGE_SETUP_GUIDE.md`
- **Content:** Complete setup instructions and usage guide

---

## 📁 Folder Structure

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
```

---

## 🔧 Next Steps

### 1. Create Storage Bucket (Manual - Recommended)

1. Go to [Appwrite Console](https://cloud.appwrite.io)
2. Select project: **ATTENDANCE APP**
3. Go to **Storage** → **Create Bucket**
4. **Bucket ID:** `photos_bucket`
5. **Name:** `Attendance Photos Bucket`
6. **File size limit:** `10 MB`
7. **Allowed extensions:** `jpg`, `jpeg`, `png`
8. **Permissions:** 
   - Read: `users`
   - Create: `users`
   - Update: `users`
   - Delete: `users`

### 2. Verify Configuration

Check `lib/appwrite_config.dart`:
```dart
static const String storageBucketId = 'photos_bucket';
```

### 3. Test Photo Upload

The attendance screen will now automatically:
- Extract batch year from selected batch
- Generate organized storage path
- Upload photo with proper structure
- Store path in database

---

## 📝 How It Works

### When Marking Attendance:

1. **User selects:**
   - Institute
   - Batch (contains `year` field)
   - Subject
   - Roll Number
   - Date

2. **System generates path:**
   ```dart
   instituteId/batchYear/rollNumber/subject/date/photo.jpg
   ```

3. **Photo uploaded:**
   - File stored in Appwrite Storage
   - Path stored in database document
   - URL generated for access

4. **Database record:**
   ```json
   {
     "rollNumber": "STU001",
     "subject": "Mathematics",
     "date": "2024-02-03",
     "photoUrl": "https://...",
     "storagePath": "INST001/2024/STU001/mathematics/2024-02-03/photo.jpg",
     "batchYear": "2024",
     "instituteId": "INST001"
   }
   ```

---

## 🎯 Benefits

✅ **Organized Structure:** Easy to find photos by institute, batch, student, subject, or date

✅ **Efficient Cleanup:** Can delete entire batch year folders after batch ends

✅ **Scalable:** Structure supports thousands of institutes and students

✅ **Maintainable:** Clear organization makes management easier

✅ **Query-Friendly:** Can list photos by any level of the hierarchy

---

## ⚠️ Important Notes

1. **Appwrite Storage is Flat:** Appwrite doesn't have true folders, but we simulate them using:
   - Path stored in filename (if supported)
   - Path stored in database document
   - Logical organization for queries

2. **Batch Year Required:** Make sure batch documents have a `year` field

3. **Path Cleaning:** Subject names and roll numbers are cleaned (spaces → underscores, special chars removed)

4. **File IDs:** Appwrite generates unique file IDs, but we store the logical path separately

---

## 🔍 Verification Checklist

- [ ] Storage bucket `photos_bucket` created in Appwrite Console
- [ ] Bucket permissions set to allow `users` read/create/update/delete
- [ ] `storageBucketId` in `appwrite_config.dart` matches bucket ID
- [ ] Batch documents have `year` field
- [ ] Test photo upload works
- [ ] Photos are organized correctly
- [ ] Database records include `storagePath` field

---

## 📚 Related Files

- `lib/services/storage_service.dart` - Storage service implementation
- `lib/presentation/screens/admin_attendance_screen.dart` - Updated attendance screen
- `scripts/setup_appwrite_storage.dart` - Bucket creation script
- `STORAGE_SETUP_GUIDE.md` - Detailed setup guide
- `lib/appwrite_config.dart` - Configuration file
