import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/property_models.dart';
import '../services/property_service.dart';

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

  Future<void> submit() async {
    if (!_validateCurrent()) return;
    isSubmitting.value = true;
    try {
      await PropertyService().savePropertyMultipart(
        fields: payload,
        registryItems: registry,
        assessmentImagePaths: assessmentPhotos,
      );
      Get.snackbar('Success', 'Property saved successfully');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      isSubmitting.value = false;
    }
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
      out[k] = payload[k];
    }
    Get.log('Landlord payload: ' + out.toString());
    // Also print for dev consoles that do not capture Get.log
    // ignore: avoid_print
    print(out);
  }
}
