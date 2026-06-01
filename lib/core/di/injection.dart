// This file is kept for compatibility but the app uses Provider-based DI
// See lib/app.dart for the actual dependency injection setup

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

final GetIt getIt = GetIt.instance;

/// Stub for compatibility - not used in current architecture
Future<void> configureDependencies() async {
  getIt.registerSingleton<Logger>(
    Logger(
      printer: PrettyPrinter(
        printTime: true,
      ),
    ),
  );
}
