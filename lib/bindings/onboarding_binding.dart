// lib/bindings/onboarding_binding.dart

import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/auth_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(),
    );
    Get.lazyPut<AuthController>(
      () => AuthController(),
    );
  }
}

