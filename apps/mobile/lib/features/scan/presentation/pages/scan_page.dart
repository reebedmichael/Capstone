import 'package:flutter/material.dart';
import 'package:capstone_mobile/features/app/presentation/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

class QrScanner extends StatelessWidget {
  const QrScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Skandeer",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent, width: 4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Fake "camera" background
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            size: 100,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                      // Scanning line animation
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 2,
                            width: double.infinity,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }
}
