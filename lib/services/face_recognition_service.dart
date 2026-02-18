import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceRecognitionService {
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: false,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  static Future<Map<String, dynamic>?> extractFaceFeatures(String imagePath) async {
    if (kIsWeb) return null;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (kDebugMode) debugPrint('No face detected in image');
        return null;
      }

      final face = faces.first;
      final features = {
        'boundingBox': {
          'left': face.boundingBox.left,
          'top': face.boundingBox.top,
          'width': face.boundingBox.width,
          'height': face.boundingBox.height,
        },
        'headEulerAngleY': face.headEulerAngleY,
        'headEulerAngleZ': face.headEulerAngleZ,
        'leftEyeOpenProbability': face.leftEyeOpenProbability,
        'rightEyeOpenProbability': face.rightEyeOpenProbability,
        'smilingProbability': face.smilingProbability,
        'landmarks': _extractLandmarks(face),
      };

      return features;
    } catch (e) {
      if (kDebugMode) debugPrint('Error extracting face features: $e');
      return null;
    }
  }

  static Map<String, dynamic> _extractLandmarks(Face face) {
    final landmarks = <String, dynamic>{};
    final landmarkTypes = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
    ];

    for (final type in landmarkTypes) {
      final landmark = face.landmarks[type];
      if (landmark != null) {
        landmarks[type.toString()] = {
          'x': landmark.position.x,
          'y': landmark.position.y,
        };
      }
    }

    return landmarks;
  }

  static double calculateSimilarity(Map<String, dynamic> features1, Map<String, dynamic> features2) {
    try {
      double similarity = 0.0;
      int comparisons = 0;

      final angleY1 = features1['headEulerAngleY'] as double? ?? 0.0;
      final angleY2 = features2['headEulerAngleY'] as double? ?? 0.0;
      final angleZ1 = features1['headEulerAngleZ'] as double? ?? 0.0;
      final angleZ2 = features2['headEulerAngleZ'] as double? ?? 0.0;

      final angleDiffY = (angleY1 - angleY2).abs();
      final angleDiffZ = (angleZ1 - angleZ2).abs();
      final angleSimilarity = 1.0 - ((angleDiffY + angleDiffZ) / 180.0).clamp(0.0, 1.0);
      similarity += angleSimilarity;
      comparisons++;

      final landmarks1 = features1['landmarks'] as Map<String, dynamic>? ?? {};
      final landmarks2 = features2['landmarks'] as Map<String, dynamic>? ?? {};

      if (landmarks1.isNotEmpty && landmarks2.isNotEmpty) {
        double landmarkSimilarity = 0.0;
        int landmarkCount = 0;

        for (final key in landmarks1.keys) {
          if (landmarks2.containsKey(key)) {
            final l1 = landmarks1[key] as Map<String, dynamic>;
            final l2 = landmarks2[key] as Map<String, dynamic>;
            final x1 = l1['x'] as double? ?? 0.0;
            final y1 = l1['y'] as double? ?? 0.0;
            final x2 = l2['x'] as double? ?? 0.0;
            final y2 = l2['y'] as double? ?? 0.0;

            final box1 = features1['boundingBox'] as Map<String, dynamic>? ?? {};
            final box2 = features2['boundingBox'] as Map<String, dynamic>? ?? {};
            final width1 = box1['width'] as double? ?? 1.0;
            final height1 = box1['height'] as double? ?? 1.0;
            final width2 = box2['width'] as double? ?? 1.0;
            final height2 = box2['height'] as double? ?? 1.0;

            final normX1 = x1 / width1;
            final normY1 = y1 / height1;
            final normX2 = x2 / width2;
            final normY2 = y2 / height2;

            final distance = ((normX1 - normX2).abs() + (normY1 - normY2).abs()) / 2.0;
            landmarkSimilarity += (1.0 - distance.clamp(0.0, 1.0));
            landmarkCount++;
          }
        }

        if (landmarkCount > 0) {
          similarity += landmarkSimilarity / landmarkCount;
          comparisons++;
        }
      }

      final leftEye1 = features1['leftEyeOpenProbability'] as double? ?? 0.5;
      final leftEye2 = features2['leftEyeOpenProbability'] as double? ?? 0.5;
      final rightEye1 = features1['rightEyeOpenProbability'] as double? ?? 0.5;
      final rightEye2 = features2['rightEyeOpenProbability'] as double? ?? 0.5;

      final eyeSimilarity = 1.0 - ((leftEye1 - leftEye2).abs() + (rightEye1 - rightEye2).abs()) / 2.0;
      similarity += eyeSimilarity;
      comparisons++;

      return comparisons > 0 ? (similarity / comparisons).clamp(0.0, 1.0) : 0.0;
    } catch (e) {
      if (kDebugMode) debugPrint('Error calculating similarity: $e');
      return 0.0;
    }
  }

  static Future<Map<String, dynamic>?> identifyStudent(String attendancePhotoPath, String instituteId) async {
    if (kIsWeb) return null;

    try {
      final attendanceFeatures = await extractFaceFeatures(attendancePhotoPath);
      if (attendanceFeatures == null) return null;

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .get();

      if (studentsSnapshot.docs.isEmpty) return null;

      double bestSimilarity = 0.0;
      Map<String, dynamic>? bestMatch;

      for (final studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final faceTemplate = studentData['faceTemplate'] as Map<String, dynamic>?;
        if (faceTemplate == null) continue;

        final similarity = calculateSimilarity(attendanceFeatures, faceTemplate);
        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatch = {
            'rollNumber': studentData['rollNumber'] ?? studentData['userId'],
            'name': studentData['name'] ?? 'Unknown',
            'similarity': similarity,
            'studentId': studentDoc.id,
          };
        }
      }

      if (bestMatch != null && bestSimilarity >= 0.70) {
        return bestMatch;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error identifying student: $e');
      return null;
    }
  }

  static Future<bool> saveFaceTemplate(String imagePath, String instituteId, String rollNumber, String studentId) async {
    if (kIsWeb) return false;

    try {
      final features = await extractFaceFeatures(imagePath);
      if (features == null) return false;

      await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .doc(studentId)
          .update({
        'faceTemplate': features,
        'faceTemplateUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving face template: $e');
      return false;
    }
  }

  static Future<bool> verifyStudent(String attendancePhotoPath, String instituteId, String rollNumber) async {
    if (kIsWeb) return false;

    try {
      final attendanceFeatures = await extractFaceFeatures(attendancePhotoPath);
      if (attendanceFeatures == null) return false;

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .where('rollNumber', isEqualTo: rollNumber)
          .limit(1)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        final fallback = await FirebaseFirestore.instance
            .collection('institutes')
            .doc(instituteId)
            .collection('students')
            .where('userId', isEqualTo: rollNumber)
            .limit(1)
            .get();
        if (fallback.docs.isEmpty) return false;

        final studentData = fallback.docs.first.data();
        final faceTemplate = studentData['faceTemplate'] as Map<String, dynamic>?;
        if (faceTemplate == null) return false;

        final similarity = calculateSimilarity(attendanceFeatures, faceTemplate);
        return similarity >= 0.70;
      }

      final studentData = studentsSnapshot.docs.first.data();
      final faceTemplate = studentData['faceTemplate'] as Map<String, dynamic>?;
      if (faceTemplate == null) return false;

      final similarity = calculateSimilarity(attendanceFeatures, faceTemplate);
      return similarity >= 0.70;
    } catch (e) {
      if (kDebugMode) debugPrint('Error verifying student: $e');
      return false;
    }
  }

  static Future<bool> hasFaceTemplate(String instituteId, String studentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .doc(studentId)
          .get();

      final data = doc.data();
      return data != null && data['faceTemplate'] != null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error checking face template: $e');
      return false;
    }
  }
}
