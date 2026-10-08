/// ข้อมูลอธิบายโค้ดของแต่ละส่วนในแอป ใช้กับ "โหมดตรวจโค้ด" (Admin เท่านั้น)
/// key = id ที่ใช้ใน .explain('id') ของแต่ละ Widget
class CodeNote {
  final String group; // หมวดในสารบัญ
  final String title; // ชื่อส่วน
  final String file; // ไฟล์ที่โค้ดอยู่
  final String where; // คลาส / ฟังก์ชัน
  final String rubric; // ตรงกับเกณฑ์คะแนนข้อไหน
  final String summary; // อธิบายสั้นๆ
  final List<String> flow; // ลำดับการทำงานทีละขั้น
  final String code; // โค้ดที่เกี่ยวข้อง

  const CodeNote({
    required this.group,
    required this.title,
    required this.file,
    required this.where,
    required this.rubric,
    required this.summary,
    required this.flow,
    required this.code,
  });
}

final Map<String, CodeNote> codeNotes = {
  // ───────────────────────── ภาพรวมแอป ─────────────────────────
  'app_init': CodeNote(
    group: 'ภาพรวมแอป / Firebase',
    title: 'เริ่มต้น Firebase (Initialize)',
    file: 'lib/main.dart',
    where: 'GpuGridApp > home: FutureBuilder',
    rubric: 'การตั้งค่า Firebase และสถาปัตยกรรมโค้ด (15 คะแนน)',
    summary:
        'ก่อนใช้งาน Firebase ต้องเรียก Firebase.initializeApp() ก่อนเสมอ '
        'ซึ่งเป็นงานแบบ async จึงใช้ FutureBuilder รอจนเสร็จ '
        'ระหว่างรอแสดงวงกลมโหลด เมื่อเสร็จแล้วจึงไปหน้า AuthGate',
    flow: [
      'แอปเริ่ม: main() เรียก runApp(GpuGridApp)',
      'FutureBuilder เรียก Firebase.initializeApp() (อ่านค่าจาก google-services.json)',
      'ยังไม่เสร็จ: แสดง CircularProgressIndicator',
      'เสร็จแล้ว: แสดง AuthGate เพื่อเช็กว่าล็อกอินอยู่หรือไม่',
    ],
    code: r'''home: FutureBuilder<FirebaseApp>(
  future: Firebase.initializeApp(),
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const AuthGate();
  },
),''',
  ),
  'auth_gate': CodeNote(
    group: 'ภาพรวมแอป / Firebase',
    title: 'AuthGate: เลือกหน้า Login หรือหน้าหลัก',
    file: 'lib/main.dart',
    where: 'class AuthGate',
    rubric: 'ระบบ Authentication และการแบ่งสิทธิ์ RBAC (25 คะแนน)',
    summary:
        'ฟังสถานะการล็อกอินของ Firebase แบบต่อเนื่องด้วย authStateChanges() '
        'ถ้ามีผู้ใช้ล็อกอินอยู่ไปหน้าหลัก ถ้าไม่มีไปหน้า Login '
        'เมื่อกด Sign Out หน้าจะเปลี่ยนกลับมาที่ Login เองโดยอัตโนมัติ',
    flow: [
      'StreamBuilder ฟัง FirebaseAuth.instance.authStateChanges()',
      'snap.hasData = true (มี User) แสดง HomeScreen',
      'snap.hasData = false (ไม่มี User) แสดง LoginScreen',
    ],
    code: r'''StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snap) {
    if (snap.hasData) return const HomeScreen();
    return const LoginScreen();
  },
)''',
  ),

  // ───────────────────────── หน้า Login ─────────────────────────
  'login_email': CodeNote(
    group: 'หน้า Login',
    title: 'ช่อง Email (Login)',
    file: 'lib/screens/login_screen.dart',
    where: '_LoginScreenState > TextFormField (controller: _email)',
    rubric: 'การออกแบบฟอร์มและการจัดการ Validation (15 คะแนน)',
    summary:
        'ช่องกรอกอีเมล ใช้ MultiValidator รวมเงื่อนไข 2 ข้อ: ห้ามว่าง '
        'และรูปแบบต้องเป็นอีเมล (EmailValidator จากแพ็กเกจ form_field_validator) '
        'ตั้ง keyboardType เป็น emailAddress ให้คีย์บอร์ดมีปุ่ม @',
    flow: [
      'ผู้ใช้พิมพ์อีเมล เก็บค่าใน TextEditingController ชื่อ _email',
      'กด Login: เรียก _formKey.currentState!.validate()',
      'validator ตรวจ RequiredValidator แล้วตาม EmailValidator',
      'ผิด: แสดงข้อความแดงใต้ช่อง ถูก: ไปขั้นล็อกอิน',
    ],
    code: r'''TextFormField(
  controller: _email,
  keyboardType: TextInputType.emailAddress,
  decoration: const InputDecoration(
    labelText: 'Email',
    prefixIcon: Icon(Icons.email_rounded),
  ),
  validator: MultiValidator([
    RequiredValidator(errorText: 'กรุณากรอกอีเมล'),
    EmailValidator(errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
  ]),
)''',
  ),
  'login_password': CodeNote(
    group: 'หน้า Login',
    title: 'ช่อง Password และปุ่มรูปตา',
    file: 'lib/screens/login_screen.dart',
    where: '_LoginScreenState > TextFormField (controller: _password)',
    rubric: 'การออกแบบฟอร์มและการจัดการ Validation (15 คะแนน)',
    summary:
        'obscureText ซ่อนรหัสผ่านเป็นจุดๆ ปุ่มรูปตาเป็น IconButton ใน suffixIcon '
        'กดแล้วสลับค่า _obscure (true/false) ด้วย setState ทำให้ช่องแสดงหรือซ่อนรหัสผ่าน',
    flow: [
      'ตัวแปร bool _obscure เริ่มที่ true (ซ่อนรหัส)',
      'กดปุ่มตา: setState สลับ _obscure',
      'Flutter สร้างช่องใหม่ตามค่า _obscure และไอคอนเปลี่ยนตาม',
    ],
    code: r'''TextFormField(
  controller: _password,
  obscureText: _obscure,
  decoration: InputDecoration(
    labelText: 'Password',
    prefixIcon: const Icon(Icons.lock_rounded),
    suffixIcon: IconButton(
      icon: Icon(_obscure
          ? Icons.visibility_rounded
          : Icons.visibility_off_rounded),
      onPressed: () => setState(() => _obscure = !_obscure),
    ),
  ),
  validator: RequiredValidator(errorText: 'กรุณากรอกรหัสผ่าน'),
)''',
  ),
  'login_button': CodeNote(
    group: 'หน้า Login',
    title: 'ปุ่ม Login',
    file: 'lib/screens/login_screen.dart + lib/controllers/auth_controller.dart',
    where: '_LoginScreenState._login() > AuthController.signIn()',
    rubric: 'ระบบ Authentication และการแบ่งสิทธิ์ RBAC (25 คะแนน)',
    summary:
        'ตรวจฟอร์มก่อน ถ้าผ่านจึงเรียก signInWithEmailAndPassword ของ Firebase Auth '
        'สำเร็จแล้วเรียก _ensureUserDoc เพื่อสร้างเอกสารผู้ใช้ใน collection users (ถ้ายังไม่มี) '
        'ไม่ต้องสั่งเปลี่ยนหน้าเอง เพราะ AuthGate จะเห็นว่าล็อกอินแล้วและพาไปหน้าหลักให้',
    flow: [
      'validate() ฟอร์ม ไม่ผ่านให้หยุด',
      'setState(_loading = true) แสดงวงกลมโหลดบนปุ่ม',
      'await _auth.signIn(...) เรียก Firebase Auth',
      'ผิดพลาด: จับ FirebaseAuthException แล้วแสดง SnackBar สีแดง',
      'สำเร็จ: authStateChanges ส่ง User ใหม่ AuthGate เปลี่ยนไป HomeScreen',
    ],
    code: r'''// login_screen.dart
Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _loading = true);
  try {
    await _auth.signIn(_email.text, _password.text);
  } on FirebaseAuthException catch (e) {
    _toast('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

// auth_controller.dart
Future<void> signIn(String email, String password) async {
  final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password);
  await _ensureUserDoc(cred.user!);
}''',
  ),
  'login_demo': CodeNote(
    group: 'หน้า Login',
    title: 'ปุ่มบัญชีทดสอบ (กรอกอัตโนมัติ)',
    file: 'lib/screens/login_screen.dart',
    where: '_LoginScreenState._fill() + ActionChip',
    rubric: 'ข้อกำหนดการพัฒนา UI (บัญชีทดสอบ Admin / Operator)',
    summary:
        'ปุ่มช่วยกรอกอีเมลและรหัสผ่านให้อัตโนมัติ เพื่อสลับทดสอบระหว่าง Admin กับ Operator ได้เร็ว '
        'เป็นแค่ตัวช่วยในหน้าจอ ไม่เกี่ยวกับระบบสิทธิ์ ต้องมีบัญชีนั้นอยู่ใน Firebase Authentication จริง',
    flow: [
      'กดชิป: เรียก _fill(อีเมล)',
      'ตั้ง _email.text เป็นอีเมลที่เลือก และ _password.text เป็น 123456',
      'กดปุ่ม Login ต่อตามปกติ',
    ],
    code: r'''void _fill(String email) {
  setState(() {
    _email.text = email;
    _password.text = '123456';
  });
}

ActionChip(
  label: const Text('admin@test.com'),
  onPressed: () => _fill('admin@test.com'),
),''',
  ),
  'users_collection': CodeNote(
    group: 'หน้า Login',
    title: 'Collection users: เก็บ uid, name, email, role',
    file: 'lib/controllers/auth_controller.dart + lib/models/app_user.dart',
    where: 'AuthController._ensureUserDoc() / AppUser',
    rubric: 'ระบบ Authentication และการแบ่งสิทธิ์ RBAC (25 คะแนน)',
    summary:
        'ตอนล็อกอินครั้งแรก แอปสร้างเอกสารใน collection users โดยใช้ uid ของผู้ใช้เป็น Document ID '
        'ฟิลด์ role คือหัวใจของ RBAC: อีเมล admin@test.com ได้ role = admin นอกนั้นได้ operator '
        'จากนั้นทุกหน้าอ่าน role นี้เพื่อตัดสินว่าจะแสดงปุ่มอะไร',
    flow: [
      'ล็อกอินสำเร็จ ได้ User จาก Firebase Auth',
      'อ่านเอกสาร users/{uid} ถ้ามีแล้วไม่ทำอะไร',
      'ถ้ายังไม่มี: กำหนด role จากอีเมล แล้ว set() เอกสารใหม่',
      'AppUser.toMap() แปลงเป็น Map เก็บ uid, name, email, role',
    ],
    code: r'''Future<void> _ensureUserDoc(User user) async {
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
}''',
  ),

  // ───────────────────────── AppBar / หน้าหลัก ─────────────────────────
  'appbar_role': CodeNote(
    group: 'AppBar / หน้าหลัก',
    title: 'ป้าย ADMIN / OPERATOR',
    file: 'lib/screens/home_screen.dart + lib/models/app_user.dart',
    where: '_HomeScreenState.build > StreamBuilder<AppUser>',
    rubric: 'ระบบ Authentication และการแบ่งสิทธิ์ RBAC (25 คะแนน)',
    summary:
        'อ่านเอกสารผู้ใช้ปัจจุบันจาก Firestore แบบ real-time (snapshots) แปลงเป็น AppUser '
        'แล้วใช้ getter isAdmin (role == admin) เลือกข้อความ สี และสิทธิ์ของทั้งหน้าจอ '
        'ถ้าแก้ role ใน Firestore หน้าจอจะเปลี่ยนตามทันที',
    flow: [
      'HomeScreen เรียก _auth.userStream(uid)',
      'AuthController แปลง snapshot ของ users/{uid} เป็น AppUser',
      'user.isAdmin ใช้เลือกข้อความ ADMIN หรือ OPERATOR และสี',
      'ส่ง user ต่อให้ DisplayScreen เพื่อซ่อนหรือแสดงปุ่ม Edit/Delete',
    ],
    code: r'''// home_screen.dart
StreamBuilder<AppUser>(
  stream: _auth.userStream(_uid),
  builder: (context, snap) {
    final user = snap.data!;
    // ...
    Text(user.isAdmin ? 'ADMIN' : 'OPERATOR')
  },
)

// auth_controller.dart
Stream<AppUser> userStream(String uid) =>
    _users.doc(uid).snapshots().map((d) => AppUser.fromDoc(d));

// app_user.dart
bool get isAdmin => role == 'admin';''',
  ),
  'appbar_signout': CodeNote(
    group: 'AppBar / หน้าหลัก',
    title: 'ปุ่ม Sign Out',
    file: 'lib/screens/home_screen.dart + lib/controllers/auth_controller.dart',
    where: 'AppBar > actions > IconButton (Sign Out)',
    rubric: 'ระบบ Authentication และการแบ่งสิทธิ์ RBAC (25 คะแนน)',
    summary:
        'เรียก FirebaseAuth.signOut() ให้ออกจากระบบ ใบงานกำหนดให้มีปุ่มนี้บน AppBar '
        'เพื่อสลับทดสอบระหว่าง Admin กับ Operator หลัง signOut AuthGate จะเห็นว่าไม่มีผู้ใช้ '
        'และแสดงหน้า Login ให้เอง',
    flow: [
      'กดปุ่ม: ปิดโหมดตรวจโค้ด แล้วเรียก _auth.signOut()',
      'FirebaseAuth ล้างผู้ใช้ปัจจุบัน',
      'authStateChanges ส่งค่า null',
      'AuthGate แสดง LoginScreen',
    ],
    code: r'''// home_screen.dart
IconButton(
  tooltip: 'Sign Out',
  icon: const Icon(Icons.logout_rounded),
  onPressed: () {
    CodeInspector.enabled.value = false;
    _auth.signOut();
  },
)

// auth_controller.dart
Future<void> signOut() => _auth.signOut();''',
  ),
  'appbar_tabbar': CodeNote(
    group: 'AppBar / หน้าหลัก',
    title: 'TabBar: แท็บ Form และ Display',
    file: 'lib/screens/home_screen.dart',
    where: '_HomeScreenState (TabController + TabBar + TabBarView)',
    rubric: 'UI/UX และ App Branding (15 คะแนน)',
    summary:
        'TabController ควบคุมการสลับแท็บ ต้องใช้ SingleTickerProviderStateMixin เพื่อให้ได้ vsync '
        'สำหรับแอนิเมชัน TabBar เป็นปุ่มแท็บด้านบน TabBarView เป็นเนื้อหาของแต่ละแท็บ '
        'ทั้งสองต้องใช้ controller ตัวเดียวกัน จึงสลับพร้อมกันได้ทั้งการกดและการปัดซ้ายขวา',
    flow: [
      'initState: สร้าง TabController(length: 2, vsync: this)',
      'TabBar แสดงแท็บ Form กับ Display',
      'TabBarView แสดง JobFormTab และ DisplayScreen',
      'บันทึกฟอร์มสำเร็จ: เรียก _tab.animateTo(1) พาไปแท็บ Display',
    ],
    code: r'''class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }
  // ...
  bottom: TabBar(controller: _tab, tabs: const [
    Tab(icon: Icon(Icons.edit_note_rounded), text: 'Form'),
    Tab(icon: Icon(Icons.monitor_heart_rounded), text: 'Display'),
  ]),
  // ...
  body: TabBarView(controller: _tab, children: [
    JobFormTab(onSaved: () => _tab.animateTo(1), db: _db),
    DisplayScreen(user: user, db: _db),
  ]),''',
  ),
  'appbar_inspector': CodeNote(
    group: 'AppBar / หน้าหลัก',
    title: 'ปุ่มโหมดตรวจโค้ด (ส่วนเสริมนอกใบงาน)',
    file: 'lib/widgets/code_inspector.dart + lib/utils/code_notes.dart',
    where: 'CodeInspector.enabled / class Explain / showCodeNote()',
    rubric: 'ส่วนเสริมนอกใบงาน (ต้องอธิบายการทำงานของโค้ดส่วนนี้ได้)',
    summary:
        'ส่วนที่เพิ่มเอง ไม่ได้อยู่ในใบงาน ปุ่มแสดงเฉพาะ Admin ใช้ ValueNotifier<bool> เก็บสถานะเปิด/ปิด '
        'Widget ชื่อ Explain ครอบองค์ประกอบต่างๆ ไว้ ตอนปิดโหมดทำงานเหมือนเดิม '
        'ตอนเปิดโหมดจะวางกรอบสีส้มทับและดักการแตะ (AbsorbPointer กันไม่ให้ปุ่มเดิมทำงาน) '
        'แตะแล้วเปิด BottomSheet แสดงคำอธิบายจาก Map ชื่อ codeNotes',
    flow: [
      'ValueNotifier CodeInspector.enabled เก็บสถานะ true/false',
      'ValueListenableBuilder ใน Explain ฟังค่านี้ แล้วสร้างกรอบสีส้มเมื่อเป็น true',
      'แตะกรอบ: เรียก showCodeNote(context, id)',
      'ดึง CodeNote จาก Map codeNotes ด้วย id แล้วแสดงใน showModalBottomSheet',
    ],
    code: r'''class CodeInspector {
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
}

extension ExplainX on Widget {
  Widget explain(String id) => Explain(id: id, child: this);
}

// ตัวอย่างการใช้
IconButton(...).explain('display_edit')''',
  ),

  // ───────────────────────── แท็บ 1 Form ─────────────────────────
  'form_name': CodeNote(
    group: 'แท็บ 1 Form',
    title: 'ช่องชื่อโปรเจกต์ / การทดลอง',
    file: 'lib/widgets/job_form.dart',
    where: '_JobFormState > TextFormField (controller: _name)',
    rubric: 'การออกแบบฟอร์มและการจัดการ Validation (15 คะแนน)',
    summary:
        'ช่องข้อความธรรมดา ตรวจด้วย RequiredValidator ห้ามเว้นว่างตามใบงาน '
        'ค่าเก็บใน TextEditingController ชื่อ _name และตอนบันทึกจะ trim() ตัดช่องว่างหัวท้าย',
    flow: [
      'กดส่งฟอร์ม: validate() เรียก validator ของทุกช่อง',
      'ช่องว่าง: แสดงข้อความ "กรุณากรอกชื่อโปรเจกต์ / การทดลอง"',
      'ผ่าน: อ่านค่าด้วย _name.text.trim()',
    ],
    code: r'''TextFormField(
  controller: _name,
  decoration: const InputDecoration(
    labelText: 'ชื่อโปรเจกต์ / การทดลอง (Experiment Name)',
    hintText: 'เช่น LLM-FineTune-V3',
  ),
  validator: RequiredValidator(
      errorText: 'กรุณากรอกชื่อโปรเจกต์ / การทดลอง'),
)''',
  ),
  'form_framework': CodeNote(
    group: 'แท็บ 1 Form',
    title: 'ช่องประเภทโมเดล / Framework',
    file: 'lib/widgets/job_form.dart',
    where: '_JobFormState > TextFormField (controller: _framework)',
    rubric: 'การออกแบบฟอร์มและการจัดการ Validation (15 คะแนน)',
    summary:
        'ช่องข้อความที่ห้ามว่างตามใบงาน (เช่น PyTorch, TensorFlow, JAX) '
        'ค่าที่กรอกจะถูกใช้ตัดสินสีของป้ายในแท็บ Display ด้วย (ฟังก์ชัน _frameworkColor)',
    flow: [
      'ผู้ใช้พิมพ์เอง หรือแตะชิปด้านล่างเพื่อเติมให้',
      'RequiredValidator ตรวจว่าห้ามว่าง',
      'บันทึกลง Firestore ในฟิลด์ framework',
    ],
    code: r'''TextFormField(
  controller: _framework,
  decoration: const InputDecoration(
    labelText: 'ประเภทโมเดล / Framework',
    hintText: 'เช่น PyTorch, TensorFlow, JAX',
  ),
  validator: RequiredValidator(
      errorText: 'กรุณากรอกประเภทโมเดล / Framework'),
)''',
  ),
  'form_chips': CodeNote(
    group: 'แท็บ 1 Form',
    title: 'ชิปเลือก Framework (PyTorch / TensorFlow / JAX)',
    file: 'lib/widgets/job_form.dart',
    where: '_JobFormState > Wrap + ActionChip',
    rubric: 'UI/UX และ App Branding (15 คะแนน) - ส่วนเสริมช่วยกรอก',
    summary:
        'ส่วนเสริมเพื่อความสะดวก ไม่ได้อยู่ในใบงาน สร้างชิปจาก List _frameworks ด้วย map() '
        'แตะแล้วเติมข้อความลงช่อง _framework ผู้ใช้ยังพิมพ์ชื่ออื่นเองได้',
    flow: [
      'static const _frameworks = [PyTorch, TensorFlow, JAX]',
      '.map() สร้าง ActionChip หนึ่งอันต่อชื่อ',
      'แตะชิป: setState ตั้ง _framework.text เป็นชื่อนั้น',
    ],
    code: r'''static const _frameworks = ['PyTorch', 'TensorFlow', 'JAX'];

Wrap(
  spacing: 8,
  children: _frameworks
      .map((f) => ActionChip(
            label: Text(f),
            onPressed: () => setState(() => _framework.text = f),
          ))
      .toList(),
)''',
  ),
  'form_email': CodeNote(
    group: 'แท็บ 1 Form',
    title: 'ช่องอีเมลนักวิจัยหลัก',
    file: 'lib/widgets/job_form.dart',
    where: '_JobFormState > TextFormField (controller: _email)',
    rubric: 'การออกแบบฟอร์มและการจัดการ Validation (15 คะแนน)',
    summary:
        'ใบงานกำหนดให้ตรวจ Format อีเมล จึงใช้ MultiValidator รวม RequiredValidator '
        '(ห้ามว่าง) กับ EmailValidator (ต้องมี @ และรูปแบบอีเมลถูกต้อง) '
        'และตั้ง keyboardType เป็น emailAddress',
    flow: [
      'validate() เรียก MultiValidator',
      'ตรวจตามลำดับ ผิดข้อแรกจะแสดงข้อความของข้อนั้นทันที',
      'ผ่านทั้งสองข้อ: บันทึกเป็น researcherEmail',
    ],
    code: r'''TextFormField(
  controller: _email,
  keyboardType: TextInputType.emailAddress,
  validator: MultiValidator([
    RequiredValidator(errorText: 'กรุณากรอกอีเมล'),
    EmailValidator(errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
  ]),
)''',
  ),
  'form_gpus': CodeNote(
    group: 'แท็บ 1 Form',
    title: 'ช่องจำนวนการ์ด GPU (ตัวเลขเท่านั้น)',
    file: 'lib/widgets/job_form.dart',
    where: '_JobFormState > TextFormField (controller: _gpus) + _numberValidator',
    rubric: 'การออกแบบฟอร์มและการจัดการ Validation (15 คะแนน)',
    summary:
        'ใบงานให้ใช้ keyboardType แบบตัวเลขและห้ามว่าง จึงใช้ 3 ชั้นป้องกัน: '
        '1) keyboardType: number เปิดแป้นตัวเลข '
        '2) inputFormatters digitsOnly ไม่ให้พิมพ์ตัวอักษร '
        '3) _numberValidator ห้ามว่างและต้องเป็นจำนวนเต็มมากกว่า 0 (Regex)',
    flow: [
      'พิมพ์: FilteringTextInputFormatter.digitsOnly กรองเหลือแต่ตัวเลข',
      'กดส่ง: _numberValidator ตรวจห้ามว่าง แล้วตรวจ Regex',
      'ผ่าน: int.parse(_gpus.text) แปลงเป็นตัวเลขก่อนบันทึก',
    ],
    code: r'''TextFormField(
  controller: _gpus,
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  validator: _numberValidator,
)

final _numberValidator = MultiValidator([
  RequiredValidator(errorText: 'ห้ามเว้นว่าง'),
  PatternValidator(r'^[1-9][0-9]*$',
      errorText: 'กรอกเป็นตัวเลขจำนวนเต็มที่มากกว่า 0'),
]);''',
  ),
  'form_hours': CodeNote(
    group: 'แท็บ 1 Form',
    title: 'ช่องเวลาจำกัดการรัน (Max Compute Hours)',
    file: 'lib/widgets/job_form.dart',
    where: '_JobFormState > TextFormField (controller: _hours) + _numberValidator',
    rubric: 'การออกแบบฟอร์มและการจัดการ Validation (15 คะแนน)',
    summary:
        'ทำงานเหมือนช่องจำนวน GPU ทุกอย่าง ใช้ _numberValidator ตัวเดียวกัน '
        '(เขียนครั้งเดียวใช้ซ้ำ 2 ช่อง) ตัวเลขเก็บเป็น int ในฟิลด์ maxHours',
    flow: [
      'digitsOnly กรองให้เหลือแต่ตัวเลข',
      '_numberValidator ตรวจห้ามว่างและมากกว่า 0',
      'int.parse(_hours.text) ก่อนบันทึก',
    ],
    code: r'''TextFormField(
  controller: _hours,
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  decoration: const InputDecoration(
    labelText: 'เวลาจำกัดการรัน (Max Compute Hours)',
  ),
  validator: _numberValidator,
)''',
  ),
  'form_submit': CodeNote(
    group: 'แท็บ 1 Form',
    title: 'ปุ่มส่งคำขอจอง GPU (Create)',
    file: 'lib/widgets/job_form.dart + lib/screens/home_screen.dart + lib/controllers/firestore_controller.dart',
    where: '_JobFormState._submit() > JobFormTab.onSubmit > FirestoreController.addJob()',
    rubric: 'CRUD - Create บันทึกลง Firestore สำเร็จทั้ง 2 สิทธิ์ (8 คะแนน)',
    summary:
        'ตรวจทุกช่องด้วย validate() ถ้าผ่านจะสร้างอ็อบเจ็กต์ GpuJob แล้วส่งให้ฟังก์ชัน onSubmit '
        'ซึ่งเรียก addJob() บันทึกเอกสารใหม่ลง collection gpu_jobs ด้วย add() ร่วมกับ async/await '
        'ใครล็อกอินอยู่ก็ทำได้ ทั้ง Admin และ Operator เพราะไม่มีเงื่อนไขเช็ก role',
    flow: [
      'validate() ทุกช่อง ไม่ผ่านให้หยุดและแสดงข้อความแดง',
      'สร้าง GpuJob จากค่าที่กรอก (int.parse กับ GPU และชั่วโมง)',
      'เรียก widget.onSubmit(job) ซึ่งส่งต่อไป db.addJob(job)',
      'addJob ใช้ _col.add() เพิ่ม Document ใหม่ พร้อมเวลา createdAt จากเซิร์ฟเวอร์',
      'สำเร็จ: ล้างฟอร์ม แสดง SnackBar และพาไปแท็บ Display',
    ],
    code: r'''// job_form.dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _saving = true);
  await widget.onSubmit(GpuJob(
    experimentName: _name.text.trim(),
    framework: _framework.text.trim(),
    researcherEmail: _email.text.trim(),
    gpus: int.parse(_gpus.text.trim()),
    maxHours: int.parse(_hours.text.trim()),
  ));
}

// home_screen.dart (JobFormTab)
onSubmit: (job) async {
  await db.addJob(job);
  onSaved();
},

// firestore_controller.dart
Future<void> addJob(GpuJob job) async {
  await _col.add({
    ...job.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
  });
}''',
  ),

  // ───────────────────────── แท็บ 2 Display ─────────────────────────
  'display_summary': CodeNote(
    group: 'แท็บ 2 Display',
    title: 'การ์ดสรุป (Jobs ในคิว / GPU ที่จองรวม)',
    file: 'lib/screens/display_screen.dart',
    where: 'DisplayScreen.build > jobs.fold(...) + class _Stat',
    rubric: 'UI/UX และ App Branding (15 คะแนน) - ส่วนเสริม',
    summary:
        'ส่วนเสริมนอกใบงาน นับจำนวนรายการจาก jobs.length และรวมจำนวนการ์ด GPU ด้วย fold() '
        'ซึ่งวนบวกค่า gpus ของทุกรายการ เริ่มจาก 0 ตัวเลขอัปเดตเองเมื่อข้อมูลเปลี่ยน '
        'เพราะอยู่ใน StreamBuilder',
    flow: [
      'StreamBuilder ได้ snapshot ใหม่ทุกครั้งที่ข้อมูลเปลี่ยน',
      'แปลงเอกสารเป็น List<GpuJob>',
      'fold รวมค่า gpus ทั้งหมดเป็น totalGpus',
      'แสดงใน _Stat 2 ตัว',
    ],
    code: r'''final jobs = snap.data!.docs.map(GpuJob.fromDoc).toList();
final totalGpus = jobs.fold<int>(0, (s, j) => s + j.gpus);

_Stat(label: 'Jobs ในคิว', value: '${jobs.length}'),
_Stat(label: 'GPU ที่จองรวม', value: '$totalGpus'),''',
  ),
  'display_avatar': CodeNote(
    group: 'แท็บ 2 Display',
    title: 'CircleAvatar แสดงจำนวนการ์ด GPU',
    file: 'lib/screens/display_screen.dart',
    where: 'DisplayScreen.build > ListView.builder > ListTile (leading)',
    rubric: 'CRUD - Read แสดงด้วย ListView/ListTile (8 คะแนน)',
    summary:
        'ใบงานกำหนดให้ใช้ CircleAvatar แสดงจำนวนการ์ด GPU วงกลมสีเขียวแสดงเลข job.gpus '
        'พร้อมคำว่า GPU ตัวเล็กด้านล่าง อยู่ในตำแหน่ง leading ของ ListTile',
    flow: [
      'ListView.builder วนสร้างรายการตามจำนวน jobs',
      'แต่ละรายการสร้าง ListTile',
      'leading เป็น CircleAvatar ที่แสดงค่า job.gpus',
    ],
    code: r'''leading: CircleAvatar(
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
      const Text('GPU', style: TextStyle(fontSize: 9)),
    ],
  ),
),''',
  ),
  'display_title': CodeNote(
    group: 'แท็บ 2 Display',
    title: 'ชื่องานวิจัย และรายการแบบ real-time (StreamBuilder)',
    file: 'lib/screens/display_screen.dart + lib/controllers/firestore_controller.dart',
    where: 'DisplayScreen.build > StreamBuilder > ListView.builder',
    rubric: 'CRUD - Read แบบ Real-time ผ่าน ListView/ListTile (8 คะแนน)',
    summary:
        'ดึงข้อมูลแบบ real-time ด้วย StreamBuilder ที่ฟัง collection().snapshots() '
        'เมื่อมีการเพิ่ม แก้ หรือลบข้อมูล (แม้จากเครื่องอื่น) รายการจะอัปเดตเองโดยไม่ต้องรีเฟรช '
        'แล้วแสดงด้วย ListView.builder และ ListTile ชื่อ title คือ job.experimentName',
    flow: [
      'jobsStream() คืน Stream จาก _col.snapshots()',
      'StreamBuilder สร้างหน้าใหม่ทุกครั้งที่มี snapshot ใหม่',
      'GpuJob.fromDoc แปลงเอกสาร Firestore เป็นอ็อบเจ็กต์',
      'ListView.builder สร้าง Card + ListTile ต่อหนึ่งรายการ',
    ],
    code: r'''// firestore_controller.dart
Stream<QuerySnapshot<Map<String, dynamic>>> jobsStream() =>
    _col.snapshots();

// display_screen.dart
StreamBuilder(
  stream: db.jobsStream(),
  builder: (context, snap) {
    final jobs = snap.data!.docs.map(GpuJob.fromDoc).toList();
    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (context, i) {
        final job = jobs[i];
        return Card(
          child: ListTile(
            title: Text(job.experimentName),
            // leading, subtitle, trailing ...
          ),
        );
      },
    );
  },
)''',
  ),
  'display_badge': CodeNote(
    group: 'แท็บ 2 Display',
    title: 'ป้าย Framework (สีต่างกันตามชนิด)',
    file: 'lib/screens/display_screen.dart',
    where: 'DisplayScreen._frameworkColor()',
    rubric: 'UI/UX และ App Branding (15 คะแนน)',
    summary:
        'ฟังก์ชัน _frameworkColor รับชื่อ Framework แล้วคืนสี โดยแปลงเป็นตัวพิมพ์เล็กก่อนเทียบ '
        'ด้วย switch ชื่อที่ไม่รู้จักใช้สีน้ำเงินเป็นค่าเริ่มต้น (default) '
        'สีที่ได้ใช้ทำพื้นโปร่งแสงด้วย color.withOpacity(.2)',
    flow: [
      'รับ job.framework',
      'toLowerCase() แล้ว switch เทียบกับ pytorch / tensorflow / jax',
      'คืนสีของ Framework นั้น หรือสีเริ่มต้น',
    ],
    code: r'''Color _frameworkColor(String f) {
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
}''',
  ),
  'display_edit': CodeNote(
    group: 'แท็บ 2 Display',
    title: 'ปุ่ม Edit (Update) เฉพาะ Admin',
    file: 'lib/screens/display_screen.dart + lib/widgets/job_form.dart + lib/controllers/firestore_controller.dart',
    where: 'DisplayScreen._edit() > JobForm(job: job) > FirestoreController.updateJob()',
    rubric: 'CRUD - Update แก้ไขได้เฉพาะ Admin (8 คะแนน) / RBAC (25 คะแนน)',
    summary:
        'ปุ่มนี้อยู่ใน trailing ของ ListTile และสร้างเฉพาะเมื่อ user.isAdmin เป็นจริง '
        'ส่วน Operator ได้ trailing = null ปุ่มจึงไม่ถูกสร้างเลย กดแล้วเปิดหน้าแก้ไขที่ใช้ JobForm ตัวเดิม '
        'โดยส่ง job เข้าไปเพื่อเติมค่าเดิมลงช่อง เมื่อกดบันทึกจะเรียก update() ตาม Document ID',
    flow: [
      'trailing: user.isAdmin ? Row(ปุ่ม Edit, Delete) : null (นี่คือ RBAC)',
      'กด Edit: Navigator.push ไปหน้า JobForm พร้อมส่ง job',
      'JobForm.initState เติมค่าเดิมลง TextEditingController',
      'กดบันทึก: db.updateJob(job.id!, updated)',
      'Firestore: _col.doc(id).update(...) แล้ว Stream อัปเดตรายการอัตโนมัติ',
    ],
    code: r'''// display_screen.dart
trailing: user.isAdmin
    ? Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.edit_rounded),
          onPressed: () => _edit(context, job),
        ),
        // ปุ่ม Delete ...
      ])
    : null,

// firestore_controller.dart
Future<void> updateJob(String id, GpuJob job) async {
  await _col.doc(id).update(job.toMap());
}''',
  ),
  'display_delete': CodeNote(
    group: 'แท็บ 2 Display',
    title: 'ปุ่ม Delete (Terminate Job) เฉพาะ Admin',
    file: 'lib/screens/display_screen.dart + lib/controllers/firestore_controller.dart',
    where: 'DisplayScreen._confirmDelete() > FirestoreController.deleteJob()',
    rubric: 'CRUD - Delete มี Dialog ยืนยันและลบได้เฉพาะ Admin (6 คะแนน) / RBAC (25 คะแนน)',
    summary:
        'ปุ่มถูกสร้างเฉพาะ Admin (เงื่อนไข user.isAdmin เดียวกับปุ่ม Edit) กดแล้วเปิด AlertDialog ถามยืนยันก่อน '
        'showDialog คืนค่า true เมื่อกด Terminate และ false เมื่อกดยกเลิก ถ้าเป็น true จึงลบเอกสารตาม ID ด้วย delete()',
    flow: [
      'กดถังขยะ: เรียก _confirmDelete(context, job)',
      'showDialog แสดง AlertDialog (ยกเลิก / Terminate)',
      'กด Terminate: Navigator.pop(ctx, true)',
      'ok == true: await db.deleteJob(job.id!)',
      'Firestore: _col.doc(id).delete() แล้ว Stream อัปเดตรายการอัตโนมัติ',
    ],
    code: r'''// display_screen.dart
Future<void> _confirmDelete(BuildContext context, GpuJob job) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Terminate Job'),
      content: Text('ต้องการสั่ง Terminate งาน "${job.experimentName}" ...'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Terminate')),
      ],
    ),
  );
  if (ok == true && job.id != null) {
    await db.deleteJob(job.id!);
  }
}

// firestore_controller.dart
Future<void> deleteJob(String id) async {
  await _col.doc(id).delete();
}''',
  ),
};
