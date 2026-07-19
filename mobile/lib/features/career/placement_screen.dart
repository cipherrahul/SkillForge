import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Placement Portal Screen
/// API: GET /api/v1/jobs
///      POST /api/v1/jobs/{jobId}/apply
///      GET  /api/v1/jobs/applications
class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _jobs = [];
  List<dynamic> _applications = [];
  bool _loadingJobs = true;
  bool _loadingApps = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadJobs();
    _loadApplications();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadJobs() async {
    try {
      final resp = await ApiClient.get(AppConstants.jobsUrl);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _jobs = (body['data']?['content'] ?? body['data'] ?? [])
              .where((j) => j['type'] != 'INTERNSHIP').toList();
          _loadingJobs = false;
        });
      } else {
        setState(() => _loadingJobs = false);
      }
    } catch (_) { setState(() => _loadingJobs = false); }
  }

  Future<void> _loadApplications() async {
    try {
      final resp = await ApiClient.get('${AppConstants.jobsUrl}/applications');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _applications = body['data']?['content'] ?? body['data'] ?? [];
          _loadingApps = false;
        });
      } else {
        setState(() => _loadingApps = false);
      }
    } catch (_) { setState(() => _loadingApps = false); }
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
        if (resp.statusCode == 200) _loadApplications();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Placement Portal'),
        backgroundColor: AppTheme.bgMain,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Job Listings'),
            Tab(text: 'My Applications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _loadingJobs ? _shimmer() : _JobList(jobs: _jobs, onApply: _apply),
          _loadingApps ? _shimmer() : _ApplicationList(applications: _applications),
        ],
      ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(AppTheme.sp16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection, highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(4, (_) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp8), height: 140,
        decoration: BoxDecoration(color: AppTheme.bgSection,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
      ))),
    ),
  );
}

class _JobList extends StatelessWidget {
  final List<dynamic> jobs;
  final Function(String) onApply;
  const _JobList({required this.jobs, required this.onApply});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.work_off_outlined, size: 56, color: AppTheme.textDisabled),
          const SizedBox(height: AppTheme.sp16),
          Text('No job listings right now.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.sp16),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp8),
      itemBuilder: (_, i) {
        final j = jobs[i];
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
                child: const Icon(Icons.business_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: AppTheme.sp16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(j['title']?.toString() ?? 'Position',
                    style: Theme.of(context).textTheme.labelLarge),
                Text(j['companyName']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodySmall),
              ])),
            ]),
            const SizedBox(height: AppTheme.sp8),
            Wrap(spacing: AppTheme.sp8, runSpacing: AppTheme.sp4, children: [
              _Chip(j['location']?.toString() ?? '', Icons.location_on_outlined),
              _Chip(j['salary']?.toString() ?? '', Icons.currency_rupee_rounded),
              _Chip(j['jobType']?.toString() ?? 'Full-time', Icons.access_time_rounded),
            ]),
            const SizedBox(height: AppTheme.sp16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onApply(j['id']?.toString() ?? ''),
                child: const Text('Apply Now'),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _ApplicationList extends StatelessWidget {
  final List<dynamic> applications;
  const _ApplicationList({required this.applications});

  Color _statusColor(String? s) {
    switch (s) {
      case 'SHORTLISTED': return AppTheme.success;
      case 'REJECTED': return AppTheme.error;
      case 'INTERVIEW': return AppTheme.warning;
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: AppTheme.textDisabled),
          const SizedBox(height: AppTheme.sp16),
          Text("You haven't applied to any jobs yet.", style: Theme.of(context).textTheme.bodyMedium),
        ],
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.sp16),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp8),
      itemBuilder: (_, i) {
        final a = applications[i];
        final status = a['status']?.toString() ?? 'APPLIED';
        return Container(
          padding: const EdgeInsets.all(AppTheme.sp16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['jobTitle']?.toString() ?? a['job']?['title'] ?? 'Position',
                  style: Theme.of(context).textTheme.labelLarge),
              Text(a['companyName']?.toString() ?? a['job']?['companyName'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(color: _statusColor(status), fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: AppTheme.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
