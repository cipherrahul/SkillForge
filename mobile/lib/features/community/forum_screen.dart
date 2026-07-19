import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Community Forum Screen
/// API: GET  /api/v1/forum/posts
///      POST /api/v1/forum/posts          { title, content }
///      GET  /api/v1/forum/posts/{postId}
///      POST /api/v1/forum/posts/{postId}/comments  { content }
class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _posts = [];
  List<dynamic> _announcements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final postsResp = await ApiClient.get(AppConstants.forumPostsUrl);
      final annResp   = await ApiClient.get(AppConstants.announcementsUrl);

      setState(() {
        if (postsResp.statusCode == 200) {
          final body = jsonDecode(postsResp.body);
          _posts = body['data']?['content'] ?? body['data'] ?? [];
        }
        if (annResp.statusCode == 200) {
          final body = jsonDecode(annResp.body);
          _announcements = body['data']?['content'] ?? body['data'] ?? [];
        }
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; _error = 'You are offline.'; });
    }
  }

  void _showNewPostSheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgMain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.sp24, right: AppTheme.sp24, top: AppTheme.sp24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppTheme.sp24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Start a Discussion', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.sp16),
          TextField(controller: titleCtrl,
              decoration: const InputDecoration(hintText: 'Title')),
          const SizedBox(height: AppTheme.sp16),
          TextField(controller: contentCtrl, maxLines: 5,
              decoration: const InputDecoration(hintText: 'What would you like to discuss?')),
          const SizedBox(height: AppTheme.sp16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiClient.post(AppConstants.forumPostsUrl, {
                'title': titleCtrl.text.trim(),
                'content': contentCtrl.text.trim(),
                'isQuestion': true,
                'category': 'GENERAL',
              });
              _load();
            },
            child: const Text('Post'),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: AppTheme.bgMain,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Discussions'),
            Tab(text: 'Announcements'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPostSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: _loading
          ? _shimmer()
          : _error != null
              ? _errorState()
              : TabBarView(
                  controller: _tab,
                  children: [
                    _PostList(posts: _posts, onRefresh: _load),
                    _AnnouncementList(items: _announcements),
                    const _Leaderboard(),
                  ],
                ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(AppTheme.sp16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection, highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(5, (_) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp8), height: 100,
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

class _PostList extends StatelessWidget {
  final List<dynamic> posts;
  final VoidCallback onRefresh;
  const _PostList({required this.posts, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(child: Text('No discussions yet. Be the first!',
          style: Theme.of(context).textTheme.bodyMedium));
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.sp16),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp8),
        itemBuilder: (_, i) {
          final p = posts[i];
          return Container(
            padding: const EdgeInsets.all(AppTheme.sp16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['title']?.toString() ?? 'Discussion',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppTheme.sp4),
              Text(p['content']?.toString() ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppTheme.sp8),
              Row(children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(p['authorName']?.toString() ?? 'Student',
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                const Icon(Icons.comment_outlined,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text('${p['commentCount'] ?? 0} replies',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ]),
          );
        },
      ),
    );
  }
}

class _AnnouncementList extends StatelessWidget {
  final List<dynamic> items;
  const _AnnouncementList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text('No announcements.',
          style: Theme.of(context).textTheme.bodyMedium));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.sp16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp8),
      itemBuilder: (_, i) {
        final a = items[i];
        return Container(
          padding: const EdgeInsets.all(AppTheme.sp16),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.campaign_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: AppTheme.sp8),
              Expanded(child: Text(a['title']?.toString() ?? 'Announcement',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: AppTheme.primary))),
            ]),
            const SizedBox(height: AppTheme.sp8),
            Text(a['content']?.toString() ?? '',
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
        );
      },
    );
  }
}

class _Leaderboard extends StatefulWidget {
  const _Leaderboard();

  @override
  State<_Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<_Leaderboard> {
  List<dynamic> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await ApiClient.get(AppConstants.leaderboardUrl);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() { _entries = body['data'] ?? []; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_entries.isEmpty) {
      return Center(child: Text('No leaderboard data.',
          style: Theme.of(context).textTheme.bodyMedium));
    }

    const medals = ['🥇', '🥈', '🥉'];
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.sp16),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp8),
      itemBuilder: (_, i) {
        final e = _entries[i];
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp16, vertical: AppTheme.sp12),
          decoration: BoxDecoration(
            color: i < 3 ? AppTheme.primaryLight : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: i < 3
                ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.divider),
          ),
          child: Row(children: [
            SizedBox(width: 36, child: Text(i < 3 ? medals[i] : '${i + 1}',
                style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)),
            const SizedBox(width: AppTheme.sp16),
            Expanded(child: Text(e['userName']?.toString() ?? 'Student',
                style: Theme.of(context).textTheme.labelLarge)),
            Text('${e['xpPoints'] ?? 0} XP',
                style: TextStyle(
                    color: i < 3 ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        );
      },
    );
  }
}

// sp12 extension used across screens
extension AppSpacing on num {
  static const double sp12 = 12;
}
