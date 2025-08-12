import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_settings.dart';

class UserSettingsService {
  UserSettingsService._();
  static final instance = UserSettingsService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _doc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    return _firestore.collection('users').doc(uid);
  }

  Stream<UserSettings> stream() {
    return _doc().snapshots().map((snap) => UserSettings.fromMap(snap.data()));
  }

  Future<UserSettings> getOnce() async {
    final snap = await _doc().get();
    return UserSettings.fromMap(snap.data());
  }

  Future<void> save(UserSettings settings) async {
    await _doc().set(settings.toMap(), SetOptions(merge: true));
    // Also update FirebaseAuth displayName for consistency
    if (_auth.currentUser != null && settings.displayName.isNotEmpty) {
      await _auth.currentUser!.updateDisplayName(settings.displayName);
    }
  }
}
