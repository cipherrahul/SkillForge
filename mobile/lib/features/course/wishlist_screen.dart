import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';
import 'package:skillforge_student/features/course/course_detail_screen.dart';

/// Wishlist Screen
/// API: GET /api/v1/wishlist
///      POST /api/v1/wishlist  { courseId }
///      DELETE /api/v1/wishlist/{courseId}
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> _items = [];
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
      final resp = await ApiClient.get(AppConstants.wishlistUrl);
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
          _items = list;
          _loading = false;
        });
      } else {
        setState(() { _items = []; _loading = false; });
      }
    } catch (_) {
      setState(() { _items = []; _loading = false; });
    }
  }

  Future<void> _remove(String courseId) async {
    try {
      await ApiClient.delete('${AppConstants.wishlistUrl}/$courseId');
      setState(() => _items.removeWhere(
          (w) => (w['courseId'] ?? w['course']?['id'])?.toString() == courseId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Removed from wishlist'),
          backgroundColor: AppTheme.textHeading,
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Wishlist'),
        backgroundColor: AppTheme.bgMain,
      ),
      body: _loading
          ? _shimmer()
          : _error != null
              ? _errorState()
              : _items.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.sp16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.sp8),
                        itemBuilder: (_, i) {
                          final course = _items[i]['course'] ?? _items[i];
                          final courseId =
                              (_items[i]['courseId'] ?? course['id'])?.toString() ?? '';
                          return Dismissible(
                            key: ValueKey(courseId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: AppTheme.sp24),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusCard),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.error),
                            ),
                            onDismissed: (_) => _remove(courseId),
                            child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) =>
                                      CourseDetailScreen(courseId: courseId))),
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.sp16),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgCard,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                                  border: Border.all(color: AppTheme.divider),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 72, height: 72,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusButton),
                                      ),
                                      child: const Icon(
                                          Icons.play_circle_outline_rounded,
                                          color: AppTheme.primary, size: 36),
                                    ),
                                    const SizedBox(width: AppTheme.sp16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course['title']?.toString() ??
                                                'Course',
                                            style: Theme.of(context)
                                                .textTheme.labelLarge,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: AppTheme.sp4),
                                          Text(
                                            course['price'] == 0
                                                ? 'Free'
                                                : '₹${course['price']}',
                                            style: TextStyle(
                                              color: course['price'] == 0
                                                  ? AppTheme.success
                                                  : AppTheme.textHeading,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.bookmark_rounded,
                                        color: AppTheme.primary),
                                  ],
                                ),
                              ),
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
      child: Column(children: List.generate(5, (_) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp8),
        height: 100,
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
      const Icon(Icons.bookmark_border_rounded, size: 56, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text('Your wishlist is empty.', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppTheme.sp8),
      Text('Save courses to revisit later.', style: Theme.of(context).textTheme.bodyMedium),
    ],
  ));
}
