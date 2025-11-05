import 'dart:async';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/property_models.dart';
import 'property_service.dart';

class SyncService {
  SyncService._();
  static final SyncService _i = SyncService._();
  factory SyncService() => _i;

  Future<void> syncAll() async {
    final Box<dynamic> drafts = await Hive.openBox<dynamic>(HiveBoxes.propertyDrafts);
    final List<dynamic> items = drafts.values.toList();
    for (final dynamic raw in items) {
      if (raw is! Map) continue;
      final Map draft = raw;
      if (draft[PropertyDraftKeys.status] == PropertyDraftStatus.synced) continue;
      try {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(draft[PropertyDraftKeys.payload] as Map);
        final Map<String, dynamic> files = Map<String, dynamic>.from(draft[PropertyDraftKeys.files] as Map);
        await PropertyService().savePropertyMultipart(
          fields: payload,
          registryItems: Map<String, dynamic>.from(files['registry'] as Map),
          assessmentImagePaths: List<String>.from(files['assessmentPhotos'] as List),
        );
        draft[PropertyDraftKeys.status] = PropertyDraftStatus.synced;
        await drafts.put(draft[PropertyDraftKeys.id], draft);
      } catch (e) {
        Get.log('Sync failed: $e');
        draft[PropertyDraftKeys.status] = PropertyDraftStatus.queued;
        draft[PropertyDraftKeys.lastError] = e.toString();
        await drafts.put(draft[PropertyDraftKeys.id], draft);
      }
    }
  }
}


