// ignore_for_file: avoid_print
import 'dart:io';

/// ตัวช่วยเปิดโค้ดใน VS Code เมื่อแตะกรอบสีส้มในแอป (ใช้ตอนพัฒนาเท่านั้น)
///
/// วิธีรัน: เปิด Terminal ใหม่ใน VS Code (ที่โฟลเดอร์โปรเจกต์) แล้วพิมพ์
///   dart run tool/open_in_vscode.dart
/// ปล่อยให้รันค้างไว้ แล้วใช้งานแอปตามปกติ

const int port = 8787;

/// id ที่ไม่ได้ใช้ .explain() บนหน้าจอ
/// รูปแบบ: [ไฟล์, ข้อความที่ค้นหา, (ถ้ามี) ข้อความที่ให้ย้อนขึ้นไปหาจากจุดที่เจอ]
const Map<String, List<String>> anchors = {
  'app_init': ['lib/main.dart', 'Firebase.initializeApp()'],
  'auth_gate': ['lib/main.dart', 'class AuthGate'],
  'login_email': [
    'lib/screens/login_screen.dart',
    'controller: _email',
    'TextFormField('
  ],
  'login_password': [
    'lib/screens/login_screen.dart',
    'controller: _password',
    'TextFormField('
  ],
  'login_button': ['lib/screens/login_screen.dart', 'Future<void> _login()'],
  'login_demo': ['lib/screens/login_screen.dart', 'void _fill('],
  'users_collection': [
    'lib/controllers/auth_controller.dart',
    'Future<void> _ensureUserDoc'
  ],
  'appbar_tabbar': ['lib/screens/home_screen.dart', 'bottom: TabBar('],
  'appbar_inspector': ['lib/widgets/code_inspector.dart', 'class CodeInspector'],
};

/// ไฟล์ที่มีข้อความ .explain('...') อยู่ในตัวอย่างโค้ด ไม่ใช่โค้ดจริง
const List<String> skipFiles = ['code_notes.dart', 'code_inspector.dart'];

class Spot {
  final File file;
  final int line;
  Spot(this.file, this.line);
}

int lineOf(String text, int index) {
  var line = 1;
  for (var i = 0; i < index && i < text.length; i++) {
    if (text.codeUnitAt(i) == 10) line++;
  }
  return line;
}

bool isIdent(int c) =>
    (c >= 48 && c <= 57) ||
    (c >= 65 && c <= 90) ||
    (c >= 97 && c <= 122) ||
    c == 95 ||
    c == 46;

/// ย้อนจาก ".explain(" ไปหาบรรทัดแรกของ widget ที่อยู่ก่อนหน้า
/// (นับวงเล็บย้อนกลับจนเจอ "(" ที่เปิดคู่กัน แล้วเก็บชื่อคลาสหน้าวงเล็บ)
int widgetStart(String text, int dotIndex) {
  var i = dotIndex - 1;
  while (i >= 0 && text[i].trim().isEmpty) {
    i--;
  }
  if (i < 0 || text[i] != ')') return dotIndex;
  var depth = 0;
  for (; i >= 0; i--) {
    final ch = text[i];
    if (ch == ')') depth++;
    if (ch == '(') {
      depth--;
      if (depth == 0) break;
    }
  }
  if (i < 0) return dotIndex;
  var s = i;
  while (s > 0 && isIdent(text.codeUnitAt(s - 1))) {
    s--;
  }
  return s;
}

Spot? locate(String id) {
  final a = anchors[id];
  if (a != null) {
    final f = File(a[0]);
    if (!f.existsSync()) return null;
    final text = f.readAsStringSync();
    var i = text.indexOf(a[1]);
    if (i < 0) return null;
    if (a.length > 2) {
      final up = text.lastIndexOf(a[2], i);
      if (up >= 0) i = up;
    }
    return Spot(f.absolute, lineOf(text, i));
  }

  final needle = ".explain('$id')";
  for (final e in Directory('lib').listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    if (skipFiles.any((s) => e.path.endsWith(s))) continue;
    final text = e.readAsStringSync();
    final i = text.indexOf(needle);
    if (i < 0) continue;
    return Spot(e.absolute, lineOf(text, widgetStart(text, i)));
  }
  return null;
}

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    print('ต้องรันที่โฟลเดอร์โปรเจกต์ (โฟลเดอร์ที่มีไฟล์ pubspec.yaml)');
    exit(1);
  }

  HttpServer server;
  try {
    // ฟังเฉพาะในเครื่องนี้ อีมูเลเตอร์เรียกผ่านที่อยู่ 10.0.2.2
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  } catch (e) {
    print('เปิดพอร์ต $port ไม่ได้ (อาจมีตัวช่วยรันค้างอยู่แล้ว): $e');
    exit(1);
  }
  print('พร้อมแล้ว รอรับคำสั่งจากแอปที่พอร์ต $port (กด Ctrl + C เพื่อหยุด)');

  await for (final req in server) {
    final id = req.uri.queryParameters['id'] ?? '';
    String msg;
    if (req.uri.path == '/open' && RegExp(r'^[a-z_]+$').hasMatch(id)) {
      final spot = locate(id);
      if (spot == null) {
        msg = 'ไม่พบตำแหน่งโค้ดของ "$id"';
      } else {
        final result = await Process.run(
          'code',
          ['-r', '-g', '${spot.file.path}:${spot.line}:1'],
          runInShell: true,
        );
        msg = result.exitCode == 0
            ? 'เปิด ${spot.file.path} บรรทัด ${spot.line}  ($id)'
            : 'สั่ง code ไม่สำเร็จ: ${result.stderr}';
      }
    } else {
      msg = 'คำขอไม่ถูกต้อง';
    }
    print(msg);
    req.response.write(msg);
    await req.response.close();
  }
}
