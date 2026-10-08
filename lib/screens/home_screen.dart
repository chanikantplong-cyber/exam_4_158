import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/firestore_controller.dart';
import '../main.dart';
import '../models/app_user.dart';
import '../widgets/code_inspector.dart';
import '../widgets/job_form.dart';
import 'display_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _auth = AuthController();
  final _db = FirestoreController();
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser>(
      stream: _auth.userStream(_uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        final user = snap.data!;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Row(children: [
              const Icon(Icons.memory_rounded, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text('GPUGrid',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ]),
            actions: [
              // ปุ่มโหมดตรวจโค้ด: แสดงเฉพาะ Admin
              if (user.isAdmin)
                PopupMenuButton<String>(
                  tooltip: 'ตรวจโค้ด',
                  icon: ValueListenableBuilder<bool>(
                    valueListenable: CodeInspector.enabled,
                    builder: (context, on, _) => Icon(Icons.code_rounded,
                        color: on ? kInspectColor : null),
                  ),
                  onSelected: (v) {
                    if (v == 'toggle') {
                      CodeInspector.enabled.value =
                          !CodeInspector.enabled.value;
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CodeIndexScreen()),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'toggle',
                        child: Text('เปิด / ปิดโหมดตรวจโค้ด')),
                    PopupMenuItem(
                        value: 'index', child: Text('สารบัญโค้ดทั้งหมด')),
                  ],
                ),
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (user.isAdmin ? AppColors.accent : AppColors.accent2)
                        .withOpacity(.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            user.isAdmin ? AppColors.accent : AppColors.accent2),
                  ),
                  child: Text(
                    user.isAdmin ? 'ADMIN' : 'OPERATOR',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            user.isAdmin ? AppColors.accent : AppColors.accent2),
                  ),
                ).explain('appbar_role'),
              ),
              IconButton(
                tooltip: 'Sign Out',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  CodeInspector.enabled.value = false;
                  _auth.signOut();
                },
              ).explain('appbar_signout'),
            ],
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textDim,
              tabs: const [
                Tab(icon: Icon(Icons.edit_note_rounded), text: 'Form'),
                Tab(icon: Icon(Icons.monitor_heart_rounded), text: 'Display'),
              ],
            ),
          ),
          body: Column(
            children: [
              // แถบแจ้งว่ากำลังอยู่ในโหมดตรวจโค้ด
              ValueListenableBuilder<bool>(
                valueListenable: CodeInspector.enabled,
                builder: (context, on, _) {
                  if (!on) return const SizedBox.shrink();
                  return _InspectBanner(
                    onClose: () => CodeInspector.enabled.value = false,
                    onOpenTabbarNote: () =>
                        showCodeNote(context, 'appbar_tabbar'),
                  );
                },
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    JobFormTab(
                      onSaved: () => _tab.animateTo(1),
                      db: _db,
                    ),
                    DisplayScreen(user: user, db: _db),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// แถบด้านบนตอนเปิดโหมดตรวจโค้ด
class _InspectBanner extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onOpenTabbarNote;
  const _InspectBanner({required this.onClose, required this.onOpenTabbarNote});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: kInspectColor.withOpacity(.18),
      child: Row(children: [
        const Icon(Icons.touch_app_rounded, color: kInspectColor, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'โหมดตรวจโค้ด: แตะกรอบสีส้มเพื่อดูโค้ดของส่วนนั้น '
            '(สลับแท็บได้ตามปกติ)',
            style: TextStyle(fontSize: 12.5, height: 1.4),
          ),
        ),
        TextButton(
          onPressed: onOpenTabbarNote,
          child: const Text('TabBar', style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: onClose,
          child: const Text('ปิด', style: TextStyle(color: kInspectColor)),
        ),
      ]),
    );
  }
}

/// แท็บ 1 (Form) - ยื่นคำขอจองโหนดประมวลผล
class JobFormTab extends StatelessWidget {
  final VoidCallback onSaved;
  final FirestoreController db;
  const JobFormTab({super.key, required this.onSaved, required this.db});

  @override
  Widget build(BuildContext context) {
    return JobForm(
      submitLabel: 'ส่งคำขอจอง GPU',
      onSubmit: (job) async {
        await db.addJob(job);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: AppColors.accent,
            content: Text('บันทึกคำขอสำเร็จ',
                style: TextStyle(color: Colors.black)),
          ));
          onSaved();
        }
      },
    );
  }
}
