// lib/routes/app_pages.dart

import 'package:get/get.dart';
import '../bindings/home_binding.dart';
import '../bindings/onboarding_binding.dart';
import '../views/home/home_view.dart';
import '../views/onboarding/onboarding_view.dart';
import '../views/dashboard/assessment_dashboard_view.dart';
import '../views/dashboard/cashier_dashboard_view.dart';
import '../views/property/property_list_view.dart';
import '../views/property/property_wizard_view.dart';
import '../views/property/edit_landlord_view.dart';
import '../views/property/edit_property_view.dart';
import '../views/property/edit_occupancy_view.dart';
import '../views/property/edit_geo_view.dart';
import '../views/property/edit_assessment_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.onboarding;

  static final routes = [
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.assessmentDashboard,
      page: () => const AssessmentDashboardView(),
    ),
    GetPage(
      name: Routes.cashierDashboard,
      page: () => const CashierDashboardView(),
    ),
    GetPage(
      name: Routes.propertyList,
      page: () => const PropertyListView(),
    ),
    GetPage(
      name: Routes.propertyWizard,
      page: () => const PropertyWizardView(),
    ),
    GetPage(
      name: Routes.editLandlord,
      page: () {
        final property = Get.arguments as Map<String, dynamic>;
        return EditLandlordView(property: property);
      },
    ),
    GetPage(
      name: Routes.editProperty,
      page: () {
        final property = Get.arguments as Map<String, dynamic>;
        return EditPropertyView(property: property);
      },
    ),
    GetPage(
      name: Routes.editOccupancy,
      page: () {
        final property = Get.arguments as Map<String, dynamic>;
        return EditOccupancyView(property: property);
      },
    ),
    GetPage(
      name: Routes.editGeo,
      page: () {
        final property = Get.arguments as Map<String, dynamic>;
        return EditGeoView(property: property);
      },
    ),
    GetPage(
      name: Routes.editAssessment,
      page: () {
        final property = Get.arguments as Map<String, dynamic>;
        return EditAssessmentView(property: property);
      },
    ),
  ];
}

