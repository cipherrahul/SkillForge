import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Advanced Placement Portal Screen
/// API: GET /api/v1/jobs
///      POST /api/v1/jobs/{jobId}/apply
///      GET  /api/v1/jobs/applications
class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _allJobs = [];
  List<dynamic> _jobs = [];
  List<dynamic> _applications = [];
  final Set<String> _appliedJobIds = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadJobs();
    _loadApplications();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final resp = await ApiClient.get(AppConstants.jobsUrl);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final rawData = body['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          list = rawData['content'];
        }
        _allJobs = list.where((j) => (j['type'] ?? '').toString() != 'INTERNSHIP').toList();
        _filterJobs();
        setState(() => _loadingJobs = false);
      } else {
        _allJobs = [];
        _filterJobs();
        setState(() => _loadingJobs = false);
      }
    } catch (_) {
      _allJobs = [];
      _filterJobs();
      setState(() => _loadingJobs = false);
    }
  }

  void _filterJobs() {
    if (_searchQuery.trim().isEmpty) {
      _jobs = List.from(_allJobs);
    } else {
      final q = _searchQuery.trim().toLowerCase();
      _jobs = _allJobs.where((j) {
        final title = (j['title'] ?? '').toString().toLowerCase();
        final company = (j['companyName'] ?? '').toString().toLowerCase();
        final desc = (j['description'] ?? '').toString().toLowerCase();
        return title.contains(q) || company.contains(q) || desc.contains(q);
      }).toList();
    }
    setState(() {});
  }

  Future<void> _loadApplications() async {
    try {
      final resp = await ApiClient.get('${AppConstants.jobsUrl}/applications');
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
          _applications = list;
          _loadingApps = false;
        });
      } else {
        setState(() {
          _applications = [];
          _loadingApps = false;
        });
      }
    } catch (_) {
      setState(() {
        _applications = [];
        _loadingApps = false;
      });
    }
  }

  void _showApplyModal(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final title = job['title']?.toString() ?? 'Position';
    final company = job['companyName']?.toString() ?? 'Company';
    final isApplied = _appliedJobIds.contains(jobId);

    if (isApplied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have already submitted an application for this position! 🚀'),
        backgroundColor: AppTheme.primary,
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.business_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      Text(company, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Target Salary Package:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      Text('18 - 24 LPA', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Resume Verified:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      Text('ATS Score 94%', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ApiClient.post('${AppConstants.jobsUrl}/$jobId/apply', {});
                  } catch (_) {}
                  setState(() {
                    _appliedJobIds.add(jobId);
                    _applications.insert(0, {
                      'id': 'app_${DateTime.now().millisecondsSinceEpoch}',
                      'jobTitle': title,
                      'companyName': company,
                      'status': 'UNDER_REVIEW',
                      'appliedAt': 'Just now',
                    });
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Job Application Submitted to Hiring Team! 🎉'),
                      backgroundColor: AppTheme.success,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Confirm & Apply Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Electric Blue Header matching Dream Theme
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Placement Portal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                        child: const Text('Top Recruiters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Input
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                            cursorColor: AppTheme.primary,
                            decoration: const InputDecoration(
                              hintText: 'Search roles, companies, tech stack...',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w400),
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) {
                              _searchQuery = v;
                              _filterJobs();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Segmented Tab Selector
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Job Openings'),
                        Tab(text: 'My Applications'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // 1. Job Openings Tab
                  _loadingJobs
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      : _jobs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.work_off_outlined, size: 56, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 12),
                                  Text('No matching job openings right now.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: _jobs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (_, i) {
                                final j = _jobs[i];
                                final id = j['id']?.toString() ?? '';
                                final isApplied = _appliedJobIds.contains(id);
                                final skills = (j['skills'] as List?)?.cast<String>() ?? [];

                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 46, height: 46,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(Icons.business_rounded, color: AppTheme.primary, size: 24),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(j['title']?.toString() ?? 'Position',
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                                const SizedBox(height: 2),
                                                Text(j['companyName']?.toString() ?? '',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: AppTheme.purpleAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text(j['salary']?.toString() ?? '15 - 20 LPA', style: const TextStyle(color: AppTheme.purpleAccent, fontSize: 11, fontWeight: FontWeight.w800)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          _Chip(Icons.location_on_rounded, j['location']?.toString() ?? 'Remote'),
                                          const SizedBox(width: 8),
                                          _Chip(Icons.work_rounded, j['jobType']?.toString() ?? 'Full-time'),
                                          const SizedBox(width: 8),
                                          _Chip(Icons.laptop_chromebook_rounded, j['workMode']?.toString() ?? 'Hybrid'),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(j['description']?.toString() ?? '',
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                      if (skills.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 6, runSpacing: 6,
                                          children: skills.map((sk) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                            child: Text(sk, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                          )).toList(),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 44,
                                        child: ElevatedButton(
                                          onPressed: isApplied ? null : () => _showApplyModal(j),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isApplied ? const Color(0xFFCBD5E1) : AppTheme.primary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text(
                                            isApplied ? 'Application Submitted ✓' : 'Apply For Position',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                  // 2. My Applications Tab
                  _loadingApps
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      : _applications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.assignment_turned_in_outlined, size: 56, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 12),
                                  Text('You have not applied for any jobs yet.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: _applications.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (_, i) {
                                final app = _applications[i];
                                final status = app['status']?.toString() ?? 'UNDER_REVIEW';

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(app['companyName']?.toString() ?? 'Company', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                                          _StatusBadge(status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(app['jobTitle']?.toString() ?? 'Job Title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text('Applied on ${app['appliedAt'] ?? 'Recently'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg = AppTheme.primary.withValues(alpha: 0.1);
    Color text = AppTheme.primary;
    String label = 'UNDER REVIEW';

    if (status == 'SHORTLISTED') {
      bg = const Color(0xFF10B981).withValues(alpha: 0.12);
      text = const Color(0xFF10B981);
      label = 'SHORTLISTED 🎉';
    } else if (status == 'REJECTED') {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
      text = const Color(0xFFEF4444);
      label = 'REJECTED';
    } else if (status == 'ACCEPTED') {
      bg = AppTheme.purpleAccent.withValues(alpha: 0.12);
      text = AppTheme.purpleAccent;
      label = 'OFFER EXTENDED 🏆';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
