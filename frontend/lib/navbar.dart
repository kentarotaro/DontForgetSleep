import 'package:flutter/material.dart';
import 'package:dont_forget_sleep/theme/app_colors.dart';
import 'package:dont_forget_sleep/settings_page.dart';
import 'package:dont_forget_sleep/views/home/home_screen.dart';
import 'package:dont_forget_sleep/features/rescue_mode/pages/rescue_mode_page.dart';
import 'package:dont_forget_sleep/features/schedule/schedule_page.dart';
import 'package:dont_forget_sleep/features/history/pages/sleep_history_page.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const <Widget>[
    HomeScreen(),
    
    SchedulePage(),
    const RescueModePage(sleepHours: 11.0),
     SleepHistoryPage(),
    // Use the real SettingsPage so the bottom nav stays visible when opened
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// Reusable app bottom navigation bar
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const AppBottomNav({required this.selectedIndex, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.purple900,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                text: 'Home',
                icon: Icons.home_outlined,
                selected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                text: 'Schedule',
                icon: Icons.calendar_today_outlined,
                selected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                text: 'Rescue',
                icon: Icons.shield_outlined,
                selected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                text: 'History',
                icon: Icons.history_outlined,
                selected: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                text: 'Settings',
                icon: Icons.settings_outlined,
                selected: selectedIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.text,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = AppColors.purple500;
    final Color inactiveColor =AppColors.purple900 ;

    final double baseIconSize = 24;
    final double iconSize = icon == Icons.home_outlined ? 26 : baseIconSize;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: selected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            // Di sini logic dot nya diimplementasikan
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Dot transparan saat tidak dipilih
                color: selected ? activeColor : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}