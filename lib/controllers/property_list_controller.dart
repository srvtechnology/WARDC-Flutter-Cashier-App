import 'package:get/get.dart';
import '../services/property_service.dart';

class PropertyListController extends GetxController {
  final RxList<dynamic> properties = <dynamic>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasMore = true.obs;
  final int limit = 10;

  @override
  void onInit() {
    super.onInit();
    fetchProperties();
  }

  Future<void> fetchProperties({int? page, bool append = false}) async {
    if (isLoading.value || isLoadingMore.value) return;

    if (append) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      errorMessage.value = '';
    }

    try {
      final int pageToFetch = page ?? currentPage.value;
      final Map<String, dynamic> response =
          await PropertyService().getPropertyListing(
        page: pageToFetch,
        limit: limit,
      );

      // Log the response structure for debugging
      // removed debug response structure logging

      // Extract properties from response
      List<dynamic> newProperties = [];
      
      // Case 1: API returns { success, property: { current_page, data: [...], ... } }
      if (response.containsKey('property')) {
        final dynamic prop = response['property'];
        if (prop is Map) {
          if (prop.containsKey('data') && prop['data'] is List) {
            newProperties = List<dynamic>.from(prop['data'] as List);
          }
          // Extract pagination info
          if (prop.containsKey('current_page')) {
            currentPage.value = (prop['current_page'] as num).toInt();
          }
          if (prop.containsKey('last_page')) {
            totalPages.value = (prop['last_page'] as num).toInt();
          }
          if (prop.containsKey('total')) {
            totalItems.value = (prop['total'] as num).toInt();
          } else if (prop.containsKey('to')) {
            // Fallback when total not provided; use 'to' if available
            totalItems.value = (prop['to'] as num).toInt();
          }
          // Prefer next_page_url to determine hasMore if provided
          if (prop.containsKey('next_page_url')) {
            hasMore.value = prop['next_page_url'] != null;
          }
        }
      } else if (response.containsKey('data')) {
        final dynamic data = response['data'];
        if (data is Map) {
          // If data is a map, check for common pagination keys
          if (data.containsKey('data') && data['data'] is List) {
            newProperties = List<dynamic>.from(data['data'] as List);
          } else if (data.containsKey('properties') && data['properties'] is List) {
            newProperties = List<dynamic>.from(data['properties'] as List);
          } else if (data.containsKey('items') && data['items'] is List) {
            newProperties = List<dynamic>.from(data['items'] as List);
          }

          // Extract pagination info
          if (data.containsKey('current_page')) {
            currentPage.value = (data['current_page'] as num).toInt();
          }
          if (data.containsKey('last_page')) {
            totalPages.value = (data['last_page'] as num).toInt();
          } else if (data.containsKey('total_pages')) {
            totalPages.value = (data['total_pages'] as num).toInt();
          }
          if (data.containsKey('total')) {
            totalItems.value = (data['total'] as num).toInt();
          }
        } else if (data is List) {
          // If data is directly a list
          newProperties = List<dynamic>.from(data);
        }
      } else if (response.containsKey('properties') && response['properties'] is List) {
        newProperties = List<dynamic>.from(response['properties'] as List);
      } else if (response.containsKey('data') && response['data'] is List) {
        newProperties = List<dynamic>.from(response['data'] as List);
      }

      // Handle pagination for infinite scroll
      if (append) {
        // Append new properties to existing list
        properties.addAll(newProperties);
      } else {
        // Replace properties list
        properties.value = newProperties;
      }

      // Check if there are more pages to load
      if (!response.containsKey('property')) {
        hasMore.value = currentPage.value < totalPages.value && newProperties.length >= limit;
      }

      // If no properties found but response is successful, set empty list
      if (properties.isEmpty && response.containsKey('success') && response['success'] == true) {
        properties.value = [];
        hasMore.value = false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.log('Error fetching properties: $e');
      hasMore.value = false;
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshProperties() async {
    currentPage.value = 1;
    hasMore.value = true;
    await fetchProperties(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (hasMore.value && !isLoading.value && !isLoadingMore.value) {
      final int nextPage = currentPage.value + 1;
      await fetchProperties(page: nextPage, append: true);
    }
  }
}

