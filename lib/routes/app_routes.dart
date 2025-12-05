// This file is part of app_pages.dart
// lib/routes/app_routes.dart

part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const onboarding = '/onboarding';
  static const home = '/home';
  static const assessmentDashboard = '/assessment-dashboard';

  static const propertyList = '/property-list';
  static const propertyWizard = '/property-wizard';
  static const editLandlord = '/edit-landlord';
  static const editProperty = '/edit-property';
  static const editOccupancy = '/edit-occupancy';
  static const editGeo = '/edit-geo';
  static const editAssessment = '/edit-assessment';
  static const userProfile = '/user-profile';
  static const propertySearch = '/property-search';
  static const paymentSearch = '/payment-search';
}
