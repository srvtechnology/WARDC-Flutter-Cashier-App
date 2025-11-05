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
  ];
}

