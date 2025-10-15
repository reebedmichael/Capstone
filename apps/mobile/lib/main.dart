import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'shared/constants/strings_af.dart';
import 'shared/providers/theme_provider.dart';
import 'bootstrap.dart';
import 'locator.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/order_cleanup_service.dart';
import 'core/services/timezone_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Starting app initialization...');
    
    // Initialize Firebase (if configuration exists)
    try {
      await Firebase.initializeApp();
      print('Firebase initialized');
    } catch (e) {
      print('Firebase initialization failed (this is OK if not configured yet): $e');
      // Continue without Firebase - it's optional until configured
    }
    
    // Initialize Supabase with error handling
    try {
      await bootstrapSupabase();
      print('Supabase initialized');
    } catch (e) {
      print('Supabase initialization failed: $e');
      // Continue without Supabase for now
    }

    try {
      setupLocator();
      print('Locator setup complete');
    } catch (e) {
      print('Locator setup failed: $e');
    }

    try {
      // Initialize timezone service
      TimezoneService.initialize();
      print('Timezone service initialized');
    } catch (e) {
      print('Timezone service failed: $e');
    }

    try {
      // Initialiseer notifikasie service
      await NotificationService().initialize();
      print('Notification service initialized');
    } catch (e) {
      print('Notification service failed: $e');
    }

    try {
      // Start automatic order cleanup service
      _startOrderCleanupService();
      print('Order cleanup service started');
    } catch (e) {
      print('Order cleanup service failed: $e');
    }


    print('All services initialized, starting app...');
    runApp(const MyApp());
  } catch (e) {
    print('Error initializing app: $e');
    print('Stack trace: ${StackTrace.current}');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final themeMode = ref.watch(themeProvider);
          return MaterialApp.router(
            title: StringsAf.appTitle,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
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
      ),
    );
  }
}

/// Start the automatic order cleanup service
void _startOrderCleanupService() {
  // Run cleanup every 6 hours to catch expired orders
  // This ensures orders are cancelled after midnight of their due date
  Timer.periodic(const Duration(hours: 6), (timer) async {
    try {
      final client = Supabase.instance.client;
      final cleanupService = OrderCleanupService(client);
      final result = await cleanupService.cancelUnclaimedOrders();
      
      if (result['success'] == true && result['cancelledCount'] > 0) {
        print('🧹 Automatic cleanup: ${result['message']}');
      }
    } catch (e) {
      print('❌ Automatic cleanup failed: $e');
    }
  });
  
  // Also run cleanup immediately on app start
  Timer(const Duration(seconds: 5), () async {
    try {
      final client = Supabase.instance.client;
      final cleanupService = OrderCleanupService(client);
      final result = await cleanupService.cancelUnclaimedOrders();
      
      if (result['success'] == true && result['cancelledCount'] > 0) {
        print('🧹 Initial cleanup: ${result['message']}');
      }
    } catch (e) {
      print('❌ Initial cleanup failed: $e');
    }
  });
}