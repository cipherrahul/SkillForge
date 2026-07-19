import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';
import 'package:skillforge_student/features/auth/auth_provider.dart';
import 'package:skillforge_student/features/course/course_list_screen.dart';
import 'package:skillforge_student/features/liveclass/live_class_screen.dart';
import 'package:skillforge_student/features/notifications/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Dashboard data from /mobile/student/dashboard
  Map<String, dynamic>? _dashboard;
  // Enrollment data from /enrollments (has progressPercent)
  List<dynamic> _enrollments = [];
  // Courses from /courses (for trending)
  List<dynamic> _courses = [];

  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Fire all three API calls in parallel
      final results = await Future.wait([
        ApiClient.get(AppConstants.studentDashboardUrl),
        ApiClient.get(AppConstants.enrollmentsUrl),
        ApiClient.get('${AppConstants.coursesUrl}?size=6&sort=enrolledCount,desc'),
      ]);

      final dashResp = results[0];
      final enrollResp = results[1];
      final coursesResp = results[2];

      if (dashResp.statusCode == 200) {
        _dashboard = jsonDecode(dashResp.body)['data'];
      }

      if (enrollResp.statusCode == 200) {
        final body = jsonDecode(enrollResp.body);
        _enrollments = body['data']?['content'] ?? body['data'] ?? [];
      }

      if (coursesResp.statusCode == 200) {
        final body = jsonDecode(coursesResp.body);
        _courses = body['data']?['content'] ?? body['data'] ?? [];
      }

      if (dashResp.statusCode != 200) {
        setState(() { _loading = false; _error = 'Failed to load dashboard.'; });
        return;
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = 'You are offline. Check your connection.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _searchBar()),
              if (_loading)
                SliverToBoxAdapter(child: _shimmer())
              else if (_error != null)
                SliverToBoxAdapter(child: _errorState())
              else ...[
                if (_enrollments.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _sectionHeader('Continue Learning',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())))),
                  SliverToBoxAdapter(child: _continueLearning()),
                ],
                if (_dashboard?['nextLiveClassTitle'] != null) ...[
                  SliverToBoxAdapter(child: _sectionHeader('Your Schedule',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveClassScreen())))),
                  SliverToBoxAdapter(child: _scheduleCard()),
                ],
                if (_courses.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _sectionHeader('Trending Now 🔥',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())))),
                  SliverToBoxAdapter(child: _trendingRow()),
                ],
                if (_enrollments.isNotEmpty)
                  SliverToBoxAdapter(child: _weeklyGoalCard()),
                if (_enrollments.isEmpty && _courses.isEmpty)
                  SliverToBoxAdapter(child: _emptyState()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final auth = context.watch<AuthProvider>();
    final firstName = (auth.userName ?? 'Learner').split(' ').first;
    final unread = _dashboard?['unreadNotificationsCount'] ?? 0;
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, $firstName! 👋',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A), letterSpacing: -0.4)),
              const SizedBox(height: 2),
              Text('Keep learning, keep growing.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                child: Stack(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.notifications_outlined, size: 22, color: Color(0xFF0F172A)),
                    ),
                    if (unread > 0)
                      Positioned(top: 6, right: 6,
                        child: Container(
                          width: 9, height: 9,
                          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
              const SizedBox(width: 10),
              Text('Search for courses, topics...',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: const Size(0, 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  // Colors per course index
  static const List<List<Color>> _courseColors = [
    [Color(0xFFEF4444), Color(0xFFDC2626)],
    [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    [Color(0xFF22C55E), Color(0xFF16A34A)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF6366F1), Color(0xFF4F46E5)],
    [Color(0xFF0EA5E9), Color(0xFF0284C7)],
  ];

  static const List<IconData> _courseIcons = [
    Icons.code_rounded, Icons.phone_android_rounded, Icons.storage_rounded,
    Icons.bar_chart_rounded, Icons.account_tree_rounded, Icons.cloud_rounded,
  ];

  Widget _continueLearning() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _enrollments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final e = _enrollments[i];
          final title = e['courseTitle']?.toString() ?? 'Course';
          final progressPercent = (e['progressPercent'] ?? 0).toDouble();
          final progress = (progressPercent / 100.0).clamp(0.0, 1.0);
          final colors = _courseColors[i % _courseColors.length];
          final icon = _courseIcons[i % _courseIcons.length];
          final tag = title.split(' ').first.toUpperCase().substring(0, title.split(' ').first.length.clamp(0, 6));

          return Container(
            width: 260,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 70, height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 26),
                      const SizedBox(height: 4),
                      Text(tag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text('${progressPercent.toInt()}% Complete',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors[0])),
                      const SizedBox(height: 6),
                      LinearPercentIndicator(
                        lineHeight: 6, percent: progress,
                        backgroundColor: Colors.grey.shade100,
                        progressColor: colors[0],
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: colors[0].withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.play_arrow_rounded, color: colors[0], size: 20),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _scheduleCard() {
    final title = _dashboard?['nextLiveClassTitle'] ?? 'Live Class';
    final rawTime = _dashboard?['nextLiveClassTime'];
    String timeStr = 'Scheduled';
    if (rawTime != null) {
      try {
        final dt = DateTime.parse(rawTime.toString()).toLocal();
        final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1];
        timeStr = '${dt.day} $month, $hour:${dt.minute.toString().padLeft(2,'0')} $ampm';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toString(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(timeStr, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveClassScreen())),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF), foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Join', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendingRow() {
    // Color gradients for trending cards
    final gradients = [
      [const Color(0xFF22C55E), const Color(0xFF16A34A)],
      [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
      [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
    ];
    final icons = [Icons.storage_rounded, Icons.account_tree_rounded, Icons.phone_android_rounded,
      Icons.bar_chart_rounded, Icons.code_rounded, Icons.cloud_rounded];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _courses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final c = _courses[i];
          final title = c['title']?.toString() ?? 'Course';
          final category = c['categorySlug']?.toString() ?? c['difficulty']?.toString() ?? '';
          final grad = gradients[i % gradients.length];
          final icon = icons[i % icons.length];

          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: grad[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white.withOpacity(0.85), size: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (category.isNotEmpty)
                        Text(category, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _weeklyGoalCard() {
    // Calculate real overall progress from enrollments
    final totalProgress = _enrollments.isEmpty ? 0.0
        : _enrollments.map((e) => (e['progressPercent'] ?? 0).toDouble()).reduce((a, b) => a + b)
        / (_enrollments.length * 100.0);
    final xp = _dashboard?['statsXp'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('⚡ $xp XP', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              lineHeight: 8, percent: totalProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.25),
              progressColor: Colors.white,
              barRadius: const Radius.circular(8),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            Text('${_enrollments.length} course${_enrollments.length == 1 ? '' : 's'} enrolled • ${(totalProgress * 100).toInt()}% avg completion',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.school_outlined, color: AppTheme.primary, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Start Your Learning Journey!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text('Explore and enroll in courses to see your progress here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())),
            icon: const Icon(Icons.explore_rounded, size: 18),
            label: const Text('Explore Courses'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade100,
        highlightColor: Colors.grey.shade50,
        child: Column(
          children: List.generate(4, (_) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 90,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          )),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: AppTheme.textDisabled),
          const SizedBox(height: 16),
          Text(_error!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }
}
