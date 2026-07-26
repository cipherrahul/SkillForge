import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Notifications Screen
/// API: GET /api/v1/mobile/notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
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
      final resp = await ApiClient.get(AppConstants.notificationsUrl);
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
          _notifications = list;
          _loading = false;
        });
      } else {
        setState(() { _notifications = []; _loading = false; });
      }
    } catch (_) {
      setState(() { _notifications = []; _loading = false; });
    }
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'LIVE_CLASS': return Icons.videocam_rounded;
      case 'ASSIGNMENT': return Icons.assignment_rounded;
      case 'CERTIFICATE': return Icons.workspace_premium_rounded;
      case 'PAYMENT': return Icons.receipt_rounded;
      case 'ANNOUNCEMENT': return Icons.campaign_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String? type) {
    switch (type) {
      case 'LIVE_CLASS': return AppTheme.error;
      case 'ASSIGNMENT': return AppTheme.warning;
      case 'CERTIFICATE': return AppTheme.success;
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.bgMain,
        actions: [
          TextButton(
            onPressed: () => setState(() => _notifications = []),
            child: const Text('Clear All',
                style: TextStyle(color: AppTheme.primary, fontSize: 13)),
          ),
        ],
      ),
      body: _loading
          ? _shimmer()
          : _error != null
              ? _errorState()
              : _notifications.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.sp16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.sp8),
                        itemBuilder: (_, i) {
                          final n = _notifications[i];
                          final type = n['type']?.toString();
                          final read = n['read'] == true;
                          return Container(
                            padding: const EdgeInsets.all(AppTheme.sp16),
                            decoration: BoxDecoration(
                              color: read ? AppTheme.bgCard : AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                              border: Border.all(
                                color: read ? AppTheme.divider : AppTheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: _colorFor(type).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                                  ),
                                  child: Icon(_iconFor(type),
                                      color: _colorFor(type), size: 20),
                                ),
                                const SizedBox(width: AppTheme.sp16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n['title']?.toString() ?? 'Notification',
                                          style: Theme.of(context).textTheme.labelLarge),
                                      const SizedBox(height: AppTheme.sp4),
                                      Text(n['message']?.toString() ?? '',
                                          style: Theme.of(context).textTheme.bodySmall,
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                if (!read)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(AppTheme.sp16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection,
      highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(6, (_) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp8),
        height: 80,
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

  Widget _emptyState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.notifications_none_rounded, size: 56, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text('No notifications yet.', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppTheme.sp8),
      Text("You're all caught up!", style: Theme.of(context).textTheme.bodyMedium),
    ],
  ));
}
