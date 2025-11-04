// lib/controllers/home_controller.dart

import 'package:get/get.dart';

class HomeController extends GetxController {
  // Observable variables
  final _counter = 0.obs;
  final _isLoading = false.obs;

  // Getters
  int get counter => _counter.value;
  bool get isLoading => _isLoading.value;

  // Methods
  void incrementCounter() {
    _counter.value++;
  }

  void decrementCounter() {
    if (_counter.value > 0) {
      _counter.value--;
    }
  }

  void resetCounter() {
    _counter.value = 0;
  }

  Future<void> simulateLoading() async {
    _isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2));
    _isLoading.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize controller
  }

  @override
  void onReady() {
    super.onReady();
    // Called after the widget is rendered on screen
  }

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}

