import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/property_controller.dart';
import '../../controllers/property_list_controller.dart';
import '../../services/auth_service.dart';
import '../../routes/app_pages.dart';
import '../property/property_list_view.dart';
import '../property/property_wizard_view.dart';
import '../profile/user_profile_view.dart';

class AssessmentDashboardView extends StatelessWidget {
  const AssessmentDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assessment Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Search Icon Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded, size: 22),
            ),
            onPressed: () {
              Get.toNamed(Routes.propertySearch);
            },
            tooltip: 'Search properties',
          ),
          // View Toggle Button
          Obx(() {
            final controller = Get.put(PropertyListController());
            return IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.isGridView.value
                      ? Icons.list_rounded
                      : Icons.grid_view_rounded,
                  size: 22,
                ),
              ),
              onPressed: controller.toggleViewMode,
              tooltip: controller.isGridView.value
                  ? 'Switch to List View'
                  : 'Switch to Grid View',
            );
          }),
          // Profile Avatar Button
          FutureBuilder<Map<String, dynamic>>(
            future: _getUserInitials(authService),
            builder: (context, snapshot) {
              final initials = snapshot.data?['initials'] ?? 'U';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.to(() => const UserProfileView()),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: const PropertyListView(useScaffold: false),
      floatingActionButton: Builder(
        builder: (context) {
          // Ensure controller is initialized
          Get.put(PropertyListController());
          return FloatingActionButton.extended(
            onPressed: () async {
              final controller = Get.find<PropertyListController>();
              Get.put(PropertyController());
              final result = await Get.to(() => const PropertyWizardView());
              if (result == true) {
                await controller.refreshProperties();
              }
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 4,
            highlightElevation: 8,
            tooltip: 'Add New Property',
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            label: const Text(
              'New Property',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<Map<String, dynamic>> _getUserInitials(AuthService authService) async {
    try {
      // Try to get user data from API
      final userData = await authService.getUserData();
      if (userData['userData'] != null) {
        final name = userData['userData']?['name']?.toString() ?? '';
        if (name.isNotEmpty) {
          return {'initials': _getInitialsFromName(name), 'name': name};
        }
      }
    } catch (e) {
      // If API fails, fallback to saved email
    }

    // Fallback to email-based initials
    final email = await authService.getSavedUserEmail();
    return {
      'initials': _getInitialsFromEmail(email ?? ''),
      'name': email ?? '',
    };
  }

  String _getInitialsFromName(String name) {
    if (name.isEmpty) return 'U';
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'U';
    // Get first letter of the first word
    final firstChar = trimmedName[0].toUpperCase();
    return firstChar;
  }

  String _getInitialsFromEmail(String email) {
    if (email.isEmpty) return 'U';
    final parts = email.split('@');
    if (parts.isEmpty) return 'U';
    final name = parts[0];
    if (name.isEmpty) return 'U';
    if (name.length == 1) return name.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }
}
