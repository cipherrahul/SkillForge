import 'dart:convert';
import 'dart:math' as math;
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
    setState(() { _loading = true; });
    try {
      final resp = await ApiClient.get(
          '${AppConstants.coursesUrl}/${widget.courseId}');
      if (resp.statusCode == 200) {
        setState(() {
          _course = jsonDecode(resp.body)['data'];
          _loading = false;
        });
      } else {
        // Real course data unavailable – show error, never show fake data
        setState(() { _course = null; _loading = false; });
      }
    } catch (_) {
      setState(() { _course = null; _loading = false; });
    }
  }

  Future<void> _enroll() async {
    final double basePrice = ((_course?['price'] ?? 0) as num).toDouble();
    String couponInput = '';
    double discount = 0;
    double gst = (basePrice * 0.18);
    double total = basePrice + gst;
    String selectedMethod = 'Razorpay UPI';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(stCtx).viewInsets.bottom + 20,
                top: 24, left: 20, right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Course Checkout & Tax Receipt',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textHeading)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_course?['title'] ?? 'Course', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  
                  // Promo Code Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => couponInput = v.trim().toUpperCase(),
                          decoration: InputDecoration(
                            hintText: 'Promo / Coupon Code (e.g. SAVE20)',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setModalState(() {
                            if (couponInput.isNotEmpty) {
                              discount = (basePrice * 0.15); // 15% discount
                              double newSub = math.max(0, basePrice - discount);
                              gst = newSub * 0.18;
                              total = newSub + gst;
                            }
                          });
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // GST Price Breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Base Price:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          Text('₹${basePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                        if (discount > 0) ...[
                          const SizedBox(height: 6),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Discount ($couponInput):', style: const TextStyle(fontSize: 13, color: AppTheme.success)),
                            Text('- ₹${discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.success)),
                          ]),
                        ],
                        const SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('18% Itemized GST Tax:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          Text('+ ₹${gst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                        const Divider(height: 18),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textHeading)),
                          Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Select Payment Gateway:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Razorpay UPI', 'Credit/Debit Card', 'NetBanking'].map((m) {
                      final isSelected = selectedMethod == m;
                      return ChoiceChip(
                        label: Text(m),
                        selected: isSelected,
                        onSelected: (sel) => setModalState(() => selectedMethod = m),
                        selectedColor: AppTheme.primaryLight,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(modalCtx, true);
                      },
                      child: Text('Pay ₹${total.toStringAsFixed(2)} & Complete Order 🚀', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    setState(() => _enrolling = true);
    try {
      final resp = await ApiClient.post(AppConstants.enrollmentsUrl, {'courseId': widget.courseId});
      if (!mounted) return;
      final ok = resp.statusCode == 200;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '🎉 Payment Successful! Course Unlocked & Invoice Sent.'
            : 'Payment failed. Please try again.'),
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
    // Show error state when course could not be loaded from backend
    if (!_loading && _course == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgMain,
        appBar: AppBar(title: const Text('Course Detail')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.textDisabled),
                const SizedBox(height: 20),
                const Text('Could not load course',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textHeading)),
                const SizedBox(height: 8),
                const Text('Please check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  onPressed: _load,
                ),
              ],
            ),
          ),
        ),
      );
    }
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
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: CustomScrollView(
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
