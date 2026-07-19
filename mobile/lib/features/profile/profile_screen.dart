import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';
import 'package:skillforge_student/features/auth/auth_provider.dart';
import 'package:skillforge_student/features/auth/login_screen.dart';
import 'package:skillforge_student/features/career/placement_screen.dart';
import 'package:skillforge_student/features/career/internship_screen.dart';
import 'package:skillforge_student/features/career/resume_screen.dart';
import 'package:skillforge_student/features/certificate/certificates_screen.dart';
import 'package:skillforge_student/features/notifications/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _registeringDevice = false;

  Future<void> _registerDevice() async {
    setState(() => _registeringDevice = true);
    try {
      final token = 'FCM_TOKEN_${DateTime.now().millisecondsSinceEpoch}';
      await ApiClient.post(AppConstants.registerDeviceUrl, {
        'deviceToken': token,
        'osPlatform': 'ANDROID',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Push notifications enabled! 🔔'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
    if (mounted) setState(() => _registeringDevice = false);
  }

  void _nav(Widget screen) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initial = auth.userName?.isNotEmpty == true
        ? auth.userName![0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.bgMain,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _nav(const NotificationsScreen()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.sp24),
        child: Column(children: [
          // Profile card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.sp24),
            decoration: BoxDecoration(
              color: AppTheme.bgMain,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primary,
                child: Text(initial, style: const TextStyle(
                    color: Colors.white, fontSize: 36,
                    fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: AppTheme.sp16),
              Text(auth.userName ?? 'Student',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.sp4),
              Text(auth.userEmail ?? '',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppTheme.sp8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp8, vertical: AppTheme.sp4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('STUDENT', style: TextStyle(
                    color: AppTheme.primary, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ),
            ]),
          ),

          const SizedBox(height: AppTheme.sp16),

          // Learning settings
          _SettingsGroup(title: 'Learning', tiles: [
            _SettingTile(Icons.workspace_premium_outlined, 'My Certificates',
                'View and share your achievements',
                onTap: () => _nav(const CertificatesScreen())),
            _SettingTile(Icons.notifications_outlined, 'Push Notifications',
                'Get notified about live classes and updates',
                trailing: _registeringDevice
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primary))
                    : null,
                onTap: _registerDevice),
            _SettingTile(Icons.download_outlined, 'Offline Downloads',
                'Manage downloaded course content', onTap: () {}),
          ]),

          const SizedBox(height: AppTheme.sp16),

          // Career settings
          _SettingsGroup(title: 'Career', tiles: [
            _SettingTile(Icons.work_outline_rounded, 'Placement Portal',
                'Browse jobs and track applications',
                onTap: () => _nav(const PlacementScreen())),
            _SettingTile(Icons.laptop_mac_outlined, 'Internship Portal',
                'Find internship opportunities',
                onTap: () => _nav(const InternshipScreen())),
            _SettingTile(Icons.description_outlined, 'Resume Builder',
                'Build and update your professional resume',
                onTap: () => _nav(const ResumeScreen())),
          ]),

          const SizedBox(height: AppTheme.sp16),

          // Support
          _SettingsGroup(title: 'Support', tiles: [
            _SettingTile(Icons.help_outline_rounded, 'Help & Support',
                'FAQs and contact us', onTap: () {}),
          ]),

          const SizedBox(height: AppTheme.sp24),

          // Sign Out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded,
                  color: AppTheme.error, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.sp16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
              ),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ),
          const SizedBox(height: AppTheme.sp48),
        ]),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingTile> tiles;
  const _SettingsGroup({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(
            left: AppTheme.sp4, bottom: AppTheme.sp8),
        child: Text(title,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.8)),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.bgMain,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: tiles.indexed.map((entry) {
            final (i, tile) = entry;
            return Column(children: [
              tile,
              if (i < tiles.length - 1)
                const Divider(height: 1, color: AppTheme.divider,
                    indent: AppTheme.sp16),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingTile(this.icon, this.title, this.subtitle,
      {this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sp16, vertical: AppTheme.sp16),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: AppTheme.sp16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          trailing ?? const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textSecondary),
        ]),
      ),
    );
  }
}
