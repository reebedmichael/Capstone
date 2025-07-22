import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/utils/locale_provider.dart';
import 'features/admin/admin_app.dart';
import 'features/student/student_app.dart';
import 'features/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'models/user.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class SpysApp extends StatelessWidget {
  const SpysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Spys',
            // theme: AppTheme.lightTheme,
            // darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: localeProvider.locale,
            supportedLocales: const [Locale('en'), Locale('af')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/student': (context) => const StudentApp(),
              '/admin': (context) => const AdminApp(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _autoLoginTriggered = false;

  @override
  void initState() {
    super.initState();
    // Trigger auto-login only once
    Future.microtask(() async {
      if (AuthService().currentUser == null) {
        await AuthService().login('demo@spys.com', 'password123');
      }
      if (mounted) {
        setState(() {
          _autoLoginTriggered = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (!_autoLoginTriggered || snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // If login fails, show login screen
          return const LoginScreen();
        }

        // Show AdminApp on web, StudentApp on mobile
        if (kIsWeb) {
          return const AdminApp();
        } else {
          return const StudentApp();
        }
      },
    );
  }
} 