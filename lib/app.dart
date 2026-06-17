import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/bloc/auth/auth_bloc.dart';
import 'package:gulflands/bloc/auth/auth_event.dart';
import 'package:gulflands/bloc/auth/auth_state.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:gulflands/core/services/ai_recommendation_service.dart';
import 'package:gulflands/features/ai_assistant/bloc/ai_assistant_bloc.dart';
import 'package:gulflands/core/services/telemetry_service.dart';
import 'package:gulflands/core/storage/cache_manager.dart';
import 'package:gulflands/presentation/screens/auth/login_screen.dart';
import 'package:gulflands/presentation/screens/auth/register_screen.dart';
import 'package:gulflands/presentation/screens/main_shell.dart';
import 'package:gulflands/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:gulflands/services/land_repository.dart';
import 'package:logger/logger.dart';
import 'package:nested/nested.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServicesContainer>(
      future: _initializeServices(),
      builder:
          (BuildContext context, AsyncSnapshot<ServicesContainer> snapshot) {
            if (!snapshot.hasData) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  backgroundColor: AppColors.navyDeep,
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }

            final ServicesContainer services = snapshot.data!;

            return MultiRepositoryProvider(
              providers: <SingleChildWidget>[
                RepositoryProvider<CacheManager>.value(
                  value: services.cacheManager,
                ),
                RepositoryProvider<TelemetryService>.value(
                  value: services.telemetryService,
                ),
                RepositoryProvider<AIRecommendationService>.value(
                  value: AIRecommendationServiceImpl(Logger()),
                ),
                RepositoryProvider<LandRepository>.value(
                  value: services.landRepository,
                ),
              ],
              child: MultiBlocProvider(
                providers: <SingleChildWidget>[
                  BlocProvider<AuthBloc>(
                    create: (_) => AuthBloc()..add(const AuthCheckRequested()),
                  ),
                  BlocProvider<LandBloc>(
                    create: (BuildContext context) =>
                        LandBloc(repository: context.read<LandRepository>()),
                  ),
                  BlocProvider<AIAssistantBloc>(
                    create: (_) => AIAssistantBloc(),
                  ),
                ],
                child: MaterialApp(
                  title: 'Gulf Lands',
                  debugShowCheckedModeBanner: false,
                  theme: _buildDarkTheme(),
                  home: _AuthGate(seenOnboarding: services.seenOnboarding),
                ),
              ),
            );
          },
    );
  }

  static ThemeData _buildDarkTheme() {
    final tokens = AppDesignTokens.dark();
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.cardBg,
        error: AppColors.error,
        onPrimary: AppColors.navy,
        onSecondary: AppColors.navy,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardBg,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.gold : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.gold : AppColors.textMuted,
            size: 24,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardBgLight,
        selectedColor: AppColors.gold.withValues(alpha: 0.2),
        side: const BorderSide(color: AppColors.dividerColor),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.dividerColor),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }

  Future<ServicesContainer> _initializeServices() async {
    final CacheManagerImpl cacheManager = await CacheManagerImpl.create();
    final TelemetryService telemetryService =
        await TelemetryService.initialize();
    final LandRepositoryImpl landRepository = LandRepositoryImpl(
      cacheManager: cacheManager,
    );
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    return ServicesContainer(
      cacheManager: cacheManager,
      telemetryService: telemetryService,
      landRepository: landRepository,
      seenOnboarding: seenOnboarding,
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.seenOnboarding});
  final bool seenOnboarding;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _showLogin = true;
  late bool _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _seenOnboarding = widget.seenOnboarding;
  }

  void _onOnboardingDone() {
    setState(() => _seenOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_seenOnboarding) {
      return OnboardingScreen(onDone: _onOnboardingDone);
    }

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState state) {
        if (state is AuthInitial || state is AuthLoading) {
          return Scaffold(
            backgroundColor: AppColors.darkSurface,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          return const MainShell();
        }

        if (_showLogin) {
          return LoginScreen(
            onNavigateToRegister: () => setState(() => _showLogin = false),
          );
        }

        return RegisterScreen(
          onNavigateToLogin: () => setState(() => _showLogin = true),
        );
      },
    );
  }
}

class ServicesContainer {
  ServicesContainer({
    required this.cacheManager,
    required this.telemetryService,
    required this.landRepository,
    required this.seenOnboarding,
  });
  final CacheManager cacheManager;
  final TelemetryService telemetryService;
  final LandRepository landRepository;
  final bool seenOnboarding;
}
