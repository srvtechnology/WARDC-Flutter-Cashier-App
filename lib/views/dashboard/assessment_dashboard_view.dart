import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_pages.dart';
import '../../services/auth_service.dart';

class AssessmentDashboardView extends StatelessWidget {
  const AssessmentDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Officer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              Get.offAllNamed(Routes.onboarding);
            },
          ),
        ],
      ),
      body: const Center(child: Text('Assessment Officer Dashboard')),
    );
  }
}


