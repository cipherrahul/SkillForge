import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Quiz Screen — AI-Generated quiz per lesson
/// API: POST /api/v1/ai/lessons/{lessonId}/generate-quiz
///      POST /api/v1/assessments/{assessmentId}/submissions  { answers: [...] }
class QuizScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  const QuizScreen({super.key, required this.lessonId, required this.lessonTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _questions = [];
  String? _assessmentId;
  Map<int, int> _selected = {};
  bool _loading = true;
  bool _submitted = false;
  bool _submitting = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.post(
          '${AppConstants.baseUrl}/ai/lessons/${widget.lessonId}/generate-quiz', {});
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _questions = body['data']?['questions'] ?? [];
          _assessmentId = body['data']?['assessmentId']?.toString();
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = 'Could not generate quiz. Please try again.'; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = 'You are offline.'; });
    }
  }

  Future<void> _submit() async {
    if (_selected.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please answer all questions before submitting.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      final answers = _selected.entries.map((e) => {
        'questionIndex': e.key,
        'selectedOption': e.value,
      }).toList();

      final url = _assessmentId != null
          ? '${AppConstants.assessmentsBase}/$_assessmentId/submissions'
          : '${AppConstants.assessmentsBase}/submissions';

      final resp = await ApiClient.post(url, {'answers': answers});
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _result = body['data'];
          _submitted = true;
          _submitting = false;
        });
      } else {
        setState(() => _submitting = false);
      }
    } catch (_) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: Text(widget.lessonTitle, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.bgMain,
      ),
      body: _loading
          ? _loadingState()
          : _error != null
              ? _errorState()
              : _submitted
                  ? _resultState()
                  : _quizBody(),
    );
  }

  Widget _loadingState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const CircularProgressIndicator(color: AppTheme.primary),
      const SizedBox(height: AppTheme.sp16),
      Text('Generating your quiz...', style: Theme.of(context).textTheme.bodyMedium),
    ],
  ));

  Widget _errorState() => Center(child: Padding(
    padding: const EdgeInsets.all(AppTheme.sp48),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
      const SizedBox(height: AppTheme.sp16),
      Text(_error!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: AppTheme.sp16),
      ElevatedButton(onPressed: _generate, child: const Text('Try Again')),
    ]),
  ));

  Widget _resultState() {
    final score = _result?['score'] ?? 0;
    final total = _result?['totalQuestions'] ?? _questions.length;
    final passed = _result?['passed'] ?? false;
    return Center(child: Padding(
      padding: const EdgeInsets.all(AppTheme.sp32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: passed ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
            size: 52,
            color: passed ? AppTheme.success : AppTheme.error,
          ),
        ),
        const SizedBox(height: AppTheme.sp24),
        Text(passed ? '🎉 Great Job!' : 'Keep Practicing!',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppTheme.sp8),
        Text('You scored $score out of $total',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppTheme.sp32),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selected = {};
              _submitted = false;
              _result = null;
            });
            _generate();
          },
          child: const Text('Retake Quiz'),
        ),
      ]),
    ));
  }

  Widget _quizBody() => Column(
    children: [
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppTheme.sp16),
          itemCount: _questions.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp16),
          itemBuilder: (_, qi) {
            final q = _questions[qi];
            final options = (q['options'] as List?) ?? [];
            return Container(
              padding: const EdgeInsets.all(AppTheme.sp16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('${qi + 1}',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 13))),
                    ),
                    const SizedBox(width: AppTheme.sp8),
                    Expanded(
                      child: Text(q['question']?.toString() ?? '',
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                  ]),
                  const SizedBox(height: AppTheme.sp16),
                  ...List.generate(options.length, (oi) {
                    final selected = _selected[qi] == oi;
                    return GestureDetector(
                      onTap: () => setState(() => _selected[qi] = oi),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.sp8),
                        padding: const EdgeInsets.all(AppTheme.sp16),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryLight
                              : AppTheme.bgSecondary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                          border: Border.all(
                            color: selected ? AppTheme.primary : AppTheme.divider,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            selected ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected ? AppTheme.primary : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.sp8),
                          Expanded(child: Text(options[oi]?.toString() ?? '',
                              style: TextStyle(
                                color: selected ? AppTheme.primary : AppTheme.textBody,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ))),
                        ]),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
      Container(
        padding: const EdgeInsets.all(AppTheme.sp16),
        color: AppTheme.bgMain,
        child: Row(children: [
          Text('${_selected.length}/${_questions.length} answered',
              style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Quiz'),
          ),
        ]),
      ),
    ],
  );
}
