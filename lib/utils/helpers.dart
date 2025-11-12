// lib/utils/helpers.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/toast_service.dart';

/// Helper functions for common operations
class Helpers {
  Helpers._();

  /// Show success toast
  static void showSuccess(String message, {String? title}) {
    ToastService.showSuccess(message, title: title);
  }

  /// Show error toast
  static void showError(String message, {String? title}) {
    ToastService.showError(message, title: title);
  }

  /// Show info toast
  static void showInfo(String message, {String? title}) {
    ToastService.showInfo(message, title: title);
  }

  /// Show warning toast
  static void showWarning(String message, {String? title}) {
    ToastService.showWarning(message, title: title);
  }

  /// Show loading dialog
  static void showLoading() {
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Format date
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format currency
  static String formatCurrency(double amount) {
    return 'SLL ${amount.toStringAsFixed(2)}';
  }

  /// Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate phone number (Sierra Leone format)
  static bool isValidPhoneNumber(String phone) {
    // Sierra Leone phone numbers typically start with +232 or 0
    return RegExp(r'^(\+232|0)[0-9]{8,9}$').hasMatch(phone);
  }
}

