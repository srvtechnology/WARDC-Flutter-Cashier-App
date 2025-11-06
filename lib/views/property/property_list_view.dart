import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/property_controller.dart';
import 'property_wizard_view.dart';

class PropertyListView extends StatelessWidget {
  const PropertyListView({super.key, this.actions});

  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Properties'), actions: actions),
      body: const Center(child: Text('Tap + to create a new property')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Get.put(PropertyController());
          Get.to(() => const PropertyWizardView());
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
