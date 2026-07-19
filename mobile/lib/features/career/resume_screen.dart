import 'package:flutter/material.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Resume Builder Screen
/// API: POST /api/v1/resumes  { fullName, education, experience, skills, projects }
class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  bool _saved = false;

  final _fullName  = TextEditingController();
  final _education = TextEditingController();
  final _experience= TextEditingController();
  final _skills    = TextEditingController();
  final _projects  = TextEditingController();

  @override
  void dispose() {
    for (final c in [_fullName, _education, _experience, _skills, _projects]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final resp = await ApiClient.post(AppConstants.resumesUrl, {
        'fullName'   : _fullName.text.trim(),
        'education'  : _education.text.trim(),
        'experience' : _experience.text.trim(),
        'skills'     : _skills.text.trim(),
        'projects'   : _projects.text.trim(),
      });
      if (mounted) {
        setState(() { _saving = false; _saved = resp.statusCode == 200; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(resp.statusCode == 200
              ? 'Resume saved & PDF generated! 🎉' : 'Could not save. Please try again.'),
          backgroundColor: resp.statusCode == 200 ? AppTheme.success : AppTheme.error,
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Resume Builder'),
        backgroundColor: AppTheme.bgMain,
        actions: [
          if (_saved)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.sp16),
              child: Icon(Icons.check_circle_rounded, color: AppTheme.success),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.sp16),
          children: [
            const _SectionHeader('Personal Information'),
            const SizedBox(height: AppTheme.sp8),
            _Field('Full Name', _fullName, required: true),
            const SizedBox(height: AppTheme.sp16),
            const _SectionHeader('Education'),
            const SizedBox(height: AppTheme.sp8),
            _Field('e.g. B.Tech CS — XYZ University (2021–2025)', _education, lines: 3, required: true),
            const SizedBox(height: AppTheme.sp16),
            const _SectionHeader('Work Experience'),
            const SizedBox(height: AppTheme.sp8),
            _Field('e.g. Flutter Intern — ABC Corp (2024)', _experience, lines: 4, required: true),
            const SizedBox(height: AppTheme.sp16),
            const _SectionHeader('Skills'),
            const SizedBox(height: AppTheme.sp4),
            Text('Separate with commas — e.g. Flutter, Java, Dart, REST APIs',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppTheme.sp8),
            _Field('Skills', _skills, lines: 2, required: true),
            const SizedBox(height: AppTheme.sp16),
            const _SectionHeader('Projects'),
            const SizedBox(height: AppTheme.sp8),
            _Field('e.g. Portfolio App, E-Commerce Website', _projects, lines: 3, required: true),
            const SizedBox(height: AppTheme.sp32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.sp16),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & Build Resume', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: AppTheme.sp48),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700));
}

class _Field extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final int lines;
  final bool required;
  const _Field(this.hint, this.ctrl,
      {this.lines = 1, this.required = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: lines, minLines: 1,
      decoration: InputDecoration(hintText: hint),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$hint is required' : null
          : null,
    );
  }
}
