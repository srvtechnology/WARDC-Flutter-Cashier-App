import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/property_service.dart';
import '../../routes/app_pages.dart';
import '../../services/toast_service.dart';
import '../../utils/validation_utils.dart';
import '../../utils/input_formatters.dart';

class EditLandlordView extends StatefulWidget {
  const EditLandlordView({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  State<EditLandlordView> createState() => _EditLandlordViewState();
}

class _EditLandlordViewState extends State<EditLandlordView> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();
  String _isOrganization = '0';

  // Form controllers
  final Map<String, TextEditingController> _controllers = {};
  String? _ownerTitleId;
  String? _sex;
  String? _ward;
  String? _constituency;
  String? _section;
  String? _chiefdom;
  String? _district;
  String? _province;

  Map<String, dynamic>? _variables;
  List<String> _wards = [];
  Map<String, dynamic> _wardFilteredData = {};
  bool _loadingVars = false;
  bool _isSubmitting = false;

  Map<String, dynamic> get _landlord => Map<String, dynamic>.from(
    (widget.property['landlord'] ?? {}) as Map? ?? {},
  );

  @override
  void initState() {
    super.initState();
    _isOrganization =
        (widget.property['is_organization'] == true ||
            widget.property['is_organization'] == 1 ||
            widget.property['is_organization'] == '1')
        ? '1'
        : '0';
    _initializeForm();
    _loadVariables();
  }

  void _initializeForm() {
    _ownerTitleId =
        _landlord['ownerTitle']?.toString() ??
        _landlord['ownerTitle_id']?.toString();
    _sex = _landlord['sex']?.toString() ?? 'm';
    _ward = _landlord['ward']?.toString();
    _constituency = _landlord['constituency']?.toString();
    _section = _landlord['section']?.toString();
    _chiefdom = _landlord['chiefdom']?.toString();
    _district = _landlord['district']?.toString();
    _province = _landlord['province']?.toString();

    _controllers['first_name'] = TextEditingController(
      text: _landlord['first_name']?.toString() ?? '',
    );
    _controllers['middle_name'] = TextEditingController(
      text: _landlord['middle_name']?.toString() ?? '',
    );
    _controllers['surname'] = TextEditingController(
      text: _landlord['surname']?.toString() ?? '',
    );
    _controllers['email'] = TextEditingController(
      text: _landlord['email']?.toString() ?? '',
    );
    _controllers['id_type'] = TextEditingController(
      text: _landlord['id_type']?.toString() ?? '',
    );
    _controllers['id_number'] = TextEditingController(
      text: _landlord['id_number']?.toString() ?? '',
    );
    _controllers['street_number'] = TextEditingController(
      text: _landlord['street_number']?.toString() ?? '',
    );
    _controllers['street_name'] = TextEditingController(
      text: _landlord['street_name']?.toString() ?? '',
    );
    _controllers['postcode'] = TextEditingController(
      text: _landlord['postcode']?.toString() ?? '',
    );
    _controllers['mobile_1'] = TextEditingController(
      text:
          _landlord['mobile_1']?.toString() ??
          _landlord['phone_number']?.toString() ??
          '',
    );
    _controllers['mobile_2'] = TextEditingController(
      text: _landlord['mobile_2']?.toString() ?? '',
    );
    _controllers['organization_name'] = TextEditingController(
      text: widget.property['organization_name']?.toString() ?? '',
    );
    _controllers['organization_addresss'] = TextEditingController(
      text: widget.property['organization_addresss']?.toString() ?? '',
    );
    _controllers['organization_type'] = TextEditingController(
      text: widget.property['organization_type']?.toString() ?? '',
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
      final wards = await _propertyService.getAllWards();
      setState(() {
        _variables = {'data': data};
        _wards = wards;
        _loadingVars = false;
      });

      // If ward is already selected, fetch filtered data
      if (_ward != null && _ward!.isNotEmpty) {
        _onWardSelected(_ward!, initialLoad: true);
      }
    } catch (e) {
      setState(() => _loadingVars = false);
      ToastService.showError('Failed to load form options: $e');
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'property_id': widget.property['id'],
        'landlord_id': _landlord['id'],
        'first_name': _controllers['first_name']!.text.trim(),
        'middle_name': _controllers['middle_name']!.text.trim(),
        'surname': _controllers['surname']!.text.trim(),
        'sex': _sex ?? 'm',
        'email': _controllers['email']!.text.trim(),
        'id_number': _controllers['id_number']!.text.trim(),
        'id_type': _controllers['id_type']!.text.trim(),
        'street_number': _controllers['street_number']!.text.trim(),
        'street_name': _controllers['street_name']!.text.trim(),
        'ward': _ward ?? '',
        'constituency': _constituency ?? '',
        'section': _section ?? '',
        'chiefdom': _chiefdom ?? '',
        'district': _district ?? '',
        'province': _province ?? '',
        'postcode': _controllers['postcode']!.text.trim(),
        'mobile_1': _controllers['mobile_1']!.text.trim(),
        'mobile_2': _controllers['mobile_2']!.text.trim(),
        'is_organization': _isOrganization,
        'organization_name': _controllers['organization_name']!.text.trim(),
        'organization_type': _controllers['organization_type']!.text.trim(),
        'organization_addresss': _controllers['organization_addresss']!.text
            .trim(),
      };

      if (_ownerTitleId != null) {
        payload['ownerTitle'] = _ownerTitleId;
      }

      await _propertyService.updateLandlord(payload: payload);

      ToastService.showSuccess('Landlord information updated successfully');

      Get.offAllNamed(Routes.propertyList);
    } catch (e) {
      ToastService.showError('Failed to update landlord: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Landlord')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkboxes
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isOrganization == '1',
                      onChanged: (v) => setState(
                        () => _isOrganization = v == true ? '1' : '0',
                      ),
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

              if (_isOrganization == '0') ...[
                // Personal Information
                Row(
                  children: [
                    Expanded(child: _buildTitleSelect()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _controllers['first_name'],
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
                  selectedItem: _sex == 'm'
                      ? 'Male'
                      : (_sex == 'f' ? 'Female' : null),
                  validator: (v) =>
                      ValidationUtils.validateRequired(v, fieldName: 'Sex'),
                  onChanged: (v) =>
                      setState(() => _sex = v == 'Male' ? 'm' : 'f'),
                ),
              ] else ...[
                // Organization Information
                TextFormField(
                  controller: _controllers['organization_name'],
                  decoration: _decoration.copyWith(
                    labelText: 'Organization Name',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => ValidationUtils.validateRequired(
                    v,
                    fieldName: 'Organization Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _controllers['organization_addresss'],
                  decoration: _decoration.copyWith(
                    labelText: 'Organization Address',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => ValidationUtils.validateRequired(
                    v,
                    fieldName: 'Organization Address',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _controllers['organization_type'],
                  decoration: _decoration.copyWith(
                    labelText: 'Organization Type',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],

              const SizedBox(height: 16),
              // Address Part 1
              TextFormField(
                controller: _controllers['street_number'],
                decoration: _decoration.copyWith(labelText: 'Street Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controllers['street_name'],
                decoration: _decoration.copyWith(labelText: 'Street Name'),
              ),

              const SizedBox(height: 16),
              // Administrative
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
                      selectedItem: _province,
                      onChanged: (v) => setState(() => _province = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Address Part 2
              /*
              TextFormField(
                controller: _controllers['postcode'],
                decoration: _decoration.copyWith(labelText: 'Postcode'),
              ),
              */
              const SizedBox(height: 16),
              // Contact
              TextFormField(
                controller: _controllers['email'],
                decoration: _decoration.copyWith(labelText: 'Email Id'),
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: ValidationUtils.validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controllers['mobile_1'],
                decoration: _decoration.copyWith(labelText: 'Mobile #1*'),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneNumberFormatter()],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    ValidationUtils.validatePhone(v, isRequired: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controllers['mobile_2'],
                decoration: _decoration.copyWith(labelText: 'Mobile #2'),
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
                      : const Text('Update Landlord'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSelect() {
    final List<Map<String, dynamic>> rawOptions = _getTitleOptions();

    // Deduplicate options by ID to prevent duplicate values
    final Map<String, Map<String, dynamic>> uniqueOptions = {};
    for (final option in rawOptions) {
      final id = (option['id'] ?? option['value']).toString();
      if (!uniqueOptions.containsKey(id)) {
        uniqueOptions[id] = option;
      }
    }
    final List<Map<String, dynamic>> options = uniqueOptions.values.toList();

    // Only set value if it exists in the options
    final String? selectedValue = options.isEmpty
        ? null
        : (_ownerTitleId != null &&
              options.any(
                (o) => (o['id'] ?? o['value']).toString() == _ownerTitleId,
              ))
        ? _ownerTitleId
        : null;

    return DropdownSearch<String>(
      items: (filter, infiniteScrollProps) {
        if (options.isEmpty) return [];
        return options.map((o) => (o['id'] ?? o['value']).toString()).toList();
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: _decoration.copyWith(
          labelText: 'Title*',
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
      enabled: options.isNotEmpty,
      selectedItem: selectedValue,
      compareFn: (item1, item2) => item1 == item2,
      onChanged: options.isEmpty
          ? null
          : (v) {
              setState(() {
                _ownerTitleId = v;
              });
            },
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
