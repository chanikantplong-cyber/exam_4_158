import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' | 'operator'

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: d['uid'] ?? doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      role: d['role'] ?? 'operator',
    );
  }

  Map<String, dynamic> toMap() =>
      {'uid': uid, 'name': name, 'email': email, 'role': role};
}
