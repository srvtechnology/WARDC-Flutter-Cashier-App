import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/property_service.dart';
import '../../routes/app_pages.dart';
import '../../services/toast_service.dart';
import '../../utils/validation_utils.dart';
import '../../utils/input_formatters.dart';

class EditOccupancyView extends StatefulWidget {
  const EditOccupancyView({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  State<EditOccupancyView> createState() => _EditOccupancyViewState();
}

class _EditOccupancyViewState extends State<EditOccupancyView> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();
  final Set<String> _selectedTypes = <String>{};
  String? _tenantTitleId;

  final Map<String, TextEditingController> _controllers = {};

  Map<String, dynamic>? _variables;
  bool _loadingVars = false;
  bool _isSubmitting = false;

  static const List<String> _types = <String>[
    'Owned Tenancy',
    'Unoccupied House',
    'Rented House',
  ];

  Map<String, dynamic> get _occupancy => Map<String, dynamic>.from(
    (widget.property['occupancy'] ?? {}) as Map? ?? {},
  );
  List<dynamic> get _occupancies =>
      (widget.property['occupancies'] as List?) ?? const [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadVariables();
  }

  void _initializeForm() {
    // Get occupancy types
    for (final occ in _occupancies) {
      if (occ is Map && occ['occupancy_type'] != null) {
        _selectedTypes.add(occ['occupancy_type'].toString());
      }
    }

    _tenantTitleId =
        _occupancy['ownerTenantTitle_id']?.toString() ??
        _occupancy['ownerTenantTitle']?.toString();

    _controllers['tenant_first_name'] = TextEditingController(
      text: _occupancy['tenant_first_name']?.toString() ?? '',
    );
    _controllers['middle_name'] = TextEditingController(
      text: _occupancy['middle_name']?.toString() ?? '',
    );
    _controllers['surname'] = TextEditingController(
      text: _occupancy['surname']?.toString() ?? '',
    );
    _controllers['mobile_1'] = TextEditingController(
      text: _occupancy['mobile_1']?.toString() ?? '',
    );
    _controllers['mobile_2'] = TextEditingController(
      text: _occupancy['mobile_2']?.toString() ?? '',
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      ToastService.showError('Please select at least one occupancy type');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'property_id': widget.property['id'],
        'occupancy_id': _occupancy['id'],
        'tenant_first_name': _controllers['tenant_first_name']!.text.trim(),
        'middle_name': _controllers['middle_name']!.text.trim(),
        'surname': _controllers['surname']!.text.trim(),
        'mobile_1': _controllers['mobile_1']!.text.trim(),
        'mobile_2': _controllers['mobile_2']!.text.trim(),
        'occupancy_type': _selectedTypes.toList(),
      };

      await _propertyService.updateOccupancy(payload: payload);

      ToastService.showSuccess('Occupancy information updated successfully');

      Get.offAllNamed(Routes.propertyList);
    } catch (e) {
      ToastService.showError('Failed to update occupancy: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Occupancy')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Occupancy Type Dropdown
              DropdownSearch<String>(
                items: (filter, infiniteScrollProps) => _types,
                decoratorProps: DropDownDecoratorProps(
                  decoration: _decoration.copyWith(
                    labelText: 'Occupancy Type*',
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
                selectedItem: _selectedTypes.isNotEmpty
                    ? _selectedTypes.first
                    : null,
                validator: (v) => ValidationUtils.validateRequired(
                  v,
                  fieldName: 'Occupancy Type',
                ),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedTypes.clear();
                      _selectedTypes.add(v);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Title and First Name Row
              Row(
                children: [
                  Expanded(child: _buildTitleSelect()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _controllers['tenant_first_name'],
                      decoration: _decoration.copyWith(
                        labelText: 'First Name*',
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => ValidationUtils.validateRequired(
                        v,
                        fieldName: 'First Name',
                      ),
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
                      controller: _controllers['middle_name'],
                      decoration: _decoration.copyWith(
                        labelText: 'Middle Name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _controllers['surname'],
                      decoration: _decoration.copyWith(labelText: 'Surname*'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => ValidationUtils.validateRequired(
                        v,
                        fieldName: 'Surname',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mobile #1
              TextFormField(
                controller: _controllers['mobile_1'],
                decoration: _decoration.copyWith(
                  labelText: 'Mobile #1*',
                  prefixText: '+232 ',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneNumberFormatter()],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    ValidationUtils.validatePhone(v, isRequired: true),
              ),
              const SizedBox(height: 12),

              // Mobile #2
              TextFormField(
                controller: _controllers['mobile_2'],
                decoration: _decoration.copyWith(
                  labelText: 'Mobile #2',
                  prefixText: '+232 ',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneNumberFormatter()],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    ValidationUtils.validatePhone(v, isRequired: false),
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
                      : const Text('Update Occupancy'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSelect() {
    final List<Map<String, dynamic>> options = _getTitleOptions();
    return DropdownSearch<String>(
      items: (filter, infiniteScrollProps) {
        return options.map((o) => (o['id'] ?? o['value']).toString()).toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: _decoration.copyWith(
          labelText: 'Title',
          hintText: 'Select Title',
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
          final option = options.firstWhere(
            (o) => (o['id'] ?? o['value']).toString() == item,
            orElse: () => {'label': item},
          );
          return ListTile(
            title: Text(
              option['label']?.toString() ?? 'Item',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
          );
        },
      ),
      selectedItem: _tenantTitleId,
      compareFn: (item1, item2) => item1 == item2,
      onChanged: (v) => setState(() => _tenantTitleId = v),
    );
  }

  List<Map<String, dynamic>> _getTitleOptions() {
    if (_variables == null)
      return const [
        {'id': '1', 'label': 'Mr.'},
        {'id': '2', 'label': 'Ms.'},
      ];
    final data = _variables!['data'] as Map<String, dynamic>?;
    if (data == null)
      return const [
        {'id': '1', 'label': 'Mr.'},
        {'id': '2', 'label': 'Ms.'},
      ];

    final allTitles = data['all_titles'] as List?;
    if (allTitles != null && allTitles.isNotEmpty) {
      return allTitles
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['is_active'] == null || e['is_active'] == 1)
          .toList();
    }
    return const [
      {'id': '1', 'label': 'Mr.'},
      {'id': '2', 'label': 'Ms.'},
    ];
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
