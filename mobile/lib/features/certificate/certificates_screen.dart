import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Certificates Screen
/// API: GET /api/v1/enrollments  → get enrollmentIds
///      GET /api/v1/certificates/enrollments/{enrollmentId}  → certificate
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<dynamic> _certs = [];
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
      // Get completed enrollments then fetch their certificates
      final enrollResp = await ApiClient.get(AppConstants.enrollmentsUrl);
      if (enrollResp.statusCode != 200) {
        setState(() { _loading = false; _error = 'Could not load certificates.'; });
        return;
      }
      final enrollments = jsonDecode(enrollResp.body)['data']?['content']
          ?? jsonDecode(enrollResp.body)['data'] ?? [];

      final certs = <dynamic>[];
      for (final e in enrollments) {
        final progress = (e['progressPercent'] ?? 0).toDouble();
        if (progress < 100) continue;
        final eid = e['id']?.toString() ?? '';
        if (eid.isEmpty) continue;
        try {
          final cResp = await ApiClient.get(
              '${AppConstants.certificatesBase}/enrollments/$eid');
          if (cResp.statusCode == 200) {
            final body = jsonDecode(cResp.body)['data'];
            if (body != null) {
              certs.add({...body, 'courseTitle': e['courseTitle']
                  ?? e['course']?['title'] ?? 'Course'});
            }
          }
        } catch (_) {}
      }

      setState(() { _certs = certs; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; _error = 'You are offline.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: AppTheme.bgMain,
      ),
      body: _loading
          ? _shimmer()
          : _error != null
              ? _errorState()
              : _certs.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.sp16),
                        itemCount: _certs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.sp16),
                        itemBuilder: (_, i) => _CertCard(cert: _certs[i]),
                      ),
                    ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(AppTheme.sp16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection, highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp16), height: 160,
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

  Widget _emptyState() => Center(child: Padding(
    padding: const EdgeInsets.all(AppTheme.sp32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.workspace_premium_outlined, size: 72, color: AppTheme.textDisabled),
      const SizedBox(height: AppTheme.sp16),
      Text('No certificates yet.', style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center),
      const SizedBox(height: AppTheme.sp8),
      Text('Complete 100% of a course to earn your certificate.',
          style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
    ]),
  ));
}

class _CertCard extends StatelessWidget {
  final dynamic cert;
  const _CertCard({required this.cert});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Stack(children: [
        // Watermark icon
        Positioned(right: -10, top: -10,
          child: Icon(Icons.workspace_premium_rounded,
              size: 100, color: AppTheme.primary.withValues(alpha: 0.06))),
        Padding(
          padding: const EdgeInsets.all(AppTheme.sp24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.workspace_premium_rounded,
                color: AppTheme.primary, size: 36),
            const SizedBox(height: AppTheme.sp16),
            Text('Certificate of Completion',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
            const SizedBox(height: AppTheme.sp4),
            Text(cert['courseTitle']?.toString() ?? 'Course',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.sp4),
            if (cert['issuedAt'] != null)
              Text('Issued: ${cert['issuedAt']}',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppTheme.sp16),
            // QR code / verification
            if (cert['verificationCode'] != null)
              Row(children: [
                const Icon(Icons.qr_code_2_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: AppTheme.sp8),
                Text('Code: ${cert['verificationCode']}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontFamily: 'monospace')),
              ]),
            const SizedBox(height: AppTheme.sp16),
            Row(children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Share'),
                onPressed: () {},
              ),
              const SizedBox(width: AppTheme.sp8),
              OutlinedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download'),
                onPressed: () {},
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
