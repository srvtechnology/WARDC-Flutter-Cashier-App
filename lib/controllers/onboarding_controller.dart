// lib/controllers/onboarding_controller.dart

import 'package:get/get.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';

class OnboardingController extends GetxController {
  final RxBool showLogin = false.obs;
  final AuthService _auth = AuthService();

  @override
  void onInit() {
    super.onInit();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    final String? token = await _auth.getToken();
    if (token == null || token.isEmpty) {
      return; // Not logged in; remain on onboarding
    }
    final UserType? type = await _auth.getSavedUserType();
    if (type == UserType.assessmentOfficer) {
      Get.offAllNamed(Routes.assessmentDashboard);
    }
  }

  void showLoginForms() {
    showLogin.value = true;
  }
}
