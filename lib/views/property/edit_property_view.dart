import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/property_service.dart';
import '../../routes/app_pages.dart';

class EditPropertyView extends StatefulWidget {
  const EditPropertyView({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  State<EditPropertyView> createState() => _EditPropertyViewState();
}

class _EditPropertyViewState extends State<EditPropertyView> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();
  bool _isLoading = false;
  String? _deliveredImagePath;
  String? _categoryType;
  String? _isDraftDelivered;
  String? _propertyInaccessible;

  final Map<String, TextEditingController> _controllers = {};
  String? _ward;
  String? _constituency;
  String? _section;
  String? _chiefdom;
  String? _district;
  String? _province;

  Map<String, dynamic>? _variables;
  bool _loadingVars = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadVariables();
  }

  void _initializeForm() {
    _categoryType = widget.property['category']?.toString();
    _isDraftDelivered = (widget.property['is_draft_delivered'] == 1)
        ? '1'
        : '0';

    // Property inaccessible - get first value from array if it exists
    final dynamic inaccessibleRaw = widget.property['property_inaccessible'];
    if (inaccessibleRaw is List && inaccessibleRaw.isNotEmpty) {
      final firstItem = inaccessibleRaw.first;
      if (firstItem is Map) {
        _propertyInaccessible = firstItem['id']?.toString();
      } else if (firstItem is String || firstItem is int) {
        _propertyInaccessible = firstItem.toString();
      }
    } else if (inaccessibleRaw is String && inaccessibleRaw.isNotEmpty) {
      _propertyInaccessible = inaccessibleRaw;
    }

    _ward = widget.property['ward']?.toString();
    _constituency = widget.property['constituency']?.toString();
    _section = widget.property['section']?.toString();
    _chiefdom = widget.property['chiefdom']?.toString();
    _district = widget.property['district']?.toString();
    _province = widget.property['province']?.toString();

    _controllers['street_number'] = TextEditingController(
      text: widget.property['street_number']?.toString() ?? '',
    );
    _controllers['street_numbernew'] = TextEditingController(
      text: widget.property['street_numbernew']?.toString() ?? '',
    );
    _controllers['street_name'] = TextEditingController(
      text: widget.property['street_name']?.toString() ?? '',
    );
    _controllers['postcode'] = TextEditingController(
      text: widget.property['postcode']?.toString() ?? '',
    );
    _controllers['delivered_name'] = TextEditingController(
      text: widget.property['delivered_name']?.toString() ?? '',
    );
    _controllers['delivered_number'] = TextEditingController(
      text: widget.property['delivered_number']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadVariables() async {
    if (_loadingVars) return;
    setState(() => _loadingVars = true);
    try {
      final data = await _propertyService.getAllVariables();
      setState(() {
        _variables = {'data': data};
        _loadingVars = false;
      });
    } catch (e) {
      setState(() => _loadingVars = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (file != null) {
      setState(() => _deliveredImagePath = file.path);
    }
  }

  void _printPropertyPayload(Map<String, dynamic> fields) {
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final MapEntry<String, dynamic> entry in fields.entries) {
      if (entry.value != null) {
        if (entry.value is List) {
          out[entry.key] = entry.value;
        } else {
          out[entry.key] = entry.value.toString();
        }
      }
    }

    // Handle delivered_image_path separately (it's a file path)
    if (_deliveredImagePath != null && _deliveredImagePath!.isNotEmpty) {
      out['delivered_image'] =
          '(binary file: ${_deliveredImagePath!.split('/').last})';
    }

    Get.log('Property update payload: ${jsonEncode(out)}');
    // Also print for dev consoles that do not capture Get.log
    // ignore: avoid_print
    print('\n=== Property Update Payload ===');
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fields = <String, dynamic>{
        'property_id': widget.property['id'],
        'street_number': _controllers['street_number']!.text.trim(),
        'street_numbernew': _controllers['street_numbernew']!.text.trim(),
        'street_name': _controllers['street_name']!.text.trim(),
        'ward': _ward ?? '',
        'constituency': _constituency ?? '',
        'section': _section ?? '',
        'chiefdom': _chiefdom ?? '',
        'district': _district ?? '',
        'province': _province ?? '',
        'postcode': _controllers['postcode']!.text.trim(),
        'is_draft_delivered': _isDraftDelivered ?? '0',
        'delivered_name': _controllers['delivered_name']!.text.trim(),
        'delivered_number': _controllers['delivered_number']!.text.trim(),
        'property_inaccessable': _propertyInaccessible ?? '',
      };

      // Log the payload before submission
      _printPropertyPayload(fields);

      final response = await _propertyService.updateProperty(
        fields: fields,
        deliveredImagePath: _deliveredImagePath,
      );

      // Log the API response
      Get.log('Property update response: ${jsonEncode(response)}');
      // ignore: avoid_print
      print('\n=== Property Update Response ===');
      // ignore: avoid_print
      print(jsonEncode(response));
      // ignore: avoid_print
      print('==================================\n');

      Get.snackbar(
        'Success',
        'Property information updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAllNamed(Routes.propertyList);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update property: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Property')),
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
                      title: 'Category Type',
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: _decoration.copyWith(
                            labelText: 'Category Type*',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'R',
                              child: Text('Residential'),
                            ),
                            DropdownMenuItem(
                              value: 'C',
                              child: Text('Commercial'),
                            ),
                          ],
                          value: _categoryType,
                          isExpanded: true,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) =>
                              (v == null || v.toString().trim().isEmpty)
                              ? 'Required'
                              : null,
                          onChanged: (v) => setState(() => _categoryType = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Delivery',
                      children: [
                        _ImageInputBox(
                          label: 'Delivery Proof Image',
                          path: _deliveredImagePath,
                          existingImageUrl: widget.property['delivered_image']
                              ?.toString(),
                          onPick: _pickImage,
                          onRemove: () =>
                              setState(() => _deliveredImagePath = null),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: _decoration.copyWith(
                            labelText: 'Is Draft Delivered?',
                          ),
                          items: const [
                            DropdownMenuItem(value: '0', child: Text('No')),
                            DropdownMenuItem(value: '1', child: Text('Yes')),
                          ],
                          value: _isDraftDelivered,
                          onChanged: (v) =>
                              setState(() => _isDraftDelivered = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['delivered_name'],
                                decoration: _decoration.copyWith(
                                  labelText: 'Recipient Name',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['delivered_number'],
                                decoration: _decoration.copyWith(
                                  labelText: 'Recipient Number',
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Address',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['street_number'],
                                decoration: _decoration.copyWith(
                                  labelText: 'Street Number',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['street_numbernew'],
                                decoration: _decoration.copyWith(
                                  labelText: 'Street Number (New)',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _controllers['street_name'],
                          decoration: _decoration.copyWith(
                            labelText: 'Street Name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['postcode'],
                                decoration: _decoration.copyWith(
                                  labelText: 'Postcode',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Administrative',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildAdminSelect(
                                'wards',
                                'Ward',
                                (v) => setState(() => _ward = v),
                                _ward,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAdminSelect(
                                'constituencies',
                                'Constituency',
                                (v) => setState(() => _constituency = v),
                                _constituency,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAdminSelect(
                                'sections',
                                'Section',
                                (v) => setState(() => _section = v),
                                _section,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAdminSelect(
                                'chiefdoms',
                                'Chiefdom',
                                (v) => setState(() => _chiefdom = v),
                                _chiefdom,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAdminSelect(
                                'districts',
                                'District',
                                (v) => setState(() => _district = v),
                                _district,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAdminSelect(
                                'provinces',
                                'Province',
                                (v) => setState(() => _province = v),
                                _province,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Other',
                      children: [_buildInaccessibleDropdown()],
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Update Property'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAdminSelect(
    String dataKey,
    String label,
    Function(String?) onChanged,
    String? value,
  ) {
    final List<Map<String, dynamic>> options = _getAdminOptions(dataKey);
    return DropdownButtonFormField<String>(
      decoration: _decoration.copyWith(labelText: label),
      value: options.isEmpty ? null : value,
      isExpanded: true,
      hint: options.isEmpty
          ? const Text('Loading...', style: TextStyle(color: Colors.grey))
          : null,
      selectedItemBuilder: options.isEmpty
          ? null
          : (context) => [
              for (final Map<String, dynamic> o in options)
                Text(
                  o['label']?.toString() ?? 'Item',
                  overflow: TextOverflow.ellipsis,
                ),
            ],
      items: options.isEmpty
          ? [
              const DropdownMenuItem<String>(
                value: null,
                enabled: false,
                child: Text('Loading options...'),
              ),
            ]
          : [
              for (final Map<String, dynamic> o in options)
                DropdownMenuItem<String>(
                  value: (o['id'] ?? o['value']).toString(),
                  child: Text(o['label']?.toString() ?? 'Item'),
                ),
            ],
      onChanged: options.isEmpty ? null : onChanged,
    );
  }

  Widget _buildInaccessibleDropdown() {
    final List<Map<String, dynamic>> options = _getInaccessibleOptions();
    return DropdownButtonFormField<String>(
      decoration: _decoration.copyWith(labelText: 'Property Inaccessible'),
      isExpanded: true,
      value: _propertyInaccessible,
      items: options.isEmpty
          ? [
              const DropdownMenuItem<String>(
                value: null,
                enabled: false,
                child: Text('Loading options...'),
              ),
            ]
          : [
              for (final Map<String, dynamic> o in options)
                DropdownMenuItem<String>(
                  value: (o['id'] ?? o['value']).toString(),
                  child: Text(o['label']?.toString() ?? 'Item'),
                ),
            ],
      onChanged: options.isEmpty
          ? null
          : (v) => setState(() => _propertyInaccessible = v),
    );
  }

  List<Map<String, dynamic>> _getAdminOptions(String dataKey) {
    if (_variables == null) return const [];
    final data = _variables!['data'] as Map<String, dynamic>?;
    if (data == null) return const [];

    final Map<String, String> apiKeyMap = {
      'wards': 'ward',
      'constituencies': 'constituency',
      'sections': 'section',
      'chiefdoms': 'chiefdom',
      'districts': 'district',
      'provinces': 'province',
    };

    final String apiKey = apiKeyMap[dataKey] ?? dataKey;
    final raw = data[apiKey];

    if (raw is Map) {
      return raw.entries
          .map<Map<String, dynamic>>(
            (e) => {'id': e.key.toString(), 'label': e.value.toString()},
          )
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> _getInaccessibleOptions() {
    if (_variables == null) return const [];
    final data = _variables!['data'] as Map<String, dynamic>?;
    if (data == null) return const [];

    final raw = data['property_inaccessibles'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
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

class _ImageInputBox extends StatelessWidget {
  const _ImageInputBox({
    required this.label,
    required this.path,
    this.existingImageUrl,
    required this.onPick,
    required this.onRemove,
  });
  final String label;
  final String? path;
  final String? existingImageUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool hasLocalImage =
        path != null && path!.isNotEmpty && File(path!).existsSync();
    final bool hasExistingImage =
        existingImageUrl != null && existingImageUrl!.isNotEmpty;
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
              Image.file(File(path!), fit: BoxFit.cover)
            else if (hasExistingImage)
              Image.network(
                'http://13.232.84.109/apis/storage/app/public/$existingImageUrl',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          size: 42,
                          color: Colors.black45,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: const TextStyle(color: Colors.black54),
                        ),
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
