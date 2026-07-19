import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Assignments Screen
/// API: GET /api/v1/courses/{courseId}/assessments
///      POST /api/v1/assessments/{assessmentId}/submissions  { textResponse }
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  // Load assignments via enrolled course IDs
  List<dynamic> _assignments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Get enrollments first, then assignments for each course
      final enrollResp = await ApiClient.get(AppConstants.enrollmentsUrl);
      if (enrollResp.statusCode != 200) {
        setState(() { _loading = false; _error = 'Could not load assignments.'; });
        return;
      }
      final enrollments = jsonDecode(enrollResp.body)['data']?['content']
          ?? jsonDecode(enrollResp.body)['data'] ?? [];

      final all = <dynamic>[];
      for (final enroll in enrollments.take(5)) {
        final courseId = (enroll['courseId'] ?? enroll['course']?['id'])?.toString() ?? '';
        if (courseId.isEmpty) continue;
        try {
          final aResp = await ApiClient.get(
              '${AppConstants.coursesUrl}/$courseId/assessments');
          if (aResp.statusCode == 200) {
            final items = jsonDecode(aResp.body)['data']?['content']
                ?? jsonDecode(aResp.body)['data'] ?? [];
            for (final item in items) {
              all.add({...item, 'courseTitle': enroll['courseTitle']
                  ?? enroll['course']?['title'] ?? 'Course'});
            }
          }
        } catch (_) {}
      }

      setState(() { _assignments = all; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; _error = 'You are offline.'; });
    }
  }

  void _openSubmitSheet(dynamic assignment) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgMain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.sp24, right: AppTheme.sp24, top: AppTheme.sp24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppTheme.sp24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment['title']?.toString() ?? 'Assignment',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.sp8),
            Text(assignment['description']?.toString() ?? '',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppTheme.sp16),
            TextField(
              controller: ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write your answer here...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppTheme.sp16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final assessmentId = assignment['id']?.toString() ?? '';
                  await ApiClient.post(
                    '${AppConstants.assessmentsBase}/$assessmentId/submissions',
                    {'textResponse': ctrl.text.trim()},
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Assignment submitted! 🎉'),
                      backgroundColor: AppTheme.success,
                    ));
                    _load();
                  }
                },
                child: const Text('Submit Assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Assignments'),
        backgroundColor: AppTheme.bgMain,
      ),
      body: _loading
          ? _shimmer()
          : _error != null
              ? _errorState()
              : _assignments.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.sp16),
                        itemCount: _assignments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.sp8),
                        itemBuilder: (_, i) {
                          final a = _assignments[i];
                          final submitted = a['submitted'] == true;
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
                                  Expanded(
                                    child: Text(a['title']?.toString() ?? 'Assignment',
                                        style: Theme.of(context).textTheme.labelLarge),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: submitted
                                          ? AppTheme.success.withValues(alpha: 0.1)
                                          : AppTheme.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      submitted ? 'Submitted' : 'Pending',
                                      style: TextStyle(
                                        color: submitted
                                            ? AppTheme.success : AppTheme.warning,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: AppTheme.sp4),
                                Text(a['courseTitle']?.toString() ?? '',
                                    style: Theme.of(context).textTheme.bodySmall),
                                if (a['description'] != null) ...[
                                  const SizedBox(height: AppTheme.sp8),
                                  Text(a['description'].toString(),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                                if (!submitted) ...[
                                  const SizedBox(height: AppTheme.sp16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => _openSubmitSheet(a),
                                      child: const Text('Submit'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(AppTheme.sp16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection,
      highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(4, (_) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp8),
        height: 120,
        decoration: BoxDecoration(color: AppTheme.bgSection,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
      ))),
    ),
  );

  Widget _errorState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: AppTheme.sp16),
      OutlinedButton(onPressed: _load, child: const Text('Retry')),
    ],
  ));

  Widget _emptyState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.assignment_outlined, size: 56, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text('No assignments yet.', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppTheme.sp8),
      Text('Enroll in a course to see assignments.', style: Theme.of(context).textTheme.bodyMedium),
    ],
  ));
}
