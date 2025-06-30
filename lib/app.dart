import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'features/admin/admin_app.dart';
import 'features/student/student_app.dart';

class SpysRoot extends StatelessWidget {
  const SpysRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // Show admin web app if on web, otherwise student/staff app
    if (kIsWeb) {
      return const AdminApp();
    } else {
      return const StudentApp();
    }
  }
} 