// lib/controllers/onboarding_controller.dart

import 'package:get/get.dart';
import '../routes/app_pages.dart';

class OnboardingController extends GetxController {
  // Handle navigation to home/next screen
  void navigateToHome() {
    Get.offAllNamed(Routes.home);
  }
}

