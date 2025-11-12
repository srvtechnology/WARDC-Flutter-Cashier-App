// lib/services/loading_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingService {
  LoadingService._();

  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  /// Show loading overlay
  static void showLoading({String? message}) {
    final context = Get.context;
    if (context == null) {
      Get.log('LoadingService: Context not available, cannot show loading');
      return;
    }

    // Remove existing loading if any
    if (_isVisible) {
      hideLoading();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingWidget(message: message),
    );

    final overlay = Overlay.of(context);
    overlay.insert(_overlayEntry!);
    _isVisible = true;
  }

  /// Hide loading overlay
  static void hideLoading() {
    if (_overlayEntry != null && _isVisible) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }

  /// Check if loading is currently visible
  static bool get isLoading => _isVisible;
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

