import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:gulflands/presentation/screens/bookmarks/bookmarks_screen.dart';
import 'package:gulflands/presentation/screens/map/map_screen.dart';
import 'package:gulflands/presentation/screens/profile/profile_screen.dart';
import 'package:gulflands/presentation/screens/valuation_screen.dart';
import 'package:gulflands/screens/home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
      icon: Icons.calculate_outlined,
      activeIcon: Icons.calculate,
      label: 'Valuation',
    ),
    _NavItem(
      icon: Icons.bookmark_outline,
      activeIcon: Icons.bookmark,
      label: 'Saved',
    ),
    _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Map'),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  void _onTabTapped(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: IndexedStack(
          index: _index,
          children: <Widget>[
            const HomeScreen(),
            const ValuationScreen(),
            const BookmarksScreen(),
            const MapScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _GulfNavBar(
          items: _navItems,
          selectedIndex: _index,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

class _GulfNavBar extends StatelessWidget {
  const _GulfNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });
  final List<_NavItem> items;
  final int selectedIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: const Border(top: BorderSide(color: AppColors.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: 8,
            bottom: bottomPadding > 0 ? 0 : 8,
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color:
                              isSelected ? AppColors.gold : AppColors.textMuted,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color:
                              isSelected ? AppColors.gold : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
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
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
