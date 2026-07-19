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

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // GET /api/v1/live-sessions — returns all live sessions for enrolled courses
      final resp = await ApiClient.get(AppConstants.liveSessionsBase);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final all = (body['data'] as List? ?? []);
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
        setState(() { _loading = false; _error = 'Something went wrong.'; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = 'You are offline.'; });
    }
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
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Live Classes'),
        backgroundColor: AppTheme.bgMain,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past Sessions'),
          ],
        ),
      ),
      body: _loading
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
