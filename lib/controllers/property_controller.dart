import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/property_models.dart';
import '../services/property_service.dart';
import '../services/toast_service.dart';

class PropertyController extends GetxController {
  final RxInt step = 0.obs; // 0..4
  final GlobalKey<FormState> step1Key = GlobalKey<FormState>();
  final GlobalKey<FormState> step2Key = GlobalKey<FormState>();
  final GlobalKey<FormState> step3Key = GlobalKey<FormState>();
  final GlobalKey<FormState> step4Key = GlobalKey<FormState>();
  final GlobalKey<FormState> step5Key = GlobalKey<FormState>();

  final RxMap<String, dynamic> payload = <String, dynamic>{}.obs;
  final RxMap<String, Map<String, String>> registry =
      <String, Map<String, String>>{}.obs;
  final RxList<String> assessmentPhotos = <String>[].obs;

  final RxBool isSubmitting = false.obs;
  // Tracks whether the landlord is an organization ('1') or an individual ('0')
  final RxString isOrganization = '0'.obs;
  // Used to notify the UI when cached variables change
  final RxInt variablesTick = 0.obs;

  Box<dynamic>? _variables;

  @override
  Future<void> onInit() async {
    await Hive.initFlutter();
    _variables = await Hive.openBox<dynamic>(HiveBoxes.variablesCache);
    payload['randomdata'] = DateTime.now().millisecondsSinceEpoch.toString();
    // Default to non-organization
    payload['is_organization'] = '0';
    // Default values for assessment form
    payload['group_name'] = 'A';
    payload['ownerTitle'] = '1';
    await _maybeRefreshVariables();
    super.onInit();
  }

  Map<String, dynamic>? get cachedVariables {
    final dynamic raw = _variables?.get('all');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> refreshVariables() async {
    try {
      final Map<String, dynamic> resp = await PropertyService()
          .getAllVariables();
      _variables?.put('all', <String, dynamic>{
        'fetchedAt': DateTime.now().millisecondsSinceEpoch,
        'data': resp,
      });
      // Notify listeners that variables have changed
      variablesTick.value++;
    } catch (e) {
      // Network error; keep using cached values if any
      Get.log('Variables fetch failed: $e');
    }
  }

  Future<void> _maybeRefreshVariables() async {
    final dynamic raw = _variables?.get('all');
    final Map<String, dynamic>? cached =
        raw is Map ? Map<String, dynamic>.from(raw) : null;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int ttlMs = 1000 * 60 * 60; // 1 hour
    if (cached == null || (now - (cached['fetchedAt'] as int? ?? 0)) > ttlMs) {
      await refreshVariables();
    } else {
      // Trigger one tick so dependent widgets can read existing cache
      variablesTick.value++;
    }
  }

  void setField(String key, dynamic value) {
    payload[key] = value;
  }

  void setIsOrganization(String value) {
    isOrganization.value = value;
    payload['is_organization'] = value;
  }

  void addRegistryItem(int index, {String? meterNumber, String? imagePath}) {
    final Map<String, String> current = Map<String, String>.from(
      registry['$index'] ?? <String, String>{},
    );
    if (meterNumber != null) current['meter_number'] = meterNumber;
    if (imagePath != null) current['meter_image'] = imagePath;
    registry['$index'] = current;
  }

  int addEmptyRegistryItem() {
    final int idx = registry.length;
    registry['$idx'] = <String, String>{};
    return idx;
  }

  void removeRegistryItem(int index) {
    registry.remove('$index');
  }

  void addAssessmentPhoto(String path) {
    if (path.isNotEmpty && File(path).existsSync()) {
      assessmentPhotos.add(path);
    }
  }

  void removeAssessmentPhoto(int idx) {
    if (idx >= 0 && idx < assessmentPhotos.length) {
      assessmentPhotos.removeAt(idx);
    }
  }

  Future<void> nextStep() async {
    if (!_validateCurrent()) return;
    if (step.value == 0) {
      _printLandlordPayload();
    }
    if (step.value == 1) {
      _printPropertyPayload();
    }
    if (step.value == 2) {
      _printOccupancyPayload();
    }
    if (step.value == 3) {
      _printGeoRegistryPayload();
    }
    if (step.value < 4) {
      step.value += 1;
    }
  }

  void prevStep() {
    if (step.value > 0) {
      step.value -= 1;
    }
  }

  bool _validateCurrent() {
    switch (step.value) {
      case 0:
        return step1Key.currentState?.validate() ?? true;
      case 1:
        return step2Key.currentState?.validate() ?? true;
      case 2:
        return step3Key.currentState?.validate() ?? true;
      case 3:
        return step4Key.currentState?.validate() ?? true;
      case 4:
        return step5Key.currentState?.validate() ?? true;
      default:
        return true;
    }
  }

  /// Merges all step payloads and formats them according to API specification
  Map<String, dynamic> _prepareSubmissionPayload() {
    final Map<String, dynamic> merged = Map<String, dynamic>.from(payload);

    // Set default values for required fields if not present
    merged['categoryType'] = merged['categoryType'] ?? 'C'; // C or R
    merged['randomdata'] = merged['randomdata'] ?? 
        DateTime.now().millisecondsSinceEpoch.toString();
    merged['group_name'] = merged['group_name'] ?? 'A';
    merged['is_organization'] = merged['is_organization'] ?? '0';
    merged['is_completed'] = merged['is_completed'] ?? '0';
    merged['is_property_inaccessible'] = merged['is_property_inaccessible'] ?? '0';
    merged['sanitation'] = merged['sanitation'];
    merged['wall_material_condition'] = merged['wall_material_condition'];

    // Map landlord_ownerTitle_id (use ownerTitle if landlord_ownerTitle_id not set)
    if (merged['landlord_ownerTitle_id'] == null && merged['ownerTitle'] != null) {
      merged['landlord_ownerTitle_id'] = merged['ownerTitle'].toString();
    }

    // Map assessment rate fields (API expects camelCase)
    if (merged['property_rate_without_gst'] != null) {
      merged['assessmentRateWithoutGST'] = merged['property_rate_without_gst'].toString();
      merged['assessment_rate_without_gst'] = merged['property_rate_without_gst'].toString();
    } else {
      merged['assessmentRateWithoutGST'] = '0.00';
      merged['assessment_rate_without_gst'] = '0.00';
    }

    if (merged['property_rate_with_gst'] != null) {
      merged['assessmentRateWithGST'] = merged['property_rate_with_gst'].toString();
      merged['assessment_rate_with_gst'] = merged['property_rate_with_gst'].toString();
    } else {
      merged['assessmentRateWithGST'] = '0';
      merged['assessment_rate_with_gst'] = '0';
    }

    // Map property_types to assessment_types_total
    if (merged['property_types'] != null) {
      merged['assessment_types_total'] = merged['property_types'];
    }

    // Map is_draft_delivered to isDraftDelivered (camelCase)
    if (merged['is_draft_delivered'] != null) {
      merged['isDraftDelivered'] = merged['is_draft_delivered'].toString();
    }

    // Ensure property_inaccessable is an array
    if (merged['property_inaccessable'] != null) {
      if (merged['property_inaccessable'] is! List) {
        final dynamic val = merged['property_inaccessable'];
        merged['property_inaccessable'] = val != null ? [val.toString()] : [];
      }
    } else {
      merged['property_inaccessable'] = [];
    }

    // Ensure occupancy_type is an array
    if (merged['occupancy_type'] != null) {
      if (merged['occupancy_type'] is! List) {
        final dynamic val = merged['occupancy_type'];
        merged['occupancy_type'] = val != null ? [val.toString()] : [];
      }
    }

    // Ensure assessment_categories_id is an array
    if (merged['assessment_categories_id'] != null) {
      if (merged['assessment_categories_id'] is! List) {
        final dynamic val = merged['assessment_categories_id'];
        merged['assessment_categories_id'] = val != null ? [val.toString()] : [];
      }
    }

    // Ensure assessment_value_added_id is an array
    if (merged['assessment_value_added_id'] != null) {
      if (merged['assessment_value_added_id'] is! List) {
        final dynamic val = merged['assessment_value_added_id'];
        merged['assessment_value_added_id'] = val != null ? [val.toString()] : [];
      }
    }

    // Ensure property_types is an array
    if (merged['property_types'] != null) {
      if (merged['property_types'] is! List) {
        final dynamic val = merged['property_types'];
        merged['property_types'] = val != null ? [val.toString()] : [];
      }
    }

    // Handle newAdjustmentIds - should already be a JSON string from _CouncilAdjustmentsChips
    // If it's not set, set it to empty array JSON string
    if (merged['newAdjustmentIds'] == null || merged['newAdjustmentIds'].toString().isEmpty) {
      merged['newAdjustmentIds'] = '[]';
    }

    // Ensure optional numeric fields are properly formatted
    if (merged['total_shops'] != null) {
      merged['total_shops'] = int.tryParse(merged['total_shops'].toString()) ?? 0;
    }
    if (merged['total_mast'] != null) {
      merged['total_mast'] = int.tryParse(merged['total_mast'].toString()) ?? 0;
    }
    if (merged['total_compound_house'] != null) {
      merged['total_compound_house'] = int.tryParse(merged['total_compound_house'].toString()) ?? 0;
    }

    // Handle swimming_pool - ensure it's a string or number
    if (merged['swimming_pool'] != null) {
      merged['swimming_pool'] = merged['swimming_pool'].toString();
    }

    // Ensure all registry points are strings (lat,long format)
    for (int i = 1; i <= 8; i++) {
      final String key = 'registry_point$i';
      if (merged[key] != null) {
        merged[key] = merged[key].toString();
      }
    }

    // Ensure dor_lat_long is a string
    if (merged['dor_lat_long'] != null) {
      merged['dor_lat_long'] = merged['dor_lat_long'].toString();
    }

    // Ensure registry_digital_address is a string
    if (merged['registry_digital_address'] != null) {
      merged['registry_digital_address'] = merged['registry_digital_address'].toString();
    }

    // Convert all null values to null explicitly (they will be filtered in service)
    // Convert empty strings to null for optional fields
    final List<String> optionalStringFields = [
      'sanitation',
      'wall_material_condition',
      'landlord_middle_name',
      'landlord_email',
      'landlord_mobile_2',
      'occupancy_middle_name',
      'occupancy_mobile_2',
      'compound_name',
      'assessment_window_type_id',
    ];

    for (final String field in optionalStringFields) {
      if (merged[field] != null && merged[field].toString().trim().isEmpty) {
        merged[field] = null;
      }
    }

    return merged;
  }

  Future<void> submit() async {
    if (!_validateCurrent()) {
      ToastService.showError('Please fill all required fields', title: 'Validation Error');
      return;
    }

    // Log step 5 (Assessment) payload before submission
    _printAssessmentPayload();

    isSubmitting.value = true;
    try {
      // Merge and prepare all payload data from all steps
      final Map<String, dynamic> finalPayload = _prepareSubmissionPayload();

      // Log the merged payload from all steps
      _printMergedPayload(finalPayload);

      final Map<String, dynamic> response = await PropertyService().savePropertyMultipart(
        fields: finalPayload,
        registryItems: registry,
        assessmentImagePaths: assessmentPhotos,
      );

      // Log the complete API response
      _printApiResponse(response);

      // Check response for success
      if (response['success'] == true) {
        final String message = response['message']?.toString() ?? 
            'Property saved successfully';
        ToastService.showSuccess(message);

        // Reset local state so next create starts fresh
        _resetFormState();

        // Go back to listing and signal success so it can auto-refresh
        Get.back(result: true);
      } else {
        final String errorMsg = response['message']?.toString() ?? 
            'Failed to save property';
        ToastService.showError(errorMsg, title: 'Failed');
      }
    } catch (e) {
      Get.log('Property submission error: $e');
      ToastService.showError(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  void _resetFormState() {
    step.value = 0;
    payload.clear();
    registry.clear();
    assessmentPhotos.clear();
    // re-initialize defaults
    payload['randomdata'] = DateTime.now().millisecondsSinceEpoch.toString();
    payload['is_organization'] = '0';
    payload['group_name'] = 'A';
    payload['ownerTitle'] = '1';
  }

  void _printMergedPayload(Map<String, dynamic> mergedPayload) {
    Get.log('Merged payload from all steps: ${jsonEncode(mergedPayload)}');
    // Also print for dev consoles that do not capture Get.log
    // ignore: avoid_print
    print('\n=== Merged Payload (All Steps) ===');
    for (final MapEntry<String, dynamic> entry in mergedPayload.entries) {
      // ignore: avoid_print
      if (entry.value is List) {
        // ignore: avoid_print
        print('"${entry.key}": ${entry.value}');
      } else {
        // ignore: avoid_print
        print('"${entry.key}": "${entry.value}"');
      }
    }
    // ignore: avoid_print
    print('==================================\n');
  }

  void _printApiResponse(Map<String, dynamic> response) {
    Get.log('API Response: ${jsonEncode(response)}');
    // Also print for dev consoles that do not capture Get.log
    // ignore: avoid_print
    print('\n=== API POST Response ===');
    // ignore: avoid_print
    print('Status: ${response['success'] == true ? 'Success' : 'Failed'}');
    // ignore: avoid_print
    print('Message: ${response['message'] ?? 'N/A'}');
    if (response['data'] != null) {
      // ignore: avoid_print
      print('Data: ${jsonEncode(response['data'])}');
    }
    // ignore: avoid_print
    print('Full Response:');
    for (final MapEntry<String, dynamic> entry in response.entries) {
      // ignore: avoid_print
      if (entry.value is Map) {
        // ignore: avoid_print
        print('"${entry.key}": ${jsonEncode(entry.value)}');
      } else if (entry.value is List) {
        // ignore: avoid_print
        print('"${entry.key}": ${entry.value}');
      } else {
        // ignore: avoid_print
        print('"${entry.key}": "${entry.value}"');
      }
    }
    // ignore: avoid_print
    print('==========================\n');
  }

  void _printLandlordPayload() {
    final List<String> keys = <String>[
      'is_organization',
      'organization_addresss',
      'organization_name',
      'organization_type',
      'landlord_ownerTitle_id',
      'landlord_first_name',
      'landlord_middle_name',
      'landlord_surname',
      'landlord_email',
      'landlord_id_number',
      'landlord_id_type',
      'landlord_sex',
      'landlord_street_number',
      'landlord_street_name',
      'landlord_ward',
      'landlord_constituency',
      'landlord_section',
      'landlord_chiefdom',
      'landlord_district',
      'landlord_province',
      'landlord_postcode',
      'landlord_mobile_1',
      'landlord_mobile_2',
    ];
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final String k in keys) {
      final dynamic value = payload[k];
      if (value != null) {
        out[k] = value.toString();
      }
    }
    Get.log('Landlord payload: ${jsonEncode(out)}');
    // Also print for dev consoles that do not capture Get.log
    // ignore: avoid_print
    print('\n=== Step 1 (Landlord) Payload ===');
    for (final MapEntry<String, dynamic> entry in out.entries) {
      // ignore: avoid_print
      print('"${entry.key}": "${entry.value}"');
    }
    // ignore: avoid_print
    print('==================================\n');
  }

  void _printPropertyPayload() {
    final List<String> keys = <String>[
      'categoryType',
      'property_street_number',
      'property_street_numbernew',
      'property_street_name',
      'property_ward',
      'property_constituency',
      'property_section',
      'property_chiefdom',
      'property_district',
      'property_province',
      'property_postcode',
      'is_draft_delivered',
      'delivered_name',
      'delivered_number',
      'property_inaccessable',
    ];
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final String k in keys) {
      final dynamic value = payload[k];
      if (value != null) {
        if (value is List) {
          out[k] = value;
        } else {
          out[k] = value.toString();
        }
      }
    }
    
    // Handle delivered_image_path separately (it's a file path)
    final String? deliveredImagePath =
        payload['delivered_image_path'] as String?;
    if (deliveredImagePath != null && deliveredImagePath.isNotEmpty) {
      out['delivered_image'] = '(binary file: ${deliveredImagePath.split('/').last})';
    }
    
    Get.log('Property payload: ${jsonEncode(out)}');
    // Also print for dev consoles that do not capture Get.log
    // ignore: avoid_print
    print('\n=== Step 2 (Property) Payload ===');
    for (final MapEntry<String, dynamic> entry in out.entries) {
      // ignore: avoid_print
      if (entry.value is List) {
        // ignore: avoid_print
        print('"${entry.key}": ${entry.value}');
      } else {
        // ignore: avoid_print
        print('"${entry.key}": "${entry.value}"');
      }
    }
    // ignore: avoid_print
    print('==================================\n');
  }

  void _printOccupancyPayload() {
    final List<String> keys = <String>[
      'occupancy_type',
      'occupancy_tenant_first_name',
      'occupancy_middle_name',
      'occupancy_surname',
      'occupancy_mobile_1',
      'occupancy_mobile_2',
      'tenant_ownerTitle_id',
    ];
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final String k in keys) {
      final dynamic value = payload[k];
      if (value != null) {
        if (value is List) {
          out[k] = value;
        } else {
          out[k] = value.toString();
        }
      }
    }
    
    Get.log('Occupancy payload: ${jsonEncode(out)}');
    // Also print for dev consoles that do not capture Get.log
    // ignore: avoid_print
    print('\n=== Step 3 (Occupancy) Payload ===');
    for (final MapEntry<String, dynamic> entry in out.entries) {
      // ignore: avoid_print
      if (entry.value is List) {
        // ignore: avoid_print
        print('"${entry.key}": ${entry.value}');
      } else {
        // ignore: avoid_print
        print('"${entry.key}": "${entry.value}"');
      }
    }
    // ignore: avoid_print
    print('==================================\n');
  }

  void _printGeoRegistryPayload() {
    final Map<String, dynamic> out = <String, dynamic>{};
    
    // Print registry points (1-8)
    for (int i = 1; i <= 8; i++) {
      final String key = 'registry_point$i';
      final dynamic value = payload[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        out[key] = value.toString();
      }
    }
    
    // Print digital address and dor_lat_long
    if (payload['registry_digital_address'] != null &&
        payload['registry_digital_address'].toString().trim().isNotEmpty) {
      out['registry_digital_address'] =
          payload['registry_digital_address'].toString();
    }
    if (payload['dor_lat_long'] != null &&
        payload['dor_lat_long'].toString().trim().isNotEmpty) {
      out['dor_lat_long'] = payload['dor_lat_long'].toString();
    }
    
    // Print registry meters
    final List<int> indices = registry.keys
        .map((k) => int.tryParse(k) ?? -1)
        .where((i) => i >= 0)
        .toList()
      ..sort();
    
    for (final int idx in indices) {
      final Map<String, String>? meter = registry['$idx'];
      if (meter != null) {
        final String? meterNumber = meter['meter_number'];
        final String? meterImage = meter['meter_image'];
        if (meterNumber != null && meterNumber.trim().isNotEmpty) {
          out['registry[$idx][meter_number]'] = meterNumber;
        }
        if (meterImage != null && meterImage.isNotEmpty) {
          out['registry[$idx][meter_image]'] = '(file upload)';
        }
      }
    }
    
    Get.log('Geo Registry payload: ${jsonEncode(out)}');
    // Also print for dev consoles that do not capture Get.log
    // ignore: avoid_print
    print('\n=== Step 4 (Geo Registry) Payload ===');
    for (final MapEntry<String, dynamic> entry in out.entries) {
      // ignore: avoid_print
      print('"${entry.key}": "${entry.value}"');
    }
    // ignore: avoid_print
    print('==================================\n');
  }

  void _printAssessmentPayload() {
    final List<String> keys = <String>[
      'assessment_categories_id',
      'property_types',
      'assessment_wall_materials_id',
      'assessment_roofs_materials_id',
      'assessment_window_type_id',
      'assessment_length',
      'assessment_breadth',
      'assessment_value_added_id',
      'assessment_use_id',
      'assessment_zone_id',
      'swimming_pool',
      'gated_community',
      'total_shops',
      'total_mast',
      'total_compound_house',
      'compound_name',
      'randomdata',
      'group_name',
      'ownerTitle',
      'newAdjustmentIds',
    ];
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final String k in keys) {
      final dynamic value = payload[k];
      if (value != null) {
        if (value is List) {
          out[k] = value;
        } else {
          out[k] = value.toString();
        }
      }
    }
    
    // Handle assessment images separately (they're file paths)
    if (assessmentPhotos.isNotEmpty) {
      for (int i = 0; i < assessmentPhotos.length; i++) {
        final String path = assessmentPhotos[i];
        if (path.isNotEmpty) {
          out['assessment_images_${i + 1}'] =
              '(binary file: ${path.split('/').last})';
        }
      }
    }
    
    Get.log('Assessment payload: ${jsonEncode(out)}');
    // Also print for dev consoles that do not capture Get.log
    // ignore: avoid_print
    print('\n=== Step 5 (Assessment) Payload ===');
    for (final MapEntry<String, dynamic> entry in out.entries) {
      // ignore: avoid_print
      if (entry.value is List) {
        // ignore: avoid_print
        print('"${entry.key}": ${entry.value}');
      } else {
        // ignore: avoid_print
        print('"${entry.key}": "${entry.value}"');
      }
    }
    // ignore: avoid_print
    print('==================================\n');
  }
}
