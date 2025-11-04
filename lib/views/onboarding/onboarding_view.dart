// lib/views/onboarding/onboarding_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/onboarding_controller.dart';
import '../../theme/app_theme.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   colors: [
          //     AppTheme.primaryGreen.withOpacity(0.1),
          //     AppTheme.primaryGreen.withOpacity(0.2),
          //   ],
          // ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Map Graphic Section
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/logo_clear.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Text Section
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'WESTERN AREA RURAL',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DISTRICT COUNCIL',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Digital Property Management System',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryGreen.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Get Started Button
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.navigateToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.pureWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Sierra Leone Map with Flag Colors
class SierraLeoneMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    // Sierra Leone has a distinctive shape - wider at the top, narrower at bottom
    // with a curved coastline on the right (west coast)

    // Create the overall map path (approximate Sierra Leone shape)
    final mapPath = Path()
      // Top-left corner
      ..moveTo(size.width * 0.08, size.height * 0.02)
      // Top edge (north border)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.0,
        size.width * 0.5,
        size.height * 0.0,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.0,
        size.width * 0.92,
        size.height * 0.02,
      )
      // Right edge (west coast - curved)
      ..quadraticBezierTo(
        size.width * 0.95,
        size.height * 0.15,
        size.width * 0.94,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.93,
        size.height * 0.45,
        size.width * 0.92,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.93,
        size.height * 0.75,
        size.width * 0.94,
        size.height * 0.9,
      )
      // Bottom edge (south border)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.98,
        size.width * 0.7,
        size.height * 1.0,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.99,
        size.width * 0.3,
        size.height * 0.99,
      )
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.98,
        size.width * 0.06,
        size.height * 0.94,
      )
      // Left edge (east border)
      ..quadraticBezierTo(
        size.width * 0.05,
        size.height * 0.75,
        size.width * 0.06,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.05,
        size.height * 0.45,
        size.width * 0.06,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.05,
        size.height * 0.15,
        size.width * 0.08,
        size.height * 0.02,
      )
      ..close();

    // Clip to map shape first, then draw horizontal flag stripes
    canvas.save();
    canvas.clipPath(mapPath);

    // Draw horizontal flag stripes (green, white, blue)
    // Top third - Green
    paint.color = AppTheme.primaryGreen;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height / 3), paint);

    // Middle third - White
    paint.color = AppTheme.pureWhite;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 3, size.width, size.height / 3),
      paint,
    );

    // Bottom third - Blue
    paint.color = AppTheme.secondaryBlue;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 2 / 3, size.width, size.height / 3),
      paint,
    );

    canvas.restore();

    // Draw border outline
    paint.color = AppTheme.secondaryBlue.withOpacity(0.6);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3.0;
    canvas.drawPath(mapPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
