// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'theme/app_theme.dart';
import 'utils/api_config.dart';

void main() {
  // Configure API environment
  // Set to Environment.development for dev, Environment.production for prod
  // Default is production (https://wardc.srvtechnology.com/public/api/)
  ApiConfig.setEnvironment(Environment.production);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Western Area Rural District Council',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode
          .system, // Can be changed to ThemeMode.light or ThemeMode.dark
      // Routing Configuration
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,

      // GetX Configuration
      defaultTransition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 400),

      // Global Configuration
      locale: const Locale(
        'en',
        'US',
      ), // Can be changed based on user preference
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
