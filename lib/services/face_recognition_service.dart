import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  // Extract face features from an image
  static Future<Map<String, dynamic>?> extractFaceFeatures(String imagePath) async {
    if (kIsWeb) return null;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (kDebugMode) debugPrint('❌ No face detected in image');
        return null;
      }

      if (faces.length > 1) {
        if (kDebugMode) debugPrint('⚠️ Multiple faces detected, using first face');
      }

      final face = faces.first;

      // Extract face features (landmarks, bounding box, etc.)
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

      if (kDebugMode) debugPrint('✅ Face features extracted successfully');
      return features;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error extracting face features: $e');
      return null;
    }
  }

  // Extract face landmarks
  static Map<String, dynamic> _extractLandmarks(Face face) {
    final landmarks = <String, dynamic>{};

    // Extract key facial landmarks
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

    for (var type in landmarkTypes) {
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

  // Calculate similarity between two face feature sets
  static double calculateSimilarity(
    Map<String, dynamic> features1,
    Map<String, dynamic> features2,
  ) {
    try {
      double similarity = 0.0;
      int comparisons = 0;

      // Compare head angles
      final angleY1 = features1['headEulerAngleY'] as double? ?? 0.0;
      final angleY2 = features2['headEulerAngleY'] as double? ?? 0.0;
      final angleZ1 = features1['headEulerAngleZ'] as double? ?? 0.0;
      final angleZ2 = features2['headEulerAngleZ'] as double? ?? 0.0;

      final angleDiffY = (angleY1 - angleY2).abs();
      final angleDiffZ = (angleZ1 - angleZ2).abs();
      final angleSimilarity = 1.0 - ((angleDiffY + angleDiffZ) / 180.0).clamp(0.0, 1.0);
      similarity += angleSimilarity;
      comparisons++;

      // Compare landmarks if available
      final landmarks1 = features1['landmarks'] as Map<String, dynamic>? ?? {};
      final landmarks2 = features2['landmarks'] as Map<String, dynamic>? ?? {};

      if (landmarks1.isNotEmpty && landmarks2.isNotEmpty) {
        double landmarkSimilarity = 0.0;
        int landmarkCount = 0;

        for (var key in landmarks1.keys) {
          if (landmarks2.containsKey(key)) {
            final l1 = landmarks1[key] as Map<String, dynamic>;
            final l2 = landmarks2[key] as Map<String, dynamic>;
            final x1 = l1['x'] as double? ?? 0.0;
            final y1 = l1['y'] as double? ?? 0.0;
            final x2 = l2['x'] as double? ?? 0.0;
            final y2 = l2['y'] as double? ?? 0.0;

            // Normalize by bounding box size
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

      // Compare eye probabilities
      final leftEye1 = features1['leftEyeOpenProbability'] as double? ?? 0.5;
      final leftEye2 = features2['leftEyeOpenProbability'] as double? ?? 0.5;
      final rightEye1 = features1['rightEyeOpenProbability'] as double? ?? 0.5;
      final rightEye2 = features2['rightEyeOpenProbability'] as double? ?? 0.5;

      final eyeSimilarity = 1.0 - ((leftEye1 - leftEye2).abs() + (rightEye1 - rightEye2).abs()) / 2.0;
      similarity += eyeSimilarity;
      comparisons++;

      return comparisons > 0 ? (similarity / comparisons).clamp(0.0, 1.0) : 0.0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error calculating similarity: $e');
      return 0.0;
    }
  }

  // Find matching student from attendance photo
  static Future<Map<String, dynamic>?> identifyStudent(
    String attendancePhotoPath,
    String instituteId,
  ) async {
    if (kIsWeb) return null;

    try {
      // Extract features from attendance photo
      final attendanceFeatures = await extractFaceFeatures(attendancePhotoPath);
      if (attendanceFeatures == null) {
        if (kDebugMode) debugPrint('❌ Could not extract features from attendance photo');
        return null;
      }

      // Load all students with face templates
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        if (kDebugMode) debugPrint('⚠️ No students found in institute');
        return null;
      }

      double bestSimilarity = 0.0;
      Map<String, dynamic>? bestMatch;

      // Compare with each student's face template
      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final faceTemplate = studentData['faceTemplate'] as Map<String, dynamic>?;

        if (faceTemplate == null) continue;

        final similarity = calculateSimilarity(attendanceFeatures, faceTemplate);
        if (kDebugMode) {
          debugPrint('🎯 Student ${studentData['rollNumber']}: Similarity = ${(similarity * 100).toStringAsFixed(1)}%');
        }

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

      // Return match if confidence is high enough (>= 70%)
      if (bestMatch != null && bestSimilarity >= 0.70) {
        if (kDebugMode) {
          debugPrint('✅ Student identified: ${bestMatch['name']} (Roll ${bestMatch['rollNumber']}) - ${(bestSimilarity * 100).toStringAsFixed(1)}% match');
        }
        return bestMatch;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ No confident match found. Best similarity: ${(bestSimilarity * 100).toStringAsFixed(1)}%');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error identifying student: $e');
      return null;
    }
  }

  // Save face template for a student
  static Future<bool> saveFaceTemplate(
    String imagePath,
    String instituteId,
    String rollNumber,
    String studentId,
  ) async {
    if (kIsWeb) return false;

    try {
      // Extract face features
      final features = await extractFaceFeatures(imagePath);
      if (features == null) {
        if (kDebugMode) debugPrint('❌ Could not extract face features');
        return false;
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .doc(studentId)
          .update({
        'faceTemplate': features,
        'faceTemplateUpdated': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) debugPrint('✅ Face template saved for Roll $rollNumber');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving face template: $e');
      return false;
    }
  }

  // Verify if scanned face matches the selected roll number
  static Future<bool> verifyStudent(
    String attendancePhotoPath,
    String instituteId,
    String rollNumber,
  ) async {
    if (kIsWeb) return false;

    try {
      // Extract features from attendance photo
      final attendanceFeatures = await extractFaceFeatures(attendancePhotoPath);
      if (attendanceFeatures == null) {
        if (kDebugMode) debugPrint('❌ Could not extract features from attendance photo');
        return false;
      }

      // Find student by roll number
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .where('userId', isEqualTo: rollNumber)
          .limit(1)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        if (kDebugMode) debugPrint('⚠️ Student with roll number $rollNumber not found');
        return false;
      }

      final studentDoc = studentsSnapshot.docs.first;
      final studentData = studentDoc.data();
      final faceTemplate = studentData['faceTemplate'] as Map<String, dynamic>?;

      if (faceTemplate == null) {
        if (kDebugMode) debugPrint('⚠️ Student $rollNumber does not have a face template');
        return false;
      }

      // Compare face features
      final similarity = calculateSimilarity(attendanceFeatures, faceTemplate);
      
      if (kDebugMode) {
        debugPrint('🎯 Face verification for Roll $rollNumber: ${(similarity * 100).toStringAsFixed(1)}% match');
      }

      // Return true if similarity is >= 70%
      return similarity >= 0.70;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error verifying student: $e');
      return false;
    }
  }

  // Check if student has face template
  static Future<bool> hasFaceTemplate(String instituteId, String studentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .doc(studentId)
          .get();

      if (!doc.exists) return false;
      final data = doc.data();
      return data?['faceTemplate'] != null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error checking face template: $e');
      return false;
    }
  }
}
