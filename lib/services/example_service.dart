// lib/services/example_service.dart

import 'package:get/get.dart';

/// Example service class
/// Services are used for business logic, API calls, and data operations
class ExampleService extends GetxService {
  // Example method
  Future<String> fetchData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    return 'Data fetched successfully';
  }

  // Example method with error handling
  Future<String> fetchDataWithError() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Error occurred');
    } catch (e) {
      return 'Error: $e';
    }
  }
}

