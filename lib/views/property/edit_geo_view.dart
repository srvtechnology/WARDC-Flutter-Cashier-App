import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/property_service.dart';
import '../../routes/app_pages.dart';
import '../../services/toast_service.dart';

class EditGeoView extends StatefulWidget {
  const EditGeoView({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  State<EditGeoView> createState() => _EditGeoViewState();
}

class _EditGeoViewState extends State<EditGeoView> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();
  bool _isLoading = false;
  final Map<String, TextEditingController> _pointControllers = {};
  final TextEditingController _digitalAddressController = TextEditingController();
  final TextEditingController _dorLatLongController = TextEditingController();

  // Meter management
  final List<Map<String, dynamic>> _meters = [];

  Map<String, dynamic> get _geo =>
      Map<String, dynamic>.from(
          (widget.property['geo_registry'] ?? {}) as Map? ?? {});
  List<dynamic> get _registryMeters =>
      (widget.property['registry_meters'] as List?) ?? const [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Initialize registry points
    for (int i = 1; i <= 8; i++) {
      _pointControllers['point$i'] = TextEditingController(
        text: _geo['point$i']?.toString() ?? '',
      );
    }

    _digitalAddressController.text = _geo['digital_address']?.toString() ?? '';
    _dorLatLongController.text = _geo['dor_lat_long']?.toString() ?? '';

    // Initialize meters from existing data
    for (final meter in _registryMeters) {
      if (meter is Map) {
        _meters.add({
          'id': meter['id'],
          'property_id': meter['property_id'],
          'number': meter['number']?.toString() ?? '',
          'image': meter['image']?.toString(),
          'imageFile': null, // No new image selected yet
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _pointControllers.values) {
      controller.dispose();
    }
    _digitalAddressController.dispose();
    _dorLatLongController.dispose();
    super.dispose();
  }

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
      _pointControllers['point$pointNumber']?.text = latLng;
      if (pointNumber == 1) {
        _dorLatLongController.text = latLng;
      }
    } catch (e) {
      ToastService.showError('Failed to get location: $e');
    }
  }

  void _addMeter() {
    setState(() {
      _meters.add({
        'number': '',
        'imageFile': null,
      });
    });
  }

  void _removeMeter(int index) {
    setState(() {
      _meters.removeAt(index);
    });
  }

  void _updateMeterNumber(int index, String number) {
    setState(() {
      _meters[index]['number'] = number;
    });
  }

  Future<void> _pickMeterImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (file != null) {
      setState(() {
        _meters[index]['imageFile'] = file.path;
        // Clear existing image URL if new image is selected
        _meters[index]['image'] = null;
      });
    }
  }

  void _removeMeterImage(int index) {
    setState(() {
      _meters[index]['imageFile'] = null;
      // If it's an existing meter, keep the image URL
      if (!_meters[index].containsKey('id')) {
        _meters[index].remove('image');
      }
    });
  }

  String? _validateLatLong(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final String trimmed = v.trim();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fields = <String, dynamic>{
        'property_id': widget.property['id'],
        'property_geo_registry_id': _geo['id'],
        'digital_address': _digitalAddressController.text.trim(),
        'dor_lat_long': _dorLatLongController.text.trim(),
      };

      // Add registry points
      for (int i = 1; i <= 8; i++) {
        final pointValue = _pointControllers['point$i']?.text.trim() ?? '';
        if (pointValue.isNotEmpty) {
          fields['point$i'] = pointValue;
        }
      }

      // Prepare meter data
      final List<Map<String, dynamic>> meterData = [];
      for (final meter in _meters) {
        final Map<String, dynamic> meterEntry = {};
        
        // Existing meter (has id)
        if (meter.containsKey('id') && meter['id'] != null) {
          meterEntry['id'] = meter['id'];
          meterEntry['property_id'] = meter['property_id'];
          meterEntry['number'] = meter['number']?.toString() ?? '';
          
          // If new image file is selected, use it; otherwise keep existing image
          if (meter['imageFile'] != null) {
            meterEntry['imageFile'] = meter['imageFile'];
          } else if (meter['image'] != null) {
            meterEntry['image'] = meter['image'];
          }
        } else {
          // New meter (no id)
          meterEntry['number'] = meter['number']?.toString() ?? '';
          if (meter['imageFile'] != null) {
            meterEntry['imageFile'] = meter['imageFile'];
          }
        }
        
        // Only add if meter has number or image
        if ((meterEntry['number']?.toString().isNotEmpty ?? false) ||
            meterEntry.containsKey('imageFile') ||
            meterEntry.containsKey('image')) {
          meterData.add(meterEntry);
        }
      }

      await _propertyService.updateGeoLocation(
        fields: fields,
        meterData: meterData.isNotEmpty ? meterData : null,
      );

      ToastService.showSuccess('Geo location information updated successfully');
      
      Get.offAllNamed(Routes.propertyList);
    } catch (e) {
      ToastService.showError('Failed to update geo location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Geo Registry')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Location',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dorLatLongController,
                                decoration: _decoration.copyWith(
                                  labelText: 'Dor Lat Long',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.my_location),
                                    tooltip: 'Use current location',
                                    onPressed: () => _fetchLocationForPoint(1),
                                  ),
                                ),
                                readOnly: true,
                                validator: _validateLatLong,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _digitalAddressController,
                                decoration: _decoration.copyWith(
                                  labelText: 'Digital Address',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Registry Points',
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 8,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 4,
                          ),
                          itemBuilder: (context, index) {
                            final int p = index + 1;
                            return TextFormField(
                              controller: _pointControllers['point$p'],
                              decoration: _decoration.copyWith(
                                labelText: 'Point $p',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.my_location, size: 20),
                                  tooltip: 'Use current location',
                                  onPressed: () => _fetchLocationForPoint(p),
                                ),
                              ),
                              keyboardType: TextInputType.text,
                              validator: _validateLatLong,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Meters',
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: _addMeter,
                            icon: const Icon(Icons.add),
                            label: const Text('+ Add Meter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_meters.length, (index) {
                          final meter = _meters[index];
                          final bool isExisting = meter.containsKey('id') && meter['id'] != null;
                          final String? existingImageUrl = meter['image']?.toString();
                          final String? imageFilePath = meter['imageFile']?.toString();
                          
                          return Padding(
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
                                        isExisting
                                            ? 'Meter ${index + 1} (Existing)'
                                            : 'Meter ${index + 1} (New)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _removeMeter(index),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: meter['number']?.toString() ?? '',
                                    decoration: _decoration.copyWith(
                                      labelText: 'Meter Number',
                                    ),
                                    onChanged: (v) => _updateMeterNumber(index, v),
                                  ),
                                  const SizedBox(height: 12),
                                  _MeterImageBox(
                                    label: 'Meter Image',
                                    imageFilePath: imageFilePath,
                                    existingImageUrl: existingImageUrl,
                                    onPick: () => _pickMeterImage(index),
                                    onRemove: () => _removeMeterImage(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Update Geo Registry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

class _MeterImageBox extends StatelessWidget {
  const _MeterImageBox({
    required this.label,
    this.imageFilePath,
    this.existingImageUrl,
    required this.onPick,
    required this.onRemove,
  });
  final String label;
  final String? imageFilePath;
  final String? existingImageUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool hasLocalImage = imageFilePath != null && imageFilePath!.isNotEmpty && File(imageFilePath!).existsSync();
    final bool hasExistingImage = existingImageUrl != null && existingImageUrl!.isNotEmpty;
    final bool hasImage = hasLocalImage || hasExistingImage;

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
            if (hasLocalImage)
              Image.file(File(imageFilePath!), fit: BoxFit.cover)
            else if (hasExistingImage)
              Image.network(
                'http://13.232.84.109/apis/storage/app/public/$existingImageUrl',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image, size: 42, color: Colors.black45),
                        const SizedBox(height: 8),
                        Text(label, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  );
                },
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt, size: 42, color: Colors.black45),
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

