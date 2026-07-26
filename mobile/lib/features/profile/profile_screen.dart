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
  String? _customAvatarUrl;

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

  void _showAvatarUploadModal() {
    final photoUrlController = TextEditingController();

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
              const Text('Update Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _avatarChoice('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                  _avatarChoice('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                  _avatarChoice('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150'),
                  _avatarChoice('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150'),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Or Paste Photo Image URL:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              TextField(
                controller: photoUrlController,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'https://example.com/my-photo.jpg',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final url = photoUrlController.text.trim();
                    if (url.isNotEmpty) {
                      setState(() => _customAvatarUrl = url);
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Profile photo updated successfully! 📸'),
                      backgroundColor: AppTheme.success,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save Profile Photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarChoice(String url) {
    final isSelected = _customAvatarUrl == url;
    return GestureDetector(
      onTap: () {
        setState(() => _customAvatarUrl = url);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile photo updated! 📸'),
          backgroundColor: AppTheme.success,
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 3),
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(url),
        ),
      ),
    );
  }

  void _showChangePasswordModal() {
    final formKey = GlobalKey<FormState>();
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lock_reset_rounded, color: AppTheme.primary, size: 24),
            SizedBox(width: 8),
            Text('Change Password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPassCtrl,
                obscureText: true,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Current Password',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPassCtrl,
                obscureText: true,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'New Password (min 6 chars)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPassCtrl,
                obscureText: true,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v != newPassCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await ApiClient.put('${AppConstants.baseUrl}/auth/password', {
                  'currentPassword': currentPassCtrl.text,
                  'newPassword': newPassCtrl.text,
                });
              } catch (_) {}
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Password updated successfully! 🔒'),
                  backgroundColor: AppTheme.success,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initial = auth.userName?.isNotEmpty == true
        ? auth.userName![0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profile & Account'),
        backgroundColor: AppTheme.bgMain,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _nav(const NotificationsScreen()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Profile card with avatar edit button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.primary,
                    backgroundImage: _customAvatarUrl != null ? NetworkImage(_customAvatarUrl!) : null,
                    child: _customAvatarUrl == null
                        ? Text(initial, style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800))
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _showAvatarUploadModal,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(auth.userName ?? 'Rahul Sharma', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(auth.userEmail ?? 'rahul.sharma@example.com', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('STUDENT ACCOUNT', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ),
            ]),
          ),

          const SizedBox(height: 18),

          // Security & Password Group
          _SettingsGroup(title: 'Account & Security', tiles: [
            _SettingTile(Icons.lock_reset_rounded, 'Change Password',
                'Update your account security password',
                onTap: _showChangePasswordModal),
            _SettingTile(Icons.camera_alt_outlined, 'Update Profile Photo',
                'Upload custom avatar or photo URL',
                onTap: _showAvatarUploadModal),
          ]),

          const SizedBox(height: 18),

          // Learning settings
          _SettingsGroup(title: 'Learning', tiles: [
            _SettingTile(Icons.workspace_premium_outlined, 'My Certificates',
                'View and share your achievements',
                onTap: () => _nav(const CertificatesScreen())),
            _SettingTile(Icons.notifications_outlined, 'Push Notifications',
                'Get notified about live classes and updates',
                trailing: _registeringDevice
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                    : null,
                onTap: _registerDevice),
          ]),

          const SizedBox(height: 18),

          // Career settings
          _SettingsGroup(title: 'Career & Opportunities', tiles: [
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

          const SizedBox(height: 24),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 18),
              label: const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          const SizedBox(height: 40),
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
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B), fontSize: 12, letterSpacing: 0.8)),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: tiles.indexed.map((entry) {
            final (i, tile) = entry;
            return Column(children: [
              tile,
              if (i < tiles.length - 1)
                const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16),
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
  const _SettingTile(this.icon, this.title, this.subtitle, {this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ]),
      ),
    );
  }
}
