import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Progress Tracking Screen
/// API: GET /api/v1/enrollments
///      POST /api/v1/enrollments/{enrollmentId}/lessons/{lessonId}/progress
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<dynamic> _enrollments = [];
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
      final resp = await ApiClient.get(AppConstants.enrollmentsUrl);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _enrollments = body['data']?['content'] ?? body['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = 'Something went wrong. Please try again.'; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = 'You are offline. Previously downloaded content is still available.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: AppTheme.bgMain,
      ),
      body: _loading
          ? _shimmer()
          : _error != null
              ? _errorState()
              : _enrollments.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.sp16),
                        itemCount: _enrollments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.sp8),
                        itemBuilder: (_, i) =>
                            _EnrollmentCard(enrollment: _enrollments[i]),
                      ),
                    ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(AppTheme.sp16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection,
      highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(5, (_) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp8),
        height: 110,
        decoration: BoxDecoration(color: AppTheme.bgSection,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
      ))),
    ),
  );

  Widget _errorState() => Center(child: Padding(
    padding: const EdgeInsets.all(AppTheme.sp48),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text(_error!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: AppTheme.sp16),
      OutlinedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  ));

  Widget _emptyState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.school_outlined, size: 56, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text('No courses enrolled yet.', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppTheme.sp8),
      Text('Start exploring courses.', style: Theme.of(context).textTheme.bodyMedium),
    ],
  ));
}

class _EnrollmentCard extends StatelessWidget {
  final dynamic enrollment;
  const _EnrollmentCard({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final courseTitle = enrollment['courseTitle'] ?? enrollment['course']?['title'] ?? 'Course';
    final progress = (enrollment['progressPercent'] ?? 0).toDouble() / 100.0;
    final completedLessons = enrollment['completedLessons'] ?? 0;
    final totalLessons = enrollment['totalLessons'] ?? 0;

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
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
                child: const Icon(Icons.play_circle_outline_rounded,
                    color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: AppTheme.sp16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(courseTitle.toString(),
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('$completedLessons / $totalLessons lessons',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text('${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: AppTheme.sp12),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: progress.clamp(0.0, 1.0),
            backgroundColor: AppTheme.bgSection,
            progressColor: progress >= 1.0 ? AppTheme.success : AppTheme.primary,
            barRadius: const Radius.circular(8),
            padding: EdgeInsets.zero,
          ),
          if (progress >= 1.0) ...[
            const SizedBox(height: AppTheme.sp8),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 16),
                const SizedBox(width: 6),
                Text('Completed! Certificate available.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.success,
                            fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
