// Lightweight models for property drafts and variables.
// We store plain Map<String, dynamic> objects in Hive to avoid codegen.

class PropertyDraftStatus {
  static const String draft = 'draft';
  static const String queued = 'queued';
  static const String synced = 'synced';
}

class PropertyDraftKeys {
  static const String id = 'randomdata';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String payload = 'payload'; // Map<String, dynamic>
  static const String files = 'files'; // Map<String, String> path per key
  static const String status = 'status';
  static const String lastError = 'lastError';
}

class HiveBoxes {
  static const String propertyDrafts = 'propertyDrafts';
  static const String syncQueue = 'syncQueue';
  static const String variablesCache = 'variablesCache';
}


