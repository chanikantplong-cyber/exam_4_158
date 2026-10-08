import 'dart:io' show HttpClient;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../utils/code_notes.dart';

/// สีกรอบของโหมดตรวจโค้ด
const kInspectColor = Color(0xFFFFB020);

/// ตัวควบคุมโหมดตรวจโค้ด (true = เปิด) ใช้ได้เฉพาะ Admin
class CodeInspector {
  CodeInspector._();
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
}

/// เขียนต่อท้าย Widget ได้เลย เช่น IconButton(...).explain('display_edit')
extension ExplainX on Widget {
  Widget explain(String id) => Explain(id: id, child: this);
}

/// ครอบ Widget ไว้ ตอนปิดโหมดทำงานเหมือนเดิมทุกอย่าง
/// ตอนเปิดโหมดจะวางกรอบสีส้มทับ และแตะเพื่อดูโค้ดของส่วนนั้นแทนการกดปุ่มจริง
class Explain extends StatelessWidget {
  final String id;
  final Widget child;

  /// ตำแหน่งบรรทัดที่เขียน .explain(...) (หาได้เฉพาะตอน debug)
  final String? location = _findCaller();

  Explain({super.key, required this.id, required this.child});

  /// อ่าน stack trace แล้วหาบรรทัดแรกที่ไม่ใช่ไฟล์นี้ = ตำแหน่งที่เรียก .explain()
  static String? _findCaller() {
    if (!kDebugMode) return null;
    final re = RegExp(r'\((package:[^)\s]+\.dart:\d+(?::\d+)?)\)');
    for (final line in StackTrace.current.toString().split('\n')) {
      if (line.contains('code_inspector.dart')) continue;
      final m = re.firstMatch(line);
      if (m != null) return m.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: CodeInspector.enabled,
      builder: (context, on, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // เปิดโหมด: กันไม่ให้ปุ่มหรือช่องเดิมทำงาน
            AbsorbPointer(absorbing: on, child: child),
            if (on)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showCodeNote(context, id, location: location),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kInspectColor.withOpacity(.14),
                      border: Border.all(color: kInspectColor, width: 1.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// ส่งคำสั่งไปที่ตัวช่วยบนคอม (tool/open_in_vscode.dart) ให้ VS Code เปิดโค้ดของ id นี้
/// 10.0.2.2 คือที่อยู่ของคอมที่รันอีมูเลเตอร์ ถ้าตัวช่วยไม่ได้รันอยู่จะเงียบไป ไม่มี error
Future<void> openInEditor(String id) async {
  if (!kDebugMode) return;
  try {
    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 800);
    final req = await client.getUrl(Uri.parse('http://10.0.2.2:8787/open?id=$id'));
    final res = await req.close();
    await res.drain<void>();
    client.close();
  } catch (_) {}
}

/// เปิดหน้าต่างอธิบายโค้ดของ id ที่ระบุ
void showCodeNote(BuildContext context, String id, {String? location}) {
  final note = codeNotes[id];
  if (note == null) return;
  // พิมพ์ลง Debug Console ใน VS Code (กด Ctrl + คลิก ที่ลิงก์เพื่อเปิดบรรทัดนั้น)
  if (location != null) debugPrint('[ตรวจโค้ด] ${note.title} -> $location');
  openInEditor(id); // ให้ VS Code เด้งไปที่โค้ดส่วนนี้ด้วย
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _NoteSheet(note: note, location: location),
  );
}

class _NoteSheet extends StatelessWidget {
  final CodeNote note;
  final String? location;
  const _NoteSheet({required this.note, this.location});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.88;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kInspectColor.withOpacity(.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.code_rounded, color: kInspectColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(note.title,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 16),
            _InfoRow(
                icon: Icons.insert_drive_file_rounded,
                label: 'ไฟล์',
                value: note.file),
            _InfoRow(
                icon: Icons.account_tree_rounded,
                label: 'ตำแหน่ง',
                value: note.where),
            if (location != null)
              _InfoRow(
                  icon: Icons.my_location_rounded,
                  label: 'บรรทัดจริง',
                  value: location!
                      .replaceFirst(RegExp(r'^package:[^/]+/'), 'lib/'),
                  valueColor: kInspectColor),
            _InfoRow(
                icon: Icons.grading_rounded,
                label: 'เกณฑ์คะแนน',
                value: note.rubric,
                valueColor: AppColors.accent),
            const SizedBox(height: 14),
            const _Heading('ทำงานอย่างไร'),
            Text(note.summary,
                style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 16),
            const _Heading('ลำดับการทำงาน'),
            ...List.generate(note.flow.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 10, top: 1),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ),
                    Expanded(
                      child: Text(note.flow[i],
                          style: const TextStyle(fontSize: 14.5, height: 1.5)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(children: [
              const Expanded(child: _Heading('โค้ดที่เกี่ยวข้อง')),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: note.code));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('คัดลอกโค้ดแล้ว'),
                      duration: Duration(seconds: 1)));
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('คัดลอก'),
              ),
            ]),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A101C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2C47)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  note.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.55,
                    color: Color(0xFFB8F5E0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.accent2)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textDim),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(label,
                style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor)),
          ),
        ],
      ),
    );
  }
}

/// สารบัญโค้ดทั้งหมด (รวมส่วนที่ไม่อยู่บนหน้าจอนี้ เช่น Login และ Firebase)
class CodeIndexScreen extends StatelessWidget {
  const CodeIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // จัดกลุ่มตามหมวด โดยคงลำดับที่เขียนไว้
    final groups = <String, List<MapEntry<String, CodeNote>>>{};
    for (final e in codeNotes.entries) {
      groups.putIfAbsent(e.value.group, () => []).add(e);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('สารบัญโค้ดทั้งหมด')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          for (final g in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
              child: Text(g.key,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent)),
            ),
            for (final e in g.value)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.code_rounded, color: kInspectColor),
                  title: Text(e.value.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(e.value.file,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showCodeNote(context, e.key),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
