import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../controllers/property_controller.dart';
import '../../models/property_models.dart';
import 'property_wizard_view.dart';

class PropertyListView extends StatelessWidget {
  const PropertyListView({super.key, this.actions});

  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Properties'), actions: actions),
      body: FutureBuilder<Box<dynamic>>(
        future: Hive.openBox<dynamic>(HiveBoxes.propertyDrafts),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final Box<dynamic> box = snapshot.data!;
          return ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<dynamic> b, _) {
              final List<Map> items = b.values
                  .whereType<Map>()
                  .cast<Map>()
                  .toList();
              if (items.isEmpty) {
                return const Center(child: Text('No properties yet'));
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final Map draft = items[index];
                    final String id = (draft[PropertyDraftKeys.id] ?? '')
                        .toString();
                    final String status =
                        draft[PropertyDraftKeys.status] ??
                        PropertyDraftStatus.draft;
                    final Map<String, dynamic>? files =
                        (draft[PropertyDraftKeys.files] as Map?)
                            ?.cast<String, dynamic>();
                    final List<String> photos = List<String>.from(
                      files?['assessmentPhotos'] ?? <String>[],
                    );
                    final String? cover =
                        photos.isNotEmpty && File(photos.first).existsSync()
                        ? photos.first
                        : null;
                    final String title =
                        (draft[PropertyDraftKeys
                                    .payload]?['landlord_street_name'] ??
                                'Draft')
                            .toString();

                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.hardEdge,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: cover == null
                                ? Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(
                                        Icons.home_filled,
                                        size: 42,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  )
                                : Image.file(
                                    File(cover),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 6.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color:
                                          status == PropertyDraftStatus.synced
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (status == PropertyDraftStatus.synced)
                                      const Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.green,
                                      )
                                    else
                                      const Icon(
                                        Icons.cloud_upload,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: $id',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
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
