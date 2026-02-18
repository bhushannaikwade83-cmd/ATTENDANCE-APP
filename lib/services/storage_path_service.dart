class StoragePathService {
  static String sanitize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'unknown';
    return trimmed
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '')
        .toLowerCase();
  }

  static String buildAttendancePhotoPath({
    required String instituteName,
    required String batchName,
    required String subject,
    required String studentName,
    required String date,
    required String lectureKey,
  }) {
    final safeInstitute = sanitize(instituteName);
    final safeBatch = sanitize(batchName);
    final safeSubject = sanitize(subject);
    final safeStudent = sanitize(studentName);
    final safeDate = sanitize(date);
    final safeLecture = sanitize(lectureKey);
    final ts = DateTime.now().millisecondsSinceEpoch;

    return 'attendance/$safeInstitute/$safeBatch/$safeSubject/$safeStudent/$safeDate/${safeLecture}_$ts.jpg';
  }
}
