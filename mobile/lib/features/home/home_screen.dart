import 'package:flutter/material.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';
import 'package:skillforge_student/features/dashboard/dashboard_screen.dart';
import 'package:skillforge_student/features/course/course_list_screen.dart';
import 'package:skillforge_student/features/liveclass/live_class_screen.dart';
import 'package:skillforge_student/features/learning/progress_screen.dart';
import 'package:skillforge_student/features/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _animController;

  final List<Widget> _pages = const [
    DashboardScreen(),
    CourseListScreen(),
    LiveClassScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, outlinedIcon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.menu_book_rounded, outlinedIcon: Icons.menu_book_outlined, label: 'My Courses'),
    _NavItem(icon: Icons.videocam_rounded, outlinedIcon: Icons.videocam_outlined, label: 'Live Classes'),
    _NavItem(icon: Icons.show_chart_rounded, outlinedIcon: Icons.show_chart_outlined, label: 'Progress'),
    _NavItem(icon: Icons.person_rounded, outlinedIcon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isSelected = _index == i;
              return GestureDetector(
                onTap: () => setState(() => _index = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? item.icon : item.outlinedIcon,
                          key: ValueKey(isSelected),
                          color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 16 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  const _NavItem({required this.icon, required this.outlinedIcon, required this.label});
}
