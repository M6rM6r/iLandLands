import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gulflands/bloc/auth/auth_bloc.dart';
import 'package:gulflands/bloc/auth/auth_event.dart';
import 'package:gulflands/bloc/auth/auth_state.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/core/services/ai_recommendation_service.dart';
import 'package:gulflands/core/services/telemetry_service.dart';
import 'package:gulflands/core/storage/cache_manager.dart';
import 'package:gulflands/presentation/screens/auth/login_screen.dart';
import 'package:gulflands/presentation/screens/auth/register_screen.dart';
import 'package:gulflands/presentation/screens/main_shell.dart';
import 'package:gulflands/services/land_repository.dart';
import 'package:logger/logger.dart';
import 'package:nested/nested.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServicesContainer>(
      future: _initializeServices(),
      builder:
          (BuildContext context, AsyncSnapshot<ServicesContainer> snapshot) {
            if (!snapshot.hasData) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
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
                ],
                child: MaterialApp(
                  title: 'Gulf Lands Market',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    brightness: Brightness.dark,
                    scaffoldBackgroundColor: Colors.black,
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.blueGrey,
                      brightness: Brightness.dark,
                    ),
                    useMaterial3: true,
                  ),
                  home: const _AuthGate(),
                ),
              ),
            );
          },
    );
  }

  Future<ServicesContainer> _initializeServices() async {
    final CacheManagerImpl cacheManager = await CacheManagerImpl.create();
    final TelemetryService telemetryService =
        await TelemetryService.initialize();
    final LandRepositoryImpl landRepository = LandRepositoryImpl(
      cacheManager: cacheManager,
    );

    return ServicesContainer(
      cacheManager: cacheManager,
      telemetryService: telemetryService,
      landRepository: landRepository,
    );
  }
}

/// Top-level auth router.
/// - Shows a loading spinner during the initial auth check.
/// - Routes to [HomeScreen] when authenticated.
/// - Routes to [LoginScreen] / [RegisterScreen] when unauthenticated.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          return const MainShell();
        }

        // Unauthenticated or error — show login/register toggle
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
  });
  final CacheManager cacheManager;
  final TelemetryService telemetryService;
  final LandRepository landRepository;
}
