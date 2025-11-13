// lib/services/toast_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

class ToastService {
  ToastService._();

  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  /// Show a toast notification
  static void show({
    required String message,
    required ToastType type,
    String? title,
    Duration? duration,
  }) {
    // Check if context is available
    final context = Get.context;
    if (context == null) {
      _showFallbackSnackbar(message, type, title, duration);
      return;
    }

    // Check if overlay is available before trying to use it
    OverlayState? overlay;
    try {
      overlay = Overlay.maybeOf(context, rootOverlay: true);
    } catch (e) {
      // Overlay not available, use fallback
      _showFallbackSnackbar(message, type, title, duration);
      return;
    }

    if (overlay == null) {
      // Overlay not available, use fallback
      _showFallbackSnackbar(message, type, title, duration);
      return;
    }

    // Remove existing toast if any
    if (_isVisible) {
      hide();
    }

    final toastDuration = duration ?? _getDefaultDuration(type);
    final toastData = _getToastData(type);

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        title: title ?? toastData['title'] as String,
        icon: toastData['icon'] as IconData,
        backgroundColor: toastData['backgroundColor'] as Color,
        iconColor: toastData['iconColor'] as Color,
        textColor: toastData['textColor'] as Color,
        duration: toastDuration,
        onDismiss: hide,
      ),
    );

    overlay.insert(_overlayEntry!);
    _isVisible = true;

    // Auto dismiss
    Future.delayed(toastDuration, () {
      hide();
    });
  }

  /// Fallback to Get.snackbar when overlay is not available
  static void _showFallbackSnackbar(
    String message,
    ToastType type,
    String? title,
    Duration? duration,
  ) {
    final toastData = _getToastData(type);
    final snackbarTitle = title ?? toastData['title'] as String;
    final snackbarDuration = duration ?? _getDefaultDuration(type);
    
    Get.snackbar(
      snackbarTitle,
      message,
      backgroundColor: toastData['backgroundColor'] as Color,
      colorText: toastData['textColor'] as Color,
      icon: Icon(
        toastData['icon'] as IconData,
        color: toastData['iconColor'] as Color,
      ),
      duration: snackbarDuration,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Show success toast
  static void showSuccess(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      type: ToastType.success,
      title: title,
      duration: duration,
    );
  }

  /// Show error toast
  static void showError(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      type: ToastType.error,
      title: title,
      duration: duration,
    );
  }

  /// Show info toast
  static void showInfo(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      type: ToastType.info,
      title: title,
      duration: duration,
    );
  }

  /// Show warning toast
  static void showWarning(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      type: ToastType.warning,
      title: title,
      duration: duration,
    );
  }

  /// Hide the current toast
  static void hide() {
    if (_overlayEntry != null && _isVisible) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }

  static Duration _getDefaultDuration(ToastType type) {
    switch (type) {
      case ToastType.success:
      case ToastType.info:
        return const Duration(seconds: 2);
      case ToastType.error:
      case ToastType.warning:
        return const Duration(seconds: 3);
    }
  }

  static Map<String, dynamic> _getToastData(ToastType type) {
    final colorScheme = Get.theme.colorScheme;
    final isDark = Get.theme.brightness == Brightness.dark;

    switch (type) {
      case ToastType.success:
        return {
          'title': 'Success',
          'icon': Icons.check_circle,
          'backgroundColor': isDark
              ? AppTheme.primaryGreen.withOpacity(0.2)
              : AppTheme.primaryGreen,
          'iconColor': isDark ? AppTheme.primaryGreen : Colors.white,
          'textColor': isDark ? Colors.white : Colors.white,
        };
      case ToastType.error:
        return {
          'title': 'Error',
          'icon': Icons.error,
          'backgroundColor': isDark
              ? colorScheme.error.withOpacity(0.2)
              : colorScheme.error,
          'iconColor': isDark ? colorScheme.error : Colors.white,
          'textColor': isDark ? Colors.white : Colors.white,
        };
      case ToastType.info:
        return {
          'title': 'Info',
          'icon': Icons.info,
          'backgroundColor': isDark
              ? AppTheme.secondaryBlue.withOpacity(0.2)
              : AppTheme.secondaryBlue,
          'iconColor': isDark ? AppTheme.secondaryBlue : Colors.white,
          'textColor': isDark ? Colors.white : Colors.white,
        };
      case ToastType.warning:
        return {
          'title': 'Warning',
          'icon': Icons.warning,
          'backgroundColor': isDark
              ? Colors.orange.withOpacity(0.2)
              : Colors.orange,
          'iconColor': isDark ? Colors.orange : Colors.white,
          'textColor': isDark ? Colors.white : Colors.white,
        };
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    // Start reverse animation before duration ends
    Future.delayed(
      widget.duration - const Duration(milliseconds: 250),
      () {
        if (mounted) {
          _controller.reverse().then((_) {
            widget.onDismiss();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _controller.reverse().then((_) {
                        widget.onDismiss();
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: widget.textColor.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

