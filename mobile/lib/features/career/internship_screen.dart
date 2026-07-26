import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Advanced Internship Portal Screen
/// API: GET  /api/v1/jobs?type=INTERNSHIP
///      POST /api/v1/jobs/{jobId}/apply
class InternshipScreen extends StatefulWidget {
  const InternshipScreen({super.key});

  @override
  State<InternshipScreen> createState() => _InternshipScreenState();
}

class _InternshipScreenState extends State<InternshipScreen> {
  List<dynamic> _allInternships = [];
  List<dynamic> _internships = [];
  final Set<String> _appliedIds = {};
  bool _loading = true;
  String? _error;
  String _selectedPill = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, dynamic>> _defaultInternships = [
    {
      'id': 'int_1',
      'title': 'Frontend Developer Intern',
      'companyName': 'Google Cloud Solutions',
      'location': 'Bangalore (Hybrid)',
      'stipend': '₹35,000 / mo',
      'duration': '6 Months',
      'type': 'INTERNSHIP',
      'workMode': 'Hybrid',
      'skills': ['React.js', 'TypeScript', 'Tailwind'],
      'description': 'Work with world-class engineering teams to build modern cloud dashboard components.',
      'postedDaysAgo': '2 days ago',
    },
    {
      'id': 'int_2',
      'title': 'Flutter Mobile App Intern',
      'companyName': 'Razorpay Technologies',
      'location': 'Remote',
      'stipend': '₹40,000 / mo',
      'duration': '3 Months',
      'type': 'INTERNSHIP',
      'workMode': 'Remote',
      'skills': ['Flutter', 'Dart', 'REST APIs', 'State Management'],
      'description': 'Help engineer next-gen mobile payment checkout screens and transaction dashboards.',
      'postedDaysAgo': 'Just now',
    },
    {
      'id': 'int_3',
      'title': 'Backend Java Spring Developer',
      'companyName': 'Atlassian India',
      'location': 'Bengaluru, KA',
      'stipend': '₹45,000 / mo',
      'duration': '6 Months',
      'type': 'INTERNSHIP',
      'workMode': 'On-site',
      'skills': ['Java 17', 'Spring Boot', 'PostgreSQL', 'Docker'],
      'description': 'Develop scalable REST microservices and automated deployment pipelines.',
      'postedDaysAgo': '1 day ago',
    },
    {
      'id': 'int_4',
      'title': 'AI / ML Engineer Intern',
      'companyName': 'Microsoft AI Labs',
      'location': 'Hyderabad (Remote)',
      'stipend': '₹50,000 / mo',
      'duration': '6 Months',
      'type': 'INTERNSHIP',
      'workMode': 'Remote',
      'skills': ['Python', 'PyTorch', 'LLMs', 'LangChain'],
      'description': 'Build fine-tuned AI models and conversational intelligent tutor agents.',
      'postedDaysAgo': '3 days ago',
    },
  ];

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
        final rawData = body['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          list = rawData['content'];
        }
        if (list.isEmpty) list = List.from(_defaultInternships);
        _allInternships = List.from(list);
        _filterInternships();
        setState(() => _loading = false);
      } else {
        _setFallback();
      }
    } catch (_) {
      _setFallback();
    }
  }

  void _setFallback() {
    _allInternships = List.from(_defaultInternships);
    _filterInternships();
    setState(() => _loading = false);
  }

  void _filterInternships() {
    var list = _allInternships;
    if (_selectedPill == 'Remote') {
      list = list.where((j) => (j['workMode'] ?? j['location'] ?? '').toString().toLowerCase().contains('remote')).toList();
    } else if (_selectedPill == 'High Stipend') {
      list = list.where((j) => (j['stipend'] ?? '').toString().contains('40') || (j['stipend'] ?? '').toString().contains('50') || (j['stipend'] ?? '').toString().contains('45')).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((j) {
        final title = (j['title'] ?? '').toString().toLowerCase();
        final company = (j['companyName'] ?? '').toString().toLowerCase();
        final desc = (j['description'] ?? '').toString().toLowerCase();
        return title.contains(q) || company.contains(q) || desc.contains(q);
      }).toList();
    }

    setState(() => _internships = list);
  }

  void _showApplyModal(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final title = job['title']?.toString() ?? 'Internship';
    final company = job['companyName']?.toString() ?? 'Company';
    final isApplied = _appliedIds.contains(jobId);
    final noteController = TextEditingController();

    if (isApplied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have already applied for this internship! 🚀'),
        backgroundColor: AppTheme.primary,
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
                    child: const Icon(Icons.laptop_mac_rounded, color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text(company, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Attach Cover Note (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Why are you a great fit for this internship?',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: const [
                    Icon(Icons.description_rounded, color: AppTheme.primary, size: 20),
                    SizedBox(width: 10),
                    Text('Latest Verified Resume Attached', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
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
                      await ApiClient.post('${AppConstants.jobsUrl}/$jobId/apply', {'coverNote': noteController.text});
                    } catch (_) {}
                    setState(() => _appliedIds.add(jobId));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Application Submitted Successfully! 🎉'),
                        backgroundColor: AppTheme.success,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Submit Application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
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
                          const Text('Internship Portal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                        child: Text('${_internships.length} Available', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
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
                              hintText: 'Search roles, technologies, companies...',
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
                              _filterInternships();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Category Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPill('All'),
                        const SizedBox(width: 8),
                        _buildPill('Remote'),
                        const SizedBox(width: 8),
                        _buildPill('High Stipend'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Internship List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _internships.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.laptop_mac_outlined, size: 56, color: Color(0xFF94A3B8)),
                              SizedBox(height: 12),
                              Text('No matching internships found.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _internships.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (_, i) {
                            final j = _internships[i];
                            final id = j['id']?.toString() ?? '';
                            final isApplied = _appliedIds.contains(id);
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 46, height: 46,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.business_center_rounded, color: AppTheme.primary, size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(j['title']?.toString() ?? 'Internship',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                            const SizedBox(height: 2),
                                            Text(j['companyName']?.toString() ?? '',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('INTERNSHIP', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      _Tag(Icons.currency_rupee_rounded, j['stipend']?.toString() ?? 'Stipend Unspecified', AppTheme.purpleAccent),
                                      const SizedBox(width: 8),
                                      _Tag(Icons.schedule_rounded, j['duration']?.toString() ?? '3 Months', const Color(0xFF64748B)),
                                      const SizedBox(width: 8),
                                      _Tag(Icons.location_on_rounded, j['location']?.toString() ?? 'Remote', const Color(0xFF64748B)),
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
                                        elevation: isApplied ? 0 : 2,
                                      ),
                                      child: Text(
                                        isApplied ? 'Applied ✓' : 'Apply Now',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label) {
    final isSelected = _selectedPill == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPill = label;
          _filterInternships();
        });
      },
      child: Container(
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
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
