import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/gpu_job.dart';

class FirestoreController {
  final _col = FirebaseFirestore.instance.collection('gpu_jobs');

  // Create
  Future<void> addJob(GpuJob job) async {
    await _col.add({
      ...job.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Read (Real-time)
  Stream<QuerySnapshot<Map<String, dynamic>>> jobsStream() =>
      _col.snapshots();

  // Update
  Future<void> updateJob(String id, GpuJob job) async {
    await _col.doc(id).update(job.toMap());
  }

  // Delete
  Future<void> deleteJob(String id) async {
    await _col.doc(id).delete();
  }
}
