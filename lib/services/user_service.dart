import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final _col = FirebaseFirestore.instance.collection('users');

  Future<AppUser?> fetchUser(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return AppUser.fromMap(uid, data);
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? photoURL,
  }) async {
    final Map<String, dynamic> patch = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) patch['displayName'] = displayName;
    if (photoURL != null) patch['photoURL'] = photoURL;

    await _col.doc(uid).set(
      patch,
      SetOptions(merge: true),
    );
  }

  Future<void> saveOnboarding({
    required String uid,
    required String businessName,
    required String rubro,
    String? logoUrl,
    required String primaryColor,
    required String fontStyle,
  }) async {
    final Map<String, dynamic> patch = {
      'businessName': businessName,
      'rubro': rubro,
      'primaryColor': primaryColor,
      'fontStyle': fontStyle,
      'onboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (logoUrl != null) patch['logoUrl'] = logoUrl;

    await _col.doc(uid).set(patch, SetOptions(merge: true));
  }
}
