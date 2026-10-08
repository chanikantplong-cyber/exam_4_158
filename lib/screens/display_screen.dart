import 'package:flutter/material.dart';

import '../controllers/firestore_controller.dart';
import '../main.dart';
import '../models/app_user.dart';
import '../models/gpu_job.dart';
import '../widgets/code_inspector.dart';
import '../widgets/job_form.dart';

/// แท็บ 2 (Display) - จอมอนิเตอร์คิวงาน GPU
class DisplayScreen extends StatelessWidget {
  final AppUser user;
  final FirestoreController db;
  const DisplayScreen({super.key, required this.user, required this.db});

  Color _frameworkColor(String f) {
    switch (f.toLowerCase()) {
      case 'pytorch':
        return const Color(0xFFFF7A45);
      case 'tensorflow':
        return const Color(0xFFFFC53D);
      case 'jax':
        return const Color(0xFFB37FEB);
      default:
        return AppColors.accent2;
    }
  }

  Future<void> _confirmDelete(BuildContext context, GpuJob job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.danger, size: 40),
        title: const Text('Terminate Job'),
        content: Text('ต้องการสั่ง Terminate งาน "${job.experimentName}" '
            'ที่รันค้างหรือไม่เกิดผลใช่หรือไม่?\nการลบไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
    if (ok == true && job.id != null) {
      await db.deleteJob(job.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Terminate งานเรียบร้อยแล้ว')));
      }
    }
  }

  void _edit(BuildContext context, GpuJob job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const Text('แก้ไขคำขอ / Edit Job')),
          body: JobForm(
            job: job,
            submitLabel: 'บันทึกการแก้ไข',
            onSubmit: (updated) async {
              await db.updateJob(job.id!, updated);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: AppColors.accent,
                    content: Text('อัปเดตข้อมูลสำเร็จ',
                        style: TextStyle(color: Colors.black))));
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: db.jobsStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }
        final jobs = snap.data!.docs.map(GpuJob.fromDoc).toList();
        final totalGpus = jobs.fold<int>(0, (s, j) => s + j.gpus);

        if (jobs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.dns_rounded, size: 72, color: AppColors.textDim),
              SizedBox(height: 12),
              Text('ยังไม่มีงานในคิว',
                  style: TextStyle(color: AppColors.textDim, fontSize: 16)),
            ]),
          );
        }

        return Column(
          children: [
            // สรุปภาพรวม
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0E5C4F), Color(0xFF123E73)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(label: 'Jobs ในคิว', value: '${jobs.length}'),
                    Container(width: 1, height: 36, color: Colors.white24),
                    _Stat(label: 'GPU ที่จองรวม', value: '$totalGpus'),
                  ],
                ),
              ).explain('display_summary'),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: jobs.length,
                itemBuilder: (context, i) {
                  final job = jobs[i];
                  final color = _frameworkColor(job.framework);
                  return Card(
                    margin: const EdgeInsets.only(top: 10),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.accent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${job.gpus}',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            const Text('GPU',
                                style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ).explain('display_avatar'),
                      title: Text(job.experimentName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))
                          .explain('display_title'),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(job.framework,
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ).explain('display_badge'),
                              const SizedBox(width: 10),
                              const Icon(Icons.timer_outlined,
                                  size: 15, color: AppColors.textDim),
                              const SizedBox(width: 3),
                              Text('${job.maxHours} ชม.',
                                  style: const TextStyle(
                                      color: AppColors.textDim)),
                            ]),
                            const SizedBox(height: 4),
                            Text(job.researcherEmail,
                                style: const TextStyle(
                                    color: AppColors.textDim, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Operator: ซ่อนปุ่ม Edit / Delete
                      trailing: user.isAdmin
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_rounded,
                                    color: AppColors.accent2),
                                onPressed: () => _edit(context, job),
                              ).explain('display_edit'),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_rounded,
                                    color: AppColors.danger),
                                onPressed: () => _confirmDelete(context, job),
                              ).explain('display_delete'),
                            ])
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}
