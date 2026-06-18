import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconController;
  late Animation<double> _iconScaleAnimation;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.landscape,
      title: 'Discover Gulf Land',
      subtitle:
          'Browse premium land listings across UAE, Saudi Arabia, Qatar, Kuwait, Bahrain & Oman – all in one place.',
      gradientStart: Color(0xFF071a2d),
      gradientEnd: Color(0xFF0A2540),
      accentIcon: Icons.map_outlined,
    ),
    _OnboardingSlide(
      icon: Icons.smart_toy_outlined,
      title: 'AI-Powered Search',
      subtitle:
          'Ask questions in plain language. Our Gemini-powered assistant finds the perfect plot based on your needs and budget.',
      gradientStart: Color(0xFF0d1b2a),
      gradientEnd: Color(0xFF112240),
      accentIcon: Icons.auto_awesome,
    ),
    _OnboardingSlide(
      icon: Icons.calculate_outlined,
      title: 'Instant Valuation',
      subtitle:
          'Get real-time land valuation estimates powered by live market data. Know what a plot is worth before you buy.',
      gradientStart: Color(0xFF071a2d),
      gradientEnd: Color(0xFF0a1e35),
      accentIcon: Icons.trending_up,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _iconScaleAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _iconController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _iconController.reset();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
      _iconController.forward();
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                _iconController.reset();
                _iconController.forward();
              },
              itemBuilder: (context, index) =>
                  _SlidePage(slide: _slides[index], animation: _iconScaleAnimation),
            ),

            // ── Bottom controls ──────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.navyDeep.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DotIndicator(
                      count: _slides.length,
                      current: _currentPage,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        if (_currentPage < _slides.length - 1)
                          TextButton(
                            onPressed: _finish,
                            child: Text(
                              'Skip',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (_currentPage < _slides.length - 1)
                          const Spacer(),
                        GestureDetector(
                          onTap: _goNext,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _currentPage == _slides.length - 1
                                ? double.infinity
                                : 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(
                                _currentPage == _slides.length - 1 ? 14 : 28,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _currentPage == _slides.length - 1
                                  ? Text(
                                      'Get Started',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_forward,
                                      color: AppColors.navy,
                                      size: 22,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide, required this.animation});
  final _OnboardingSlide slide;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [slide.gradientStart, slide.gradientEnd],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // ── Animated illustration ─────────────────────────────────────
            ScaleTransition(
              scale: animation,
              child: Container(
                width: size.width > 600 ? 280.0 : size.width * 0.55,
                height: size.width > 600 ? 280.0 : size.width * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBg,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    slide.icon,
                    size: size.width > 600 ? 110.0 : size.width * 0.22,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // ── Text content ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Accent badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(slide.accentIcon, size: 13, color: AppColors.gold),
                        const SizedBox(width: 6),
                        Text(
                          'Gulf Lands',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    slide.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.gold : AppColors.textMuted,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accentIcon,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData accentIcon;
}
