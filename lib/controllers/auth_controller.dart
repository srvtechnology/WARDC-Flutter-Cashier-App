import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../services/toast_service.dart';

class AuthController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

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
      const UserType type = UserType.cashier;
      await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
        type: type,
      );

      Get.offAllNamed(Routes.paymentSearch);
    } on AuthException catch (e) {
      ToastService.showError(e.message, title: 'Login failed');
    } catch (e) {
      ToastService.showError(
        'Unexpected error occurred',
        title: 'Login failed',
      );
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
