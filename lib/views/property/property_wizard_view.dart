import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../controllers/property_controller.dart';
import '../../utils/validation_utils.dart';
import '../../utils/input_formatters.dart';

class PropertyWizardView extends GetView<PropertyController> {
  const PropertyWizardView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PropertyController>()) {
      Get.put(PropertyController());
    }
    final PropertyController controller = Get.find<PropertyController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Property')),
      body: Obx(() {
        final int step = controller.step.value;
        final List<String> photosSnapshot = controller.assessmentPhotos
            .toList();
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderStepper(
                currentIndex: step,
                labels: const [
                  'Landlord',
                  'Property',
                  'Occupancy',
                  'Geo Registry',
                  'Assessment',
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _StepForms(
                    step: step,
                    controller: controller,
                    photosSnapshot: photosSnapshot,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final int step = controller.step.value;
        final bool isLastStep = step >= 4;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            child: Row(
              children: [
                if (step > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.prevStep,
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (step > 0) const SizedBox(width: 12),
                Expanded(
                  child: Obx(() {
                    final bool isSubmitting = controller.isSubmitting.value;
                    final bool inaccessible =
                        controller.payload['inaccessible_property'] == '1';

                    if (inaccessible) {
                      return ElevatedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : controller.submitInaccessibleProperty,
                        icon: isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.save, size: 18),
                        label: const Text('SAVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }

                    return ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : (isLastStep
                                ? controller.submit
                                : controller.nextStep),
                      icon: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              isLastStep
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_forward_ios,
                              size: 18,
                            ),
                      label: Text(isLastStep ? 'Submit' : 'Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _HeaderStepper extends StatelessWidget {
  const _HeaderStepper({required this.currentIndex, required this.labels});
  final int currentIndex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row for labels that should be above (odd indices: 1, 3)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Expanded(
                  child: Container(),
                ); // Placeholder for connectors
              }
              final int step = i ~/ 2;
              final bool isAbove = step.isOdd; // Odd indices (1, 3) go above
              if (!isAbove) {
                return const SizedBox(
                  width: 32,
                ); // Placeholder for below labels
              }
              final bool isActive = step == currentIndex;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Text(
                      labels[step],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.green : Colors.black87,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          // Middle row with circles and connectors
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                final int left = (i - 1) ~/ 2;
                final bool active = left < currentIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? Colors.green : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                );
              }
              final int step = i ~/ 2;
              final bool isDone = step <= currentIndex;
              return Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Colors.green : Colors.white,
                  border: Border.all(
                    color: isDone ? Colors.green : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Text(
                  '${step + 1}',
                  style: TextStyle(
                    color: isDone ? Colors.white : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            }),
          ),
          // Bottom row for labels that should be below (even indices: 0, 2, 4)
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Expanded(
                  child: Container(),
                ); // Placeholder for connectors
              }
              final int step = i ~/ 2;
              final bool isBelow =
                  step.isEven; // Even indices (0, 2, 4) go below
              if (!isBelow) {
                return const SizedBox(
                  width: 32,
                ); // Placeholder for above labels
              }
              final bool isActive = step == currentIndex;
              return Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[step],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.green : Colors.black87,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepForms extends StatelessWidget {
  const _StepForms({
    required this.step,
    required this.controller,
    required this.photosSnapshot,
  });
  final int step;
  final PropertyController controller;
  final List<String> photosSnapshot;

  InputDecoration get _decoration => const InputDecoration(
    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.green),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.green, width: 2),
    ),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  String? _val(String key) => controller.payload[key] as String?;

  Future<void> _fetchLocationForPoint(int pointNumber) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final String latLng = '${pos.latitude},${pos.longitude}';
      controller.setField('registry_point$pointNumber', latLng);
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return Form(
        key: controller.step1Key,
        child: Obx(() {
          final bool org = controller.isOrganization.value == '1';
          final bool inaccessible = _val('inaccessible_property') == '1';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkboxes
              // Inaccessible Property Checkbox
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: inaccessible,
                      onChanged: (v) {
                        controller.setField(
                          'inaccessible_property',
                          v == true ? '1' : '0',
                        );
                        if (v != true) {
                          // Clear fields if unchecked
                          controller.setField('property_inaccessable', []);
                          controller.setField(
                            'property_inaccessible_image',
                            null,
                          );
                          controller.setField('inaccessible_lat', null);
                          controller.setField('inaccessible_lng', null);
                        } else {
                          // Auto-fetch location when checked
                          controller.getCurrentLocation();
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Inaccessible Property',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),

              // Conditional fields for Inaccessible Property
              if (inaccessible) ...[
                const SizedBox(height: 12),
                _SingleSelectVariablesDropdown(
                  controller: controller,
                  dataKey: 'property_inaccessibles',
                  payloadKey: 'property_inaccessable',
                  label: 'Property Inaccessible*',
                ),
                const SizedBox(height: 12),

                // Location Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('lat_${_val('inaccessible_lat')}'),
                        initialValue: _val('inaccessible_lat'),
                        readOnly: true,
                        decoration: _decoration.copyWith(
                          labelText: 'Latitude',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('lng_${_val('inaccessible_lng')}'),
                        initialValue: _val('inaccessible_lng'),
                        readOnly: true,
                        decoration: _decoration.copyWith(
                          labelText: 'Longitude',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => controller.getCurrentLocation(),
                      icon: const Icon(Icons.location_on, color: Colors.blue),
                      tooltip: 'Get Current Location',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Image Upload
                _DashedPicker(
                  label: 'Property Image',
                  onPick: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? photo = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 75,
                    );
                    if (photo != null) {
                      controller.setField(
                        'property_inaccessible_image',
                        photo.path,
                      );
                    }
                  },
                ),

                // Show selected image preview if exists
                if (_val('property_inaccessible_image') != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_val('property_inaccessible_image')!),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () => controller.setField(
                            'property_inaccessible_image',
                            null,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: org,
                      onChanged: (v) =>
                          controller.setIsOrganization(v == true ? '1' : '0'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Organization Property',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!org) ...[
                // Personal Information
                Row(
                  children: [
                    Expanded(
                      child: _TitleSelect(
                        controller: controller,
                        payloadKey: 'landlord_ownerTitle_id',
                        label: 'Title*',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _val('landlord_first_name'),
                        decoration: _decoration.copyWith(
                          labelText: 'First Name*',
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (v) => ValidationUtils.validateRequired(
                          v,
                          fieldName: 'First Name',
                        ),
                        onChanged: (v) =>
                            controller.setField('landlord_first_name', v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _val('landlord_middle_name'),
                        decoration: _decoration.copyWith(labelText: 'Middle'),
                        onChanged: (v) =>
                            controller.setField('landlord_middle_name', v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _val('landlord_surname'),
                        decoration: _decoration.copyWith(labelText: 'Surname*'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (v) => ValidationUtils.validateRequired(
                          v,
                          fieldName: 'Surname',
                        ),
                        onChanged: (v) =>
                            controller.setField('landlord_surname', v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownSearch<String>(
                  items: (filter, infiniteScrollProps) => const [
                    'Male',
                    'Female',
                  ],
                  decoratorProps: DropDownDecoratorProps(
                    decoration: _decoration.copyWith(labelText: 'Sex*'),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Search gender...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  selectedItem: _val('landlord_sex') == 'm'
                      ? 'Male'
                      : (_val('landlord_sex') == 'f' ? 'Female' : null),
                  validator: (v) =>
                      ValidationUtils.validateRequired(v, fieldName: 'Sex'),
                  onChanged: (v) => controller.setField(
                    'landlord_sex',
                    v == 'Male' ? 'm' : 'f',
                  ),
                ),
              ] else ...[
                // Organization Information
                TextFormField(
                  initialValue: _val('organization_name'),
                  decoration: _decoration.copyWith(
                    labelText: 'Organization Name',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => ValidationUtils.validateRequired(
                    v,
                    fieldName: 'Organization Name',
                  ),
                  onChanged: (v) => controller.setField('organization_name', v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _val('organization_addresss'),
                  decoration: _decoration.copyWith(
                    labelText: 'Organization Address',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => ValidationUtils.validateRequired(
                    v,
                    fieldName: 'Organization Address',
                  ),
                  onChanged: (v) =>
                      controller.setField('organization_addresss', v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _val('organization_type'),
                  decoration: _decoration.copyWith(
                    labelText: 'Organization Type',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => ValidationUtils.validateRequired(
                    v,
                    fieldName: 'Organization Type',
                  ),
                  onChanged: (v) => controller.setField('organization_type', v),
                ),
              ],

              const SizedBox(height: 16),
              // Address Part 1
              TextFormField(
                initialValue: _val('landlord_street_number'),
                decoration: _decoration.copyWith(labelText: 'Street Number'),
                onChanged: (v) =>
                    controller.setField('landlord_street_number', v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _val('landlord_street_name'),
                decoration: _decoration.copyWith(labelText: 'Street Name'),
                onChanged: (v) =>
                    controller.setField('landlord_street_name', v),
              ),

              const SizedBox(height: 16),
              // Administrative
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownSearch<String>(
                        items: (filter, infiniteScrollProps) =>
                            controller.wards,
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _decoration.copyWith(
                            labelText: 'Ward Number*',
                          ),
                        ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: const TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        selectedItem: _val('landlord_ward'),
                        validator: (v) => ValidationUtils.validateRequired(
                          v,
                          fieldName: 'Ward Number',
                        ),
                        onChanged: (v) {
                          if (v != null) {
                            controller.setField('landlord_ward', v);
                            controller.onWardSelected(v);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => DropdownSearch<String>(
                        items: (filter, infiniteScrollProps) =>
                            (controller.wardFilteredData['sections'] as List?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [],
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _decoration.copyWith(
                            labelText: 'Section*',
                          ),
                        ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: const TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        selectedItem: _val('landlord_section'),
                        validator: (v) => ValidationUtils.validateRequired(
                          v,
                          fieldName: 'Section',
                        ),
                        onChanged: (v) =>
                            controller.setField('landlord_section', v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownSearch<String>(
                        items: (filter, infiniteScrollProps) =>
                            (controller.wardFilteredData['constituencies']
                                    as List?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [],
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _decoration.copyWith(
                            labelText: 'Constituency*',
                          ),
                        ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: const TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        selectedItem: _val('landlord_constituency'),
                        validator: (v) => ValidationUtils.validateRequired(
                          v,
                          fieldName: 'Constituency',
                        ),
                        onChanged: (v) =>
                            controller.setField('landlord_constituency', v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => DropdownSearch<String>(
                        items: (filter, infiniteScrollProps) =>
                            (controller.wardFilteredData['chiefdoms'] as List?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [],
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _decoration.copyWith(
                            labelText: 'Chiefdom*',
                          ),
                        ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: const TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        selectedItem: _val('landlord_chiefdom'),
                        validator: (v) => ValidationUtils.validateRequired(
                          v,
                          fieldName: 'Chiefdom',
                        ),
                        onChanged: (v) =>
                            controller.setField('landlord_chiefdom', v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownSearch<String>(
                        items: (filter, infiniteScrollProps) =>
                            (controller.wardFilteredData['districts'] as List?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [],
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _decoration.copyWith(
                            labelText: 'District*',
                          ),
                        ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: const TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        selectedItem: _val('landlord_district'),
                        validator: (v) => ValidationUtils.validateRequired(
                          v,
                          fieldName: 'District',
                        ),
                        onChanged: (v) =>
                            controller.setField('landlord_district', v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => DropdownSearch<String>(
                        items: (filter, infiniteScrollProps) =>
                            (controller.wardFilteredData['provinces'] as List?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [],
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _decoration.copyWith(
                            labelText: 'Province',
                          ),
                        ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: const TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        selectedItem: _val('landlord_province'),
                        onChanged: (v) =>
                            controller.setField('landlord_province', v),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Address Part 2
              /*
              TextFormField(
                initialValue: _val('landlord_postcode'),
                decoration: _decoration.copyWith(labelText: 'Postcode'),
                onChanged: (v) => controller.setField('landlord_postcode', v),
              ),
              */
              const SizedBox(height: 16),
              // Contact
              TextFormField(
                initialValue: _val('landlord_email'),
                decoration: _decoration.copyWith(labelText: 'Email Id'),
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: ValidationUtils.validateEmail,
                onChanged: (v) => controller.setField('landlord_email', v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _val('landlord_mobile_1'),
                decoration: _decoration.copyWith(labelText: 'Mobile #1*'),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneNumberFormatter()],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    ValidationUtils.validatePhone(v, isRequired: true),
                onChanged: (v) => controller.setField('landlord_mobile_1', v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _val('landlord_mobile_2'),
                decoration: _decoration.copyWith(labelText: 'Mobile #2'),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneNumberFormatter()],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    ValidationUtils.validatePhone(v, isRequired: false),
                onChanged: (v) => controller.setField('landlord_mobile_2', v),
              ),
            ],
          );
        }),
      );
    }
    if (step == 1) {
      return Form(
        key: controller.step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Same as Landlord Address Checkbox
            Obx(
              () => Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: controller.sameAsLandlord.value,
                      onChanged: (v) =>
                          controller.toggleSameAsLandlord(v == true),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Same as Landlord Address',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Address Fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'prop_st_num_${_val('property_street_number')}',
                    ),
                    initialValue: _val('property_street_number'),
                    decoration: _decoration.copyWith(
                      labelText: 'Old Street Number',
                    ),
                    onChanged: (v) =>
                        controller.setField('property_street_number', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'prop_st_num_new_${_val('property_street_numbernew')}',
                    ),
                    initialValue: _val('property_street_numbernew'),
                    decoration: _decoration.copyWith(
                      labelText: 'New Street Number',
                    ),
                    onChanged: (v) =>
                        controller.setField('property_street_numbernew', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('prop_st_name_${_val('property_street_name')}'),
              initialValue: _val('property_street_name'),
              decoration: _decoration.copyWith(labelText: 'Street Name*'),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  ValidationUtils.validateRequired(v, fieldName: 'Street Name'),
              onChanged: (v) => controller.setField('property_street_name', v),
            ),
            const SizedBox(height: 12),

            // Administrative Fields
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownSearch<String>(
                      items: (filter, infiniteScrollProps) => controller.wards,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _decoration.copyWith(
                          labelText: 'Ward Number*',
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      selectedItem: _val('property_ward'),
                      validator: (v) => ValidationUtils.validateRequired(
                        v,
                        fieldName: 'Ward Number',
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          controller.setField('property_ward', v);
                          controller.onPropertyWardSelected(v);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => DropdownSearch<String>(
                      items: (filter, infiniteScrollProps) =>
                          (controller.propertyWardFilteredData['sections']
                                  as List?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [],
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _decoration.copyWith(labelText: 'Section*'),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      selectedItem: _val('property_section'),
                      validator: (v) => ValidationUtils.validateRequired(
                        v,
                        fieldName: 'Section',
                      ),
                      onChanged: (v) =>
                          controller.setField('property_section', v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownSearch<String>(
                      items: (filter, infiniteScrollProps) =>
                          (controller.propertyWardFilteredData['constituencies']
                                  as List?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [],
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _decoration.copyWith(
                          labelText: 'Constituency*',
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      selectedItem: _val('property_constituency'),
                      validator: (v) => ValidationUtils.validateRequired(
                        v,
                        fieldName: 'Constituency',
                      ),
                      onChanged: (v) =>
                          controller.setField('property_constituency', v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => DropdownSearch<String>(
                      items: (filter, infiniteScrollProps) =>
                          (controller.propertyWardFilteredData['chiefdoms']
                                  as List?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [],
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _decoration.copyWith(
                          labelText: 'Chiefdom*',
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      selectedItem: _val('property_chiefdom'),
                      validator: (v) => ValidationUtils.validateRequired(
                        v,
                        fieldName: 'Chiefdom',
                      ),
                      onChanged: (v) =>
                          controller.setField('property_chiefdom', v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownSearch<String>(
                      items: (filter, infiniteScrollProps) =>
                          (controller.propertyWardFilteredData['districts']
                                  as List?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [],
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _decoration.copyWith(
                          labelText: 'District*',
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      selectedItem: _val('property_district'),
                      validator: (v) => ValidationUtils.validateRequired(
                        v,
                        fieldName: 'District',
                      ),
                      onChanged: (v) =>
                          controller.setField('property_district', v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => DropdownSearch<String>(
                      items: (filter, infiniteScrollProps) =>
                          (controller.propertyWardFilteredData['provinces']
                                  as List?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [],
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _decoration.copyWith(labelText: 'Province'),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      selectedItem: _val('property_province'),
                      onChanged: (v) =>
                          controller.setField('property_province', v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /*
            TextFormField(
              key: ValueKey('prop_postcode_${_val('property_postcode')}'),
              initialValue: _val('property_postcode'),
              decoration: _decoration.copyWith(labelText: 'Postcode'),
              onChanged: (v) => controller.setField('property_postcode', v),
            ),
            */

            // Category Type
            DropdownSearch<String>(
              items: (filter, infiniteScrollProps) => const [
                'Residential',
                'Commercial',
              ],
              decoratorProps: DropDownDecoratorProps(
                decoration: _decoration.copyWith(labelText: 'Category Type*'),
              ),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search category...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              selectedItem: _val('categoryType') == 'R'
                  ? 'Residential'
                  : (_val('categoryType') == 'C' ? 'Commercial' : null),
              validator: (v) => (v == null || v.toString().trim().isEmpty)
                  ? 'Required'
                  : null,
              onChanged: (v) => controller.setField(
                'categoryType',
                v == 'Residential' ? 'R' : 'C',
              ),
            ),

            // Commented out unused fields as per request
            /*
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Delivery',
              children: [
                Obx(() {
                  final String? p =
                      controller.payload['delivered_image_path'] as String?;
                  return _ImageInputBox(
                    label: 'Delivery Proof Image',
                    path: p,
                    onPick: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? file = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 75,
                      );
                      if (file != null) {
                        controller.setField('delivered_image_path', file.path);
                      }
                    },
                    onRemove: () =>
                        controller.setField('delivered_image_path', ''),
                  );
                }),
                const SizedBox(height: 12),
                DropdownSearch<String>(
                  items: (filter, infiniteScrollProps) => const ['No', 'Yes'],
                  decoratorProps: DropDownDecoratorProps(
                    decoration: _decoration.copyWith(
                      labelText: 'Is Draft Delivered?',
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  selectedItem: _val('is_draft_delivered') == '0'
                      ? 'No'
                      : (_val('is_draft_delivered') == '1' ? 'Yes' : null),
                  onChanged: (v) => controller.setField(
                    'is_draft_delivered',
                    v == 'Yes' ? '1' : '0',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _val('delivered_name'),
                  decoration: _decoration.copyWith(labelText: 'Recipient Name'),
                  onChanged: (v) => controller.setField('delivered_name', v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _val('delivered_number'),
                  decoration: _decoration.copyWith(
                    labelText: 'Recipient Number',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneNumberFormatter()],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) =>
                      ValidationUtils.validatePhone(v, isRequired: false),
                  onChanged: (v) => controller.setField('delivered_number', v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Address',
              children: [
                TextFormField(
                  initialValue: _val('property_street_number'),
                  decoration: _decoration.copyWith(labelText: 'Street Number'),
                  onChanged: (v) =>
                      controller.setField('property_street_number', v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _val('property_street_numbernew'),
                  decoration: _decoration.copyWith(
                    labelText: 'Street Number (New)',
                  ),
                  onChanged: (v) =>
                      controller.setField('property_street_numbernew', v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _val('property_street_name'),
                  decoration: _decoration.copyWith(labelText: 'Street Name'),
                  onChanged: (v) =>
                      controller.setField('property_street_name', v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _val('property_postcode'),
                  decoration: _decoration.copyWith(labelText: 'Postcode'),
                  onChanged: (v) => controller.setField('property_postcode', v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Administrative',
              children: [
                Obx(
                  () => DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) => controller.wards,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _decoration.copyWith(labelText: 'Ward'),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    selectedItem: _val('property_ward'),
                    onChanged: (v) {
                      if (v != null) {
                        controller.setField('property_ward', v);
                        controller.onWardSelected(v);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) =>
                        (controller.wardFilteredData['constituencies'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _decoration.copyWith(
                        labelText: 'Constituency',
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    selectedItem: _val('property_constituency'),
                    onChanged: (v) =>
                        controller.setField('property_constituency', v),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) =>
                        (controller.wardFilteredData['sections'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _decoration.copyWith(labelText: 'Section'),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    selectedItem: _val('property_section'),
                    onChanged: (v) =>
                        controller.setField('property_section', v),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) =>
                        (controller.wardFilteredData['chiefdoms'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _decoration.copyWith(labelText: 'Chiefdom'),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    selectedItem: _val('property_chiefdom'),
                    onChanged: (v) =>
                        controller.setField('property_chiefdom', v),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) =>
                        (controller.wardFilteredData['districts'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _decoration.copyWith(labelText: 'District'),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    selectedItem: _val('property_district'),
                    onChanged: (v) =>
                        controller.setField('property_district', v),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) =>
                        (controller.wardFilteredData['provinces'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _decoration.copyWith(labelText: 'Province'),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    selectedItem: _val('property_province'),
                    onChanged: (v) =>
                        controller.setField('property_province', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Other',
              children: [
                _SingleSelectVariablesDropdownToArray(
                  controller: controller,
                  dataKey: 'property_inaccessibles',
                  payloadKey: 'property_inaccessable',
                  label: 'Property Inaccessible',
                ),
              ],
            ),
            */
          ],
        ),
      );
    }
    if (step == 2) {
      return Form(
        key: controller.step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Occupancy Type Dropdown
            DropdownSearch<String>(
              items: (filter, infiniteScrollProps) => const [
                'Owned Tenancy',
                'Unoccupied House',
                'Rented House',
              ],
              decoratorProps: DropDownDecoratorProps(
                decoration: _decoration.copyWith(labelText: 'Occupancy Type*'),
              ),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              selectedItem: () {
                final dynamic existing = controller.payload['occupancy_type'];
                if (existing is List && existing.isNotEmpty) {
                  return existing.first.toString();
                }
                if (existing is String) return existing;
                return null;
              }(),
              validator: (v) => ValidationUtils.validateRequired(
                v,
                fieldName: 'Occupancy Type',
              ),
              onChanged: (v) => controller.setField(
                'occupancy_type',
                v == null ? <String>[] : <String>[v],
              ),
            ),
            const SizedBox(height: 12),

            // Title and First Name Row
            Row(
              children: [
                Expanded(
                  child: _TitleSelect(
                    controller: controller,
                    payloadKey: 'tenant_ownerTitle_id',
                    label: 'Title*',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _val('occupancy_tenant_first_name'),
                    decoration: _decoration.copyWith(labelText: 'First Name*'),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => ValidationUtils.validateRequired(
                      v,
                      fieldName: 'First Name',
                    ),
                    onChanged: (v) =>
                        controller.setField('occupancy_tenant_first_name', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle Name and Surname Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _val('occupancy_middle_name'),
                    decoration: _decoration.copyWith(labelText: 'Middle Name'),
                    onChanged: (v) =>
                        controller.setField('occupancy_middle_name', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _val('occupancy_surname'),
                    decoration: _decoration.copyWith(labelText: 'Surname*'),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => ValidationUtils.validateRequired(
                      v,
                      fieldName: 'Surname',
                    ),
                    onChanged: (v) =>
                        controller.setField('occupancy_surname', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mobile #1
            TextFormField(
              initialValue: _val('occupancy_mobile_1'),
              decoration: _decoration.copyWith(
                labelText: 'Mobile #1*',
                prefixText: '+232 ',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneNumberFormatter()],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  ValidationUtils.validatePhone(v, isRequired: true),
              onChanged: (v) => controller.setField('occupancy_mobile_1', v),
            ),
            const SizedBox(height: 12),

            // Mobile #2
            TextFormField(
              initialValue: _val('occupancy_mobile_2'),
              decoration: _decoration.copyWith(
                labelText: 'Mobile #2',
                prefixText: '+232 ',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneNumberFormatter()],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  ValidationUtils.validatePhone(v, isRequired: false),
              onChanged: (v) => controller.setField('occupancy_mobile_2', v),
            ),
          ],
        ),
      );
    }
    if (step == 3) {
      return Form(
        key: controller.step4Key,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LocationSection(
              key: const ValueKey('location_section'),
              controller: controller,
            ),
            const SizedBox(height: 16),

            // Registry Points Grid
            Obx(() {
              // Read each point directly from the RxMap so Obx can track dependencies
              final List<String?> points = List<String?>.generate(
                8,
                (int i) =>
                    controller.payload['registry_point${i + 1}'] as String?,
              );
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 4,
                ),
                itemBuilder: (context, index) {
                  final int p = index + 1;
                  final String? pointValue = points[index];
                  return TextFormField(
                    key: ValueKey('point_${p}_$pointValue'),
                    initialValue: pointValue,
                    decoration: _decoration.copyWith(
                      labelText: 'Point $p',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location, size: 20),
                        tooltip: 'Use current location',
                        onPressed: () => _fetchLocationForPoint(p),
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    inputFormatters: [CoordinateFormatter()],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: ValidationUtils.validateLatLong,
                    onChanged: (v) =>
                        controller.setField('registry_point$p', v),
                  );
                },
              );
            }),
            const SizedBox(height: 16),

            // Add Meter Button
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.addEmptyRegistryItem();
                },
                icon: const Icon(Icons.add),
                label: const Text('+ Add Meter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Meters List
            Obx(() {
              final List<int> indices =
                  controller.registry.keys
                      .map((k) => int.tryParse(k) ?? 0)
                      .toList()
                    ..sort();
              return Column(
                children: [
                  for (final int idx in indices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Meter ${idx + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      controller.removeRegistryItem(idx),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Obx(() {
                              final String? meterImage =
                                  controller.registry['$idx']?['meter_image'];
                              final bool hasImage =
                                  meterImage != null && meterImage.isNotEmpty;
                              return TextFormField(
                                initialValue: controller
                                    .registry['$idx']?['meter_number'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  labelText: 'Meter Number',
                                ),
                                keyboardType: TextInputType.text,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (v) {
                                  // Required if meter image is present
                                  if (hasImage &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Required when image is present';
                                  }
                                  return null;
                                },
                                onChanged: (v) => controller.addRegistryItem(
                                  idx,
                                  meterNumber: v,
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            _ImageInputBox(
                              label: 'Meter Image',
                              path: controller.registry['$idx']?['meter_image'],
                              onPick: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? photo = await picker.pickImage(
                                  source: ImageSource.camera,
                                  imageQuality: 75,
                                );
                                if (photo != null) {
                                  controller.addRegistryItem(
                                    idx,
                                    imagePath: photo.path,
                                  );
                                }
                              },
                              onRemove: () => controller.addRegistryItem(
                                idx,
                                imagePath: '',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      );
    }
    return Form(
      key: controller.step5Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Categories
          _SingleSelectVariablesDropdown(
            controller: controller,
            dataKey: 'property_categories',
            payloadKey: 'assessment_categories_id',
            label: 'Property Categories*',
          ),
          const SizedBox(height: 12),

          // Property Type
          _SingleSelectVariablesDropdown(
            controller: controller,
            dataKey: 'property_types',
            payloadKey: 'property_types',
            label: 'Property Type*',
          ),
          const SizedBox(height: 12),

          // Wall Material
          _SingleSelectVariablesDropdown(
            controller: controller,
            dataKey: 'property_wall_materials',
            payloadKey: 'assessment_wall_materials_id',
            label: 'Wall Material*',
          ),
          const SizedBox(height: 12),

          // Roof Type
          _SingleSelectVariablesDropdown(
            controller: controller,
            dataKey: 'property_roofs_materials',
            payloadKey: 'assessment_roofs_materials_id',
            label: 'Roof Type*',
          ),
          const SizedBox(height: 16),

          // Property Dimension Calculator
          Text(
            'Property Dimension Calculator',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const ValueKey('length_field'),
                  initialValue: _val('assessment_length'),
                  decoration: _decoration.copyWith(labelText: 'Length'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter(decimalPlaces: 2)],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) {
                    return ValidationUtils.validateDecimal(
                      v,
                      decimalPlaces: 2,
                      isRequired: false,
                    );
                  },
                  onChanged: (v) {
                    controller.setField('assessment_length', v);
                    if (controller.step5Key.currentState != null) {
                      controller.step5Key.currentState!.validate();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const ValueKey('breadth_field'),
                  initialValue: _val('assessment_breadth'),
                  decoration: _decoration.copyWith(labelText: 'Breadth'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalInputFormatter(decimalPlaces: 2)],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) {
                    return ValidationUtils.validateDecimal(
                      v,
                      decimalPlaces: 2,
                      isRequired: false,
                    );
                  },
                  onChanged: (v) {
                    controller.setField('assessment_breadth', v);
                    if (controller.step5Key.currentState != null) {
                      controller.step5Key.currentState!.validate();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final length =
                double.tryParse(_val('assessment_length') ?? '') ?? 0.0;
            final breadth =
                double.tryParse(_val('assessment_breadth') ?? '') ?? 0.0;
            final dimension = length * breadth;
            return Text(
              'Dimension in Sq. Meters: ${dimension.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
              ),
            );
          }),
          const SizedBox(height: 16),

          // Council Adjustments (Multi-select Dropdown)
          _CouncilAdjustmentsMultiSelectDropdown(controller: controller),
          const SizedBox(height: 12),

          // Value Added Assessment Parameters (Multi-select Dropdown)
          _MultiSelectVariablesDropdown(
            controller: controller,
            dataKey: 'property_value_added',
            payloadKey: 'assessment_value_added_id',
            label: 'Value Added Assessment Parameters*',
          ),
          const SizedBox(height: 12),

          // Swimming Pool
          _SingleSelectVariablesDropdown(
            controller: controller,
            dataKey: 'swimmings',
            payloadKey: 'swimming_pool',
            label: 'Swimming Pool',
          ),
          const SizedBox(height: 12),

          // Property Use
          _SingleSelectVariablesDropdown(
            controller: controller,
            dataKey: 'property_uses',
            payloadKey: 'assessment_use_id',
            label: 'Property Use*',
          ),
          const SizedBox(height: 12),

          // Zones
          _SingleSelectVariablesDropdown(
            controller: controller,
            dataKey: 'property_zones',
            payloadKey: 'assessment_zone_id',
            label: 'Zones*',
          ),
          const SizedBox(height: 16),

          // Gated Community Checkbox
          Obx(() {
            final isGated = _val('gated_community') == '1';
            return CheckboxListTile(
              value: isGated,
              onChanged: (v) =>
                  controller.setField('gated_community', v == true ? '1' : '0'),
              title: const Text('Gated Community'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.green,
            );
          }),

          /* Commented out fields as per design
          const SizedBox(height: 16),
          _SingleSelectVariablesDropdown(
            controller: controller,
            dataKey: 'property_window_types',
            payloadKey: 'assessment_window_type_id',
            label: 'Window Type',
          ),
          
          // Additional Information section
          Obx(() {
            final dynamic selectedValueAdded =
                controller.payload['assessment_value_added_id'];
            final Set<String> valueAddedIds = <String>{};
            if (selectedValueAdded is List) {
              valueAddedIds.addAll(
                selectedValueAdded.map((dynamic e) => e.toString()),
              );
            } else if (selectedValueAdded != null) {
              valueAddedIds.add(selectedValueAdded.toString());
            }
            final bool showMasts = valueAddedIds.contains('8');
            final bool showShops = valueAddedIds.contains('9');
            final bool showCompoundFields =
                (controller.payload['gated_community']?.toString() ?? '0') ==
                '1';

            if (!showMasts && !showShops && !showCompoundFields) {
              return const SizedBox.shrink();
            }

            final List<Widget> conditionalFields = <Widget>[];
            void addField(Widget field) {
              if (conditionalFields.isNotEmpty) {
                conditionalFields.add(const SizedBox(height: 12));
              }
              conditionalFields.add(field);
            }

            if (showMasts) {
              addField(
                TextFormField(
                  initialValue: _val('total_mast'),
                  decoration: _decoration.copyWith(labelText: 'No of Masts'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [IntegerInputFormatter()],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => ValidationUtils.validateInteger(
                    v,
                    min: 0,
                    isRequired: false,
                  ),
                  onChanged: (v) => controller.setField('total_mast', v),
                ),
              );
            }

            if (showShops) {
              addField(
                TextFormField(
                  initialValue: _val('total_shops'),
                  decoration: _decoration.copyWith(labelText: 'No of Shops'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [IntegerInputFormatter()],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => ValidationUtils.validateInteger(
                    v,
                    min: 0,
                    isRequired: false,
                  ),
                  onChanged: (v) => controller.setField('total_shops', v),
                ),
              );
            }

            if (showCompoundFields) {
              addField(
                TextFormField(
                  initialValue: _val('total_compound_house'),
                  decoration: _decoration.copyWith(
                    labelText: 'No of Compound House',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [IntegerInputFormatter()],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => ValidationUtils.validateInteger(
                    v,
                    min: 0,
                    isRequired: false,
                  ),
                  onChanged: (v) =>
                      controller.setField('total_compound_house', v),
                ),
              );
              addField(
                TextFormField(
                  initialValue: _val('compound_name'),
                  decoration: _decoration.copyWith(labelText: 'Compound Name'),
                  onChanged: (v) => controller.setField('compound_name', v),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                ...conditionalFields,
              ],
            );
          }),
          */
          const SizedBox(height: 16),
          // Property Images
          Obx(() {
            final photosSnapshot = List<String>.from(
              controller.assessmentPhotos.toList(),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DashedPicker(
                        label: 'Image 1',
                        onPick: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? photo = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 75,
                          );
                          if (photo != null)
                            controller.addAssessmentPhoto(photo.path);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DashedPicker(
                        label: 'Image 2',
                        onPick: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? photo = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 75,
                          );
                          if (photo != null)
                            controller.addAssessmentPhoto(photo.path);
                        },
                      ),
                    ),
                  ],
                ),
                if (photosSnapshot.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < photosSnapshot.length; i++)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(
                              File(photosSnapshot[i]),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  controller.removeAssessmentPhoto(i),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DashedPicker extends StatelessWidget {
  const _DashedPicker({required this.label, required this.onPick});
  final String label;
  final VoidCallback onPick;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 42, color: Colors.black54),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _ImageInputBox extends StatelessWidget {
  const _ImageInputBox({
    required this.label,
    required this.path,
    required this.onPick,
    required this.onRemove,
  });
  final String label;
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        path != null && path!.isNotEmpty && File(path!).existsSync();
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(File(path!), fit: BoxFit.cover)
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 42,
                      color: Colors.black45,
                    ),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            if (hasImage)
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(children: [...children]),
        ),
      ],
    );
  }
}

class _LocationSection extends StatefulWidget {
  const _LocationSection({super.key, required this.controller});
  final PropertyController controller;

  @override
  State<_LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<_LocationSection> {
  bool _isLoading = false;
  late TextEditingController _digitalAddressController;
  late FocusNode _digitalAddressFocusNode;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current value from payload
    final String? initialValue =
        widget.controller.payload['registry_digital_address'] as String?;
    _digitalAddressController = TextEditingController(text: initialValue ?? '');
    _digitalAddressFocusNode = FocusNode();
    _digitalAddressFocusNode.addListener(() {
      // Update payload when field loses focus
      if (!_digitalAddressFocusNode.hasFocus) {
        widget.controller.setField(
          'registry_digital_address',
          _digitalAddressController.text,
        );
      }
    });
    _fetchLocation();
  }

  @override
  void dispose() {
    _digitalAddressController.dispose();
    _digitalAddressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() => _isLoading = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final String latLng = '${pos.latitude},${pos.longitude}';
      widget.controller.setField('dor_lat_long', latLng);
      widget.controller.setField('registry_point1', latLng);
    } catch (e) {
      // Handle error silently or show a message
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateLatLong(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final String trimmed = v.trim();
    // Expected format: "lat,long" (e.g., "8.237550256892234,-13.085966873914003")
    final List<String> parts = trimmed.split(',');
    if (parts.length != 2) {
      return 'Format: lat,long';
    }
    final double? lat = double.tryParse(parts[0].trim());
    final double? lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) {
      return 'Invalid coordinates';
    }
    if (lat < -90 || lat > 90) return 'Latitude must be -90 to 90';
    if (lng < -180 || lng > 180) return 'Longitude must be -180 to 180';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Location',
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(() {
                final String? latLong =
                    widget.controller.payload['dor_lat_long'] as String?;
                return TextFormField(
                  key: ValueKey('latlong_$latLong'),
                  initialValue: latLong,
                  decoration: _decoration.copyWith(
                    labelText: 'Dor Lat Long',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location),
                      tooltip: 'Use current location',
                      onPressed: _isLoading ? null : _fetchLocation,
                    ),
                  ),
                  readOnly: true,
                  validator: _validateLatLong,
                );
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const ValueKey('digital_address_field'),
                controller: _digitalAddressController,
                focusNode: _digitalAddressFocusNode,
                decoration: _decoration.copyWith(labelText: 'Digital Address'),
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration get _decoration => const InputDecoration(
    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.green),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.green, width: 2),
    ),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

class _MeterRow extends StatefulWidget {
  const _MeterRow({required this.controller, required this.meterIndex});
  final PropertyController controller;
  final int meterIndex;
  @override
  State<_MeterRow> createState() => _MeterRowState();
}

class _MeterRowState extends State<_MeterRow> {
  final TextEditingController _numController = TextEditingController();

  @override
  void dispose() {
    _numController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _numController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              labelText:
                  'Meter ${''}'
                  'Number',
            ),
            onChanged: (v) => widget.controller.addRegistryItem(
              widget.meterIndex,
              meterNumber: v,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _DashedPicker(
          label: 'Photo',
          onPick: () async {
            final ImagePicker picker = ImagePicker();
            final XFile? photo = await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 70,
            );
            if (photo != null)
              widget.controller.addRegistryItem(
                widget.meterIndex,
                imagePath: photo.path,
              );
          },
        ),
      ],
    );
  }
}

class _InaccessibleMultiSelect extends StatefulWidget {
  const _InaccessibleMultiSelect({required this.controller});
  final PropertyController controller;
  @override
  State<_InaccessibleMultiSelect> createState() =>
      _InaccessibleMultiSelectState();
}

class _InaccessibleMultiSelectState extends State<_InaccessibleMultiSelect> {
  final Set<int> _selected = <int>{};

  List<Map<String, dynamic>> get _options {
    final dynamic vars = widget.controller.cachedVariables;
    if (vars == null) return const <Map<String, dynamic>>[];
    if (vars is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> container = Map<String, dynamic>.from(vars);
    final dynamic dataRaw = container['data'];
    if (dataRaw is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> data = Map<String, dynamic>.from(dataRaw);
    final dynamic raw = data['property_inaccessibles'];
    if (raw is List) {
      final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];
      for (final dynamic e in raw) {
        if (e is Map) {
          normalized.add(Map<String, dynamic>.from(e));
        }
      }
      return normalized;
    }
    return const <Map<String, dynamic>>[];
  }

  void _commit() {
    widget.controller.setField(
      'property_inaccessable',
      _selected.map((e) => e.toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opts = _options;
    if (opts.isEmpty) {
      return const Text('No options available');
    }
    return Wrap(
      spacing: 8,
      children: [
        for (final Map<String, dynamic> o in opts)
          FilterChip(
            selected: _selected.contains(o['id'] as int),
            label: Text(o['label']?.toString() ?? 'Option'),
            onSelected: (bool val) {
              setState(() {
                if (val) {
                  _selected.add(o['id'] as int);
                } else {
                  _selected.remove(o['id'] as int);
                }
                _commit();
              });
            },
          ),
      ],
    );
  }
}

class _OccupancyTypeChips extends StatefulWidget {
  const _OccupancyTypeChips({required this.controller});
  final PropertyController controller;
  @override
  State<_OccupancyTypeChips> createState() => _OccupancyTypeChipsState();
}

class _OccupancyTypeChipsState extends State<_OccupancyTypeChips> {
  final Set<String> _selected = <String>{};
  static const List<String> _types = <String>[
    'Owned Tenancy',
    'Unoccupied House',
    'Rented House',
  ];

  void _commit() {
    widget.controller.setField('occupancy_type', _selected.toList());
  }

  @override
  void initState() {
    super.initState();
    final dynamic existing = widget.controller.payload['occupancy_type'];
    if (existing is List) {
      for (final dynamic v in existing) {
        if (v is String) _selected.add(v);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final String t in _types)
          FilterChip(
            selected: _selected.contains(t),
            label: Text(t),
            onSelected: (bool val) {
              setState(() {
                if (val) {
                  _selected.add(t);
                } else {
                  _selected.remove(t);
                }
                _commit();
              });
            },
          ),
      ],
    );
  }
}

class _MultiSelectVariablesChips extends StatefulWidget {
  const _MultiSelectVariablesChips({
    required this.controller,
    required this.dataKey,
    required this.payloadKey,
    required this.label,
  });
  final PropertyController controller;
  final String dataKey;
  final String payloadKey;
  final String label;
  @override
  State<_MultiSelectVariablesChips> createState() =>
      _MultiSelectVariablesChipsState();
}

class _MultiSelectVariablesChipsState
    extends State<_MultiSelectVariablesChips> {
  final Set<int> _selected = <int>{};
  List<Map<String, dynamic>> get _options {
    final dynamic vars = widget.controller.cachedVariables;
    if (vars == null) return const <Map<String, dynamic>>[];
    if (vars is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> container = Map<String, dynamic>.from(vars);
    final dynamic dataRaw = container['data'];
    if (dataRaw is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> data = Map<String, dynamic>.from(dataRaw);
    final dynamic raw = data[widget.dataKey];
    if (raw is List) {
      final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];
      for (final dynamic e in raw) {
        if (e is Map) {
          normalized.add(Map<String, dynamic>.from(e));
        }
      }
      return normalized;
    }
    return const <Map<String, dynamic>>[];
  }

  void _commit() {
    widget.controller.setField(
      widget.payloadKey,
      _selected.map((e) => e.toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opts = _options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final Map<String, dynamic> o in opts)
              FilterChip(
                selected: _selected.contains(o['id'] as int),
                label: Text(o['label']?.toString() ?? 'Item'),
                onSelected: (bool val) {
                  setState(() {
                    if (val) {
                      _selected.add(o['id'] as int);
                    } else {
                      _selected.remove(o['id'] as int);
                    }
                    _commit();
                  });
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _SingleSelectVariablesDropdown extends StatelessWidget {
  const _SingleSelectVariablesDropdown({
    required this.controller,
    required this.dataKey,
    required this.payloadKey,
    required this.label,
  });
  final PropertyController controller;
  final String dataKey;
  final String payloadKey;
  final String label;

  List<Map<String, dynamic>> get _options {
    final dynamic vars = controller.cachedVariables;
    if (vars == null) return const <Map<String, dynamic>>[];
    if (vars is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> container = Map<String, dynamic>.from(vars);
    final dynamic dataRaw = container['data'];
    if (dataRaw is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> data = Map<String, dynamic>.from(dataRaw);
    final dynamic raw = data[dataKey];
    if (raw is List) {
      final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];
      for (final dynamic e in raw) {
        if (e is Map) {
          normalized.add(Map<String, dynamic>.from(e));
        }
      }
      return normalized;
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opts = _options;
    final dynamic rawValue = controller.payload[payloadKey];
    final String? selectedValue = rawValue is String ? rawValue : null;

    // Find the label for the selected ID
    String? selectedLabel;
    if (selectedValue != null && selectedValue.isNotEmpty) {
      final selectedOption = opts.firstWhereOrNull(
        (o) => (o['id'] ?? o['value']).toString() == selectedValue,
      );
      if (selectedOption != null) {
        selectedLabel = selectedOption['label']?.toString();
      }
    }

    return DropdownSearch<String>(
      items: (filter, infiniteScrollProps) {
        // Return labels for display
        return opts.map((o) => o['label']?.toString() ?? 'Item').toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ).copyWith(labelText: label),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search...',
            border: OutlineInputBorder(),
          ),
        ),
        itemBuilder: (context, item, isDisabled, isSelected) {
          return ListTile(
            title: Text(
              item,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
          );
        },
      ),
      selectedItem: selectedLabel,
      compareFn: (item1, item2) => item1 == item2,
      onChanged: (selectedLabel) {
        if (selectedLabel != null) {
          // Find the ID for the selected label
          final selectedOption = opts.firstWhereOrNull(
            (o) => o['label']?.toString() == selectedLabel,
          );
          if (selectedOption != null) {
            final id = (selectedOption['id'] ?? selectedOption['value'])
                .toString();
            controller.setField(payloadKey, id);
          }
        }
      },
    );
  }
}

class _MultiSelectVariablesDropdown extends StatefulWidget {
  const _MultiSelectVariablesDropdown({
    required this.controller,
    required this.dataKey,
    required this.payloadKey,
    required this.label,
  });
  final PropertyController controller;
  final String dataKey;
  final String payloadKey;
  final String label;

  @override
  State<_MultiSelectVariablesDropdown> createState() =>
      _MultiSelectVariablesDropdownState();
}

class _MultiSelectVariablesDropdownState
    extends State<_MultiSelectVariablesDropdown> {
  List<String> _selectedItems = [];

  List<Map<String, dynamic>> get _options {
    final dynamic vars = widget.controller.cachedVariables;
    if (vars == null) return const <Map<String, dynamic>>[];
    if (vars is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> container = Map<String, dynamic>.from(vars);
    final dynamic dataRaw = container['data'];
    if (dataRaw is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> data = Map<String, dynamic>.from(dataRaw);
    final dynamic raw = data[widget.dataKey];
    if (raw is List) {
      final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];
      for (final dynamic e in raw) {
        if (e is Map) {
          normalized.add(Map<String, dynamic>.from(e));
        }
      }
      return normalized;
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  void initState() {
    super.initState();
    // Initialize selected items from payload
    final dynamic existing = widget.controller.payload[widget.payloadKey];
    if (existing is List) {
      _selectedItems = existing.map((e) => e.toString()).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opts = _options;

    // Convert selected IDs to labels for display
    final List<String> selectedLabels = [];
    for (final id in _selectedItems) {
      final option = opts.firstWhereOrNull(
        (o) => (o['id'] ?? o['value']).toString() == id,
      );
      if (option != null) {
        selectedLabels.add(option['label']?.toString() ?? 'Item');
      }
    }

    return DropdownSearch<String>.multiSelection(
      items: (filter, infiniteScrollProps) {
        return opts.map((o) => o['label']?.toString() ?? 'Item').toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ).copyWith(labelText: widget.label),
      ),
      popupProps: PopupPropsMultiSelection.menu(
        showSearchBox: true,
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search...',
            border: OutlineInputBorder(),
          ),
        ),
        itemBuilder: (context, item, isDisabled, isSelected) {
          return ListTile(
            title: Text(
              item,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            selected: isSelected,
          );
        },
        showSelectedItems: true,
      ),
      selectedItems: selectedLabels,
      compareFn: (item1, item2) => item1 == item2,
      onChanged: (selectedLabels) {
        // Convert labels back to IDs
        final List<String> selectedIds = [];
        for (final label in selectedLabels) {
          final option = opts.firstWhereOrNull(
            (o) => o['label']?.toString() == label,
          );
          if (option != null) {
            selectedIds.add((option['id'] ?? option['value']).toString());
          }
        }
        setState(() {
          _selectedItems = selectedIds;
        });
        widget.controller.setField(widget.payloadKey, selectedIds);
      },
    );
  }
}

class _CouncilAdjustmentsMultiSelectDropdown extends StatefulWidget {
  const _CouncilAdjustmentsMultiSelectDropdown({required this.controller});
  final PropertyController controller;

  @override
  State<_CouncilAdjustmentsMultiSelectDropdown> createState() =>
      _CouncilAdjustmentsMultiSelectDropdownState();
}

class _CouncilAdjustmentsMultiSelectDropdownState
    extends State<_CouncilAdjustmentsMultiSelectDropdown> {
  List<int> _selectedIds = [];

  List<Map<String, dynamic>> get _options {
    final dynamic vars = widget.controller.cachedVariables;
    if (vars == null) return const <Map<String, dynamic>>[];
    if (vars is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> container = Map<String, dynamic>.from(vars);
    final dynamic dataRaw = container['data'];
    if (dataRaw is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> data = Map<String, dynamic>.from(dataRaw);
    final dynamic raw = data['council_adjustments'];
    if (raw is List) {
      final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];
      for (final dynamic e in raw) {
        if (e is Map) {
          normalized.add(Map<String, dynamic>.from(e));
        }
      }
      return normalized;
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  void initState() {
    super.initState();
    // Try to parse existing selection from payload
    final dynamic existing = widget.controller.payload['newAdjustmentIds'];
    if (existing is String && existing.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(existing);
        _selectedIds = parsed
            .map((e) => e is Map ? (e['id'] as int?) : null)
            .whereType<int>()
            .toList();
      } catch (e) {
        // Ignore parse errors
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opts = _options;

    // Convert selected IDs to labels for display
    final List<String> selectedLabels = [];
    for (final id in _selectedIds) {
      final option = opts.firstWhereOrNull((o) => o['id'] == id);
      if (option != null) {
        selectedLabels.add('${option['name']} - ${option['type']}');
      }
    }

    return DropdownSearch<String>.multiSelection(
      items: (filter, infiniteScrollProps) {
        return opts.map((o) => '${o['name']} - ${o['type']}').toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          labelText: 'Council Adjustments',
        ),
      ),
      popupProps: PopupPropsMultiSelection.menu(
        showSearchBox: true,
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search...',
            border: OutlineInputBorder(),
          ),
        ),
        itemBuilder: (context, item, isDisabled, isSelected) {
          return ListTile(
            title: Text(
              item,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            selected: isSelected,
          );
        },
        showSelectedItems: true,
      ),
      selectedItems: selectedLabels,
      compareFn: (item1, item2) => item1 == item2,
      onChanged: (selectedLabels) {
        // Convert labels back to full objects
        final List<Map<String, dynamic>> selectedObjects = [];
        final List<int> selectedIds = [];
        for (final label in selectedLabels) {
          final option = opts.firstWhereOrNull(
            (o) => '${o['name']} - ${o['type']}' == label,
          );
          if (option != null) {
            selectedObjects.add(option);
            selectedIds.add(option['id'] as int);
          }
        }
        setState(() {
          _selectedIds = selectedIds;
        });
        widget.controller.setField(
          'newAdjustmentIds',
          jsonEncode(selectedObjects),
        );
      },
    );
  }
}

class _TitleSelect extends StatelessWidget {
  const _TitleSelect({
    required this.controller,
    required this.payloadKey,
    required this.label,
  });
  final PropertyController controller;
  final String payloadKey;
  final String label;

  static const List<Map<String, dynamic>> _defaultTitles = [
    {'id': '1', 'label': 'Mr.'},
    {'id': '2', 'label': 'Ms.'},
  ];

  List<Map<String, dynamic>> get _options {
    final dynamic vars = controller.cachedVariables;
    if (vars == null) return _defaultTitles;
    if (vars is! Map) return _defaultTitles;
    final Map<String, dynamic> container = Map<String, dynamic>.from(vars);
    final dynamic dataRaw = container['data'];
    if (dataRaw is! Map) return _defaultTitles;
    final Map<String, dynamic> data = Map<String, dynamic>.from(dataRaw);

    // First, try "all_titles" from the API (as per API specification)
    final dynamic allTitlesRaw = data['all_titles'];
    if (allTitlesRaw is List && allTitlesRaw.isNotEmpty) {
      final List<Map<String, dynamic>> titles = <Map<String, dynamic>>[];
      for (final dynamic e in allTitlesRaw) {
        if (e is Map) {
          final Map<String, dynamic> titleMap = Map<String, dynamic>.from(e);
          // Filter by is_active if present (only show active titles)
          final dynamic isActive = titleMap['is_active'];
          if (isActive == null || isActive == 1) {
            titles.add(titleMap);
          }
        }
      }
      if (titles.isNotEmpty) return titles;
    }

    // Fallback: Try other possible field names for titles
    final List<String> possibleKeys = [
      'titles',
      'owner_titles',
      'titles_list',
      'ownerTitle',
      'owner_title',
    ];

    for (final String key in possibleKeys) {
      final dynamic raw = data[key];
      if (raw is List && raw.isNotEmpty) {
        final List<Map<String, dynamic>> titles = <Map<String, dynamic>>[];
        for (final dynamic e in raw) {
          if (e is Map) {
            titles.add(Map<String, dynamic>.from(e));
          }
        }
        if (titles.isNotEmpty) return titles;
      }
      // Also check if it's a Map format (like admin fields)
      if (raw is Map) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
        final List<Map<String, dynamic>> titles = m.entries
            .map<Map<String, dynamic>>(
              (e) => <String, dynamic>{
                'id': e.key.toString(),
                'label': e.value.toString(),
              },
            )
            .toList();
        if (titles.isNotEmpty) return titles;
      }
    }

    // Fallback to default titles if not found in API
    return _defaultTitles;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int _ = controller.variablesTick.value; // dependency only
      final List<Map<String, dynamic>> opts = _options;
      final String? selectedValue =
          controller.payload[payloadKey] as String? ??
          controller.payload['ownerTitle'] as String?;

      return DropdownSearch<String>(
        items: (filter, infiniteScrollProps) {
          if (opts.isEmpty) return [];
          return opts.map((o) => o['label']?.toString() ?? 'Item').toList();
        },
        decoratorProps: DropDownDecoratorProps(
          decoration:
              const InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ).copyWith(
                labelText: label,
                hintText: opts.isEmpty ? 'Loading...' : null,
              ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: const TextFieldProps(
            decoration: InputDecoration(
              hintText: 'Search...',
              border: OutlineInputBorder(),
            ),
          ),
          itemBuilder: (context, item, isDisabled, isSelected) {
            return ListTile(
              title: Text(
                item,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
            );
          },
        ),
        enabled: opts.isNotEmpty,
        selectedItem: () {
          if (opts.isEmpty || selectedValue == null) return null;
          final option = opts.firstWhere(
            (o) => (o['id'] ?? o['value']).toString() == selectedValue,
            orElse: () => <String, dynamic>{},
          );
          return option['label']?.toString();
        }(),
        compareFn: (item1, item2) => item1 == item2,
        onChanged: opts.isEmpty
            ? null
            : (v) {
                if (v == null) return;
                final option = opts.firstWhere(
                  (o) => o['label']?.toString() == v,
                  orElse: () => <String, dynamic>{},
                );
                final id = (option['id'] ?? option['value']).toString();
                controller.setField(payloadKey, id);
                if (payloadKey == 'landlord_ownerTitle_id') {
                  controller.setField('ownerTitle', id);
                }
              },
      );
    });
  }
}

class _CouncilAdjustmentsDropdown extends StatefulWidget {
  const _CouncilAdjustmentsDropdown({required this.controller});
  final PropertyController controller;
  @override
  State<_CouncilAdjustmentsDropdown> createState() =>
      _CouncilAdjustmentsDropdownState();
}

class _CouncilAdjustmentsDropdownState
    extends State<_CouncilAdjustmentsDropdown> {
  String? _selectedValue;

  List<Map<String, dynamic>> get _options {
    final dynamic vars = widget.controller.cachedVariables;
    if (vars == null) return const <Map<String, dynamic>>[];
    if (vars is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> container = Map<String, dynamic>.from(vars);
    final dynamic dataRaw = container['data'];
    if (dataRaw is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> data = Map<String, dynamic>.from(dataRaw);
    final dynamic raw = data['council_adjustments'];
    if (raw is List) {
      final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];
      for (final dynamic e in raw) {
        if (e is Map) {
          normalized.add(Map<String, dynamic>.from(e));
        }
      }
      return normalized;
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opts = _options;

    // Find the label for the selected ID
    String? selectedLabel;
    if (_selectedValue != null && _selectedValue!.isNotEmpty) {
      final selectedOption = opts.firstWhereOrNull(
        (o) => o['id'].toString() == _selectedValue,
      );
      if (selectedOption != null) {
        selectedLabel = '${selectedOption['name']} - ${selectedOption['type']}';
      }
    }

    return DropdownSearch<String>(
      items: (filter, infiniteScrollProps) {
        // Return labels for display (name - type)
        return opts.map((o) => '${o['name']} - ${o['type']}').toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          labelText: 'Council Adjustments',
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search...',
            border: OutlineInputBorder(),
          ),
        ),
        itemBuilder: (context, item, isDisabled, isSelected) {
          return ListTile(
            title: Text(
              item,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
          );
        },
      ),
      selectedItem: selectedLabel,
      compareFn: (item1, item2) => item1 == item2,
      onChanged: (selectedLabel) {
        if (selectedLabel != null) {
          // Find the ID for the selected label
          final selectedOption = opts.firstWhereOrNull(
            (o) => '${o['name']} - ${o['type']}' == selectedLabel,
          );
          if (selectedOption != null) {
            final id = selectedOption['id'].toString();
            setState(() => _selectedValue = id);
            widget.controller.setField(
              'newAdjustmentIds',
              jsonEncode([selectedOption]),
            );
          }
        }
      },
    );
  }
}

class _CouncilAdjustmentsChips extends StatefulWidget {
  const _CouncilAdjustmentsChips({required this.controller});
  final PropertyController controller;
  @override
  State<_CouncilAdjustmentsChips> createState() =>
      _CouncilAdjustmentsChipsState();
}

class _CouncilAdjustmentsChipsState extends State<_CouncilAdjustmentsChips> {
  final Set<int> _selected = <int>{};

  List<Map<String, dynamic>> get _options {
    final dynamic vars = widget.controller.cachedVariables;
    if (vars == null) return const <Map<String, dynamic>>[];
    if (vars is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> container = Map<String, dynamic>.from(vars);
    final dynamic dataRaw = container['data'];
    if (dataRaw is! Map) return const <Map<String, dynamic>>[];
    final Map<String, dynamic> data = Map<String, dynamic>.from(dataRaw);
    final dynamic raw = data['council_adjustments'];
    if (raw is List) {
      final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];
      for (final dynamic e in raw) {
        if (e is Map) {
          normalized.add(Map<String, dynamic>.from(e));
        }
      }
      return normalized;
    }
    return const <Map<String, dynamic>>[];
  }

  void _commit() {
    final List<Map<String, dynamic>> full = _options
        .where((e) => _selected.contains(e['id'] as int))
        .toList();
    widget.controller.setField('newAdjustmentIds', jsonEncode(full));
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opts = _options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Select Council',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final Map<String, dynamic> o in opts)
              FilterChip(
                selected: _selected.contains(o['id'] as int),
                label: Text('${o['name']} - ${o['type']}'),
                onSelected: (bool val) {
                  setState(() {
                    if (val) {
                      _selected.add(o['id'] as int);
                    } else {
                      _selected.remove(o['id'] as int);
                    }
                    _commit();
                  });
                },
              ),
          ],
        ),
      ],
    );
  }
}
