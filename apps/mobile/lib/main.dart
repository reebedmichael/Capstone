import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'shared/constants/strings_af.dart';
import 'bootstrap.dart';
import 'locator.dart';
import 'shared/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Skip dotenv loading for now since .env files are not available
    // await dotenv.load(fileName: kReleaseMode ? '.env.prod' : '.env.dev');

    await bootstrapSupabase();

    setupLocator();

    // Initialiseer notifikasie service
    await NotificationService().initialize();

    runApp(const MyApp());
  } catch (e) {
    print('Error initializing app: $e');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: StringsAf.appTitle,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'App Initialization Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Check console for details'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
