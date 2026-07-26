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

  static const List<Map<String, dynamic>> _defaultEnrollments = [
    {
      'id': 'en1',
      'courseTitle': 'Full-Stack Web Development (React & Node.js)',
      'progressPercent': 75,
      'completedLessons': 18,
      'totalLessons': 24,
    },
    {
      'id': 'en2',
      'courseTitle': 'Flutter & Dart: Complete Cross-Platform Guide',
      'progressPercent': 100,
      'completedLessons': 30,
      'totalLessons': 30,
    },
    {
      'id': 'en3',
      'courseTitle': 'Java Spring Boot & Microservices Architecture',
      'progressPercent': 40,
      'completedLessons': 10,
      'totalLessons': 25,
    },
  ];

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.get(AppConstants.enrollmentsUrl);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final rawData = body['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          list = rawData['content'];
        }
        if (list.isEmpty) {
          list = List.from(_defaultEnrollments);
        }
        setState(() {
          _enrollments = list;
          _loading = false;
        });
      } else {
        setState(() {
          _enrollments = List.from(_defaultEnrollments);
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _enrollments = List.from(_defaultEnrollments);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('My Statistic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Blue Calendar Card matching Dream Theme Screen 2
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('May 2023', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _DayHeader('Sun'), _DayHeader('Mon'), _DayHeader('Tue'), _DayHeader('Wed'), _DayHeader('Thu'), _DayHeader('Fri'), _DayHeader('Sat'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _DayCell('28'), _DayCell('29'), _DayCell('30'),
                      _DayCell('31', isSelected: true),
                      _DayCell('1'), _DayCell('2'), _DayCell('3'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Purple & Green Record Cards matching Dream Theme Screen 2
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('2 Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Text('Current Record', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Text('4 Lesson', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.purpleAccent)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Text('8 Challenges', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.purpleAccent)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.greenAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('3 Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Text('Current Record', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Text('7 Lesson', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.greenAccent)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Text('11 Challenges', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.greenAccent)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Study Statistic Chart Section matching Dream Theme Screen 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Study Statistic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Learning', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.greenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Challenge', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: SizedBox(
                height: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    _BarGroup('Sun', h1: 60, h2: 40),
                    _BarGroup('Mon', h1: 120, h2: 90),
                    _BarGroup('Tue', h1: 100, h2: 70),
                    _BarGroup('Wed', h1: 85, h2: 60),
                    _BarGroup('Thu', h1: 95, h2: 75),
                    _BarGroup('Fri', h1: 70, h2: 50),
                    _BarGroup('Sat', h1: 40, h2: 30),
                  ],
                ),
              ),
            ),
          ],
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

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70));
  }
}

class _DayCell extends StatelessWidget {
  final String day;
  final bool isSelected;
  const _DayCell(this.day, {this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
          ],
        ),
      );
    }
    return Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white));
  }
}

class _BarGroup extends StatelessWidget {
  final String day;
  final double h1;
  final double h2;
  const _BarGroup(this.day, {required this.h1, required this.h2});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 7, height: h1,
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 4),
            Container(
              width: 7, height: h2,
              decoration: BoxDecoration(color: AppTheme.greenAccent, borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
      ],
    );
  }
}
