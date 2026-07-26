import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Live Classes Screen
/// API: GET  /api/v1/courses/{courseId}/live-sessions
///      POST /api/v1/live-sessions/{sessionId}/join  → returns join token/url
class LiveClassScreen extends StatefulWidget {
  const LiveClassScreen({super.key});

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _upcoming = [];
  List<dynamic> _past = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static const List<Map<String, dynamic>> _defaultSessions = [
    {
      'id': 'ls1',
      'title': 'Live Q&A: System Design & Microservices Best Practices',
      'instructorName': 'Dr. Aris Thorne',
      'scheduledAt': 'Today at 6:00 PM',
      'status': 'LIVE',
    },
    {
      'id': 'ls2',
      'title': 'Flutter 3.x State Management Workshop (Provider & Riverpod)',
      'instructorName': 'Sophia Chen',
      'scheduledAt': 'Tomorrow at 4:00 PM',
      'status': 'SCHEDULED',
    },
    {
      'id': 'ls3',
      'title': 'Building Scalable APIs with Spring Boot 3 & GraphQL',
      'instructorName': 'Marcus Vance',
      'scheduledAt': 'Yesterday at 5:00 PM',
      'status': 'COMPLETED',
    },
  ];

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.get(AppConstants.liveSessionsBase);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final rawData = body['data'];
        List<dynamic> all = [];
        if (rawData is List) {
          all = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          all = rawData['content'];
        }
        if (all.isEmpty) {
          all = List.from(_defaultSessions);
        }
        setState(() {
          _upcoming = all.where((s) {
            final status = s['status']?.toString() ?? '';
            return status == 'SCHEDULED' || status == 'LIVE';
          }).toList();
          _past = all.where((s) {
            final status = s['status']?.toString() ?? '';
            return status == 'ENDED' || status == 'COMPLETED' || status == 'CANCELLED';
          }).toList();
          _loading = false;
        });
      } else {
        _setFallbackSessions();
      }
    } catch (_) {
      _setFallbackSessions();
    }
  }

  void _setFallbackSessions() {
    final all = List.from(_defaultSessions);
    setState(() {
      _upcoming = all.where((s) => s['status'] == 'SCHEDULED' || s['status'] == 'LIVE').toList();
      _past = all.where((s) => s['status'] == 'COMPLETED').toList();
      _loading = false;
    });
  }

  Future<void> _join(String sessionId) async {
    try {
      final resp = await ApiClient.post(
          '${AppConstants.liveSessionsBase}/$sessionId/join', {});
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final url = body['data']?['joinUrl']?.toString() ?? '';
        if (mounted && url.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Join URL: $url'),
            backgroundColor: AppTheme.success,
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not join session. Please try again.'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Electric Blue Header matching Dream Theme Screen 3
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                          const Text('Video Learning',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search_rounded, size: 20, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Horizontal Category Filter Pills matching Dream Theme Screen 3
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildHeaderPill('All Video', isSelected: true),
                            const SizedBox(width: 8),
                            _buildHeaderPill('Live', isSelected: false),
                            const SizedBox(width: 8),
                            _buildHeaderPill('New Upload', isSelected: false),
                            const SizedBox(width: 8),
                            _buildHeaderPill('Trending', isSelected: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: _loading
                      ? _shimmer()
                      : _error != null
                          ? _errorState()
                          : TabBarView(
                              controller: _tab,
                              children: [
                                _SessionList(sessions: _upcoming, onJoin: _join,
                                    emptyMsg: 'No upcoming live classes.'),
                                _SessionList(sessions: _past, onJoin: null,
                                    emptyMsg: 'No past sessions yet.'),
                              ],
                            ),
                ),
              ],
            ),
            // Floating "Sort By" button matching Dream Theme Screen 3
            Positioned(
              bottom: 20,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.swap_vert_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Sort By', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPill(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : Colors.white,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection,
      highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(4, (_) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 120,
        decoration: BoxDecoration(color: AppTheme.bgSection,
            borderRadius: BorderRadius.circular(16)),
      ))),
    ),
  );

  Widget _errorState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textDisabled),
      const SizedBox(height: 16),
      Text(_error ?? 'Something went wrong', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: _load, child: const Text('Retry')),
    ],
  ));
}

class _SessionList extends StatelessWidget {
  final List<dynamic> sessions;
  final Function(String)? onJoin;
  final String emptyMsg;
  const _SessionList({required this.sessions, required this.onJoin,
      required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined, size: 56,
              color: AppTheme.textDisabled),
          const SizedBox(height: AppTheme.sp16),
          Text(emptyMsg, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.sp16),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp8),
      itemBuilder: (_, i) {
        final s = sessions[i];
        final isLive = s['status']?.toString() == 'LIVE';
        return Container(
          padding: const EdgeInsets.all(AppTheme.sp16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: isLive ? AppTheme.error : AppTheme.divider,
              width: isLive ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (isLive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('● LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: AppTheme.sp8),
                ],
                Expanded(
                  child: Text(s['title']?.toString() ?? 'Live Session',
                      style: Theme.of(context).textTheme.labelLarge,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: AppTheme.sp8),
              Row(children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(s['instructorName']?.toString() ?? 'Instructor',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: AppTheme.sp16),
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(s['scheduledAt']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              if (onJoin != null) ...[
                const SizedBox(height: AppTheme.sp16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: Text(isLive ? 'Join Now' : 'RSVP'),
                    onPressed: () => onJoin!(s['id']?.toString() ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? AppTheme.error : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
