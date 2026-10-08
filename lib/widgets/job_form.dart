import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../main.dart';
import '../models/gpu_job.dart';
import 'code_inspector.dart';

/// ฟอร์มยื่นคำขอจองโหนดประมวลผล (ใช้ทั้งตอน Create และ Edit)
class JobForm extends StatefulWidget {
  final GpuJob? job;
  final String submitLabel;
  final Future<void> Function(GpuJob job) onSubmit;

  const JobForm({
    super.key,
    this.job,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<JobForm> createState() => _JobFormState();
}

class _JobFormState extends State<JobForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _framework;
  late final TextEditingController _email;
  late final TextEditingController _gpus;
  late final TextEditingController _hours;
  bool _saving = false;

  static const _frameworks = ['PyTorch', 'TensorFlow', 'JAX'];

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    _name = TextEditingController(text: j?.experimentName ?? '');
    _framework = TextEditingController(text: j?.framework ?? '');
    _email = TextEditingController(text: j?.researcherEmail ?? '');
    _gpus = TextEditingController(text: j?.gpus.toString() ?? '');
    _hours = TextEditingController(text: j?.maxHours.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _framework, _email, _gpus, _hours]) {
      c.dispose();
    }
    super.dispose();
  }

  final _numberValidator = MultiValidator([
    RequiredValidator(errorText: 'ห้ามเว้นว่าง'),
    PatternValidator(r'^[1-9][0-9]*$',
        errorText: 'กรอกเป็นตัวเลขจำนวนเต็มที่มากกว่า 0'),
  ]);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(GpuJob(
        id: widget.job?.id,
        experimentName: _name.text.trim(),
        framework: _framework.text.trim(),
        researcherEmail: _email.text.trim(),
        gpus: int.parse(_gpus.text.trim()),
        maxHours: int.parse(_hours.text.trim()),
      ));
      if (widget.job == null && mounted) {
        _formKey.currentState!.reset();
        for (final c in [_name, _framework, _email, _gpus, _hours]) {
          c.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('เกิดข้อผิดพลาด: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
                icon: Icons.memory_rounded, text: 'ยื่นคำขอจองโหนดประมวลผล'),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'ชื่อโปรเจกต์ / การทดลอง (Experiment Name)',
                hintText: 'เช่น LLM-FineTune-V3',
                prefixIcon: Icon(Icons.science_rounded),
              ),
              validator: RequiredValidator(
                  errorText: 'กรุณากรอกชื่อโปรเจกต์ / การทดลอง'),
            ).explain('form_name'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _framework,
              decoration: const InputDecoration(
                labelText: 'ประเภทโมเดล / Framework',
                hintText: 'เช่น PyTorch, TensorFlow, JAX',
                prefixIcon: Icon(Icons.hub_rounded),
              ),
              validator:
                  RequiredValidator(errorText: 'กรุณากรอกประเภทโมเดล / Framework'),
            ).explain('form_framework'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _frameworks
                  .map((f) => ActionChip(
                        label: Text(f),
                        backgroundColor: const Color(0xFF16233B),
                        side: BorderSide.none,
                        onPressed: () =>
                            setState(() => _framework.text = f),
                      ))
                  .toList(),
            ).explain('form_chips'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'อีเมลนักวิจัยหลัก (Principal Researcher)',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: MultiValidator([
                RequiredValidator(errorText: 'กรุณากรอกอีเมล'),
                EmailValidator(errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
              ]),
            ).explain('form_email'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gpus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'จำนวนการ์ด GPU ที่ขอใช้ (Allocated GPUs)',
                prefixIcon: Icon(Icons.developer_board_rounded),
              ),
              validator: _numberValidator,
            ).explain('form_gpus'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hours,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'เวลาจำกัดการรัน (Max Compute Hours)',
                prefixIcon: Icon(Icons.timer_rounded),
              ),
              validator: _numberValidator,
            ).explain('form_hours'),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(widget.submitLabel),
            ).explain('form_submit'),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accent2]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.black),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(text,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      ),
    ]);
  }
}
