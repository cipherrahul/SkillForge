import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Internship Portal Screen
/// API: GET  /api/v1/jobs?type=INTERNSHIP
///      POST /api/v1/jobs/{jobId}/apply
class InternshipScreen extends StatefulWidget {
  const InternshipScreen({super.key});

  @override
  State<InternshipScreen> createState() => _InternshipScreenState();
}

class _InternshipScreenState extends State<InternshipScreen> {
  List<dynamic> _internships = [];
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
      final resp = await ApiClient.get('${AppConstants.jobsUrl}?type=INTERNSHIP');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _internships = body['data']?['content'] ?? body['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = 'Could not load internships.'; });
      }
    } catch (_) {
      setState(() { _loading = false; _error = 'You are offline.'; });
    }
  }

  Future<void> _apply(String jobId) async {
    try {
      final resp = await ApiClient.post('${AppConstants.jobsUrl}/$jobId/apply', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(resp.statusCode == 200
              ? 'Applied successfully! 🎉' : 'Application failed. Please try again.'),
          backgroundColor: resp.statusCode == 200 ? AppTheme.success : AppTheme.error,
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Internship Portal'),
        backgroundColor: AppTheme.bgMain,
      ),
      body: _loading
          ? _shimmer()
          : _error != null
              ? _errorState()
              : _internships.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.sp16),
                        itemCount: _internships.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp8),
                        itemBuilder: (_, i) {
                          final j = _internships[i];
                          return Container(
                            padding: const EdgeInsets.all(AppTheme.sp16),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                                  ),
                                  child: const Icon(Icons.laptop_mac_rounded,
                                      color: AppTheme.primary, size: 22),
                                ),
                                const SizedBox(width: AppTheme.sp16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(j['title']?.toString() ?? 'Internship',
                                      style: Theme.of(context).textTheme.labelLarge),
                                  Text(j['companyName']?.toString() ?? '',
                                      style: Theme.of(context).textTheme.bodySmall),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('INTERNSHIP',
                                      style: TextStyle(color: AppTheme.success,
                                          fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ]),
                              const SizedBox(height: AppTheme.sp8),
                              Wrap(spacing: AppTheme.sp16, runSpacing: AppTheme.sp4, children: [
                                if (j['duration'] != null)
                                  _Info(Icons.schedule_rounded, j['duration'].toString()),
                                if (j['stipend'] != null)
                                  _Info(Icons.currency_rupee_rounded, j['stipend'].toString()),
                                if (j['location'] != null)
                                  _Info(Icons.location_on_outlined, j['location'].toString()),
                              ]),
                              const SizedBox(height: AppTheme.sp8),
                              if (j['description'] != null)
                                Text(j['description'].toString(),
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: AppTheme.sp16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _apply(j['id']?.toString() ?? ''),
                                  child: const Text('Apply for Internship'),
                                ),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(AppTheme.sp16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection, highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(4, (_) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp8), height: 150,
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
      const Icon(Icons.laptop_mac_outlined, size: 56, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text('No internships available right now.', style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center),
    ],
  ));
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Info(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppTheme.textSecondary),
    const SizedBox(width: 4),
    Text(label, style: Theme.of(context).textTheme.bodySmall),
  ]);
}
