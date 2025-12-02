import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:map_launcher/map_launcher.dart';
import '../../services/property_service.dart';
import '../../routes/app_pages.dart';
import '../../services/toast_service.dart';
import '../../utils/api_config.dart';
import '../../widgets/section_card.dart';

class PropertyDetailsView extends StatefulWidget {
  const PropertyDetailsView({
    super.key,
    required this.property,
    this.showEditButton = true,
  });
  final Map<String, dynamic> property;
  final bool showEditButton;

  @override
  State<PropertyDetailsView> createState() => _PropertyDetailsViewState();
}

class _PropertyDetailsViewState extends State<PropertyDetailsView> {
  final RxInt _step = 0.obs;

  Map<String, dynamic> get prop => widget.property;

  String _text(dynamic v) => v?.toString() ?? '—';

  Widget _buildImageDisplay(String imagePath) {
    if (imagePath.isEmpty || imagePath == '—') {
      return Text(
        'No image available',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final String imageUrl = ApiConfig.getImageUrl(imagePath);

    return GestureDetector(
      onTap: () {
        // Show full screen image on tap
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text('Failed to load image'),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: Colors.grey.shade400,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Failed to load',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _variables;
  bool _loadingVars = false;
  Map<String, dynamic> get _landlord =>
      Map<String, dynamic>.from((prop['landlord'] ?? {}) as Map? ?? {});
  Map<String, dynamic> get _geo =>
      Map<String, dynamic>.from((prop['geo_registry'] ?? {}) as Map? ?? {});
  Map<String, dynamic>? _parseAssessment(dynamic source) {
    if (source is List) {
      for (final dynamic item in source) {
        if (item is Map && item.isNotEmpty) {
          return Map<String, dynamic>.from(item);
        }
      }
    } else if (source is Map && source.isNotEmpty) {
      return Map<String, dynamic>.from(source);
    }
    return null;
  }

  bool _hasAssessmentCollections(Map<String, dynamic> data) {
    bool hasList(dynamic value) => value is List && value.isNotEmpty;
    return hasList(data['categories']) ||
        hasList(data['types']) ||
        hasList(data['values_added']);
  }

  Map<String, dynamic> get _assessmentsObject {
    Map<String, dynamic>? preferred;
    Map<String, dynamic>? fallback;

    void consider(Map<String, dynamic>? candidate) {
      if (candidate == null || candidate.isEmpty) return;
      fallback ??= candidate;
      if (preferred != null) return;
      if (_hasAssessmentCollections(candidate)) {
        preferred = candidate;
      }
    }

    // Prefer populated 'assessments', then 'assessments_object', then nested data
    consider(_parseAssessment(prop['assessments']));
    consider(_parseAssessment(prop['assessments_object']));

    final dynamic data = prop['data'];
    if (data is Map) {
      final dynamic property = data['property'];
      if (property is Map) {
        consider(_parseAssessment(property['assessments']));
        consider(_parseAssessment(property['assessments_object']));
      }
      consider(_parseAssessment(data['assessments']));
      consider(_parseAssessment(data['assessments_object']));
    }

    return preferred ?? fallback ?? <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listOfMaps(dynamic source) {
    final List<dynamic> list = _extractList(source);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _assessmentList(String key) {
    List<Map<String, dynamic>> items = _listOfMaps(_assessmentsObject[key]);
    if (items.isNotEmpty) return items;

    items = _listOfMaps(prop[key]);
    if (items.isNotEmpty) return items;

    final dynamic data = prop['data'];
    if (data is Map) {
      final dynamic property = data['property'];
      if (property is Map) {
        items = _listOfMaps(property[key]);
        if (items.isNotEmpty) return items;
      }
      items = _listOfMaps(data[key]);
      if (items.isNotEmpty) return items;
    }

    return <Map<String, dynamic>>[];
  }

  String _labelFromItem(Map<String, dynamic> item, List<String> preferredKeys) {
    for (final String key in preferredKeys) {
      final dynamic raw = item[key];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    for (final dynamic value in item.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String _joinedLabels(String key, List<String> preferredKeys) {
    final List<Map<String, dynamic>> items = _assessmentList(key);
    if (items.isEmpty) return '—';
    final List<String> labels = items
        .map((item) => _labelFromItem(item, preferredKeys))
        .where((label) => label.isNotEmpty)
        .toList();
    return labels.isEmpty ? '—' : labels.join(', ');
  }

  List<dynamic> _extractList(dynamic source) {
    if (source is List) {
      return List<dynamic>.from(source);
    }

    if (source is String) {
      final String trimmed = source.trim();
      if (trimmed.isEmpty) return <dynamic>[];
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final dynamic decoded = jsonDecode(trimmed);
          if (decoded is List) {
            return List<dynamic>.from(decoded);
          }
        } catch (_) {
          // ignore invalid json
        }
      }
      return <dynamic>[trimmed];
    }

    if (source == null) return <dynamic>[];
    return <dynamic>[source];
  }

  List<dynamic> _extractIds(dynamic source) {
    final List<dynamic> list = _extractList(source);
    final List<dynamic> ids = <dynamic>[];
    for (final dynamic item in list) {
      if (item == null) continue;
      if (item is Map) {
        final dynamic id = item['id'];
        if (id != null) ids.add(id);
      } else {
        ids.add(item);
      }
    }
    return ids;
  }

  List<dynamic> _assessmentIds(String key) {
    List<dynamic> ids = _extractIds(_assessmentsObject[key]);
    if (ids.isNotEmpty) return ids;

    ids = _extractIds(prop[key]);
    if (ids.isNotEmpty) return ids;

    final dynamic data = prop['data'];
    if (data is Map) {
      final dynamic property = data['property'];
      if (property is Map) {
        ids = _extractIds(property[key]);
        if (ids.isNotEmpty) return ids;
      }
      ids = _extractIds(data[key]);
      if (ids.isNotEmpty) return ids;
    }

    return <dynamic>[];
  }

  String _labelsFromListOrIds({
    required String listKey,
    required List<String> preferredKeys,
    String? fallbackIdsKey,
    String? fallbackVariablesKey,
  }) {
    final String labels = _joinedLabels(listKey, preferredKeys);
    if (labels != '—') return labels;

    if (fallbackIdsKey != null && fallbackVariablesKey != null) {
      final List<dynamic> ids = _assessmentIds(fallbackIdsKey);
      if (ids.isNotEmpty) {
        return _labelsFor(fallbackVariablesKey, ids);
      }
    }

    return '—';
  }

  String _joinedIds(String key) {
    final List<String> mapIds = _assessmentList(key)
        .map((item) => item['id'])
        .where((id) => id != null)
        .map((id) => id.toString())
        .toList();
    if (mapIds.isNotEmpty) return mapIds.toString();

    final List<String> ids = _assessmentIds(
      key,
    ).where((id) => id != null).map((id) => id.toString()).toList();
    return ids.isEmpty ? '[]' : ids.toString();
  }

  Map<String, dynamic> get _occupancy {
    final dynamic data = prop['data'];
    final List<dynamic> candidates = <dynamic>[
      prop['occupancy'],
      if (data is Map) data['occupancy'],
      if (data is Map) (data['property'] as Map?)?['occupancy'],
    ];

    for (final dynamic candidate in candidates) {
      if (candidate is Map && candidate.isNotEmpty) {
        return Map<String, dynamic>.from(candidate);
      }
    }

    return <String, dynamic>{};
  }

  List<dynamic> get _occupancies {
    final dynamic direct = prop['occupancies'];
    if (direct is List && direct.isNotEmpty) return direct;

    final dynamic data = prop['data'];
    if (data is Map) {
      final dynamic dataLevel = data['occupancies'];
      if (dataLevel is List && dataLevel.isNotEmpty) return dataLevel;

      final dynamic nested = (data['property'] as Map?)?['occupancies'];
      if (nested is List && nested.isNotEmpty) return nested;
    }

    return const [];
  }

  List<dynamic> get _propertyInaccessible =>
      (prop['property_inaccessible'] as List?) ?? const [];
  List<dynamic> get _registryMeters =>
      (prop['registry_meters'] as List?) ?? const [];

  @override
  void initState() {
    super.initState();
    _loadVariables();
  }

  Future<void> _loadVariables() async {
    if (_loadingVars) return;
    setState(() => _loadingVars = true);
    try {
      // First check if the property data already includes the 'data' object
      if (prop['data'] != null && prop['data'] is Map) {
        setState(() {
          _variables = Map<String, dynamic>.from(prop['data'] as Map);
        });
      } else {
        // Otherwise fetch from API
        final Map<String, dynamic> data = await PropertyService()
            .getAllVariables();
        setState(() {
          _variables = data;
        });
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingVars = false);
    }
  }

  String _labelFor(String dataKey, dynamic id) {
    if (_variables == null || id == null) return _text(id);
    final dynamic list = _variables![dataKey];

    // Handle List format
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

    // Handle Map format (key-value pairs)
    if (list is Map) {
      final String idStr = id.toString();
      if (list.containsKey(idStr)) {
        return list[idStr]?.toString() ?? idStr;
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

  Future<void> _openGoogleMaps(String coordinates) async {
    try {
      // Parse coordinates (format: "lat,long" or "lat, long")
      final String cleanCoords = coordinates.trim().replaceAll(' ', '');
      final List<String> parts = cleanCoords.split(',');

      if (parts.length != 2) {
        ToastService.showError('Invalid coordinates format');
        return;
      }

      final double? lat = double.tryParse(parts[0]);
      final double? lng = double.tryParse(parts[1]);

      if (lat == null || lng == null) {
        ToastService.showError('Invalid coordinates format');
        return;
      }

      // Try map_launcher first (more reliable)
      try {
        final availableMaps = await MapLauncher.installedMaps;

        if (availableMaps.isNotEmpty) {
          // Prefer Google Maps if available
          MapType? preferredMap;
          for (final map in availableMaps) {
            if (map.mapType == MapType.google) {
              preferredMap = map.mapType;
              break;
            }
          }

          // Use preferred map or first available
          final mapToUse = preferredMap ?? availableMaps.first.mapType;

          await MapLauncher.showMarker(
            mapType: mapToUse,
            coords: Coords(lat, lng),
            title: 'Registry Point',
          );
          return; // Success, exit early
        }
      } catch (e) {
        // If map_launcher fails, fall back to url_launcher
        Get.log('map_launcher failed: $e, trying url_launcher...');
      }

      // Fallback to url_launcher with multiple URL formats
      final List<String> urlFormats = [
        // Format 1: Google Maps search URL (web) - recommended format
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        // Format 2: Google Maps app URL (Android/iOS)
        'https://maps.google.com/maps?q=$lat,$lng',
        // Format 3: Geo scheme (native Android)
        'geo:$lat,$lng',
        // Format 4: Google Maps with zoom
        'https://maps.google.com/?q=$lat,$lng&z=15',
      ];

      bool launched = false;
      for (final String urlString in urlFormats) {
        try {
          final Uri url = Uri.parse(urlString);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            launched = true;
            break;
          }
        } catch (_) {
          // Try next format
          continue;
        }
      }

      if (!launched) {
        // Last resort: try with encoded URL (as per Stack Overflow solution)
        try {
          final String encodedUrl = Uri.encodeFull(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
          );
          final Uri url = Uri.parse(encodedUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            launched = true;
          }
        } catch (_) {
          // Ignore
        }
      }

      if (!launched) {
        ToastService.showError(
          'Could not open maps. Please ensure a map application is installed.',
        );
      }
    } catch (e) {
      ToastService.showError('Failed to open map: ${e.toString()}');
    }
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
        final dynamic tId =
            _landlord['ownerTitle'] ?? _landlord['ownerTitle_id'];
        final String lbl = _labelFor('all_titles', tId);
        return (lbl.isEmpty || lbl == 'null') ? _text(tId) : lbl;
      case 'landlord_first_name':
        return _text(_landlord['first_name']);
      case 'landlord_middle_name':
        return _text(_landlord['middle_name']);
      case 'landlord_surname':
        return _text(_landlord['surname']);
      case 'landlord_sex':
        final String sex = _text(_landlord['sex']);
        return sex.toUpperCase() == 'M'
            ? 'M'
            : (sex.toUpperCase() == 'F' ? 'F' : sex);
      case 'landlord_email':
        return _text(_landlord['email']);
      case 'landlord_id_type':
        return _text(_landlord['id_type']);
      case 'landlord_id_number':
        return _text(_landlord['id_number']);
      case 'landlord_street_number':
        return _text(_landlord['street_number']);
      case 'landlord_street_name':
        return _text(_landlord['street_name']);
      case 'landlord_postcode':
        return _text(_landlord['postcode']);
      case 'landlord_ward':
        return _text(_landlord['ward']);
      case 'landlord_constituency':
        return _text(_landlord['constituency']);
      case 'landlord_section':
        return _text(_landlord['section']);
      case 'landlord_chiefdom':
        return _text(_landlord['chiefdom']);
      case 'landlord_district':
        return _text(_landlord['district']);
      case 'landlord_province':
        return _text(_landlord['province']);
      case 'landlord_mobile_1':
        return _text(_landlord['mobile_1'] ?? _landlord['phone_number']);
      case 'landlord_mobile_2':
        return _text(_landlord['mobile_2']);

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
        return _text(_occupancy['tenant_first_name']);
      case 'occupancy_middle_name':
        return _text(_occupancy['middle_name']);
      case 'occupancy_surname':
        return _text(_occupancy['surname']);
      case 'occupancy_mobile_1':
        return _text(_occupancy['mobile_1']);
      case 'occupancy_mobile_2':
        return _text(_occupancy['mobile_2']);
      case 'tenant_ownerTitle_id':
        // Try multiple possible keys for tenant title (ID or label)
        final dynamic tId =
            _occupancy['ownerTenantTitle_id'] ??
            _occupancy['ownerTenantTitle'] ??
            _occupancy['tenant_title'] ??
            _occupancy['tenantTitle'] ??
            _occupancy['title'];
        if (tId == null) return _text(tId);
        final String lbl = _labelFor('all_titles', tId);
        return (lbl.isEmpty || lbl == 'null') ? _text(tId) : lbl;

      // Step 4 - Geo Registry
      case 'registry_digital_address':
        return _text(_geo['digital_address']);
      case 'dor_lat_long':
        return _text(_geo['dor_lat_long']);
      // Step 5 - Assessment (mapped to create form field names)
      case 'assessment_categories_id':
        return _joinedIds('categories');
      case 'property_types':
        return _joinedIds('types');
      case 'assessment_wall_materials_id':
        return _labelFor(
          'property_wall_materials',
          _assessmentsObject['property_wall_materials'],
        );
      case 'assessment_roofs_materials_id':
        return _labelFor(
          'property_roofs_materials',
          _assessmentsObject['roofs_materials'],
        );
      case 'assessment_window_type_id':
        return _labelFor(
          'property_window_types',
          _assessmentsObject['property_window_type'],
        );
      case 'assessment_length':
        return _text(
          _assessmentsObject['assessment_length'] ??
              _assessmentsObject['length'],
        );
      case 'assessment_breadth':
        return _text(
          _assessmentsObject['assessment_breadth'] ??
              _assessmentsObject['breadth'],
        );
      case 'assessment_value_added_id':
        return _joinedIds('values_added');
      case 'assessment_use_id':
        return _labelFor('property_uses', _assessmentsObject['property_use']);
      case 'assessment_zone_id':
        return _labelFor('property_zones', _assessmentsObject['zone']);
      case 'total_mast':
        return _text(_assessmentsObject['no_of_mast']);
      case 'total_shops':
        return _text(_assessmentsObject['no_of_shop']);
      case 'total_compound_house':
        return _text(_assessmentsObject['no_of_compound_house']);
      case 'compound_name':
        return _text(_assessmentsObject['compound_name']);
      case 'gated_community':
        final dynamic gated = _assessmentsObject['gated_community'];
        if (gated == null) return '—';
        return gated.toString() == '0'
            ? 'No'
            : (gated.toString() == '1' ? 'Yes' : gated.toString());
      case 'swimming_pool':
        return _labelFor(
          'swimmings',
          _assessmentsObject['swimming_id'] ??
              _assessmentsObject['swimming_pool'],
        );
      case 'assessment_images_1':
        return _text(_assessmentsObject['assessment_images_1']);
      case 'assessment_images_2':
        return _text(_assessmentsObject['assessment_images_2']);
      default:
        if (key.startsWith('registry_point')) {
          final String idx = key.replaceFirst('registry_point', '');
          return _text(_geo['point$idx']);
        }
        break;
    }
    return '—';
  }

  void _handleEdit() {
    final int step = _step.value;
    switch (step) {
      case 0:
        Get.toNamed(Routes.editLandlord, arguments: prop);
        break;
      case 1:
        Get.toNamed(Routes.editProperty, arguments: prop);
        break;
      case 2:
        Get.toNamed(Routes.editOccupancy, arguments: prop);
        break;
      case 3:
        Get.toNamed(Routes.editGeo, arguments: prop);
        break;
      case 4:
        Get.toNamed(Routes.editAssessment, arguments: prop);
        break;
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        actions: widget.showEditButton
            ? [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: _handleEdit,
                  tooltip: 'Edit',
                ),
              ]
            : null,
      ),
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
                      isLast
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_ios,
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
            SectionCard(
              title: 'Type',
              children: [
                _KV(
                  'Is Organization',
                  _formValue('is_organization') == '1' ? 'Yes' : 'No',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Personal Information',
              children: [
                _KV('Title', _formValue('landlord_ownerTitle_id')),
                _KV('First Name', _formValue('landlord_first_name')),
                _KV('Middle Name', _formValue('landlord_middle_name')),
                _KV('Surname', _formValue('landlord_surname')),
                _KV('Gender', _formValue('landlord_sex')),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Contact',
              children: [
                _KV('Email Address', _formValue('landlord_email')),
                _KV('Mobile 1', _formValue('landlord_mobile_1')),
                _KV('Mobile 2', _formValue('landlord_mobile_2')),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Address',
              children: [
                _KV('Street No', _formValue('landlord_street_number')),
                _KV('Street Name', _formValue('landlord_street_name')),
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
            SectionCard(
              title: 'Category Type',
              children: [
                _KV(
                  'Category Type',
                  _formValue('categoryType') == 'R'
                      ? 'Residential'
                      : 'Commercial',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Address',
              children: [
                _KV('Old Street Number', _formValue('property_street_number')),
                _KV(
                  'New Street Number',
                  _formValue('property_street_numbernew'),
                ),
                _KV('Street Name', _formValue('property_street_name')),
                _KV('Ward', _formValue('property_ward')),
                _KV('Constituency', _formValue('property_constituency')),
                _KV('Section', _formValue('property_section')),
                _KV('Chiefdom', _formValue('property_chiefdom')),
                _KV('District', _formValue('property_district')),
                _KV('Province', _formValue('property_province')),
              ],
            ),
          ],
        );
      case 2:
        // Get occupancy types for chips display
        List<String> _getOccupancyTypes() {
          if (_occupancies.isEmpty) return [];
          return _occupancies
              .whereType<Map>()
              .map((e) => e['occupancy_type']?.toString())
              .where((e) => e != null && e.isNotEmpty)
              .toList()
              .cast<String>();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: 'Occupancy Types',
              children: [
                // Enhanced Selected Types with chips
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: Text(
                          'Selected Types',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _getOccupancyTypes().map((type) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                _KV('Tenant Title', _formValue('tenant_ownerTitle_id')),
                _KV(
                  'Tenant First Name',
                  _formValue('occupancy_tenant_first_name'),
                ),
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
            SectionCard(
              title: 'Digital Address',
              children: [
                _KV('Digital Address', _formValue('registry_digital_address')),
                _KV('Dor Lat Long', _formValue('dor_lat_long')),
                _KV('Open Location Code', _text(_geo['open_location_code'])),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Registry Points',
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 8,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final int p = index + 1;
                    final String pointValue = _formValue('registry_point$p');
                    final bool hasValue =
                        pointValue.isNotEmpty && pointValue != '—';

                    return GestureDetector(
                      onTap: hasValue
                          ? () => _openGoogleMaps(pointValue)
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasValue
                              ? Colors.green.withOpacity(0.05)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasValue
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: hasValue
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: hasValue
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$p',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Point $p',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: hasValue
                                          ? Colors.green.shade700
                                          : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasValue) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.open_in_new,
                                    size: 14,
                                    color: Colors.green.shade700,
                                  ),
                                ],
                              ],
                            ),
                            if (hasValue) ...[
                              const SizedBox(height: 6),
                              Flexible(
                                child: Text(
                                  pointValue,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 6),
                              Text(
                                'Not set',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (_registryMeters.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'Meters',
                children: [
                  Column(
                    children: [
                      for (int i = 0; i < _registryMeters.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < _registryMeters.length - 1 ? 16 : 0,
                          ),
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
                                Text(
                                  'Meter ${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _KV(
                                  'Meter Number',
                                  _text(
                                    (_registryMeters[i] as Map?)?['number'],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Meter Image
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 160,
                                        child: Text(
                                          'Meter Image',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildImageDisplay(
                                          _text(
                                            (_registryMeters[i]
                                                as Map?)?['image'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        );
      default:
        final String categoryLabels = _labelsFromListOrIds(
          listKey: 'categories',
          preferredKeys: const ['label', 'name', 'title', 'category', 'value'],
          fallbackIdsKey: 'assessment_categories_id',
          fallbackVariablesKey: 'property_categories',
        );
        final String typeLabels = _labelsFromListOrIds(
          listKey: 'types',
          preferredKeys: const ['label', 'name', 'title', 'type', 'value'],
          fallbackIdsKey: 'property_types',
          fallbackVariablesKey: 'property_types',
        );
        final List<String> valueAddedLabels = _listLabelsFromListOrIds(
          listKey: 'values_added',
          preferredKeys: const [
            'label',
            'name',
            'title',
            'value_added',
            'value',
          ],
          fallbackIdsKey: 'assessment_value_added_id',
          fallbackVariablesKey: 'property_value_added',
        );

        final List<String> councilAdjustmentLabels = _listLabelsFromListOrIds(
          listKey: 'council_adjustments',
          preferredKeys: const ['label', 'name', 'title', 'type', 'value'],
          fallbackIdsKey: 'newAdjustmentIds',
          fallbackVariablesKey: 'council_adjustments',
        );

        Widget buildChips(List<String> labels) {
          if (labels.isEmpty) return const Text('—');
          return Wrap(
            spacing: 8,
            runSpacing: 4,
            children: labels.map((label) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: 'Summary',
              children: [
                _KV('Property Categories', categoryLabels),
                _KV('Property Types', typeLabels),
                _KV(
                  'Wall Material',
                  _formValue('assessment_wall_materials_id'),
                ),
                _KV(
                  'Roof Material',
                  _formValue('assessment_roofs_materials_id'),
                ),
                _KV('Length', _formValue('assessment_length')),
                _KV('Breadth', _formValue('assessment_breadth')),
                _KVWidget('Value Added', buildChips(valueAddedLabels)),
                if (councilAdjustmentLabels.isNotEmpty)
                  _KVWidget(
                    'Council Adjustments',
                    buildChips(councilAdjustmentLabels),
                  ),
                _KV('Swimming Pool', _formValue('swimming_pool')),
                _KV('Property Use', _formValue('assessment_use_id')),
                _KV('Zones', _formValue('assessment_zone_id')),
                _KV('Gated Community', _formValue('gated_community')),
                // Conditional fields based on Value Added selection
                if (_assessmentIds('assessment_value_added_id').contains('8') ||
                    _assessmentIds('assessment_value_added_id').contains(8))
                  _KV('No of Masts', _formValue('total_mast')),
                if (_assessmentIds('assessment_value_added_id').contains('9') ||
                    _assessmentIds('assessment_value_added_id').contains(9))
                  _KV('No of Shops', _formValue('total_shops')),
                if (_formValue('gated_community') == 'Yes' ||
                    _formValue('gated_community') == '1') ...[
                  _KV(
                    'No of Compound House',
                    _formValue('total_compound_house'),
                  ),
                  _KV('Compound Name', _formValue('compound_name')),
                ],
                // Extra financials for quick context
                _KV('Mill rate', _text(_assessmentsObject['mill_rate'])),
                _KV(
                  'Current year amount',
                  _text(_assessmentsObject['current_year_assessment_amount']),
                ),
                _KV(
                  'Rate without GST',
                  _text(_assessmentsObject['property_rate_without_gst']),
                ),
                _KV(
                  'Rate with GST',
                  _text(_assessmentsObject['property_rate_with_gst']),
                ),
                _KV('GST', _text(_assessmentsObject['property_gst'])),
                _KV('Due', _text(_assessmentsObject['due'])),
                _KV('Balance', _text(_assessmentsObject['balance'])),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Property Images',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Image 1',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _buildImageDisplay(_formValue('assessment_images_1')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Image 2',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _buildImageDisplay(_formValue('assessment_images_2')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
    }
  }

  List<String> _getLabelsList(String key, List<String> preferredKeys) {
    final List<Map<String, dynamic>> items = _assessmentList(key);
    if (items.isEmpty) return [];
    return items
        .map((item) => _labelFromItem(item, preferredKeys))
        .where((label) => label.isNotEmpty)
        .toList();
  }

  List<String> _listLabelsFor(String dataKey, List<dynamic> ids) {
    if (ids.isEmpty) return [];
    final List<String> out = <String>[];
    for (final dynamic v in ids) {
      out.add(_labelFor(dataKey, v));
    }
    return out;
  }

  List<String> _listLabelsFromListOrIds({
    required String listKey,
    required List<String> preferredKeys,
    String? fallbackIdsKey,
    String? fallbackVariablesKey,
  }) {
    final List<String> labels = _getLabelsList(listKey, preferredKeys);
    if (labels.isNotEmpty) return labels;

    if (fallbackIdsKey != null && fallbackVariablesKey != null) {
      final List<dynamic> ids = _assessmentIds(fallbackIdsKey);
      if (ids.isNotEmpty) {
        return _listLabelsFor(fallbackVariablesKey, ids);
      }
    }

    return [];
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
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(v, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

class _KVWidget extends StatelessWidget {
  const _KVWidget(this.k, this.v);
  final String k;
  final Widget v;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(child: v),
        ],
      ),
    );
  }
}

class _HeaderStepper extends StatelessWidget {
  const _HeaderStepper({required this.currentIndex, required this.labels});
  final int currentIndex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(labels.length * 2 - 1, (i) {
              // Connector Line
              if (i.isOdd) {
                final int stepIndex = (i - 1) ~/ 2;
                final bool isCompleted = stepIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 4,
                    color: isCompleted ? Colors.green : Colors.grey.shade200,
                  ),
                );
              }

              // Step Circle
              final int step = i ~/ 2;
              final bool isCompleted = step < currentIndex;
              final bool isActive = step == currentIndex;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : (isActive ? Colors.white : Colors.grey.shade200),
                      border: Border.all(
                        color: isCompleted || isActive
                            ? Colors.green
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${step + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.green
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 8),
          // Labels Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(labels.length, (index) {
              final bool isActive = index == currentIndex;
              final bool isCompleted = index < currentIndex;
              return Expanded(
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive || isCompleted
                        ? (isActive ? Colors.green : Colors.grey.shade700)
                        : Colors.grey.shade400,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
