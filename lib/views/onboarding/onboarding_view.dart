// lib/views/onboarding/onboarding_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/onboarding_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final AuthController auth = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => controller.showLogin.value
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Image.asset(
                          'assets/images/logo_clear.png',
                          height: size.height * 0.2,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'WESTERN AREA RURAL DISTRICT COUNCIL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      DefaultTabController(
                        length: 2,
                        initialIndex: 0,
                        child: Column(
                          children: [
                            TabBar(
                              onTap: (int index) =>
                                  auth.selectedTabIndex.value = index,
                              indicatorColor: AppTheme.primaryGreen,
                              labelColor: AppTheme.primaryGreen,
                              unselectedLabelColor: Colors.black87,
                              tabs: const [
                                Tab(text: 'Assessment Officer Login'),
                                Tab(text: 'Cashier Login'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Form(
                              key: auth.formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: auth.emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email ID',
                                      hintText: 'eg. johnex@gmail.com',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: auth.validateEmail,
                                    autofillHints: const [AutofillHints.email],
                                  ),
                                  const SizedBox(height: 12),
                                  Obx(
                                    () => TextFormField(
                                      controller: auth.passwordController,
                                      obscureText: auth.obscurePassword.value,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          onPressed:
                                              auth.togglePasswordVisibility,
                                          icon: Icon(
                                            auth.obscurePassword.value
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                        ),
                                      ),
                                      validator: auth.validatePassword,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const SizedBox(height: 8),
                                  Obx(
                                    () => SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: auth.isLoading.value
                                            ? null
                                            : auth.submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryGreen,
                                          foregroundColor: AppTheme.pureWhite,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: auth.isLoading.value
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text('Submit'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 32.0,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo_clear.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
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
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: controller.showLoginForms,
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
