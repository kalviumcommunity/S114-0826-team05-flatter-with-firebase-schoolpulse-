import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _updateLastLogin(credential.user!.uid);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? districtId,
    String? schoolId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName(displayName);

      // Get or create default district and school
      final district = await _getOrCreateDefaultDistrict(districtId);
      final school = await _getOrCreateDefaultSchool(schoolId, district.id);

      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
        districtId: district.id,
        schoolId: school?.id,
        isActive: true,
        permissions: role.defaultPermissions,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(credential.user!.uid).set(userModel.toJson());

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<DistrictModel> _getOrCreateDefaultDistrict(String? preferredDistrictId) async {
    if (preferredDistrictId != null) {
      final doc = await _firestore.collection('districts').doc(preferredDistrictId).get();
      if (doc.exists) {
        return DistrictModel.fromFirestore(doc);
      }
    }

    // Check for existing default district
    final query = await _firestore
        .collection('districts')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return DistrictModel.fromFirestore(query.docs.first);
    }

    // Create default district
    const districtId = 'default-district';
    final district = DistrictModel(
      id: districtId,
      name: 'Default District',
      code: 'DEF',
      address: '123 Education St',
      phone: '+1-555-0000',
      email: 'admin@defaultdistrict.edu',
      superintendentName: 'Superintendent',
      isActive: true,
      settings: {},
      createdAt: DateTime.now(),
    );

    await _firestore.collection('districts').doc(districtId).set(district.toJson());
    return district;
  }

  Future<SchoolModel?> _getOrCreateDefaultSchool(String? preferredSchoolId, String districtId) async {
    if (preferredSchoolId != null) {
      final doc = await _firestore.collection('schools').doc(preferredSchoolId).get();
      if (doc.exists) {
        return SchoolModel.fromFirestore(doc);
      }
    }

    // Check for existing school in district
    final query = await _firestore
        .collection('schools')
        .where('districtId', isEqualTo: districtId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return SchoolModel.fromFirestore(query.docs.first);
    }

    // Create default school
    const schoolId = 'default-school';
    final school = SchoolModel(
      id: schoolId,
      districtId: districtId,
      name: 'Default School',
      code: 'DEF',
      type: SchoolType.k12,
      address: '123 School St',
      phone: '+1-555-0100',
      email: 'admin@defaultschool.edu',
      principalName: 'Principal',
      principalPhone: '+1-555-0101',
      principalEmail: 'principal@defaultschool.edu',
      totalCapacity: 500,
      currentEnrollment: 0,
      gradeLevels: ['K', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'],
      isActive: true,
      settings: {},
      createdAt: DateTime.now(),
    );

    await _firestore.collection('schools').doc(schoolId).set(school.toJson());
    return school;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    await _firestore.collection('users').doc(user.uid).update({
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> updateUserRole(String uid, UserRole role, {String? schoolId}) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.value,
      'permissions': role.defaultPermissions,
      if (schoolId != null) 'schoolId': schoolId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deactivateUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'operation-not-allowed':
        return Exception('Email/password accounts are not enabled.');
      default:
        return Exception('Authentication error: ${e.message}');
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});