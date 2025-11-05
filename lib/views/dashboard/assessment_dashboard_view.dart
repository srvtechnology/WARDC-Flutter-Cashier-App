import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_pages.dart';
import '../../services/auth_service.dart';
import '../property/property_list_view.dart';

class AssessmentDashboardView extends StatelessWidget {
  const AssessmentDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return PropertyListView(
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await AuthService().logout();
            Get.offAllNamed(Routes.onboarding);
          },
        )
      ],
    );
  }
}


