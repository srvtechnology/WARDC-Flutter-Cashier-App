import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/property_controller.dart';
import '../../controllers/property_list_controller.dart';
import 'property_wizard_view.dart';
import 'property_details_view.dart';
import '../../utils/api_config.dart';

class PropertyListView extends StatelessWidget {
  const PropertyListView({
    super.key,
    this.actions,
    this.appBar,
    this.useScaffold = true,
  });

  final List<Widget>? actions;
  final PreferredSizeWidget? appBar;
  final bool useScaffold;

  Widget _buildBody(PropertyListController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.properties.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _ErrorView(
          errorMessage: controller.errorMessage.value,
          onRetry: () => controller.refreshProperties(),
        );
      }

      if (controller.properties.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No properties found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to create a new property',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Properties',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    'Page ${controller.currentPage.value}/${controller.totalPages.value}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Colors.grey.shade200),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.refreshProperties(),
                child: controller.isGridView.value
                    ? GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount:
                            controller.properties.length +
                            (controller.hasMore.value ? 1 : 0),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemBuilder: (context, index) {
                          if (index == controller.properties.length) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final property = controller.properties[index];

                          if (index == controller.properties.length - 3 &&
                              controller.hasMore.value &&
                              !controller.isLoadingMore.value) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              controller.loadMore();
                            });
                          }

                          return _PropertyGridItem(property: property);
                        },
                      )
                    : ListView.builder(
                        itemCount:
                            controller.properties.length +
                            (controller.hasMore.value ? 1 : 0),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemBuilder: (context, index) {
                          if (index == controller.properties.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final property = controller.properties[index];

                          if (index == controller.properties.length - 3 &&
                              controller.hasMore.value &&
                              !controller.isLoadingMore.value) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              controller.loadMore();
                            });
                          }

                          return _PropertyListItem(property: property);
                        },
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFloatingActionButton(PropertyListController controller) {
    return FloatingActionButton(
      backgroundColor: Colors.green,
      onPressed: () async {
        Get.put(PropertyController());
        final result = await Get.to(() => const PropertyWizardView());
        if (result == true) {
          await controller.refreshProperties();
        }
      },
      child: const Icon(Icons.add, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PropertyListController controller = Get.put(PropertyListController());

    final body = _buildBody(controller);
    final fab = _buildFloatingActionButton(controller);
    final defaultAppBar = AppBar(
      title: const Text('Properties'),
      actions: actions,
    );
    final preferredAppBar = appBar ?? defaultAppBar;

    if (useScaffold) {
      return Scaffold(
        appBar: preferredAppBar,
        body: body,
        floatingActionButton: fab,
      );
    } else {
      // When not using Scaffold, return body only (parent handles AppBar and FAB)
      return body;
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.errorMessage, required this.onRetry});

  final String errorMessage;
  final VoidCallback onRetry;

  String _getErrorTitle() {
    final msg = errorMessage.toLowerCase();
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'Connection Timeout';
    }
    if (msg.contains('internet') ||
        msg.contains('network') ||
        msg.contains('connection')) {
      return 'No Internet Connection';
    }
    if (msg.contains('server') ||
        msg.contains('500') ||
        msg.contains('502') ||
        msg.contains('503')) {
      return 'Server Error';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return 'Resource Not Found';
    }
    if (msg.contains('401') ||
        msg.contains('403') ||
        msg.contains('unauthorized') ||
        msg.contains('forbidden')) {
      return 'Authentication Error';
    }
    return 'Something Went Wrong';
  }

  String _getErrorDescription() {
    final msg = errorMessage.toLowerCase();
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'The request took too long to complete. Please check your connection and try again.';
    }
    if (msg.contains('internet') ||
        msg.contains('network') ||
        msg.contains('connection')) {
      return 'Please check your internet connection and ensure you have a stable network.';
    }
    if (msg.contains('server') ||
        msg.contains('500') ||
        msg.contains('502') ||
        msg.contains('503')) {
      return 'Our servers are experiencing issues. Please try again in a few moments.';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return 'The requested resource could not be found. It may have been moved or deleted.';
    }
    if (msg.contains('401') ||
        msg.contains('403') ||
        msg.contains('unauthorized') ||
        msg.contains('forbidden')) {
      return 'You don\'t have permission to access this resource. Please sign in again.';
    }
    return 'We encountered an unexpected error while loading your properties. Please try again.';
  }

  IconData _getErrorIcon() {
    final msg = errorMessage.toLowerCase();
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return Icons.timer_off_outlined;
    }
    if (msg.contains('internet') ||
        msg.contains('network') ||
        msg.contains('connection')) {
      return Icons.wifi_off_outlined;
    }
    if (msg.contains('server') ||
        msg.contains('500') ||
        msg.contains('502') ||
        msg.contains('503')) {
      return Icons.cloud_off_outlined;
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return Icons.search_off_outlined;
    }
    if (msg.contains('401') ||
        msg.contains('403') ||
        msg.contains('unauthorized') ||
        msg.contains('forbidden')) {
      return Icons.lock_outline;
    }
    return Icons.error_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final errorTitle = _getErrorTitle();
    final errorDescription = _getErrorDescription();
    final errorIcon = _getErrorIcon();

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon Container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(errorIcon, size: 64, color: Colors.red.shade400),
              ),
              const SizedBox(height: 32),

              // Error Title
              Text(
                errorTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Error Description
              Text(
                errorDescription,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Error Details Card
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            errorMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Retry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Action
              TextButton(
                onPressed: () {
                  // Optionally navigate back or show more options
                  Get.back();
                },
                child: Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyListItem extends StatelessWidget {
  const _PropertyListItem({required this.property});

  final dynamic property;

  Map<String, dynamic>? get _propertyMap {
    if (property is Map) {
      return Map<String, dynamic>.from(property);
    }
    return null;
  }

  String _getPropertyId() {
    final prop = _propertyMap;
    if (prop == null) return 'N/A';
    return prop['id']?.toString() ??
        prop['property_id']?.toString() ??
        prop['propertyId']?.toString() ??
        'N/A';
  }

  String _getPropertyAddress() {
    final prop = _propertyMap;
    if (prop == null) return 'No address';

    final String? streetNumber =
        prop['property_street_number']?.toString() ??
        prop['street_number']?.toString();
    final String? streetName =
        prop['property_street_name']?.toString() ??
        prop['street_name']?.toString();
    final String? ward =
        prop['property_ward']?.toString() ?? prop['ward']?.toString();
    final String? section =
        prop['property_section']?.toString() ?? prop['section']?.toString();

    final List<String> addressParts = [];
    if (streetNumber != null && streetNumber.isNotEmpty) {
      addressParts.add(streetNumber);
    }
    if (streetName != null && streetName.isNotEmpty) {
      addressParts.add(streetName);
    }
    if (section != null && section.isNotEmpty) {
      addressParts.add(section);
    }
    if (ward != null && ward.isNotEmpty) {
      addressParts.add('Ward $ward');
    }

    if (addressParts.isNotEmpty) {
      return addressParts.join(', ');
    }

    return prop['address']?.toString() ??
        prop['property_address']?.toString() ??
        'No address';
  }

  String _getLandlordName() {
    final prop = _propertyMap;
    if (prop == null) return 'Unknown';

    // Try to get landlord from nested 'landlord' map first
    final dynamic landlordRaw = prop['landlord'];
    Map<String, dynamic>? landlord;
    if (landlordRaw is Map) {
      landlord = Map<String, dynamic>.from(landlordRaw);
    }

    // Also check for organization name if it's an organization
    if (landlord != null) {
      final bool isOrganization =
          landlord['is_organization'] == true ||
          landlord['is_organization'] == 1 ||
          landlord['is_organization'] == '1';

      if (isOrganization) {
        final String? orgName = landlord['organization_name']?.toString();
        if (orgName != null && orgName.isNotEmpty) {
          return orgName;
        }
      }
    }

    // Get name parts from nested landlord map or direct property fields
    final String? firstName =
        landlord?['first_name']?.toString() ??
        prop['landlord_first_name']?.toString() ??
        prop['first_name']?.toString();
    final String? middleName =
        landlord?['middle_name']?.toString() ??
        prop['landlord_middle_name']?.toString() ??
        prop['middle_name']?.toString();
    final String? surname =
        landlord?['surname']?.toString() ??
        prop['landlord_surname']?.toString() ??
        prop['surname']?.toString() ??
        prop['last_name']?.toString();

    final List<String> nameParts = [];
    if (firstName != null && firstName.isNotEmpty) nameParts.add(firstName);
    if (middleName != null && middleName.isNotEmpty) nameParts.add(middleName);
    if (surname != null && surname.isNotEmpty) nameParts.add(surname);

    if (nameParts.isNotEmpty) {
      return nameParts.join(' ');
    }

    // Fallback to other possible fields
    return landlord?['landlord_name']?.toString() ??
        prop['landlord_name']?.toString() ??
        landlord?['owner_name']?.toString() ??
        prop['owner_name']?.toString() ??
        landlord?['name']?.toString() ??
        prop['name']?.toString() ??
        'Unknown';
  }

  String? _getCategoryType() {
    final prop = _propertyMap;
    if (prop == null) return null;
    return prop['categoryType']?.toString() ??
        prop['category_type']?.toString() ??
        prop['category']?.toString();
  }

  String? _getMobile() {
    final prop = _propertyMap;
    if (prop == null) return null;
    return prop['landlord_mobile_1']?.toString() ??
        prop['mobile_1']?.toString() ??
        prop['mobile']?.toString() ??
        prop['phone']?.toString();
  }

  String? _getThumbnailUrl() {
    final prop = _propertyMap;
    if (prop == null) return null;

    // Helper to get first item from list
    Map<String, dynamic>? getFirst(dynamic list) {
      if (list is List && list.isNotEmpty) {
        final item = list[0];
        if (item is Map) return Map<String, dynamic>.from(item);
      }
      return null;
    }

    // Try to find assessment object
    Map<String, dynamic>? assessment;

    // 1. Try direct assessments_object
    assessment = getFirst(prop['assessments_object']);

    // 2. Try direct assessments
    if (assessment == null) {
      assessment = getFirst(prop['assessments']);
    }

    // 3. Try nested in data
    if (assessment == null && prop['data'] is Map) {
      final data = prop['data'];
      if (data['property'] is Map) {
        assessment = getFirst(data['property']['assessments_object']);
        if (assessment == null) {
          assessment = getFirst(data['property']['assessments']);
        }
      }
    }

    if (assessment != null) {
      // Try image 1
      String? img = assessment['assessment_images_1']?.toString();
      if (img != null && img.isNotEmpty) return img;

      // Try image 2
      img = assessment['assessment_images_2']?.toString();
      if (img != null && img.isNotEmpty) return img;

      // Try singular keys just in case
      img = assessment['assessment_image_1']?.toString();
      if (img != null && img.isNotEmpty) return img;

      img = assessment['assessment_image_2']?.toString();
      if (img != null && img.isNotEmpty) return img;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categoryType = _getCategoryType();
    final mobile = _getMobile();
    final thumbnailUrl = _getThumbnailUrl();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final map = _propertyMap ?? <String, dynamic>{};
            Get.to(() => PropertyDetailsView(property: map));
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property icon or image
                Stack(
                  children: [
                    if (thumbnailUrl != null)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                          ),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                            ApiConfig.getImageUrl(thumbnailUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.home,
                                color: Colors.green[700],
                                size: 26,
                              );
                            },
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.green.withOpacity(0.12),
                        child: Icon(
                          Icons.home,
                          color: Colors.green[700],
                          size: 26,
                        ),
                      ),
                    if (categoryType != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryType == 'R'
                                ? Colors.blue
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            categoryType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Property details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Property #${_getPropertyId()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getPropertyAddress(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getLandlordName(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (mobile != null && mobile.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              mobile,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyGridItem extends StatelessWidget {
  const _PropertyGridItem({required this.property});

  final dynamic property;

  // Reuse helper methods from _PropertyListItem by composition or duplication
  // For simplicity, duplicating the logic here as they are private methods in another class
  // ideally these should be in a mixin or helper class

  Map<String, dynamic>? get _propertyMap {
    if (property is Map) {
      return Map<String, dynamic>.from(property);
    }
    return null;
  }

  String _getPropertyId() {
    final prop = _propertyMap;
    if (prop == null) return 'N/A';
    return prop['id']?.toString() ??
        prop['property_id']?.toString() ??
        prop['propertyId']?.toString() ??
        'N/A';
  }

  String _getPropertyAddress() {
    final prop = _propertyMap;
    if (prop == null) return 'No address';

    final String? streetNumber =
        prop['property_street_number']?.toString() ??
        prop['street_number']?.toString();
    final String? streetName =
        prop['property_street_name']?.toString() ??
        prop['street_name']?.toString();
    final String? ward =
        prop['property_ward']?.toString() ?? prop['ward']?.toString();
    final String? section =
        prop['property_section']?.toString() ?? prop['section']?.toString();

    final List<String> addressParts = [];
    if (streetNumber != null && streetNumber.isNotEmpty) {
      addressParts.add(streetNumber);
    }
    if (streetName != null && streetName.isNotEmpty) {
      addressParts.add(streetName);
    }
    if (section != null && section.isNotEmpty) {
      addressParts.add(section);
    }
    if (ward != null && ward.isNotEmpty) {
      addressParts.add('Ward $ward');
    }

    if (addressParts.isNotEmpty) {
      return addressParts.join(', ');
    }

    return prop['address']?.toString() ??
        prop['property_address']?.toString() ??
        'No address';
  }

  String _getLandlordName() {
    final prop = _propertyMap;
    if (prop == null) return 'Unknown';

    final dynamic landlordRaw = prop['landlord'];
    Map<String, dynamic>? landlord;
    if (landlordRaw is Map) {
      landlord = Map<String, dynamic>.from(landlordRaw);
    }

    if (landlord != null) {
      final bool isOrganization =
          landlord['is_organization'] == true ||
          landlord['is_organization'] == 1 ||
          landlord['is_organization'] == '1';

      if (isOrganization) {
        final String? orgName = landlord['organization_name']?.toString();
        if (orgName != null && orgName.isNotEmpty) {
          return orgName;
        }
      }
    }

    final String? firstName =
        landlord?['first_name']?.toString() ??
        prop['landlord_first_name']?.toString() ??
        prop['first_name']?.toString();
    final String? middleName =
        landlord?['middle_name']?.toString() ??
        prop['landlord_middle_name']?.toString() ??
        prop['middle_name']?.toString();
    final String? surname =
        landlord?['surname']?.toString() ??
        prop['landlord_surname']?.toString() ??
        prop['surname']?.toString() ??
        prop['last_name']?.toString();

    final List<String> nameParts = [];
    if (firstName != null && firstName.isNotEmpty) nameParts.add(firstName);
    if (middleName != null && middleName.isNotEmpty) nameParts.add(middleName);
    if (surname != null && surname.isNotEmpty) nameParts.add(surname);

    if (nameParts.isNotEmpty) {
      return nameParts.join(' ');
    }

    return landlord?['landlord_name']?.toString() ??
        prop['landlord_name']?.toString() ??
        landlord?['owner_name']?.toString() ??
        prop['owner_name']?.toString() ??
        landlord?['name']?.toString() ??
        prop['name']?.toString() ??
        'Unknown';
  }

  String? _getCategoryType() {
    final prop = _propertyMap;
    if (prop == null) return null;
    return prop['categoryType']?.toString() ??
        prop['category_type']?.toString() ??
        prop['category']?.toString();
  }

  String? _getThumbnailUrl() {
    final prop = _propertyMap;
    if (prop == null) return null;

    Map<String, dynamic>? getFirst(dynamic list) {
      if (list is List && list.isNotEmpty) {
        final item = list[0];
        if (item is Map) return Map<String, dynamic>.from(item);
      }
      return null;
    }

    Map<String, dynamic>? assessment;
    assessment = getFirst(prop['assessments_object']);
    if (assessment == null) {
      assessment = getFirst(prop['assessments']);
    }
    if (assessment == null && prop['data'] is Map) {
      final data = prop['data'];
      if (data['property'] is Map) {
        assessment = getFirst(data['property']['assessments_object']);
        if (assessment == null) {
          assessment = getFirst(data['property']['assessments']);
        }
      }
    }

    if (assessment != null) {
      String? img = assessment['assessment_images_1']?.toString();
      if (img != null && img.isNotEmpty) return img;

      img = assessment['assessment_images_2']?.toString();
      if (img != null && img.isNotEmpty) return img;

      img = assessment['assessment_image_1']?.toString();
      if (img != null && img.isNotEmpty) return img;

      img = assessment['assessment_image_2']?.toString();
      if (img != null && img.isNotEmpty) return img;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categoryType = _getCategoryType();
    final thumbnailUrl = _getThumbnailUrl();

    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final map = _propertyMap ?? <String, dynamic>{};
            Get.to(() => PropertyDetailsView(property: map));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                      child: thumbnailUrl != null
                          ? Image.network(
                              ApiConfig.getImageUrl(thumbnailUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.green.withOpacity(0.1),
                                  child: Icon(
                                    Icons.home,
                                    color: Colors.green[700],
                                    size: 40,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.green.withOpacity(0.1),
                              child: Icon(
                                Icons.home,
                                color: Colors.green[700],
                                size: 40,
                              ),
                            ),
                    ),
                    if (categoryType != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: categoryType == 'R'
                                ? Colors.blue
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            categoryType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Details Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${_getPropertyId()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getPropertyAddress(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getLandlordName(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
