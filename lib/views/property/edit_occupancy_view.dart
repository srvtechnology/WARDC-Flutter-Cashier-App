import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/property_service.dart';
import '../../routes/app_pages.dart';
import '../../services/toast_service.dart';

class EditOccupancyView extends StatefulWidget {
  const EditOccupancyView({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  State<EditOccupancyView> createState() => _EditOccupancyViewState();
}

class _EditOccupancyViewState extends State<EditOccupancyView> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();
  bool _isLoading = false;
  final Set<String> _selectedTypes = <String>{};
  String? _tenantTitleId;

  final Map<String, TextEditingController> _controllers = {};

  Map<String, dynamic>? _variables;
  bool _loadingVars = false;

  static const List<String> _types = <String>[
    'Owned Tenancy',
    'Unoccupied House',
    'Rented House',
  ];

  Map<String, dynamic> get _occupancy =>
      Map<String, dynamic>.from(
          (widget.property['occupancy'] ?? {}) as Map? ?? {});
  List<dynamic> get _occupancies => (widget.property['occupancies'] as List?) ?? const [];

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

    _tenantTitleId = _occupancy['ownerTenantTitle_id']?.toString() ??
        _occupancy['ownerTenantTitle']?.toString();

    _controllers['tenant_first_name'] =
        TextEditingController(text: _occupancy['tenant_first_name']?.toString() ?? '');
    _controllers['middle_name'] =
        TextEditingController(text: _occupancy['middle_name']?.toString() ?? '');
    _controllers['surname'] =
        TextEditingController(text: _occupancy['surname']?.toString() ?? '');
    _controllers['mobile_1'] =
        TextEditingController(text: _occupancy['mobile_1']?.toString() ?? '');
    _controllers['mobile_2'] =
        TextEditingController(text: _occupancy['mobile_2']?.toString() ?? '');
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

    setState(() => _isLoading = true);

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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Occupancy')),
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
                      title: 'Select Occupancy Types',
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final String t in _types)
                              FilterChip(
                                selected: _selectedTypes.contains(t),
                                label: Text(t),
                                onSelected: (bool val) {
                                  setState(() {
                                    if (val) {
                                      _selectedTypes.add(t);
                                    } else {
                                      _selectedTypes.remove(t);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Tenant Information',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTitleSelect(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['tenant_first_name'],
                                decoration: _decoration.copyWith(
                                  labelText: 'Tenant First Name',
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
                                decoration: _decoration.copyWith(labelText: 'Surname'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Contact',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['mobile_1'],
                                decoration: _decoration.copyWith(
                                  labelText: 'Mobile Number 1',
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _controllers['mobile_2'],
                                decoration: _decoration.copyWith(
                                  labelText: 'Mobile Number 2',
                                ),
                                keyboardType: TextInputType.phone,
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
    return DropdownButtonFormField<String>(
      decoration: _decoration.copyWith(labelText: 'Title'),
      value: _tenantTitleId,
      isExpanded: true,
      items: options
          .map((o) => DropdownMenuItem<String>(
                value: (o['id'] ?? o['value']).toString(),
                child: Text(o['label']?.toString() ?? 'Item'),
              ))
          .toList(),
      onChanged: (v) => setState(() => _tenantTitleId = v),
    );
  }

  List<Map<String, dynamic>> _getTitleOptions() {
    if (_variables == null) return const [{'id': '1', 'label': 'Mr.'}, {'id': '2', 'label': 'Ms.'}];
    final data = _variables!['data'] as Map<String, dynamic>?;
    if (data == null) return const [{'id': '1', 'label': 'Mr.'}, {'id': '2', 'label': 'Ms.'}];
    
    final allTitles = data['all_titles'] as List?;
    if (allTitles != null && allTitles.isNotEmpty) {
      return allTitles
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['is_active'] == null || e['is_active'] == 1)
          .toList();
    }
    return const [{'id': '1', 'label': 'Mr.'}, {'id': '2', 'label': 'Ms.'}];
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

