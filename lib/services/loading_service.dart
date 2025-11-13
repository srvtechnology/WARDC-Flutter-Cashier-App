// lib/services/loading_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// @deprecated This service is deprecated. Use individual loading states
/// with button disabled state and CircularProgressIndicator in buttons instead.
@Deprecated('Use individual loading states with button disabled state instead')
class LoadingService {
  LoadingService._();

  static bool _isLoading = false;

  /// Show loading overlay
  static void showLoading({String message = 'Loading...'}) {
    if (_isLoading) return;

    _isLoading = true;
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent dialog from being dismissed by back button
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }

  /// Hide loading overlay
  static void hideLoading() {
    if (_isLoading) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      _isLoading = false;
    }
  }

  /// Check if loading is currently visible
  static bool get isLoading => _isLoading;
}


