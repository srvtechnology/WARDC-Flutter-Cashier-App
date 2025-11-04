import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxInt selectedTabIndex = 0.obs; // 0: Assessment, 1: Cashier

  final AuthService _authService = AuthService();

  String? validateEmail(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    final RegExp emailRegex = RegExp(r'^.+@.+\..+$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required';
    return null;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final UserType type =
          selectedTabIndex.value == 0 ? UserType.assessmentOfficer : UserType.cashier;
      await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
        type: type,
      );

      // Navigate based on role
      if (type == UserType.assessmentOfficer) {
        Get.offAllNamed(Routes.assessmentDashboard);
      } else {
        Get.offAllNamed(Routes.cashierDashboard);
      }
    } on AuthException catch (e) {
      Get.snackbar('Login failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Login failed', 'Unexpected error occurred',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}


