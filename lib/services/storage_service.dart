import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Upload a file to Firebase Storage
  /// Returns the download URL
  Future<String> uploadFile({
    required String path,
    required File file,
    String? customFileName,
    Map<String, String>? metadata,
  }) async {
    try {
      final fileName = customFileName ?? '${_uuid.v4()}_${file.path.split('/').last}';
      final ref = _storage.ref().child('$path/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    }
  }

  /// Upload bytes to Firebase Storage
  Future<String> uploadBytes({
    required String path,
    required List<int> bytes,
    required String fileName,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final ref = _storage.ref().child('$path/$fileName');
      final SettableMetadata metadataObj = SettableMetadata(
        contentType: contentType,
        customMetadata: metadata,
      );

      final uploadTask = ref.putData(Uint8List.fromList(bytes), metadataObj);
      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        throw Exception('Delete failed: ${e.message}');
      }
    }
  }

  /// Get download URL for a file path
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Failed to get download URL: ${e.message}');
    }
  }

  /// Upload student profile picture
  Future<String> uploadStudentPhoto(String studentId, File file) async {
    return uploadFile(
      path: 'students/photos',
      file: file,
      customFileName: '${studentId}_profile.jpg',
    );
  }

  /// Upload school logo
  Future<String> uploadSchoolLogo(String schoolId, File file) async {
    return uploadFile(
      path: 'schools/logos',
      file: file,
      customFileName: '${schoolId}_logo.jpg',
    );
  }

  /// Upload district logo
  Future<String> uploadDistrictLogo(String districtId, File file) async {
    return uploadFile(
      path: 'districts/logos',
      file: file,
      customFileName: '${districtId}_logo.jpg',
    );
  }

  /// Upload fee receipt
  Future<String> uploadFeeReceipt(String feeId, File file) async {
    return uploadFile(
      path: 'fees/receipts',
      file: file,
      customFileName: '${feeId}_receipt.jpg',
    );
  }

  /// Upload student document
  Future<String> uploadStudentDocument(String studentId, File file, String documentType) async {
    return uploadFile(
      path: 'students/documents',
      file: file,
      customFileName: '${studentId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Upload exam document
  Future<String> uploadExamDocument(String examId, File file) async {
    return uploadFile(
      path: 'exams/documents',
      file: file,
      customFileName: '${examId}_document_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// List files in a directory
  Future<List<Reference>> listFiles(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();
      return result.items;
    } on FirebaseException catch (e) {
      throw Exception('Failed to list files: ${e.message}');
    }
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } on FirebaseException catch (e) {
      throw Exception('Failed to get metadata: ${e.message}');
    }
  }

  /// Update file metadata
  Future<void> updateFileMetadata(String downloadUrl, SettableMetadata metadata) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.updateMetadata(metadata);
    } on FirebaseException catch (e) {
      throw Exception('Failed to update metadata: ${e.message}');
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());