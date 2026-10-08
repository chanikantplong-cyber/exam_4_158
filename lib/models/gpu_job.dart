import 'package:cloud_firestore/cloud_firestore.dart';

class GpuJob {
  final String? id;
  final String experimentName;
  final String framework;
  final String researcherEmail;
  final int gpus;
  final int maxHours;

  GpuJob({
    this.id,
    required this.experimentName,
    required this.framework,
    required this.researcherEmail,
    required this.gpus,
    required this.maxHours,
  });

  factory GpuJob.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return GpuJob(
      id: doc.id,
      experimentName: d['experimentName'] ?? '',
      framework: d['framework'] ?? '',
      researcherEmail: d['researcherEmail'] ?? '',
      gpus: (d['gpus'] ?? 0) as int,
      maxHours: (d['maxHours'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'experimentName': experimentName,
        'framework': framework,
        'researcherEmail': researcherEmail,
        'gpus': gpus,
        'maxHours': maxHours,
      };
}
