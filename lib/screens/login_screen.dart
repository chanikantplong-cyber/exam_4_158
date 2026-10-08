import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../controllers/auth_controller.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signIn(_email.text, _password.text);
    } on FirebaseAuthException catch (e) {
      _toast(e.code == 'invalid-credential' ||
              e.code == 'wrong-password' ||
              e.code == 'user-not-found'
          ? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง'
          : 'เข้าสู่ระบบไม่สำเร็จ: ${e.message}');
    } catch (e) {
      _toast('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(msg)));
  }

  void _fill(String email) {
    setState(() {
      _email.text = email;
      _password.text = '123456';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1220), Color(0xFF0E2A3F), Color(0xFF0B3B3A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.accent2]),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.accent.withOpacity(.35),
                              blurRadius: 30,
                              spreadRadius: 2)
                        ],
                      ),
                      child: const Icon(Icons.memory_rounded,
                          size: 56, color: Colors.black),
                    ),
                    const SizedBox(height: 18),
                    const Text('GPUGrid',
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    const Text('Cloud GPU Cluster Quota Allocator',
                        style: TextStyle(color: AppColors.textDim)),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_rounded),
                              ),
                              validator: MultiValidator([
                                RequiredValidator(
                                    errorText: 'กรุณากรอกอีเมล'),
                                EmailValidator(
                                    errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: RequiredValidator(
                                  errorText: 'กรุณากรอกรหัสผ่าน'),
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.black))
                                  : const Text('Login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('บัญชีทดสอบ (แตะเพื่อกรอกอัตโนมัติ)',
                        style: TextStyle(color: AppColors.textDim)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 10, children: [
                      ActionChip(
                        avatar: const Icon(Icons.shield_rounded, size: 18),
                        label: const Text('admin@test.com'),
                        onPressed: () => _fill('admin@test.com'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.person_rounded, size: 18),
                        label: const Text('operator@test.com'),
                        onPressed: () => _fill('operator@test.com'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
