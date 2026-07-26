import 'dart:convert';
import 'package:http/http.dart' as http;
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
import 'package:skillforge_student/features/learning/progress_screen.dart';
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
      // Fire all three API calls in parallel — some may fail (auth required)
      final results = await Future.wait([
        ApiClient.get(AppConstants.studentDashboardUrl).catchError((_) => http.Response('{}', 401)),
        ApiClient.get(AppConstants.enrollmentsUrl).catchError((_) => http.Response('{}', 401)),
        ApiClient.get('${AppConstants.coursesUrl}?size=6&sort=enrolledCount,desc').catchError((_) => http.Response('{}', 500)),
      ]);

      final dashResp = results[0];
      final enrollResp = results[1];
      final coursesResp = results[2];

      if (dashResp.statusCode == 200) {
        _dashboard = jsonDecode(dashResp.body)['data'];
      } else {
        // Provide sensible defaults when dashboard endpoint fails (e.g. mock token)
        _dashboard = {'unreadNotifications': 0, 'xp': 0};
      }

      if (enrollResp.statusCode == 200) {
        final body = jsonDecode(enrollResp.body);
        final rawData = body['data'];
        if (rawData is List) {
          _enrollments = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          _enrollments = rawData['content'];
        }
      }

      if (coursesResp.statusCode == 200) {
        final body = jsonDecode(coursesResp.body);
        final rawData = body['data'];
        if (rawData is List) {
          _courses = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          _courses = rawData['content'];
        }
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
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_loading)
                SliverToBoxAdapter(child: _shimmer())
              else if (_error != null)
                SliverToBoxAdapter(child: _errorState())
              else ...[
                // 1. Explore topics section
                SliverToBoxAdapter(
                  child: _sectionHeader('Explore topics',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen()))),
                ),
                SliverToBoxAdapter(child: _exploreTopics()),

                // 2. Recommended for you section
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: _sectionHeader('Recommended for you',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen()))),
                ),
                SliverToBoxAdapter(child: _recommendedCard()),

                // 3. Continue Learning / Schedule
                if (_enrollments.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _sectionHeader('Continue Learning',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())))),
                  SliverToBoxAdapter(child: _continueLearning()),
                ],

                // 4. Study Statistics snippet
                SliverToBoxAdapter(
                  child: _sectionHeader('My Statistic',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()))),
                ),
                SliverToBoxAdapter(child: _statisticsSnippetCard()),

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
    final fullName = auth.userName ?? 'Bianca Juliette';
    final firstName = fullName.split(' ').first;
    final unread = _dashboard?['unreadNotificationsCount'] ?? 0;
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'B';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('Good Morning', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                      SizedBox(width: 4),
                      Text('🌤️', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: -0.3)),
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
                            color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded, size: 22, color: Colors.white),
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Embedded search bar inside header matching Dream Theme Screen 1
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 10),
                  Text('What do you want to learn?',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3)),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
            ),
            child: const Text('See more', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  // Explore topics horizontal icon cards matching Dream Theme Screen 1
  Widget _exploreTopics() {
    final topics = [
      {'name': 'Business', 'icon': Icons.pie_chart_rounded},
      {'name': 'Design', 'icon': Icons.headphones_rounded},
      {'name': 'Finance', 'icon': Icons.folder_rounded},
      {'name': 'Marketing', 'icon': Icons.auto_awesome_rounded},
      {'name': 'Dev', 'icon': Icons.code_rounded},
    ];

    return SizedBox(
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final t = topics[i];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())),
            child: Column(
              children: [
                Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(t['icon'] as IconData, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(height: 8),
                Text(t['name'] as String,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
              ],
            ),
          );
        },
      ),
    );
  }

  // Recommended course card matching Dream Theme Screen 1
  Widget _recommendedCard() {
    final course = _courses.isNotEmpty ? _courses.first : {
      'title': 'Marketing Business Management',
      'category': 'Business Management',
      'instructor': 'Jerremy Mamika',
      'price': 48,
    };

    final title = course['title'] ?? 'Marketing Business Management';
    final category = course['category'] ?? course['categorySlug'] ?? 'Business Management';
    final instructor = course['instructorName'] ?? course['instructor'] ?? 'Jerremy Mamika';
    final price = course['price'] ?? 48;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseListScreen())),
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
              // Image Container with overlaid Heart icon
              Stack(
                children: [
                  Container(
                    height: 180,
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
                      child: Icon(Icons.school_rounded, size: 64, color: AppTheme.primary.withValues(alpha: 0.5)),
                    ),
                  ),
                  Positioned(
                    top: 14, right: 14,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border_rounded, size: 20, color: Color(0xFF94A3B8)),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 0.3)),
                    const SizedBox(height: 6),
                    Text(title.toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFCBD5E1),
                          child: Text(instructor[0].toUpperCase(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        Text(instructor.toString(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                        const Spacer(),
                        Text(
                          price == 0 ? 'Free' : '\$$price',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Statistics Card matching Dream Theme Screen 2
  Widget _statisticsSnippetCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: const Text('4 Lesson', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.purpleAccent)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: const Text('8 Challenges', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.purpleAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: const Text('7 Lesson', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.greenAccent)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
