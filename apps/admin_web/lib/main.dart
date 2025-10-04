import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'bootstrap.dart';
import 'locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Skip dotenv loading for now since .env files are not available
  // await dotenv.load(fileName: kReleaseMode ? '.env.prod' : '.env.dev');

  await bootstrapSupabase();

  setupLocator();

  runApp(const ProviderScope(child: SpysAdminApp()));
}

class SpysAdminApp extends ConsumerStatefulWidget {
  const SpysAdminApp({super.key});

  @override
  ConsumerState<SpysAdminApp> createState() => _SpysAdminAppState();
}

class _SpysAdminAppState extends ConsumerState<SpysAdminApp> {
  @override
  void initState() {
    super.initState();
    // Initialize theme from SharedPreferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appThemeProvider.notifier).initializeTheme();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Spys Admin',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.themeMode,
      routerConfig: router,
    );
  }
}
