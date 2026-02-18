# Applications Architecture - Two Separate Applications

## 🏗️ Architecture Overview

**Two Separate Applications:**

1. **Web Application** - Super Admin Management System (for administrators)
2. **Mobile Attendance Application** - Field Attendance App (for teachers)

---

## 📱 Application 1: Web Application (Super Admin)

### Purpose
**Centralized management system** for Super Admins to manage all 3,000 institutes.

### Who Uses It
- **Super Admins** - Manage all institutes
- **Institute Admins** - Manage their institute
- **System Administrators** - Monitor and maintain system

### Platform
- **Web-based** - Access via browser (desktop, tablet, mobile browser)
- **Hosted on:** A2 Hosting VPS
- **URL:** https://admin.attendanceapp.com (example)

### Key Features

✅ **Institute Management**
- View all 3,000 institutes
- Add/edit/delete institutes
- Bulk operations
- Institute search and filtering

✅ **Student Management**
- View students across all institutes
- Add/edit/delete students
- Bulk import/export
- Student search

✅ **Batch Management**
- Manage batches for all institutes
- Create/edit batches
- Assign subjects

✅ **User Management**
- Manage users across all institutes
- Assign roles
- Manage permissions

✅ **Reports & Analytics**
- System-wide reports
- Institute-specific reports
- Attendance analytics
- Export reports (Excel, PDF)

✅ **System Monitoring**
- System health monitoring
- Performance metrics
- Usage statistics

### Access
- **Login:** Email/password via Firebase Auth
- **Roles:** Super Admin, Institute Admin
- **Access:** Via web browser

---

## 📱 Application 2: Mobile Attendance Application

### Purpose
**Field attendance marking** for teachers to mark student attendance with photo verification.

### Who Uses It
- **Teachers** - Mark attendance for their students
- **Field Staff** - Mark attendance on-site

### Platform
- **Native Mobile Apps** - Android & iOS
- **Available on:** Google Play Store & Apple App Store
- **App Name:** "Attendance App" or similar

### Key Features

✅ **Attendance Marking**
- Select batch
- View student list
- Mark attendance (Present/Absent)
- One-tap attendance marking
- Quick attendance for all students

✅ **Photo Verification**
- Capture photo with camera
- Photo attached to attendance record
- Photo compression (0.1 MB)
- Upload to Scaleway Archive

✅ **GPS Tracking**
- Automatic GPS location capture
- Location stored with attendance
- Location verification

✅ **Offline Support**
- Works offline
- Syncs when online
- Queue attendance for upload

✅ **Quick Login**
- PIN-based quick login
- Fast access
- Secure authentication

✅ **Notifications**
- Push notifications
- Attendance reminders
- System updates

### Access
- **Login:** Email/password or PIN via Firebase Auth
- **Roles:** Teacher (limited access)
- **Access:** Via mobile app (Android/iOS)

---

## 🔄 How They Work Together

### Data Flow

```
┌─────────────────────────┐
│  Web Application        │
│  (Super Admin)          │
│                         │
│  - Manage Institutes    │
│  - Manage Students      │
│  - Manage Users         │
│  - View Reports         │
└───────────┬─────────────┘
            │
            │ Shares Same
            │ Backend
            │
            ▼
┌─────────────────────────┐
│  Backend Services       │
│  - Firebase Auth        │
│  - Contabo PostgreSQL   │
│  - Scaleway Archive     │
└───────────┬─────────────┘
            │
            │ Shares Same
            │ Backend
            │
            ▼
┌─────────────────────────┐
│  Mobile Attendance App  │
│  (Teachers)             │
│                         │
│  - Mark Attendance      │
│  - Capture Photos       │
│  - GPS Tracking         │
└─────────────────────────┘
```

### Shared Backend

**Both applications use:**
- ✅ **Firebase Auth** - Same authentication
- ✅ **Contabo PostgreSQL** - Same database
- ✅ **Scaleway Archive** - Same photo storage
- ✅ **Same API** - RESTful API endpoints

**Data Separation:**
- Data separated by `institute_id` in database
- Role-based access control
- Teachers only see their batches/students

---

## 📊 Feature Comparison

| Feature | Web App (Super Admin) | Mobile App (Attendance) |
|--------|----------------------|------------------------|
| **Purpose** | Management & Administration | Field Attendance Marking |
| **Users** | Super Admins, Institute Admins | Teachers |
| **Platform** | Web Browser | Android/iOS Native App |
| **Institute Management** | ✅ Yes | ❌ No |
| **Student Management** | ✅ Yes | ❌ No (View only) |
| **Batch Management** | ✅ Yes | ❌ No (Select only) |
| **Mark Attendance** | ❌ No | ✅ Yes |
| **Photo Capture** | ❌ No | ✅ Yes |
| **GPS Tracking** | ❌ No | ✅ Yes |
| **Reports** | ✅ Yes (All types) | ✅ Limited (Own batches) |
| **User Management** | ✅ Yes | ❌ No |
| **Offline Support** | ❌ Limited | ✅ Full offline support |
| **Bulk Operations** | ✅ Yes | ❌ No |

---

## 🎯 Use Cases

### Use Case 1: Super Admin Managing System

**User:** Super Admin  
**Application:** Web Application  
**Action:**
1. Login to web app
2. View all 3,000 institutes
3. Select an institute
4. View students, batches, reports
5. Manage users
6. Export reports

**Mobile App:** Not used for this task

---

### Use Case 2: Teacher Marking Attendance

**User:** Teacher  
**Application:** Mobile Attendance App  
**Action:**
1. Open mobile app
2. Login with PIN
3. Select batch
4. View student list
5. Mark attendance (Present/Absent)
6. Capture photo
7. Submit attendance

**Web App:** Not used for this task

---

### Use Case 3: Institute Admin Viewing Reports

**User:** Institute Admin  
**Application:** Web Application  
**Action:**
1. Login to web app
2. View their institute dashboard
3. View attendance reports
4. Export reports
5. Manage students/batches

**Mobile App:** Not typically used (but can mark attendance if needed)

---

## 🔐 Authentication & Access

### Shared Authentication

**Both apps use Firebase Auth:**
- Same login credentials
- Same user accounts
- Role-based access

### Access Control

**Web App Access:**
- Super Admin: All institutes
- Institute Admin: Their institute only
- Teacher: Limited (can view reports)

**Mobile App Access:**
- Teacher: Their batches/students only
- Can mark attendance
- Cannot manage institutes/students

---

## 💾 Data Storage

### Shared Database

**Both apps write to same database:**
- `institutes` table
- `students` table
- `batches` table
- `attendance` table
- `users` table

**Data Isolation:**
- By `institute_id` field
- Role-based filtering
- Teachers only see their data

### Photo Storage

**Both apps use Scaleway Archive:**
- Mobile app uploads photos
- Web app displays photo URLs
- Same storage bucket
- Same lifecycle policies

---

## 🚀 Deployment

### Web Application Deployment

**Platform:** A2 Hosting VPS  
**Technology:** React/Vue.js or Flutter Web  
**URL:** https://admin.attendanceapp.com  
**Access:** Via web browser

### Mobile Application Deployment

**Platform:** Google Play Store & Apple App Store  
**Technology:** Flutter (Android & iOS)  
**App Name:** "Attendance App"  
**Access:** Download from app stores

---

## 📋 Summary

### Two Separate Applications

1. **Web Application (Super Admin)**
   - For: Administrators
   - Purpose: Management & administration
   - Platform: Web browser
   - Features: Institute/student/user management, reports

2. **Mobile Attendance Application**
   - For: Teachers
   - Purpose: Field attendance marking
   - Platform: Android & iOS
   - Features: Mark attendance, photo capture, GPS tracking

### Shared Backend

- Same authentication (Firebase)
- Same database (PostgreSQL)
- Same storage (Scaleway)
- Same API endpoints

**Both applications work together but serve different purposes!** ✅
