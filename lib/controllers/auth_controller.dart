import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthController {
  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');

  Future<void> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    await _ensureUserDoc(cred.user!);
  }

  /// สร้างเอกสารใน collection users (uid, name, email, role) หากยังไม่มี
  Future<void> _ensureUserDoc(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final email = user.email ?? '';
    final role = email.toLowerCase() == 'admin@test.com' ? 'admin' : 'operator';
    final appUser = AppUser(
      uid: user.uid,
      name: email.split('@').first,
      email: email,
      role: role,
    );
    await ref.set(appUser.toMap());
  }

  Stream<AppUser> userStream(String uid) =>
      _users.doc(uid).snapshots().map((d) => AppUser.fromDoc(d));

  Future<void> signOut() => _auth.signOut();
}
