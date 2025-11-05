import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/property_controller.dart';

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
      floatingActionButton: Obx(() {
        final int step = controller.step.value;
        return FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: step < 4 ? controller.nextStep : controller.submit,
          child: Icon(step < 4 ? Icons.arrow_forward : Icons.check),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                final int left = (i - 1) ~/ 2;
                final bool active = left < currentIndex;
                return Expanded(
                  child: Container(
                    height: 4,
                    color: active ? Colors.green : Colors.grey.shade300,
                  ),
                );
              }
              final int step = i ~/ 2;
              final bool isDone = step <= currentIndex;
              return Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Colors.green : Colors.white,
                  border: Border.all(
                    color: isDone ? Colors.green : Colors.grey,
                  ),
                ),
                child: Text(
                  '${step + 1}',
                  style: TextStyle(
                    color: isDone ? Colors.white : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final String label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: labels.indexOf(label) == currentIndex
                          ? Colors.green
                          : Colors.black87,
                      fontWeight: labels.indexOf(label) == currentIndex
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
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
  );

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return Form(
        key: controller.step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: _decoration.copyWith(labelText: 'Is Organization'),
              items: const [
                DropdownMenuItem(value: '0', child: Text('No')),
                DropdownMenuItem(value: '1', child: Text('Yes')),
              ],
              onChanged: (v) => controller.setField('is_organization', v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _decoration.copyWith(labelText: 'First Name*'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              onChanged: (v) => controller.setField('landlord_first_name', v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _decoration.copyWith(labelText: 'Middle Name'),
              onChanged: (v) => controller.setField('landlord_middle_name', v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _decoration.copyWith(labelText: 'Surname*'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              onChanged: (v) => controller.setField('landlord_surname', v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _decoration.copyWith(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => controller.setField('landlord_email', v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(labelText: 'Id Number'),
                    onChanged: (v) =>
                        controller.setField('landlord_id_number', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(labelText: 'Id Type'),
                    onChanged: (v) =>
                        controller.setField('landlord_id_type', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: _decoration.copyWith(labelText: 'Title'),
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('Mr.')),
                      DropdownMenuItem(value: '2', child: Text('Ms.')),
                    ],
                    onChanged: (v) =>
                        controller.setField('landlord_ownerTitle_id', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: _decoration.copyWith(labelText: 'Sex'),
                    items: const [
                      DropdownMenuItem(value: 'm', child: Text('Male')),
                      DropdownMenuItem(value: 'f', child: Text('Female')),
                    ],
                    onChanged: (v) => controller.setField('landlord_sex', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _decoration.copyWith(labelText: 'Mobile 1'),
              onChanged: (v) => controller.setField('landlord_mobile_1', v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _decoration.copyWith(labelText: 'Mobile 2'),
              onChanged: (v) => controller.setField('landlord_mobile_2', v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: _decoration.copyWith(labelText: 'Category Type*'),
              items: const [
                DropdownMenuItem(value: 'R', child: Text('Residential')),
                DropdownMenuItem(value: 'C', child: Text('Commercial')),
              ],
              validator: (v) => v == null ? 'Required' : null,
              onChanged: (v) => controller.setField('categoryType', v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(labelText: 'Street No'),
                    onChanged: (v) =>
                        controller.setField('landlord_street_number', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(labelText: 'Street Name'),
                    onChanged: (v) =>
                        controller.setField('landlord_street_name', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'wards',
                    payloadKey: 'landlord_ward',
                    label: 'Ward',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'constituencies',
                    payloadKey: 'landlord_constituency',
                    label: 'Constituency',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'sections',
                    payloadKey: 'landlord_section',
                    label: 'Section',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'chiefdoms',
                    payloadKey: 'landlord_chiefdom',
                    label: 'Chiefdom',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'districts',
                    payloadKey: 'landlord_district',
                    label: 'District',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'provinces',
                    payloadKey: 'landlord_province',
                    label: 'Province',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(labelText: 'Postcode'),
                    onChanged: (v) =>
                        controller.setField('landlord_postcode', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Organization Name',
                    ),
                    onChanged: (v) =>
                        controller.setField('organization_name', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Organization Type',
                    ),
                    onChanged: (v) =>
                        controller.setField('organization_type', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Organization Address',
                    ),
                    onChanged: (v) =>
                        controller.setField('organization_addresss', v),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    if (step == 1) {
      return Form(
        key: controller.step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Street Number',
                    ),
                    onChanged: (v) =>
                        controller.setField('property_street_number', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Street Number (New)',
                    ),
                    onChanged: (v) =>
                        controller.setField('property_street_numbernew', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _decoration.copyWith(labelText: 'Street Name'),
              onChanged: (v) => controller.setField('property_street_name', v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'wards',
                    payloadKey: 'property_ward',
                    label: 'Ward',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'constituencies',
                    payloadKey: 'property_constituency',
                    label: 'Constituency',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'sections',
                    payloadKey: 'property_section',
                    label: 'Section',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'chiefdoms',
                    payloadKey: 'property_chiefdom',
                    label: 'Chiefdom',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'districts',
                    payloadKey: 'property_district',
                    label: 'District',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminSelect(
                    controller: controller,
                    dataKey: 'provinces',
                    payloadKey: 'property_province',
                    label: 'Province',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(labelText: 'Postcode'),
                    onChanged: (v) =>
                        controller.setField('property_postcode', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: _decoration.copyWith(
                      labelText: 'Is Draft Delivered?',
                    ),
                    items: const [
                      DropdownMenuItem(value: '0', child: Text('No')),
                      DropdownMenuItem(value: '1', child: Text('Yes')),
                    ],
                    onChanged: (v) =>
                        controller.setField('is_draft_delivered', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Recipient Name',
                    ),
                    onChanged: (v) => controller.setField('delivered_name', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Recipient Number',
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (v) =>
                        controller.setField('delivered_number', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DashedPicker(
              label: 'Delivery Proof Image',
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
            ),
            const SizedBox(height: 12),
            Text(
              'Property Inaccessible',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            _InaccessibleMultiSelect(controller: controller),
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
            Text(
              'Occupancy Type',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            _OccupancyTypeChips(controller: controller),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: _decoration.copyWith(labelText: 'Title'),
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('Mr.')),
                      DropdownMenuItem(value: '2', child: Text('Ms.')),
                    ],
                    onChanged: (v) =>
                        controller.setField('tenant_ownerTitle_id', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Tenant First Name',
                    ),
                    onChanged: (v) =>
                        controller.setField('occupancy_tenant_first_name', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(labelText: 'Middle Name'),
                    onChanged: (v) =>
                        controller.setField('occupancy_middle_name', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(labelText: 'Surname'),
                    onChanged: (v) =>
                        controller.setField('occupancy_surname', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Mobile Number 1',
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (v) =>
                        controller.setField('occupancy_mobile_1', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Mobile Number 2',
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (v) =>
                        controller.setField('occupancy_mobile_2', v),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    if (step == 3) {
      return Form(
        key: controller.step4Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final bool serviceEnabled =
                          await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        await Geolocator.openLocationSettings();
                        return;
                      }
                      LocationPermission permission =
                          await Geolocator.checkPermission();
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
                      controller.setField('dor_lat_long', latLng);
                      controller.setField('registry_point1', latLng);
                    },
                    child: const Text('Update Location'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _decoration.copyWith(
                      labelText: 'Digital Address',
                    ),
                    onChanged: (v) =>
                        controller.setField('registry_digital_address', v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
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
                return TextFormField(
                  decoration: _decoration.copyWith(
                    labelText: 'Registry Point $p',
                  ),
                  onChanged: (v) => controller.setField('registry_point$p', v),
                );
              },
            ),
            const SizedBox(height: 16),
            Text('Meters', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _MeterRow(controller: controller, meterIndex: 0),
            const SizedBox(height: 8),
            _MeterRow(controller: controller, meterIndex: 1),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _DashedPicker(
                label: 'Property Image 1',
                onPick: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 75,
                  );
                  if (photo != null) controller.addAssessmentPhoto(photo.path);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashedPicker(
                label: 'Property Image 2',
                onPick: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 75,
                  );
                  if (photo != null) controller.addAssessmentPhoto(photo.path);
                },
              ),
            ),
          ],
        ),
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
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => controller.removeAssessmentPhoto(i),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        _MultiSelectVariablesChips(
          controller: controller,
          dataKey: 'property_categories',
          payloadKey: 'assessment_categories_id',
          label: 'Select Category',
        ),
        const SizedBox(height: 12),
        _MultiSelectVariablesChips(
          controller: controller,
          dataKey: 'property_types',
          payloadKey: 'property_types',
          label: 'Select Types',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SingleSelectVariablesDropdown(
                controller: controller,
                dataKey: 'property_wall_materials',
                payloadKey: 'assessment_wall_materials_id',
                label: 'Wall Material',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SingleSelectVariablesDropdown(
                controller: controller,
                dataKey: 'property_roofs_materials',
                payloadKey: 'assessment_roofs_materials_id',
                label: 'Roof Material',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SingleSelectVariablesDropdown(
          controller: controller,
          dataKey: 'property_window_types',
          payloadKey: 'assessment_window_type_id',
          label: 'Window Type',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: _decoration.copyWith(labelText: 'length'),
                keyboardType: TextInputType.number,
                onChanged: (v) => controller.setField('assessment_length', v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: _decoration.copyWith(labelText: 'breadth'),
                keyboardType: TextInputType.number,
                onChanged: (v) => controller.setField('assessment_breadth', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MultiSelectVariablesChips(
          controller: controller,
          dataKey: 'property_value_added',
          payloadKey: 'assessment_value_added_id',
          label: 'Select value added',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SingleSelectVariablesDropdown(
                controller: controller,
                dataKey: 'property_uses',
                payloadKey: 'assessment_use_id',
                label: 'Property use',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SingleSelectVariablesDropdown(
                controller: controller,
                dataKey: 'property_zones',
                payloadKey: 'assessment_zone_id',
                label: 'Property zone',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SingleSelectVariablesDropdown(
                controller: controller,
                dataKey: 'swimmings',
                payloadKey: 'swimming_pool',
                label: 'Swimming pool',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: _decoration.copyWith(labelText: 'Gated community'),
                items: const [
                  DropdownMenuItem(value: '0', child: Text('No')),
                  DropdownMenuItem(value: '1', child: Text('Yes')),
                ],
                onChanged: (v) => controller.setField('gated_community', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: _decoration.copyWith(
                  labelText: 'No of Shops (optional)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => controller.setField('total_shops', v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: _decoration.copyWith(
                  labelText: 'No of Masts (optional)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => controller.setField('total_mast', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: _decoration.copyWith(
                  labelText: 'No of Compound House',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    controller.setField('total_compound_house', v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: _decoration.copyWith(labelText: 'Compound Name'),
                onChanged: (v) => controller.setField('compound_name', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: _decoration.copyWith(labelText: 'Random Data'),
                onChanged: (v) => controller.setField('randomdata', v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: _decoration.copyWith(labelText: 'Group Name'),
                onChanged: (v) => controller.setField('group_name', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CouncilAdjustmentsChips(controller: controller),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text('Preview Payload'),
            onPressed: () {
              final Map<String, dynamic> preview = <String, dynamic>{
                ...controller.payload,
                'registry': controller.registry,
                'assessmentPhotos': controller.assessmentPhotos,
              };
              final String formatted = const JsonEncoder.withIndent(
                '  ',
              ).convert(preview);
              showDialog<void>(
                context: context,
                builder: (BuildContext ctx) => AlertDialog(
                  title: const Text('Final Payload Preview'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Text(
                        formatted,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
    if (vars is Map &&
        vars['data'] is Map &&
        (vars['data'] as Map)['property_inaccessibles'] is List) {
      return List<Map<String, dynamic>>.from(
        (vars['data'] as Map)['property_inaccessibles'] as List,
      );
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
  static const List<String> _types = <String>['Owned Tenancy', 'Rented House'];

  void _commit() {
    widget.controller.setField('occupancy_type', _selected.toList());
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
    if (vars is Map &&
        vars['data'] is Map &&
        (vars['data'] as Map)[widget.dataKey] is List) {
      return List<Map<String, dynamic>>.from(
        (vars['data'] as Map)[widget.dataKey] as List,
      );
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
    if (vars is Map &&
        vars['data'] is Map &&
        (vars['data'] as Map)[dataKey] is List) {
      return List<Map<String, dynamic>>.from(
        (vars['data'] as Map)[dataKey] as List,
      );
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opts = _options;
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
      ).copyWith(labelText: label),
      items: [
        for (final Map<String, dynamic> o in opts)
          DropdownMenuItem<String>(
            value: (o['id'] ?? o['value']).toString(),
            child: Text(o['label']?.toString() ?? 'Item'),
          ),
      ],
      onChanged: (v) => controller.setField(payloadKey, v),
    );
  }
}

class _AdminSelect extends StatelessWidget {
  const _AdminSelect({
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
    if (vars is Map &&
        vars['data'] is Map &&
        (vars['data'] as Map)[dataKey] is List) {
      return List<Map<String, dynamic>>.from(
        (vars['data'] as Map)[dataKey] as List,
      );
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opts = _options;
    if (opts.isEmpty) {
      return TextFormField(
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
        ).copyWith(labelText: label),
        onChanged: (v) => controller.setField(payloadKey, v),
      );
    }
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
      ).copyWith(labelText: label),
      items: [
        for (final Map<String, dynamic> o in opts)
          DropdownMenuItem<String>(
            value: (o['id'] ?? o['value']).toString(),
            child: Text(o['label']?.toString() ?? 'Item'),
          ),
      ],
      onChanged: (v) => controller.setField(payloadKey, v),
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
    if (vars is Map &&
        vars['data'] is Map &&
        (vars['data'] as Map)['council_adjustments'] is List) {
      return List<Map<String, dynamic>>.from(
        (vars['data'] as Map)['council_adjustments'] as List,
      );
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
          'Select Council Adjustments',
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
