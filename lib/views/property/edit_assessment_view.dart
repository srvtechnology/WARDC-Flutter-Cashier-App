import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/property_service.dart';
import '../../routes/app_pages.dart';
import '../../services/toast_service.dart';
import '../../utils/validation_utils.dart';
import '../../utils/input_formatters.dart';

class EditAssessmentView extends StatefulWidget {
  const EditAssessmentView({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  State<EditAssessmentView> createState() => _EditAssessmentViewState();
}

class _EditAssessmentViewState extends State<EditAssessmentView> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();
  String? _assessmentImage1Path;
  String? _assessmentImage2Path;

  // Multi-select sets
  final Set<int> _selectedCategories = <int>{};
  final Set<int> _selectedTypes = <int>{};
  final Set<int> _selectedValueAdded = <int>{};
  final Set<int> _selectedCouncilAdjustments = <int>{};

  // Single select values
  String? _wallMaterials;
  String? _roofsMaterials;
  String? _windowType;
  String? _propertyUse;
  String? _zone;
  String? _swimmingPool;
  String? _gatedCommunity;

  // Text controllers
  final Map<String, TextEditingController> _controllers = {};

  Map<String, dynamic>? _variables;
  bool _loadingVars = false;
  bool _isSubmitting = false;

  Map<String, dynamic> get _assessmentsObject {
    final List<dynamic>? assessments = widget.property['assessments_object'] as List?;
    if (assessments != null && assessments.isNotEmpty) {
      return Map<String, dynamic>.from((assessments[0] as Map? ?? {}));
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadVariables();
  }

  void _initializeForm() {
    // Initialize categories
    final List<dynamic>? categories = _assessmentsObject['categories'] as List?;
    if (categories != null) {
      for (final cat in categories) {
        if (cat is Map && cat['id'] != null) {
          _selectedCategories.add(cat['id'] as int);
        }
      }
    }

    // Initialize types
    final List<dynamic>? types = _assessmentsObject['types'] as List?;
    if (types != null) {
      for (final type in types) {
        if (type is Map && type['id'] != null) {
          _selectedTypes.add(type['id'] as int);
        }
      }
    }

    // Initialize values_added
    final List<dynamic>? valuesAdded = _assessmentsObject['values_added'] as List?;
    if (valuesAdded != null) {
      for (final val in valuesAdded) {
        if (val is Map && val['id'] != null) {
          _selectedValueAdded.add(val['id'] as int);
        }
      }
    }

    // Initialize single selects
    _wallMaterials = _assessmentsObject['property_wall_materials']?.toString();
    _roofsMaterials = _assessmentsObject['roofs_materials']?.toString();
    _windowType = _assessmentsObject['property_window_type']?.toString();
    _propertyUse = _assessmentsObject['property_use']?.toString();
    _zone = _assessmentsObject['zone']?.toString();
    _swimmingPool = _assessmentsObject['swimming_id']?.toString() ??
        _assessmentsObject['swimming_pool']?.toString();
    _gatedCommunity = _assessmentsObject['gated_community']?.toString() ?? '0';

    // Initialize text fields
    _controllers['length'] = TextEditingController(
      text: _assessmentsObject['assessment_length']?.toString() ??
          _assessmentsObject['length']?.toString() ?? '',
    );
    _controllers['breadth'] = TextEditingController(
      text: _assessmentsObject['assessment_breadth']?.toString() ??
          _assessmentsObject['breadth']?.toString() ?? '',
    );
    _controllers['no_of_shop'] = TextEditingController(
      text: _assessmentsObject['no_of_shop']?.toString() ?? '',
    );
    _controllers['no_of_mast'] = TextEditingController(
      text: _assessmentsObject['no_of_mast']?.toString() ?? '',
    );
    _controllers['no_of_compound_house'] = TextEditingController(
      text: _assessmentsObject['no_of_compound_house']?.toString() ?? '',
    );
    _controllers['compound_name'] = TextEditingController(
      text: _assessmentsObject['compound_name']?.toString() ?? '',
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
      
      // Load council adjustments after variables are loaded
      setState(() {
        _loadCouncilAdjustments();
      });
    } catch (e) {
      setState(() => _loadingVars = false);
    }
  }

  void _loadCouncilAdjustments() {
    if (_variables == null) return;
    final data = _variables!['data'] as Map<String, dynamic>?;
    if (data == null) return;
    
    // Try to parse existing adjustments from assessmentsObject
    // Council adjustments might be stored as a list of IDs or as full objects
    final dynamic councilRaw = _assessmentsObject['council'] ?? 
                               _assessmentsObject['council_adjustments'] ??
                               _assessmentsObject['councils'];
    
    if (councilRaw is List) {
      for (final item in councilRaw) {
        if (item is Map && item['id'] != null) {
          _selectedCouncilAdjustments.add(item['id'] as int);
        } else if (item is int) {
          _selectedCouncilAdjustments.add(item);
        } else if (item is String) {
          final int? id = int.tryParse(item);
          if (id != null) {
            _selectedCouncilAdjustments.add(id);
          }
        }
      }
    }
  }

  Future<void> _pickImage(int imageNumber) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (file != null) {
      setState(() {
        if (imageNumber == 1) {
          _assessmentImage1Path = file.path;
        } else {
          _assessmentImage2Path = file.path;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Prepare council adjustments JSON
      final List<Map<String, dynamic>> councilAdjustments = [];
      if (_variables != null) {
        final data = _variables!['data'] as Map<String, dynamic>?;
        if (data != null) {
          final raw = data['council_adjustments'];
          if (raw is List) {
            for (final adj in raw) {
              if (adj is Map && _selectedCouncilAdjustments.contains(adj['id'] as int)) {
                councilAdjustments.add(Map<String, dynamic>.from(adj));
              }
            }
          }
        }
      }

      final fields = <String, dynamic>{
        'property_id': widget.property['id'],
        'assessment_id': _assessmentsObject['id'],
        'property_wall_materials': _wallMaterials ?? '',
        'roofs_materials': _roofsMaterials ?? '',
        'length': _controllers['length']!.text.trim(),
        'breadth': _controllers['breadth']!.text.trim(),
        'swimming_pool': _swimmingPool ?? '',
        'property_use': _propertyUse ?? '',
        'zone': _zone ?? '',
        'gated_community': _gatedCommunity ?? '0',
        'no_of_shop': _controllers['no_of_shop']!.text.trim(),
        'no_of_mast': _controllers['no_of_mast']!.text.trim(),
        'no_of_compound_house': _controllers['no_of_compound_house']!.text.trim(),
        'compound_name': _controllers['compound_name']!.text.trim(),
        'property_categories': _selectedCategories.map((e) => e.toString()).toList(),
        'property_types': _selectedTypes.map((e) => e.toString()).toList(),
        'property_value_added': _selectedValueAdded.map((e) => e.toString()).toList(),
        'council': councilAdjustments.map((e) => e['id'].toString()).toList(),
        'council_year': DateTime.now().year.toString(),
      };

      // Add window_type if available
      if (_windowType != null) {
        fields['window_type'] = _windowType;
      }

      await _propertyService.updateAssessment(
        fields: fields,
        assessmentImage1Path: _assessmentImage1Path,
        assessmentImage2Path: _assessmentImage2Path,
      );

      ToastService.showSuccess('Assessment information updated successfully');
      
      Get.offAllNamed(Routes.propertyList);
    } catch (e) {
      ToastService.showError('Failed to update assessment: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Assessment')),
      body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Classification',
                      children: [
                        _buildMultiSelectChips(
                          'property_categories',
                          'Select Category',
                          _selectedCategories,
                          (selected) {
                            setState(() {
                              _selectedCategories.clear();
                              _selectedCategories.addAll(selected);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMultiSelectChips(
                          'property_types',
                          'Select Types',
                          _selectedTypes,
                          (selected) {
                            setState(() {
                              _selectedTypes.clear();
                              _selectedTypes.addAll(selected);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMultiSelectChips(
                          'property_value_added',
                          'Select property value added',
                          _selectedValueAdded,
                          (selected) {
                            setState(() {
                              _selectedValueAdded.clear();
                              _selectedValueAdded.addAll(selected);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildCouncilAdjustmentsChips(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Materials',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSingleSelectDropdown(
                                'property_wall_materials',
                                'Wall Material',
                                _wallMaterials,
                                (v) => setState(() => _wallMaterials = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSingleSelectDropdown(
                                'property_roofs_materials',
                                'Roof Material',
                                _roofsMaterials,
                                (v) => setState(() => _roofsMaterials = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSingleSelectDropdown(
                          'property_window_types',
                          'Window Type',
                          _windowType,
                          (v) => setState(() => _windowType = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Dimensions',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const ValueKey('length_field'),
                                controller: _controllers['length'],
                                decoration: _decoration.copyWith(labelText: 'length'),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [DecimalInputFormatter(decimalPlaces: 2)],
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (v) {
                                  final breadthValue = _controllers['breadth']?.text;
                                  final decimalError = ValidationUtils.validateDecimal(v, decimalPlaces: 2, isRequired: false);
                                  if (decimalError != null) return decimalError;
                                  return ValidationUtils.validateLengthGreaterThanBreadth(v, breadthValue);
                                },
                                onChanged: (v) {
                                  // Trigger validation on breadth field when length changes
                                  if (_formKey.currentState != null) {
                                    _formKey.currentState!.validate();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                key: const ValueKey('breadth_field'),
                                controller: _controllers['breadth'],
                                decoration: _decoration.copyWith(labelText: 'breadth'),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [DecimalInputFormatter(decimalPlaces: 2)],
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (v) {
                                  final lengthValue = _controllers['length']?.text;
                                  return ValidationUtils.validateLengthGreaterThanBreadth(lengthValue, v);
                                },
                                onChanged: (v) {
                                  // Trigger validation on length field when breadth changes
                                  if (_formKey.currentState != null) {
                                    _formKey.currentState!.validate();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Property Details',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSingleSelectDropdown(
                                'property_uses',
                                'Property use',
                                _propertyUse,
                                (v) => setState(() => _propertyUse = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSingleSelectDropdown(
                                'property_zones',
                                'Property zone',
                                _zone,
                                (v) => setState(() => _zone = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSingleSelectDropdown(
                                'swimmings',
                                'Swimming pool',
                                _swimmingPool,
                                (v) => setState(() => _swimmingPool = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: _decoration.copyWith(
                                  labelText: 'Gated community',
                                ),
                                value: (_gatedCommunity == '0' || _gatedCommunity == '1')
                                    ? _gatedCommunity
                                    : '0', // Default to '0' if invalid value
                                isExpanded: true,
                                selectedItemBuilder: (BuildContext context) {
                                  return const [
                                    Text('No', overflow: TextOverflow.ellipsis),
                                    Text('Yes', overflow: TextOverflow.ellipsis),
                                  ];
                                },
                                items: const [
                                  DropdownMenuItem(value: '0', child: Text('No')),
                                  DropdownMenuItem(value: '1', child: Text('Yes')),
                                ],
                                onChanged: (v) => setState(() => _gatedCommunity = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Additional Information',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['no_of_mast'],
                                decoration: _decoration.copyWith(
                                  labelText: 'No of Masts',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [IntegerInputFormatter()],
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (v) => ValidationUtils.validateInteger(v, min: 0, isRequired: false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['no_of_shop'],
                                decoration: _decoration.copyWith(
                                  labelText: 'No of Shops',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [IntegerInputFormatter()],
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (v) => ValidationUtils.validateInteger(v, min: 0, isRequired: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['no_of_compound_house'],
                                decoration: _decoration.copyWith(
                                  labelText: 'No of Compound House',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [IntegerInputFormatter()],
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (v) => ValidationUtils.validateInteger(v, min: 0, isRequired: false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['compound_name'],
                                decoration: _decoration.copyWith(
                                  labelText: 'Compound Name',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Property Images',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _AssessmentImageBox(
                                label: 'Image 1',
                                imagePath: _assessmentImage1Path,
                                existingImageUrl: _assessmentsObject['assessment_images_1']?.toString(),
                                onPick: () => _pickImage(1),
                                onRemove: () => setState(() => _assessmentImage1Path = null),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AssessmentImageBox(
                                label: 'Image 2',
                                imagePath: _assessmentImage2Path,
                                existingImageUrl: _assessmentsObject['assessment_images_2']?.toString(),
                                onPick: () => _pickImage(2),
                                onRemove: () => setState(() => _assessmentImage2Path = null),
                              ),
                            ),
                          ],
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Update Assessment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMultiSelectChips(
    String dataKey,
    String label,
    Set<int> selected,
    Function(Set<int>) onChanged,
  ) {
    final List<Map<String, dynamic>> options = _getOptions(dataKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final Map<String, dynamic> o in options)
              FilterChip(
                selected: selected.contains(o['id'] as int),
                label: Text(o['label']?.toString() ?? 'Item'),
                onSelected: (bool val) {
                  final newSelected = Set<int>.from(selected);
                  if (val) {
                    newSelected.add(o['id'] as int);
                  } else {
                    newSelected.remove(o['id'] as int);
                  }
                  onChanged(newSelected);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCouncilAdjustmentsChips() {
    final List<Map<String, dynamic>> options = _getOptions('council_adjustments');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Council', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final Map<String, dynamic> o in options)
              FilterChip(
                selected: _selectedCouncilAdjustments.contains(o['id'] as int),
                label: Text('${o['name']} - ${o['type']}'),
                onSelected: (bool val) {
                  setState(() {
                    if (val) {
                      _selectedCouncilAdjustments.add(o['id'] as int);
                    } else {
                      _selectedCouncilAdjustments.remove(o['id'] as int);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleSelectDropdown(
    String dataKey,
    String label,
    String? value,
    Function(String?) onChanged,
  ) {
    final List<Map<String, dynamic>> rawOptions = _getOptions(dataKey);
    
    // If options are not loaded yet, return dropdown with null value
    if (rawOptions.isEmpty) {
      return DropdownButtonFormField<String>(
        decoration: _decoration.copyWith(labelText: label),
        value: null, // Always null when options are empty
        isExpanded: true,
        hint: const Text('Loading...', style: TextStyle(color: Colors.grey)),
        items: const [
          DropdownMenuItem<String>(
            value: null,
            enabled: false,
            child: Text('Loading options...'),
          ),
        ],
        onChanged: null,
      );
    }
    
    // Deduplicate options by ID to prevent Flutter assertion errors
    final Map<String, Map<String, dynamic>> uniqueOptionsMap = {};
    for (final Map<String, dynamic> o in rawOptions) {
      final String id = (o['id'] ?? o['value']).toString();
      if (id.isNotEmpty && !uniqueOptionsMap.containsKey(id)) {
        uniqueOptionsMap[id] = o;
      }
    }
    final List<Map<String, dynamic>> options = uniqueOptionsMap.values.toList();
    
    // Convert value to string for comparison
    final String? valueStr = value?.toString();
    
    // Only set value if it exists in deduplicated options and options are not empty
    final String? validValue = (valueStr != null && 
                                valueStr.isNotEmpty && 
                                uniqueOptionsMap.containsKey(valueStr))
        ? valueStr
        : null;
    
    // Create items list ensuring no duplicates
    final List<DropdownMenuItem<String>> items = options
        .map((o) {
          final String itemValue = (o['id'] ?? o['value']).toString();
          return DropdownMenuItem<String>(
            value: itemValue,
            child: Text(
              o['label']?.toString() ?? 'Item',
              overflow: TextOverflow.ellipsis,
            ),
          );
        })
        .toList();
    
    // Verify no duplicate values in items
    final Set<String> itemValues = items.map((item) => item.value ?? '').toSet();
    if (itemValues.length != items.length) {
      // If duplicates found, filter them out
      final Map<String, DropdownMenuItem<String>> uniqueItems = {};
      for (final item in items) {
        if (item.value != null && !uniqueItems.containsKey(item.value)) {
          uniqueItems[item.value!] = item;
        }
      }
      final List<DropdownMenuItem<String>> deduplicatedItems = uniqueItems.values.toList();
      
      // Re-validate value against deduplicated items
      final String? finalValue = (valueStr != null && 
                                  valueStr.isNotEmpty && 
                                  uniqueItems.containsKey(valueStr))
          ? valueStr
          : null;
      
      return DropdownButtonFormField<String>(
        decoration: _decoration.copyWith(labelText: label),
        value: finalValue,
        isExpanded: true,
        selectedItemBuilder: (BuildContext context) {
          return deduplicatedItems.map<Widget>((item) {
            return Text(
              item.child is Text ? (item.child as Text).data ?? '' : '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            );
          }).toList();
        },
        items: deduplicatedItems,
        onChanged: onChanged,
      );
    }
    
    return DropdownButtonFormField<String>(
      decoration: _decoration.copyWith(labelText: label),
      value: validValue,
      isExpanded: true,
      selectedItemBuilder: (BuildContext context) {
        return options.map<Widget>((Map<String, dynamic> o) {
          final String text = o['label']?.toString() ?? 'Item';
          return Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          );
        }).toList();
      },
      items: items,
      onChanged: onChanged,
    );
  }

  List<Map<String, dynamic>> _getOptions(String dataKey) {
    if (_variables == null) return const [];
    final data = _variables!['data'] as Map<String, dynamic>?;
    if (data == null) return const [];
    
    final raw = data[dataKey];
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

class _AssessmentImageBox extends StatelessWidget {
  const _AssessmentImageBox({
    required this.label,
    this.imagePath,
    this.existingImageUrl,
    required this.onPick,
    required this.onRemove,
  });
  final String label;
  final String? imagePath;
  final String? existingImageUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool hasLocalImage = imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync();
    final bool hasExistingImage = existingImageUrl != null && existingImageUrl!.isNotEmpty;
    final bool hasImage = hasLocalImage || hasExistingImage;

    return InkWell(
      onTap: onPick,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasLocalImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(imagePath!), fit: BoxFit.cover),
              )
            else if (hasExistingImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'http://13.232.84.109/apis/storage/app/public/$existingImageUrl',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt, size: 42, color: Colors.black54),
                          const SizedBox(height: 8),
                          Text(label, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt, size: 42, color: Colors.black54),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            if (hasImage)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: Colors.white),
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

