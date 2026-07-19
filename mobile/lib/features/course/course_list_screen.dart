import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  List<dynamic> _courses = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final url = _searchQuery.isNotEmpty
          ? '${AppConstants.coursesUrl}?keyword=${Uri.encodeComponent(_searchQuery)}'
          : AppConstants.coursesUrl;
      final resp = await ApiClient.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _courses = body['data']?['content'] ?? body['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = 'Something went wrong. Please try again.'; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = 'You are offline.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Explore'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.sp16, 0, AppTheme.sp16, AppTheme.sp16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for courses...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _load();
                        })
                    : null,
              ),
              onSubmitted: (v) {
                setState(() => _searchQuery = v.trim());
                _load();
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? _shimmer()
          : _error != null
              ? _errorState()
              : _courses.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.sp16),
                        itemCount: _courses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.sp8),
                        itemBuilder: (_, i) =>
                            _CourseTile(course: _courses[i]),
                      ),
                    ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(AppTheme.sp16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection,
      highlightColor: AppTheme.bgSecondary,
      child: Column(
        children: List.generate(6, (_) => Container(
          margin: const EdgeInsets.only(bottom: AppTheme.sp8),
          height: 100,
          decoration: BoxDecoration(color: AppTheme.bgSection,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
        )),
      ),
    ),
  );

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.sp48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textDisabled),
          const SizedBox(height: AppTheme.sp16),
          Text(_error!, style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.sp16),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    ),
  );

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textDisabled),
        const SizedBox(height: AppTheme.sp16),
        Text('No courses found',
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

/// Course Card — Design.md §13: thumbnail, title, instructor, rating,
/// duration, students enrolled, price, difficulty, progress
class _CourseTile extends StatelessWidget {
  final dynamic course;
  const _CourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final title = course['title'] ?? 'Untitled Course';
    final price = course['price'] ?? 0;
    final level = course['level'] ?? '';
    final duration = course['durationHours'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
              CourseDetailScreen(courseId: course['id'] ?? ''))),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.sp16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              ),
              child: const Icon(Icons.play_circle_outline_rounded,
                  color: AppTheme.primary, size: 36),
            ),
            const SizedBox(width: AppTheme.sp16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toString(),
                      style: Theme.of(context).textTheme.labelLarge,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppTheme.sp4),
                  // Rating, Duration
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppTheme.warning),
                      const SizedBox(width: 3),
                      Text('4.5', style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.warning,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: AppTheme.sp8),
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text('${duration}h',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppTheme.sp4),
                  // Level + Price
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(level.toString(),
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Text(
                        price == 0 ? 'Free' : '₹$price',
                        style: TextStyle(
                          color: price == 0
                              ? AppTheme.success
                              : AppTheme.textHeading,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
