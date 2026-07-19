import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';
import 'video_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Map<String, dynamic>? _course;
  bool _loading = true;
  bool _enrolling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await ApiClient.get(
          '${AppConstants.coursesUrl}/${widget.courseId}');
      if (resp.statusCode == 200) {
        setState(() {
          _course = jsonDecode(resp.body)['data'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _enroll() async {
    setState(() => _enrolling = true);
    try {
      // Backend: POST /api/v1/enrollments  { "courseId": "..." }
      // EnrollmentController.java line 29
      final resp = await ApiClient.post(AppConstants.enrollmentsUrl,
          {'courseId': widget.courseId});
      if (!mounted) return;
      final ok = resp.statusCode == 200;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Enrolled successfully! 🎉'
            : 'Enrollment failed. Please try again.'),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppTheme.error));
      }
    }
    if (mounted) setState(() => _enrolling = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.bgMain,
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.sp16),
          child: Shimmer.fromColors(
            baseColor: AppTheme.bgSection,
            highlightColor: AppTheme.bgSecondary,
            child: Column(
              children: List.generate(5, (_) => Container(
                margin: const EdgeInsets.only(bottom: AppTheme.sp16),
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.bgSection,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
              )),
            ),
          ),
        ),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Course not found.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.bgMain,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.primaryLight,
                child: const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      size: 80, color: AppTheme.primary),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.bgMain,
              padding: const EdgeInsets.all(AppTheme.sp24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_course!['title'] ?? '',
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: AppTheme.sp8),
                  Text(_course!['description'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppTheme.sp16),
                  // Meta row
                  Wrap(
                    spacing: AppTheme.sp16,
                    runSpacing: AppTheme.sp8,
                    children: [
                      _MetaChip(icon: Icons.bar_chart_rounded,
                          label: _course!['level'] ?? ''),
                      _MetaChip(icon: Icons.access_time_rounded,
                          label: '${_course!['durationHours'] ?? 0}h'),
                      const _MetaChip(icon: Icons.star_rounded,
                          label: '4.5 Rating',
                          color: AppTheme.warning),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.sp24,
                  AppTheme.sp24, AppTheme.sp24, AppTheme.sp8),
              child: Text('Course Content',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final section =
                    (_course!['sections'] as List? ?? [])[i];
                return _SectionTile(section: section);
              },
              childCount: (_course!['sections'] as List? ?? []).length,
            ),
          ),
          const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.sp64)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.sp16),
          decoration: const BoxDecoration(
            color: AppTheme.bgMain,
            border: Border(top: BorderSide(color: AppTheme.divider)),
          ),
          child: Row(
            children: [
              Text(
                _course!['price'] == 0
                    ? 'Free'
                    : '₹${_course!['price']}',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: AppTheme.primary),
              ),
              const SizedBox(width: AppTheme.sp16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _enrolling ? null : _enroll,
                  child: _enrolling
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Enroll Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({required this.icon, required this.label,
      this.color = AppTheme.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: color)),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  final dynamic section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    final lessons = (section['lessons'] as List?) ?? [];
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.sp16, 0,
          AppTheme.sp16, AppTheme.sp8),
      decoration: BoxDecoration(
        color: AppTheme.bgMain,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ExpansionTile(
        title: Text(section['title'] ?? '',
            style: Theme.of(context).textTheme.labelLarge),
        subtitle: Text('${lessons.length} lessons',
            style: Theme.of(context).textTheme.bodySmall),
        children: lessons.map<Widget>((l) {
          final type = l['lessonType'] ?? 'VIDEO';
          final dur = (l['durationSeconds'] ?? 0) ~/ 60;
          return ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                type == 'VIDEO'
                    ? Icons.play_arrow_rounded
                    : Icons.description_outlined,
                color: AppTheme.primary, size: 20,
              ),
            ),
            title: Text(l['title'] ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(type == 'VIDEO' ? '$dur min' : 'PDF',
                style: Theme.of(context).textTheme.bodySmall),
            onTap: () {
              if (type == 'VIDEO' && l['videoUrl'] != null) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(
                        videoUrl: l['videoUrl'],
                        lessonTitle: l['title'] ?? '')));
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
