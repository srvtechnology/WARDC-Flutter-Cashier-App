import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/property_service.dart';
import '../../routes/app_pages.dart';
import '../../services/toast_service.dart';
import '../../utils/validation_utils.dart';
import '../../widgets/section_card.dart';

class EditPropertyView extends StatefulWidget {
  const EditPropertyView({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  State<EditPropertyView> createState() => _EditPropertyViewState();
}

class _EditPropertyViewState extends State<EditPropertyView> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();

  final Map<String, TextEditingController> _controllers = {};
  String? _ward;
  String? _constituency;
  String? _section;
  String? _chiefdom;
  String? _district;
  String? _province;

  List<String> _wards = [];
  Map<String, dynamic> _wardFilteredData = {};
  bool _loadingVars = false;
  bool _isSubmitting = false;

  String? _categoryType;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadVariables();
  }

  void _initializeForm() {
    _ward = widget.property['ward']?.toString();
    _constituency = widget.property['constituency']?.toString();
    _section = widget.property['section']?.toString();
    _chiefdom = widget.property['chiefdom']?.toString();
    _district = widget.property['district']?.toString();
    _province = widget.property['province']?.toString();
    _categoryType = widget.property['categoryType']?.toString();

    _controllers['street_number'] = TextEditingController(
      text: widget.property['street_number']?.toString() ?? '',
    );
    _controllers['street_numbernew'] = TextEditingController(
      text: widget.property['street_numbernew']?.toString() ?? '',
    );
    _controllers['street_name'] = TextEditingController(
      text: widget.property['street_name']?.toString() ?? '',
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
      await _propertyService.getAllVariables();
      final wards = await _propertyService.getAllWards();
      setState(() {
        _wards = wards;
        _loadingVars = false;
      });

      // If ward is already selected, fetch filtered data
      if (_ward != null && _ward!.isNotEmpty) {
        _onWardSelected(_ward!, initialLoad: true);
      }
    } catch (e) {
      setState(() => _loadingVars = false);
    }
  }

  Future<void> _onWardSelected(
    String wardId, {
    bool initialLoad = false,
  }) async {
    try {
      final data = await _propertyService.filterByWard(wardId);
      setState(() {
        _wardFilteredData = data;

        // Auto-fill District and Province if available and not initial load
        if (!initialLoad) {
          if (data['districts'] is List &&
              (data['districts'] as List).isNotEmpty) {
            _district = (data['districts'] as List).first.toString();
          }
          if (data['provinces'] is List &&
              (data['provinces'] as List).isNotEmpty) {
            _province = (data['provinces'] as List).first.toString();
          }
        }
      });
    } catch (e) {
      Get.log('Failed to filter by ward: $e');
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

    setState(() => _isSubmitting = true);

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
        'categoryType': _categoryType ?? '',
      };

      // Log the payload before submission
      _printPropertyPayload(fields);

      final response = await _propertyService.updateProperty(fields: fields);

      // Log the API response
      Get.log('Property update response: ${jsonEncode(response)}');
      // ignore: avoid_print
      print('\n=== Property Update Response ===');
      // ignore: avoid_print
      print(jsonEncode(response));
      // ignore: avoid_print
      print('==================================\n');

      ToastService.showSuccess('Property information updated successfully');

      Get.offAllNamed(Routes.propertyList);
    } catch (e) {
      ToastService.showError('Failed to update property: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Property')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                title: 'Address',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _controllers['street_number'],
                          decoration: _decoration.copyWith(
                            labelText: 'Old Street Number',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _controllers['street_numbernew'],
                          decoration: _decoration.copyWith(
                            labelText: 'New Street Number',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controllers['street_name'],
                    decoration: _decoration.copyWith(labelText: 'Street Name*'),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => ValidationUtils.validateRequired(
                      v,
                      fieldName: 'Street Name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SectionCard(
                title: 'Administrative',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownSearch<String>(
                          items: (filter, infiniteScrollProps) => _wards,
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
                          selectedItem: _ward,
                          validator: (v) => ValidationUtils.validateRequired(
                            v,
                            fieldName: 'Ward Number',
                          ),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _ward = v);
                              _onWardSelected(v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownSearch<String>(
                          items: (filter, infiniteScrollProps) =>
                              (_wardFilteredData['sections'] as List?)
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
                          selectedItem: _section,
                          validator: (v) => ValidationUtils.validateRequired(
                            v,
                            fieldName: 'Section',
                          ),
                          onChanged: (v) => setState(() => _section = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownSearch<String>(
                          items: (filter, infiniteScrollProps) =>
                              (_wardFilteredData['constituencies'] as List?)
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
                          selectedItem: _constituency,
                          validator: (v) => ValidationUtils.validateRequired(
                            v,
                            fieldName: 'Constituency',
                          ),
                          onChanged: (v) => setState(() => _constituency = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownSearch<String>(
                          items: (filter, infiniteScrollProps) =>
                              (_wardFilteredData['chiefdoms'] as List?)
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
                          selectedItem: _chiefdom,
                          validator: (v) => ValidationUtils.validateRequired(
                            v,
                            fieldName: 'Chiefdom',
                          ),
                          onChanged: (v) => setState(() => _chiefdom = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownSearch<String>(
                          items: (filter, infiniteScrollProps) =>
                              (_wardFilteredData['districts'] as List?)
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
                          selectedItem: _district,
                          validator: (v) => ValidationUtils.validateRequired(
                            v,
                            fieldName: 'District',
                          ),
                          onChanged: (v) => setState(() => _district = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownSearch<String>(
                          items: (filter, infiniteScrollProps) =>
                              (_wardFilteredData['provinces'] as List?)
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
                          selectedItem: _province,
                          onChanged: (v) => setState(() => _province = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SectionCard(
                title: 'Other',
                children: [
                  DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) => const [
                      'Residential',
                      'Commercial',
                    ],
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _decoration.copyWith(
                        labelText: 'Category Type*',
                      ),
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
                    selectedItem: _categoryType == 'R'
                        ? 'Residential'
                        : (_categoryType == 'C' ? 'Commercial' : null),
                    validator: (v) => ValidationUtils.validateRequired(
                      v,
                      fieldName: 'Category Type',
                    ),
                    onChanged: (v) => setState(
                      () => _categoryType = v == 'Residential' ? 'R' : 'C',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
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
