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
  List<dynamic> _allCourses = [];
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
      final url = AppConstants.coursesUrl;
      final resp = await ApiClient.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final rawData = body['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          list = rawData['content'];
        }
        _allCourses = List.from(list);
        _filterCourses(_searchQuery);
        setState(() => _loading = false);
      } else {
        _allCourses = [];
        _filterCourses(_searchQuery);
        setState(() { _loading = false; _error = 'Failed to load courses from backend.'; });
      }
    } catch (_) {
      _allCourses = [];
      _filterCourses(_searchQuery);
      setState(() { _loading = false; _error = 'Network error. Please check backend server.'; });
    }
  }

  void _filterCourses(String query) {
    if (query.trim().isEmpty) {
      _courses = List.from(_allCourses);
    } else {
      final q = query.trim().toLowerCase();
      _courses = _allCourses.where((c) {
        final title = (c['title'] ?? '').toString().toLowerCase();
        final desc = (c['description'] ?? '').toString().toLowerCase();
        final cat = (c['category'] ?? c['categorySlug'] ?? '').toString().toLowerCase();
        final level = (c['level'] ?? '').toString().toLowerCase();
        return title.contains(q) || desc.contains(q) || cat.contains(q) || level.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Electric Blue Header matching Dream Theme
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Explore Courses',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.filter_list_rounded, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                            cursorColor: AppTheme.primary,
                            decoration: const InputDecoration(
                              hintText: 'What do you want to learn?',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400),
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) {
                              setState(() {
                                _searchQuery = v;
                                _filterCourses(v);
                              });
                            },
                            onSubmitted: (v) {
                              setState(() {
                                _searchQuery = v;
                                _filterCourses(v);
                              });
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _filterCourses('');
                              });
                            },
                            child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? _shimmer()
                  : _error != null
                      ? _errorState()
                      : _courses.isEmpty
                          ? _emptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppTheme.primary,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(20),
                                itemCount: _courses.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (_, i) => _CourseTile(course: _courses[i]),
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
    final category = course['category'] ?? course['categorySlug'] ?? 'Online Learning';
    final instructor = course['instructorName'] ?? course['instructor'] ?? 'Instructor';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course['id'] ?? ''))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Cover Image area + Heart icon overlay
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.indigo.shade50],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.school_rounded, size: 54, color: AppTheme.primary.withValues(alpha: 0.5)),
                  ),
                ),
                Positioned(
                  top: 14, right: 14,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.toString().toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 0.3)),
                  const SizedBox(height: 6),
                  Text(title.toString(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: const Color(0xFFCBD5E1),
                        child: Text(instructor[0].toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Text(instructor.toString(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                      const Spacer(),
                      Text(
                        price == 0 ? 'Free' : '₹$price',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
