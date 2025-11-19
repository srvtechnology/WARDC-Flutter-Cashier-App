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
            widget.property['is_organization'] == 1)
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
      setState(() {
        _variables = {'data': data};
        _loadingVars = false;
      });
    } catch (e) {
      setState(() => _loadingVars = false);
      ToastService.showError('Failed to load form options: $e');
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
              _SectionCard(
                title: 'Type',
                children: [
                  Row(
                    children: [
                      const Text('Is Organization'),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Radio<String>(
                            value: '0',
                            groupValue: _isOrganization,
                            onChanged: (v) =>
                                setState(() => _isOrganization = v ?? '0'),
                          ),
                          const Text('No'),
                          const SizedBox(width: 8),
                          Radio<String>(
                            value: '1',
                            groupValue: _isOrganization,
                            onChanged: (v) =>
                                setState(() => _isOrganization = v ?? '1'),
                          ),
                          const Text('Yes'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isOrganization == '0') ...[
                _SectionCard(
                  title: 'Personal Information',
                  children: [
                    _buildTitleSelect(),
                    const SizedBox(height: 12),
                    TextFormField(
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controllers['middle_name'],
                      decoration: _decoration.copyWith(
                        labelText: 'Middle Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controllers['surname'],
                      decoration: _decoration.copyWith(labelText: 'Surname*'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => ValidationUtils.validateRequired(
                        v,
                        fieldName: 'Surname',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownSearch<String>(
                      items: (filter, infiniteScrollProps) => const [
                        'Male',
                        'Female',
                      ],
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _decoration.copyWith(labelText: 'Gender'),
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
                      validator: (v) => ValidationUtils.validateRequired(
                        v,
                        fieldName: 'Gender',
                      ),
                      onChanged: (v) =>
                          setState(() => _sex = v == 'Male' ? 'm' : 'f'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controllers['id_type'],
                      decoration: _decoration.copyWith(labelText: 'Id type'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controllers['id_number'],
                      decoration: _decoration.copyWith(labelText: 'Id number'),
                    ),
                  ],
                ),
              ] else ...[
                _SectionCard(
                  title: 'Organization Information',
                  children: [
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
                ),
              ],
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Contact',
                children: [
                  TextFormField(
                    controller: _controllers['email'],
                    decoration: _decoration.copyWith(
                      labelText: 'Email Address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: ValidationUtils.validateEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controllers['mobile_1'],
                    decoration: _decoration.copyWith(labelText: 'Mobile 1*'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneNumberFormatter()],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) =>
                        ValidationUtils.validatePhone(v, isRequired: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controllers['mobile_2'],
                    decoration: _decoration.copyWith(labelText: 'Mobile 2'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneNumberFormatter()],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) =>
                        ValidationUtils.validatePhone(v, isRequired: false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Address',
                children: [
                  TextFormField(
                    controller: _controllers['street_number'],
                    decoration: _decoration.copyWith(labelText: 'Street No'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controllers['street_name'],
                    decoration: _decoration.copyWith(labelText: 'Street Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _controllers['postcode'],
                    decoration: _decoration.copyWith(labelText: 'Postcode'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Administrative',
                children: [
                  _buildAdminSelect(
                    'wards',
                    'Ward',
                    true,
                    (v) => setState(() => _ward = v),
                    _ward,
                  ),
                  const SizedBox(height: 12),
                  _buildAdminSelect(
                    'constituencies',
                    'Constituency',
                    true,
                    (v) => setState(() => _constituency = v),
                    _constituency,
                  ),
                  const SizedBox(height: 12),
                  _buildAdminSelect(
                    'sections',
                    'Section',
                    true,
                    (v) => setState(() => _section = v),
                    _section,
                  ),
                  const SizedBox(height: 12),
                  _buildAdminSelect(
                    'chiefdoms',
                    'Chiefdom',
                    true,
                    (v) => setState(() => _chiefdom = v),
                    _chiefdom,
                  ),
                  const SizedBox(height: 12),
                  _buildAdminSelect(
                    'districts',
                    'District',
                    true,
                    (v) => setState(() => _district = v),
                    _district,
                  ),
                  const SizedBox(height: 12),
                  _buildAdminSelect(
                    'provinces',
                    'Province',
                    true,
                    (v) => setState(() => _province = v),
                    _province,
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
          labelText: 'Title',
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

  Widget _buildAdminSelect(
    String dataKey,
    String label,
    bool required,
    Function(String?) onChanged,
    String? value,
  ) {
    final List<Map<String, dynamic>> rawOptions = _getAdminOptions(dataKey);

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
        : (value != null &&
              options.any((o) => (o['id'] ?? o['value']).toString() == value))
        ? value
        : null;

    return DropdownSearch<String>(
      items: (filter, infiniteScrollProps) {
        if (options.isEmpty) return [];
        return options.map((o) => (o['id'] ?? o['value']).toString()).toList();
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
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
      onChanged: options.isEmpty ? null : onChanged,
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
