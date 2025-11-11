import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/property_service.dart';

class PropertyDetailsView extends StatefulWidget {
  const PropertyDetailsView({super.key, required this.property});
  final Map<String, dynamic> property;

  @override
  State<PropertyDetailsView> createState() => _PropertyDetailsViewState();
}

class _PropertyDetailsViewState extends State<PropertyDetailsView> {
  final RxInt _step = 0.obs;

  Map<String, dynamic> get prop => widget.property;

  String _text(dynamic v) => v?.toString() ?? '—';
  Map<String, dynamic>? _variables;
  bool _loadingVars = false;
  Map<String, dynamic> get _landlordFew =>
      Map<String, dynamic>.from((prop['landlord_few'] ?? {}) as Map? ?? {});
  Map<String, dynamic> get _userDetails =>
      Map<String, dynamic>.from((prop['user_details'] ?? {}) as Map? ?? {});
  Map<String, dynamic> get _geo =>
      Map<String, dynamic>.from((prop['geo_registry'] ?? {}) as Map? ?? {});
  Map<String, dynamic> get _assessment =>
      Map<String, dynamic>.from((prop['assessment'] ?? {}) as Map? ?? {});
  List<dynamic> get _occupancies => (prop['occupancies'] as List?) ?? const [];
  List<dynamic> get _propertyInaccessible =>
      (prop['property_inaccessible'] as List?) ?? const [];

  @override
  void initState() {
    super.initState();
    _loadVariables();
  }

  Future<void> _loadVariables() async {
    if (_loadingVars) return;
    setState(() => _loadingVars = true);
    try {
      final Map<String, dynamic> data =
          await PropertyService().getAllVariables();
      setState(() {
        _variables = data;
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingVars = false);
    }
  }

  String _labelFor(String dataKey, dynamic id) {
    if (_variables == null || id == null) return _text(id);
    final dynamic list = _variables![dataKey];
    if (list is List) {
      for (final dynamic e in list) {
        if (e is Map) {
          final Map<String, dynamic> m = Map<String, dynamic>.from(e);
          final String idStr = (m['id'] ?? '').toString();
          if (idStr == id.toString()) {
            return m['label']?.toString() ?? id.toString();
          }
        }
      }
    }
    return id.toString();
  }

  String _labelsFor(String dataKey, List<dynamic> ids) {
    if (ids.isEmpty) return '—';
    final List<String> out = <String>[];
    for (final dynamic v in ids) {
      out.add(_labelFor(dataKey, v));
    }
    return out.join(', ');
  }

  // Return values using the create form field names
  String _formValue(String key) {
    switch (key) {
      // Step 1 - Landlord (create form keys)
      case 'is_organization':
        return (prop['is_organization'] == true || prop['is_organization'] == 1)
            ? '1'
            : '0';
      case 'landlord_ownerTitle_id':
        final dynamic tId = prop['landlord_ownerTitle_id'];
        final String lbl = _labelFor('all_titles', tId);
        return (lbl.isEmpty || lbl == 'null') ? _text(tId) : lbl;
      case 'landlord_first_name':
        return _text(_landlordFew['first_name']);
      case 'landlord_middle_name':
        return _text(_landlordFew['middle_name']);
      case 'landlord_surname':
        return _text(_landlordFew['surname']);
      case 'landlord_sex':
        return _text(_userDetails['gender']);
      case 'landlord_email':
        return _text(_userDetails['email']);
      case 'landlord_id_type':
        return _text(prop['landlord_id_type']); // not provided in listing
      case 'landlord_id_number':
        return _text(prop['landlord_id_number']); // not provided in listing
      case 'landlord_street_number':
        return _text(prop['street_number']);
      case 'landlord_street_name':
        return _text(prop['street_name']);
      case 'landlord_postcode':
        return _text(prop['postcode']);
      case 'landlord_ward':
        return _text(prop['ward']);
      case 'landlord_constituency':
        return _text(prop['constituency']);
      case 'landlord_section':
        return _text(prop['section']);
      case 'landlord_chiefdom':
        return _text(prop['chiefdom']);
      case 'landlord_district':
        return _text(prop['district']);
      case 'landlord_province':
        return _text(prop['province']);
      case 'landlord_mobile_1':
        return _text(prop['landlord_mobile_1']); // not provided in listing
      case 'landlord_mobile_2':
        return _text(prop['landlord_mobile_2']); // not provided in listing

      // Step 2 - Property (create form keys)
      case 'categoryType':
        return _text(prop['category']); // 'R' / 'C'
      case 'delivered_name':
        return _text(prop['delivered_name']);
      case 'delivered_number':
        return _text(prop['delivered_number']);
      case 'delivered_image':
        return _text(prop['delivered_image']);
      case 'is_draft_delivered':
        return (prop['is_draft_delivered'] == 1) ? '1' : '0';
      case 'property_street_number':
        return _text(prop['street_number']);
      case 'property_street_numbernew':
        return _text(prop['street_numbernew']);
      case 'property_street_name':
        return _text(prop['street_name']);
      case 'property_postcode':
        return _text(prop['postcode']);
      case 'property_ward':
        return _text(prop['ward']);
      case 'property_constituency':
        return _text(prop['constituency']);
      case 'property_section':
        return _text(prop['section']);
      case 'property_chiefdom':
        return _text(prop['chiefdom']);
      case 'property_district':
        return _text(prop['district']);
      case 'property_province':
        return _text(prop['province']);
      case 'property_inaccessable':
        // return comma separated ids
        if (_propertyInaccessible.isEmpty) return '[]';
        final ids = _propertyInaccessible
            .whereType<Map>()
            .map((e) => e['id'])
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
        return ids.isEmpty ? '[]' : ids.toString();

      // Step 3 - Occupancy
      case 'occupancy_type':
        if (_occupancies.isEmpty) return '[]';
        final types = _occupancies
            .whereType<Map>()
            .map((e) => e['occupancy_type'])
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
        return types.isEmpty ? '[]' : types.toString();
      case 'occupancy_tenant_first_name':
      case 'occupancy_middle_name':
      case 'occupancy_surname':
      case 'occupancy_mobile_1':
      case 'occupancy_mobile_2':
      case 'tenant_ownerTitle_id':
        return '—'; // not provided in listing

      // Step 4 - Geo Registry
      case 'registry_digital_address':
        return _text(_geo['digital_address']);
      case 'dor_lat_long':
        return _text(_geo['dor_lat_long']);
      // Step 5 - Assessment (mapped to create form field names)
      case 'assessment_wall_materials_id':
        return _labelFor('property_wall_materials', _assessment['property_wall_materials']);
      case 'assessment_roofs_materials_id':
        return _labelFor('property_roofs_materials', _assessment['roofs_materials']);
      case 'assessment_window_type_id':
        return _labelFor('property_window_types', _assessment['property_window_type']);
      case 'assessment_length':
        return _text(_assessment['length']);
      case 'assessment_breadth':
        return _text(_assessment['breadth']);
      case 'assessment_use_id':
        return _labelFor('property_uses', _assessment['property_use']);
      case 'assessment_zone_id':
        return _labelFor('property_zones', _assessment['zone']);
      case 'total_mast':
        return _text(_assessment['no_of_mast']);
      case 'total_shops':
        return _text(_assessment['no_of_shop']);
      case 'total_compound_house':
        return _text(_assessment['no_of_compound_house']);
      case 'compound_name':
        return _text(_assessment['compound_name']);
      case 'gated_community':
        return _text(_assessment['gated_community']);
      case 'swimming_pool':
        return _labelFor('swimmings', _assessment['swimming_id']);
      default:
        if (key.startsWith('registry_point')) {
          final String idx = key.replaceFirst('registry_point', '');
          return _text(_geo['point$idx']);
        }
        break;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property Details')),
      body: Obx(() {
        final int step = _step.value;
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
                  child: _buildStep(step),
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final int step = _step.value;
        final bool isLast = step >= 4;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            child: Row(
              children: [
                if (step > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _step.value = (step - 1).clamp(0, 4),
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (step > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLast
                        ? () => Get.back()
                        : () => _step.value = (step + 1).clamp(0, 4),
                    icon: Icon(
                      isLast ? Icons.check_circle_outline : Icons.arrow_forward_ios,
                      size: 18,
                    ),
                    label: Text(isLast ? 'Close' : 'Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Type',
              children: [
                _KV('Is Organization', _formValue('is_organization') == '1' ? 'Yes' : 'No'),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Personal Information',
              children: [
                _KV('Title', _formValue('landlord_ownerTitle_id')),
                _KV('First Name', _formValue('landlord_first_name')),
                _KV('Middle Name', _formValue('landlord_middle_name')),
                _KV('Surname', _formValue('landlord_surname')),
                _KV('Gender', _formValue('landlord_sex')),
                _KV('Id type', _formValue('landlord_id_type')),
                _KV('Id number', _formValue('landlord_id_number')),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Contact',
              children: [
                _KV('Email Address', _formValue('landlord_email')),
                _KV('Mobile 1', _formValue('landlord_mobile_1')),
                _KV('Mobile 2', _formValue('landlord_mobile_2')),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Address',
              children: [
                _KV('Street No', _formValue('landlord_street_number')),
                _KV('Street Name', _formValue('landlord_street_name')),
                _KV('Postcode', _formValue('landlord_postcode')),
                _KV('Ward', _formValue('landlord_ward')),
                _KV('Constituency', _formValue('landlord_constituency')),
                _KV('Section', _formValue('landlord_section')),
                _KV('Chiefdom', _formValue('landlord_chiefdom')),
                _KV('District', _formValue('landlord_district')),
                _KV('Province', _formValue('landlord_province')),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Category Type',
              children: [
                _KV('Category Type', _formValue('categoryType') == 'R' ? 'Residential' : 'Commercial'),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Delivery',
              children: [
                _KV('Delivery Proof Image', _formValue('delivered_image')),
                _KV('Is Draft Delivered?', _formValue('is_draft_delivered') == '1' ? 'Yes' : 'No'),
                _KV('Recipient Name', _formValue('delivered_name')),
                _KV('Recipient Number', _formValue('delivered_number')),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Address',
              children: [
                _KV('Street Number', _formValue('property_street_number')),
                _KV('Street Number (New)', _formValue('property_street_numbernew')),
                _KV('Street Name', _formValue('property_street_name')),
                _KV('Postcode', _formValue('property_postcode')),
                _KV('Ward', _formValue('property_ward')),
                _KV('Constituency', _formValue('property_constituency')),
                _KV('Section', _formValue('property_section')),
                _KV('Chiefdom', _formValue('property_chiefdom')),
                _KV('District', _formValue('property_district')),
                _KV('Province', _formValue('property_province')),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Other',
              children: [
                _KV(
                  'Property Inaccessible',
                  () {
                    final List<String> ids = _propertyInaccessible
                        .whereType<Map>()
                        .map((e) => e['id'])
                        .where((e) => e != null)
                        .map((e) => e.toString())
                        .toList();
                    return _labelsFor('property_inaccessibles', ids);
                  }(),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Occupancy Types',
              children: [
                _KV('Selected Types', _formValue('occupancy_type')),
                _KV('Tenant Title', _formValue('tenant_ownerTitle_id')),
                _KV('Tenant First Name', _formValue('occupancy_tenant_first_name')),
                _KV('Tenant Middle Name', _formValue('occupancy_middle_name')),
                _KV('Tenant Surname', _formValue('occupancy_surname')),
                _KV('Mobile Number 1', _formValue('occupancy_mobile_1')),
                _KV('Mobile Number 2', _formValue('occupancy_mobile_2')),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Digital Address',
              children: [
                _KV('Digital Address', _formValue('registry_digital_address')),
                _KV('Dor Lat Long', _formValue('dor_lat_long')),
                _KV('Open Location Code', _text(_geo['open_location_code'])),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 4,
                  ),
                  itemBuilder: (context, index) {
                    final int p = index + 1;
                    return TextFormField(
                      readOnly: true,
                      initialValue: _formValue('registry_point$p'),
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
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        labelText: 'Point',
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Summary',
              children: [
                _KV('Wall Material', _formValue('assessment_wall_materials_id')),
                _KV('Roof Material', _formValue('assessment_roofs_materials_id')),
                _KV('Window Type', _formValue('assessment_window_type_id')),
                _KV('Length', _formValue('assessment_length')),
                _KV('Breadth', _formValue('assessment_breadth')),
                _KV('Property Use', _formValue('assessment_use_id')),
                _KV('Property Zone', _formValue('assessment_zone_id')),
                _KV('No of Masts', _formValue('total_mast')),
                _KV('No of Shops', _formValue('total_shops')),
                _KV('No of Compound House', _formValue('total_compound_house')),
                _KV('Compound Name', _formValue('compound_name')),
                _KV('Gated Community', _formValue('gated_community')),
                _KV('Swimming Pool', _formValue('swimming_pool')),
                // Extra financials for quick context
                _KV('Mill rate', _text(_assessment['mill_rate'])),
                _KV('Current year amount', _text(_assessment['current_year_assessment_amount'])),
                _KV('Rate without GST', _text(_assessment['property_rate_without_gst'])),
                _KV('Rate with GST', _text(_assessment['property_rate_with_gst'])),
                _KV('GST', _text(_assessment['property_gst'])),
                _KV('Due', _text(_assessment['due'])),
                _KV('Balance', _text(_assessment['balance'])),
              ],
            ),
          ],
        );
    }
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v);
  final String k;
  final String v;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              k,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
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

class _HeaderStepper extends StatelessWidget {
  const _HeaderStepper({required this.currentIndex, required this.labels});
  final int currentIndex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Expanded(child: Container());
              }
              final int step = i ~/ 2;
              final bool isAbove = step.isOdd;
              if (!isAbove) {
                return const SizedBox(width: 32);
              }
              final bool isActive = step == currentIndex;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Text(
                      labels[step],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.green : Colors.black87,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                final int left = (i - 1) ~/ 2;
                final bool active = left < currentIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? Colors.green : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                );
              }
              final int step = i ~/ 2;
              final bool isDone = step <= currentIndex;
              return Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Colors.green : Colors.white,
                  border: Border.all(
                    color: isDone ? Colors.green : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Text(
                  '${step + 1}',
                  style: TextStyle(
                    color: isDone ? Colors.white : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Expanded(child: Container());
              }
              final int step = i ~/ 2;
              final bool isBelow = step.isEven;
              if (!isBelow) {
                return const SizedBox(width: 32);
              }
              final bool isActive = step == currentIndex;
              return Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[step],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.green : Colors.black87,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}


