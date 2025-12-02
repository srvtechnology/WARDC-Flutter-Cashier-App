import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/property_service.dart';
import '../../routes/app_pages.dart';
import '../../services/toast_service.dart';
import '../../utils/validation_utils.dart';
import '../../utils/input_formatters.dart';
import '../../utils/api_config.dart';

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
  List<dynamic> _fetchedAdjustments = [];

  bool get _shouldShowMastsField => _selectedValueAdded.contains(8);
  bool get _shouldShowShopsField => _selectedValueAdded.contains(9);
  bool get _shouldShowCompoundFields => _gatedCommunity == '1';

  Map<String, dynamic> get _assessmentsObject {
    final List<dynamic>? assessments =
        widget.property['assessments_object'] as List?;
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
    final List<dynamic>? valuesAdded =
        _assessmentsObject['values_added'] as List?;
    if (valuesAdded != null) {
      for (final val in valuesAdded) {
        if (val is Map && val['id'] != null) {
          _selectedValueAdded.add(val['id'] as int);
        }
      }
    }

    // Initialize single select values
    _wallMaterials = _assessmentsObject['property_wall_materials']?.toString();
    _roofsMaterials = _assessmentsObject['roofs_materials']?.toString();
    _windowType = _assessmentsObject['property_window_type']?.toString();
    _propertyUse = _assessmentsObject['property_use']?.toString();
    _zone = _assessmentsObject['zone']?.toString();
    _swimmingPool = _assessmentsObject['swimming_pool']?.toString();
    _gatedCommunity = _assessmentsObject['gated_community']?.toString();

    // Initialize controllers
    _controllers['length'] = TextEditingController(
      text: _assessmentsObject['length']?.toString() ?? '',
    );
    _controllers['breadth'] = TextEditingController(
      text: _assessmentsObject['breadth']?.toString() ?? '',
    );
    _controllers['total_mast'] = TextEditingController(
      text: _assessmentsObject['no_of_mast']?.toString() ?? '',
    );
    _controllers['total_shops'] = TextEditingController(
      text: _assessmentsObject['no_of_shop']?.toString() ?? '',
    );
    _controllers['total_compound_house'] = TextEditingController(
      text: _assessmentsObject['no_of_compound_house']?.toString() ?? '',
    );
    _controllers['compound_name'] = TextEditingController(
      text: _assessmentsObject['compound_name']?.toString() ?? '',
    );

    // Initialize images
    _assessmentImage1Path = _assessmentsObject['assessment_images_1']
        ?.toString();
    _assessmentImage2Path = _assessmentsObject['assessment_images_2']
        ?.toString();
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

      // Fetch property details to get council adjustments
      final String propertyId = widget.property['id'].toString();
      final details = await _propertyService.getPropertyDetails(
        propertyId: propertyId,
      );

      if (details['allAdjustments'] != null) {
        _fetchedAdjustments = details['allAdjustments'] as List;
      }

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

    // 1. Try to get from fetched adjustments (API)
    if (_fetchedAdjustments.isNotEmpty) {
      for (final item in _fetchedAdjustments) {
        if (item is Map && item['adjustment_id'] != null) {
          _selectedCouncilAdjustments.add(item['adjustment_id'] as int);
        }
      }
      return; // Found data, stop here
    }

    // 2. Try to parse existing adjustments from assessmentsObject first
    dynamic councilRaw =
        _assessmentsObject['council_adjustments'] ??
        _assessmentsObject['council'] ??
        _assessmentsObject['councils'] ??
        _assessmentsObject['newAdjustmentIds'];

    // If not found in assessmentsObject, check the parent property object
    councilRaw ??=
        widget.property['council_adjustments'] ??
        widget.property['council'] ??
        widget.property['councils'] ??
        widget.property['newAdjustmentIds'];

    // Also check in property['data']['property'] if it exists
    if (councilRaw == null) {
      final dynamic propData = widget.property['data'];
      if (propData is Map) {
        final dynamic propertyNested = propData['property'];
        if (propertyNested is Map) {
          councilRaw =
              propertyNested['council_adjustments'] ??
              propertyNested['council'] ??
              propertyNested['councils'] ??
              propertyNested['newAdjustmentIds'];
        }
      }
    }

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
    } else if (councilRaw is String) {
      // Handle JSON string (e.g. "[1, 2]") or single ID
      if (councilRaw.trim().startsWith('[')) {
        try {
          final List<dynamic> list = jsonDecode(councilRaw);
          for (final item in list) {
            if (item is int) {
              _selectedCouncilAdjustments.add(item);
            } else if (item is String) {
              final int? id = int.tryParse(item);
              if (id != null) _selectedCouncilAdjustments.add(id);
            }
          }
        } catch (_) {
          // Ignore parse error
        }
      } else {
        final int? id = int.tryParse(councilRaw);
        if (id != null) {
          _selectedCouncilAdjustments.add(id);
        }
      }
    } else if (councilRaw is int) {
      // Handle single ID as int
      _selectedCouncilAdjustments.add(councilRaw);
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
              if (adj is Map &&
                  _selectedCouncilAdjustments.contains(adj['id'] as int)) {
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
        'no_of_compound_house': _controllers['no_of_compound_house']!.text
            .trim(),
        'compound_name': _controllers['compound_name']!.text.trim(),
        'property_categories': _selectedCategories
            .map((e) => e.toString())
            .toList(),
        'property_types': _selectedTypes.map((e) => e.toString()).toList(),
        'property_value_added': _selectedValueAdded
            .map((e) => e.toString())
            .toList(),
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
              // Property Categories
              _buildSingleSelectChips(
                'property_categories',
                'Property Categories*',
                _selectedCategories.isNotEmpty
                    ? _selectedCategories.first
                    : null,
                (selected) {
                  setState(() {
                    _selectedCategories.clear();
                    if (selected != null) {
                      _selectedCategories.add(selected);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              // Property Types
              _buildSingleSelectChips(
                'property_types',
                'Property Type*',
                _selectedTypes.isNotEmpty ? _selectedTypes.first : null,
                (selected) {
                  setState(() {
                    _selectedTypes.clear();
                    if (selected != null) {
                      _selectedTypes.add(selected);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              // Wall Material
              _buildSingleSelectDropdownWithLabel(
                'property_wall_materials',
                'Wall Material*',
                _wallMaterials,
                (v) => setState(() => _wallMaterials = v),
              ),
              const SizedBox(height: 12),

              // Roof Material
              _buildSingleSelectDropdownWithLabel(
                'property_roofs_materials',
                'Roof Type*',
                _roofsMaterials,
                (v) => setState(() => _roofsMaterials = v),
              ),
              const SizedBox(height: 16),

              // Property Dimension Calculator
              const Text(
                'Property Dimension Calculator',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('length_field'),
                      controller: _controllers['length'],
                      decoration: _decoration.copyWith(labelText: 'Length'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        DecimalInputFormatter(decimalPlaces: 2),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) {
                        return ValidationUtils.validateDecimal(
                          v,
                          decimalPlaces: 2,
                          isRequired: false,
                        );
                      },
                      onChanged: (v) {
                        if (_formKey.currentState != null) {
                          _formKey.currentState!.validate();
                        }
                        setState(() {}); // Rebuild to update dimension
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('breadth_field'),
                      controller: _controllers['breadth'],
                      decoration: _decoration.copyWith(labelText: 'Breadth'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        DecimalInputFormatter(decimalPlaces: 2),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) {
                        return ValidationUtils.validateDecimal(
                          v,
                          decimalPlaces: 2,
                          isRequired: false,
                        );
                      },
                      onChanged: (v) {
                        if (_formKey.currentState != null) {
                          _formKey.currentState!.validate();
                        }
                        setState(() {}); // Rebuild to update dimension
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final length =
                      double.tryParse(_controllers['length']?.text ?? '') ??
                      0.0;
                  final breadth =
                      double.tryParse(_controllers['breadth']?.text ?? '') ??
                      0.0;
                  final dimension = length * breadth;
                  return Text(
                    'Dimension in Sq. Meters: ${dimension.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Council Adjustments
              _buildCouncilAdjustmentsChips(),
              const SizedBox(height: 12),

              // Value Added Assessment Parameters
              _buildMultiSelectChips(
                'property_value_added',
                'Value Added Assessment Parameters*',
                _selectedValueAdded,
                (selected) {
                  setState(() {
                    _selectedValueAdded.clear();
                    _selectedValueAdded.addAll(selected);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Swimming Pool
              _buildSingleSelectDropdownWithLabel(
                'swimmings',
                'Swimming Pool',
                _swimmingPool,
                (v) => setState(() => _swimmingPool = v),
              ),
              const SizedBox(height: 12),

              // Property Use
              _buildSingleSelectDropdownWithLabel(
                'property_uses',
                'Property Use*',
                _propertyUse,
                (v) => setState(() => _propertyUse = v),
              ),
              const SizedBox(height: 12),

              // Zones
              _buildSingleSelectDropdownWithLabel(
                'property_zones',
                'Zones*',
                _zone,
                (v) => setState(() => _zone = v),
              ),
              const SizedBox(height: 16),

              // Gated Community Checkbox
              CheckboxListTile(
                value: _gatedCommunity == '1',
                onChanged: (v) =>
                    setState(() => _gatedCommunity = v == true ? '1' : '0'),
                title: const Text('Gated Community'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.green,
              ),

              // Additional Information - Conditional fields
              if (_shouldShowMastsField)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: _controllers['no_of_mast'],
                    decoration: _decoration.copyWith(labelText: 'No of Masts'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [IntegerInputFormatter()],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => ValidationUtils.validateInteger(
                      v,
                      min: 0,
                      isRequired: false,
                    ),
                  ),
                ),
              if (_shouldShowShopsField)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: _controllers['no_of_shop'],
                    decoration: _decoration.copyWith(labelText: 'No of Shops'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [IntegerInputFormatter()],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => ValidationUtils.validateInteger(
                      v,
                      min: 0,
                      isRequired: false,
                    ),
                  ),
                ),
              if (_shouldShowCompoundFields) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: _controllers['no_of_compound_house'],
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: _controllers['compound_name'],
                    decoration: _decoration.copyWith(
                      labelText: 'Compound Name',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Property Images
              Row(
                children: [
                  Expanded(
                    child: _AssessmentImageBox(
                      label: 'Image 1',
                      imagePath: _assessmentImage1Path,
                      existingImageUrl:
                          _assessmentsObject['assessment_images_1']?.toString(),
                      onPick: () => _pickImage(1),
                      onRemove: () =>
                          setState(() => _assessmentImage1Path = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AssessmentImageBox(
                      label: 'Image 2',
                      imagePath: _assessmentImage2Path,
                      existingImageUrl:
                          _assessmentsObject['assessment_images_2']?.toString(),
                      onPick: () => _pickImage(2),
                      onRemove: () =>
                          setState(() => _assessmentImage2Path = null),
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
                      : const Text('Update Assessment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSelectChips(
    String dataKey,
    String label,
    int? selected,
    Function(int?) onChanged,
  ) {
    final List<Map<String, dynamic>> options = _getOptions(dataKey);

    // Convert selected ID to label
    String? selectedLabel;
    if (selected != null) {
      final option = options.firstWhereOrNull((o) => o['id'] == selected);
      if (option != null) {
        selectedLabel = option['label']?.toString() ?? 'Item';
      }
    }

    return DropdownSearch<String>(
      items: (filter, infiniteScrollProps) {
        return options.map((o) => o['label']?.toString() ?? 'Item').toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: _decoration.copyWith(labelText: label),
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
        // Convert label back to ID
        if (selectedLabel == null) {
          onChanged(null);
          return;
        }
        final option = options.firstWhereOrNull(
          (o) => o['label']?.toString() == selectedLabel,
        );
        if (option != null) {
          onChanged(option['id'] as int);
        }
      },
    );
  }

  Widget _buildMultiSelectChips(
    String dataKey,
    String label,
    Set<int> selected,
    Function(Set<int>) onChanged,
  ) {
    final List<Map<String, dynamic>> options = _getOptions(dataKey);

    // Convert selected IDs to labels
    final List<String> selectedLabels = [];
    for (final id in selected) {
      final option = options.firstWhereOrNull((o) => o['id'] == id);
      if (option != null) {
        selectedLabels.add(option['label']?.toString() ?? 'Item');
      }
    }

    return DropdownSearch<String>.multiSelection(
      items: (filter, infiniteScrollProps) {
        return options.map((o) => o['label']?.toString() ?? 'Item').toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: _decoration.copyWith(labelText: label),
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
        final Set<int> newSelected = {};
        for (final label in selectedLabels) {
          final option = options.firstWhereOrNull(
            (o) => o['label']?.toString() == label,
          );
          if (option != null) {
            newSelected.add(option['id'] as int);
          }
        }
        onChanged(newSelected);
      },
    );
  }

  Widget _buildCouncilAdjustmentsChips() {
    final List<Map<String, dynamic>> options = _getOptions(
      'council_adjustments',
    );

    // Convert selected IDs to labels
    final List<String> selectedLabels = [];
    for (final id in _selectedCouncilAdjustments) {
      // Compare IDs as strings to handle both int and string types from API
      final option = options.firstWhereOrNull(
        (o) => o['id']?.toString() == id.toString(),
      );
      if (option != null) {
        // Try different label formats
        String label;
        if (option['name'] != null && option['type'] != null) {
          label = '${option['name']} - ${option['type']}';
        } else if (option['label'] != null) {
          label = option['label'].toString();
        } else if (option['name'] != null) {
          label = option['name'].toString();
        } else {
          label = 'Item $id';
        }
        selectedLabels.add(label);
      }
    }

    return DropdownSearch<String>.multiSelection(
      items: (filter, infiniteScrollProps) {
        return options.map((o) {
          // Try different label formats for display
          if (o['name'] != null && o['type'] != null) {
            return '${o['name']} - ${o['type']}';
          } else if (o['label'] != null) {
            return o['label'].toString();
          } else if (o['name'] != null) {
            return o['name'].toString();
          } else {
            return 'Item ${o['id']}';
          }
        }).toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: _decoration.copyWith(labelText: 'Council Adjustments'),
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
        setState(() {
          _selectedCouncilAdjustments.clear();
          for (final label in selectedLabels) {
            final option = options.firstWhereOrNull((o) {
              // Match against different label formats
              if (o['name'] != null && o['type'] != null) {
                return '${o['name']} - ${o['type']}' == label;
              } else if (o['label'] != null) {
                return o['label'].toString() == label;
              } else if (o['name'] != null) {
                return o['name'].toString() == label;
              } else {
                return 'Item ${o['id']}' == label;
              }
            });
            if (option != null) {
              final dynamic val = option['id'];
              if (val is int) {
                _selectedCouncilAdjustments.add(val);
              } else if (val is String) {
                final int? parsed = int.tryParse(val);
                if (parsed != null) {
                  _selectedCouncilAdjustments.add(parsed);
                }
              }
            }
          }
        });
      },
    );
  }

  Widget _buildSingleSelectDropdownWithLabel(
    String dataKey,
    String label,
    String? value,
    Function(String?) onChanged,
  ) {
    final List<Map<String, dynamic>> rawOptions = _getOptions(dataKey);

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

    // Find the label for the current value
    String? selectedLabel;
    if (valueStr != null && valueStr.isNotEmpty) {
      final option = uniqueOptionsMap[valueStr];
      if (option != null) {
        selectedLabel = option['label']?.toString();
      }
    }

    return DropdownSearch<String>(
      items: (filter, infiniteScrollProps) {
        if (options.isEmpty) return [];
        return options.map((o) => o['label']?.toString() ?? 'Item').toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: _decoration.copyWith(
          labelText: label,
          hintText: options.isEmpty ? 'Loading...' : null,
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
      enabled: options.isNotEmpty,
      selectedItem: selectedLabel,
      compareFn: (item1, item2) => item1 == item2,
      onChanged: options.isEmpty
          ? null
          : (selectedLabel) {
              // Convert label back to ID
              if (selectedLabel == null) {
                onChanged(null);
                return;
              }
              final option = options.firstWhereOrNull(
                (o) => o['label']?.toString() == selectedLabel,
              );
              if (option != null) {
                onChanged((option['id'] ?? option['value']).toString());
              }
            },
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
    final bool hasLocalImage =
        imagePath != null &&
        imagePath!.isNotEmpty &&
        File(imagePath!).existsSync();
    final bool hasExistingImage =
        existingImageUrl != null && existingImageUrl!.isNotEmpty;
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
                  ApiConfig.getImageUrl(existingImageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            size: 42,
                            color: Colors.black54,
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
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 42,
                      color: Colors.black54,
                    ),
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
