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
        final rawData = body['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          list = rawData['content'];
        }
        setState(() {
          _enrollments = list;
          _loading = false;
        });
      } else {
        setState(() {
          _enrollments = [];
          _loading = false;
          _error = 'Failed to load progress from backend.';
        });
      }
    } catch (_) {
      setState(() {
        _enrollments = [];
        _loading = false;
        _error = 'Network error loading progress.';
      });
    }
  }

  int _selectedDayIndex = 3;
  int _selectedMonthOffset = 0;
  String _selectedFilter = 'All';

  final List<String> _months = const [
    'January 2023', 'February 2023', 'March 2023', 'April 2023',
    'May 2023', 'June 2023', 'July 2023', 'August 2023',
    'September 2023', 'October 2023', 'November 2023', 'December 2023'
  ];

  final List<List<String>> _monthDays = const [
    ['25', '26', '27', '28', '29', '30', '31'], // Apr
    ['28', '29', '30', '31', '1', '2', '3'],    // May
    ['26', '27', '28', '29', '30', '1', '2'],    // Jun
  ];

  @override
  Widget build(BuildContext context) {
    final currentMonthIndex = (4 + _selectedMonthOffset).clamp(0, 11);
    final monthName = _months[currentMonthIndex];
    final daysList = _monthDays[(_selectedMonthOffset + 1).clamp(0, 2)];

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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statistic options opened')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Blue Calendar Card with interactive Month & Day switching
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(monthName,
                            key: ValueKey(monthName),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_selectedMonthOffset > -1) {
                                setState(() => _selectedMonthOffset--);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (_selectedMonthOffset < 1) {
                                setState(() => _selectedMonthOffset++);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                            ),
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
                    children: List.generate(daysList.length, (idx) {
                      final dayStr = daysList[idx];
                      final isSelected = _selectedDayIndex == idx;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = idx),
                        child: _DayCell(dayStr, isSelected: isSelected),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Interactive Record Cards
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
                        Text('${_selectedDayIndex + 1} Days',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Text('Current Record', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedFilter = 'Lesson'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _selectedFilter == 'Lesson' ? Colors.amber.shade300 : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${_selectedDayIndex * 2 + 2} Lesson',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.purpleAccent)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _selectedFilter = 'Challenge'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _selectedFilter == 'Challenge' ? Colors.amber.shade300 : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${_selectedDayIndex * 3 + 4} Challenges',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.purpleAccent)),
                              ),
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
                        Text('${_selectedDayIndex + 2} Days',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Text('Current Record', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Text('${_selectedDayIndex * 2 + 3} Lesson',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.greenAccent)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Text('${_selectedDayIndex * 3 + 5} Challenges',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.greenAccent)),
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

            // 3. Dynamic Study Statistic Bar Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Study Statistic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedFilter = 'Learning'),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Learning',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _selectedFilter == 'Learning' ? AppTheme.primary : const Color(0xFF64748B),
                                  fontWeight: _selectedFilter == 'Learning' ? FontWeight.w800 : FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _selectedFilter = 'Challenge'),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.greenAccent, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Challenge',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _selectedFilter == 'Challenge' ? AppTheme.greenAccent : const Color(0xFF64748B),
                                  fontWeight: _selectedFilter == 'Challenge' ? FontWeight.w800 : FontWeight.w500)),
                        ],
                      ),
                    ),
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
                  children: [
                    _BarGroup('Sun', h1: 40 + (_selectedDayIndex * 5), h2: 30 + (_selectedDayIndex * 4)),
                    _BarGroup('Mon', h1: 100 + (_selectedDayIndex * 3), h2: 80 + (_selectedDayIndex * 2)),
                    _BarGroup('Tue', h1: 90 + (_selectedDayIndex * 4), h2: 60 + (_selectedDayIndex * 3)),
                    _BarGroup('Wed', h1: 80 + (_selectedDayIndex * 2), h2: 55 + (_selectedDayIndex * 4)),
                    _BarGroup('Thu', h1: 95 + (_selectedDayIndex * 3), h2: 70 + (_selectedDayIndex * 2)),
                    _BarGroup('Fri', h1: 65 + (_selectedDayIndex * 4), h2: 45 + (_selectedDayIndex * 3)),
                    _BarGroup('Sat', h1: 35 + (_selectedDayIndex * 2), h2: 25 + (_selectedDayIndex * 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Enrolled Courses Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            if (_loading)
              _shimmer()
            else if (_error != null)
              _errorState()
            else if (_enrollments.isEmpty)
              _emptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _enrollments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final item = _enrollments[idx];
                  final title = item['courseTitle'] ?? item['course']?['title'] ?? 'Course';
                  final progress = (item['progressPercent'] ?? item['progress'] ?? 0).toInt();
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        LinearPercentIndicator(
                          lineHeight: 8,
                          percent: (progress / 100).clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFFF1F5F9),
                          progressColor: AppTheme.primary,
                          barRadius: const Radius.circular(4),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 6),
                        Text('$progress% Completed',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  );
                },
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
