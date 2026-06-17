import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:gulflands/features/ai_assistant/bloc/ai_assistant_bloc.dart';
import 'package:gulflands/features/ai_assistant/pages/ai_assistant_page.dart';
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
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.97,
                  end: 1.0,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_index),
            child: IndexedStack(
              index: _index,
              children: const <Widget>[
                HomeScreen(),
                ValuationScreen(),
                BookmarksScreen(),
                MapScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ),
        floatingActionButton: _AIFab(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: context.read<AIAssistantBloc>(),
                  child: const AIAssistantPage(),
                ),
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: BlocBuilder<LandBloc, LandState>(
          builder: (context, landState) {
            final savedCount = landState is LandStateLoaded
                ? landState.favoriteIds.length
                : 0;
            return _GulfNavBar(
              items: _navItems,
              selectedIndex: _index,
              savedCount: savedCount,
              onTap: _onTabTapped,
            );
          },
        ),
      ),
    );
  }
}

class _GulfNavBar extends StatelessWidget {
  const _GulfNavBar({
    required this.items,
    required this.selectedIndex,
    required this.savedCount,
    required this.onTap,
  });
  final List<_NavItem> items;
  final int selectedIndex;
  final int savedCount;
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
              // Saved tab is index 2 — show badge
              final showBadge = i == 2 && savedCount > 0;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        key: ValueKey<bool>(isSelected),
                        tween: Tween<double>(
                          begin: isSelected ? 0.75 : 1.0,
                          end: 1.0,
                        ),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (_, double scale, Widget? child) =>
                            Transform.scale(scale: scale, child: child),
                        child: AnimatedContainer(
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
                          child: Badge(
                            isLabelVisible: showBadge,
                            label: Text(
                              '$savedCount',
                              style: const TextStyle(fontSize: 9),
                            ),
                            backgroundColor: AppColors.gold,
                            textColor: AppColors.navy,
                            offset: const Offset(8, -4),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                              size: 24,
                            ),
                          ),
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
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textMuted,
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

// ─── AI FAB ───────────────────────────────────────────────────────────────────
class _AIFab extends StatefulWidget {
  const _AIFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AIFab> createState() => _AIFabState();
}

class _AIFabState extends State<_AIFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gold, AppColors.goldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: AppColors.navy,
            size: 24,
          ),
        ),
      ),
    );
  }
}
