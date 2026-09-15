import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' show Get;
import '../services/auth_service.dart';
import '../utils/api_config.dart';
import '../utils/api_logger.dart';

class PropertyService {
  PropertyService._() {
    _dio.interceptors.add(ApiLoggerInterceptor());
    _updateDio.interceptors.add(ApiLoggerInterceptor());
  }
  static final PropertyService _instance = PropertyService._();
  factory PropertyService() => _instance;

  final dio.Dio _dio = dio.Dio(
    dio.BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      contentType: ApiConfig.contentType,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
    ),
  );

  Future<Map<String, dynamic>> getAllVariables() async {
    try {
      // The endpoint returns a wrapper {status, message, data: {...}}.
      // We normalize it here to return only the inner "data" map so that
      // UI consumers can directly read keys like 'property_categories',
      // 'ward', 'constituency', etc.
      final dio.Response<dynamic> res = await _dio.get(
        '/get-all-variable-datas',
      );
      final Map<String, dynamic> body = _cast(res.data);
      final Map<String, dynamic> inner = _cast(body['data']);
      return inner;
    } on dio.DioException catch (e) {
      throw AuthException(_mapDioError(e));
    }
  }

  Future<List<String>> getAllWards() async {
    try {
      final dio.Response<dynamic> res = await _dio.get('/all-wards');
      final Map<String, dynamic> body = _cast(res.data);
      if (body['wards'] is List) {
        return List<String>.from(body['wards']);
      }
      return [];
    } on dio.DioException catch (e) {
      Get.log('Failed to fetch wards: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> filterByWard(String wardId) async {
    try {
      final dio.Response<dynamic> res = await _dio.get(
        '/filter-by-ward/$wardId',
      );
      return _cast(res.data);
    } on dio.DioException catch (e) {
      Get.log('Failed to filter by ward: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getPropertyListing({
    int page = 1,
    int limit = 10,
  }) async {
    final String? token = await AuthService().getToken();

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    try {
      final dio.Response<dynamic> res = await _dio.get(
        '/admin/property-listing',
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          'mobile_app': 'yes',
        },
        options: options,
      );
      final Map<String, dynamic> response = _cast(res.data);

      return response;
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Property listing failed: $msg');
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> searchByPropertyId({
    required String propertyId,
    int page = 1,
    int limit = 10,
  }) async {
    final String? token = await AuthService().getToken();

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    try {
      final dio.Response<dynamic> res = await _dio.get(
        '/admin/property-listing',
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          'property_id': propertyId,
          'mobile_app': 'yes',
        },
        options: options,
      );
      final Map<String, dynamic> response = _cast(res.data);

      return response;
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Property search failed: $msg');
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> searchPayment({
    required Map<String, dynamic> searchData,
  }) async {
    final String? token = await AuthService().getToken();

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    try {
      Get.log('Payment search request: $searchData');
      final dio.Response<dynamic> res = await _dio.post(
        '/payment-search',
        data: searchData,
        options: options,
      );
      final Map<String, dynamic> response = _cast(res.data);
      Get.log('Payment search response: $response');
      return response;
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Payment search failed: $msg');
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> submitPayment({
    required Map<String, dynamic> payload,
  }) async {
    final String? token = await AuthService().getToken();

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    try {
      Get.log('Payment submit request: $payload');
      final dio.Response<dynamic> res = await _dio.post(
        '/payment-insert',
        data: payload,
        options: options,
      );
      final Map<String, dynamic> response = _cast(res.data);
      Get.log('Payment submit response: $response');
      return response;
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Payment submit failed: $msg');
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> getPropertyDetails({
    required String propertyId,
  }) async {
    final String? token = await AuthService().getToken();

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    try {
      Get.log('Property details request: $propertyId');
      final dio.Response<dynamic> res = await _dio.post(
        '/property/details',
        data: {'property_id': propertyId},
        options: options,
      );
      final Map<String, dynamic> response = _cast(res.data);
      Get.log('Property details response: $response');
      return response;
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Property details failed: $msg');
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> savePropertyMultipart({
    required Map<String, dynamic> fields,
    Map<String, dynamic>?
    registryItems, // index -> {meter_number, meter_image: path}
    List<String>?
    assessmentImagePaths, // ['path1','path2'] mapped to assessment_images_1,2
  }) async {
    final String? token = await AuthService().getToken();

    final dio.FormData formData = dio.FormData();

    // Add primitives and arrays as strings (backend expects strings/arrays)
    fields.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        for (final v in value) {
          formData.fields.add(MapEntry('$key[]', v.toString()));
        }
      } else {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    // Registry meters
    if (registryItems != null) {
      for (final MapEntry<String, dynamic> entry in registryItems.entries) {
        final String idx = entry.key;
        final dynamic item = entry.value;
        if (item is Map<String, dynamic>) {
          final String? number = item['meter_number']?.toString();
          final String? imagePath = item['meter_image']?.toString();
          if (number != null) {
            formData.fields.add(
              MapEntry('registry[$idx][meter_number]', number),
            );
          }
          if (imagePath != null &&
              imagePath.isNotEmpty &&
              File(imagePath).existsSync()) {
            formData.files.add(
              MapEntry(
                'registry[$idx][meter_image]',
                await dio.MultipartFile.fromFile(
                  imagePath,
                  filename: _fileName(imagePath),
                ),
              ),
            );
          }
        }
      }
    }

    // Assessment images
    if (assessmentImagePaths != null) {
      for (int i = 0; i < assessmentImagePaths.length; i++) {
        final String p = assessmentImagePaths[i];
        if (p.isEmpty || !File(p).existsSync()) continue;
        formData.files.add(
          MapEntry(
            'assessment_images_${i + 1}',
            await dio.MultipartFile.fromFile(p, filename: _fileName(p)),
          ),
        );
      }
    }

    // Delivered proof image (optional)
    final String? deliveredImagePath =
        fields['delivered_image_path'] as String?;
    if (deliveredImagePath != null &&
        deliveredImagePath.isNotEmpty &&
        File(deliveredImagePath).existsSync()) {
      formData.files.add(
        MapEntry(
          'delivered_image',
          await dio.MultipartFile.fromFile(
            deliveredImagePath,
            filename: _fileName(deliveredImagePath),
          ),
        ),
      );
    }

    // Property Inaccessible Image
    final String? inaccessibleImagePath =
        fields['property_inaccessible_image'] as String?;
    if (inaccessibleImagePath != null &&
        inaccessibleImagePath.isNotEmpty &&
        File(inaccessibleImagePath).existsSync()) {
      formData.files.add(
        MapEntry(
          'property_inaccessible_image',
          await dio.MultipartFile.fromFile(
            inaccessibleImagePath,
            filename: _fileName(inaccessibleImagePath),
          ),
        ),
      );
    }

    // Log the complete FormData structure
    _logFormData(formData, fields, registryItems, assessmentImagePaths);

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      contentType: 'multipart/form-data',
    );

    try {
      final dio.Response<dynamic> res = await _dio.post(
        '/property/save',
        data: formData,
        options: options,
      );
      return _cast(res.data);
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Property save failed: $msg');
      throw AuthException(msg);
    }
  }

  Map<String, dynamic> _cast(dynamic d) {
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    return <String, dynamic>{};
  }

  // Dio instance for update APIs - uses same base URL as main API
  final dio.Dio _updateDio = dio.Dio(
    dio.BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      contentType: ApiConfig.contentType,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
    ),
  );

  Future<Map<String, dynamic>> createInAccessibleProperties({
    required String reason,
    required String lat,
    required String long,
    required String enumerator,
    required String imagePath,
  }) async {
    final String? token = await AuthService().getToken();
    final dio.FormData formData = dio.FormData();

    formData.fields.add(MapEntry('reason', reason));
    formData.fields.add(MapEntry('lat', lat));
    formData.fields.add(MapEntry('long', long));
    formData.fields.add(MapEntry('enumerator', enumerator));

    if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      formData.files.add(
        MapEntry(
          'inaccessible_property_image',
          await dio.MultipartFile.fromFile(
            imagePath,
            filename: _fileName(imagePath),
          ),
        ),
      );
    }

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      contentType: 'multipart/form-data',
    );

    Get.log('--- Inaccessible Property Payload ---');
    Get.log('URL: ${ApiConfig.baseUrl}createInAccessibleProperties');
    Get.log('reason: $reason');
    Get.log('lat: $lat');
    Get.log('long: $long');
    Get.log('enumerator: $enumerator');
    Get.log('inaccessible_property_image: $imagePath');
    Get.log('-------------------------------------');

    try {
      final dio.Response<dynamic> res = await _dio.post(
        '/createInAccessibleProperties',
        data: formData,
        options: options,
      );
      return _cast(res.data);
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Create Inaccessible Property failed: $msg');
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> updateLandlord({
    required Map<String, dynamic> payload,
  }) async {
    final String? token = await AuthService().getToken();

    // Check if we have an image to upload
    final String? inaccessibleImagePath =
        payload['property_inaccessible_image'] as String?;
    final bool hasImage =
        inaccessibleImagePath != null &&
        inaccessibleImagePath.isNotEmpty &&
        File(inaccessibleImagePath).existsSync();

    dynamic data;
    final dio.Options options;

    if (hasImage) {
      final dio.FormData formData = dio.FormData();

      // Add all fields
      payload.forEach((key, value) {
        if (key == 'property_inaccessible_image') return; // Skip image path
        if (value == null) return;
        formData.fields.add(MapEntry(key, value.toString()));
      });

      // Add image
      formData.files.add(
        MapEntry(
          'property_inaccessible_image',
          await dio.MultipartFile.fromFile(
            inaccessibleImagePath,
            filename: _fileName(inaccessibleImagePath),
          ),
        ),
      );

      data = formData;
      options = dio.Options(
        headers: <String, String>{
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        contentType: 'multipart/form-data',
      );
    } else {
      data = payload;
      options = dio.Options(
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );
    }

    try {
      final dio.Response<dynamic> res = await _updateDio.post(
        '/landloard/update',
        data: data,
        options: options,
      );
      return _cast(res.data);
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Landlord update failed: $msg');
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> updateProperty({
    required Map<String, dynamic> fields,
    String? deliveredImagePath,
  }) async {
    final String? token = await AuthService().getToken();

    final dio.FormData formData = dio.FormData();

    // Add all fields
    fields.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        for (final v in value) {
          formData.fields.add(MapEntry('$key[]', v.toString()));
        }
      } else {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    // Delivered proof image (optional)
    if (deliveredImagePath != null &&
        deliveredImagePath.isNotEmpty &&
        File(deliveredImagePath).existsSync()) {
      formData.files.add(
        MapEntry(
          'delivered_image',
          await dio.MultipartFile.fromFile(
            deliveredImagePath,
            filename: _fileName(deliveredImagePath),
          ),
        ),
      );
    }

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      contentType: 'multipart/form-data',
    );

    try {
      final dio.Response<dynamic> res = await _updateDio.post(
        '/property/update',
        data: formData,
        options: options,
      );
      return _cast(res.data);
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Property update failed: $msg');
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> updateOccupancy({
    required Map<String, dynamic> payload,
  }) async {
    final String? token = await AuthService().getToken();

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    try {
      final dio.Response<dynamic> res = await _updateDio.post(
        '/occupency/update',
        data: payload,
        options: options,
      );
      return _cast(res.data);
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Occupancy update failed: $msg');
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> updateGeoLocation({
    required Map<String, dynamic> fields,
    List<Map<String, dynamic>>? meterData,
  }) async {
    final String? token = await AuthService().getToken();

    final dio.FormData formData = dio.FormData();

    // Add all top-level fields (property_id, property_geo_registry_id, digital_address, dor_lat_long, point1-8)
    fields.forEach((key, value) {
      if (value == null) return;
      formData.fields.add(MapEntry(key, value.toString()));
    });

    // Build meterData[n][field] structure exactly as per API requirement
    if (meterData != null && meterData.isNotEmpty) {
      for (int i = 0; i < meterData.length; i++) {
        final Map<String, dynamic> meter = meterData[i];

        // Check if this is an existing meter (has id) or new meter (no id)
        final bool isExisting = meter.containsKey('id') && meter['id'] != null;

        if (isExisting) {
          // Existing meter - include all metadata fields
          formData.fields.add(
            MapEntry('meterData[$i][id]', meter['id'].toString()),
          );
          formData.fields.add(
            MapEntry(
              'meterData[$i][property_id]',
              meter['property_id'].toString(),
            ),
          );
          formData.fields.add(
            MapEntry(
              'meterData[$i][number]',
              meter['number']?.toString() ?? '',
            ),
          );

          // Add timestamps
          if (meter.containsKey('created_at') && meter['created_at'] != null) {
            formData.fields.add(
              MapEntry(
                'meterData[$i][created_at]',
                meter['created_at'].toString(),
              ),
            );
          }
          if (meter.containsKey('updated_at') && meter['updated_at'] != null) {
            formData.fields.add(
              MapEntry(
                'meterData[$i][updated_at]',
                meter['updated_at'].toString(),
              ),
            );
          }

          // Add image URLs
          if (meter.containsKey('original') && meter['original'] != null) {
            formData.fields.add(
              MapEntry('meterData[$i][original]', meter['original'].toString()),
            );
          }
          if (meter.containsKey('small_preview') &&
              meter['small_preview'] != null) {
            formData.fields.add(
              MapEntry(
                'meterData[$i][small_preview]',
                meter['small_preview'].toString(),
              ),
            );
          }
          if (meter.containsKey('large_preview') &&
              meter['large_preview'] != null) {
            formData.fields.add(
              MapEntry(
                'meterData[$i][large_preview]',
                meter['large_preview'].toString(),
              ),
            );
          }

          // Add existing image path
          if (meter.containsKey('image') && meter['image'] != null) {
            formData.fields.add(
              MapEntry('meterData[$i][image]', meter['image'].toString()),
            );
          }

          // If user selected a new image file, add it as MultipartFile
          if (meter.containsKey('imageFile') && meter['imageFile'] != null) {
            final String imagePath = meter['imageFile'].toString();
            if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
              formData.files.add(
                MapEntry(
                  'meterData[$i][imageFile]',
                  await dio.MultipartFile.fromFile(
                    imagePath,
                    filename: _fileName(imagePath),
                  ),
                ),
              );
            }
          }
        } else {
          // New meter - meterData[n][number], meterData[n][imageFile], meterData[n][imageUrl], meterData[n][small_preview]
          formData.fields.add(
            MapEntry(
              'meterData[$i][number]',
              meter['number']?.toString() ?? '',
            ),
          );

          // Add new image file as MultipartFile
          if (meter.containsKey('imageFile') && meter['imageFile'] != null) {
            final String imagePath = meter['imageFile'].toString();
            if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
              formData.files.add(
                MapEntry(
                  'meterData[$i][imageFile]',
                  await dio.MultipartFile.fromFile(
                    imagePath,
                    filename: _fileName(imagePath),
                  ),
                ),
              );
            }
          }

          // Add blob URL if available (for web/preview)
          if (meter.containsKey('imageUrl') && meter['imageUrl'] != null) {
            formData.fields.add(
              MapEntry('meterData[$i][imageUrl]', meter['imageUrl'].toString()),
            );
          }

          // Add small_preview (empty string for new meters)
          formData.fields.add(
            MapEntry(
              'meterData[$i][small_preview]',
              meter['small_preview']?.toString() ?? '',
            ),
          );
        }
      }
    }

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      contentType: 'multipart/form-data',
    );

    try {
      // Debug logging
      Get.log('=== Geo Location Update FormData ===');
      Get.log('Fields count: ${formData.fields.length}');
      Get.log('Files count: ${formData.files.length}');
      for (final field in formData.fields) {
        Get.log('  ${field.key}: ${field.value}');
      }
      for (final file in formData.files) {
        Get.log('  ${file.key}: [MultipartFile]');
      }

      final dio.Response<dynamic> res = await _updateDio.post(
        '/geolocation/update',
        data: formData,
        options: options,
      );

      Get.log('Geo update response status: ${res.statusCode}');
      Get.log('Geo update response data: ${res.data}');

      return _cast(res.data);
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Geo location update failed: $msg');
      if (e.response != null) {
        Get.log('Error response data: ${e.response?.data}');
        Get.log('Error status code: ${e.response?.statusCode}');
      }
      throw AuthException(msg);
    }
  }

  Future<Map<String, dynamic>> updateAssessment({
    required Map<String, dynamic> fields,
    String? assessmentImage1Path,
    String? assessmentImage2Path,
  }) async {
    final String? token = await AuthService().getToken();

    final dio.FormData formData = dio.FormData();

    // Add all fields
    fields.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        // Handle arrays like property_categories, property_types, etc.
        // Send as JSON-encoded array string instead of multiple fields
        formData.fields.add(MapEntry(key, jsonEncode(value)));
      } else {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    // Assessment images
    if (assessmentImage1Path != null &&
        assessmentImage1Path.isNotEmpty &&
        File(assessmentImage1Path).existsSync()) {
      formData.files.add(
        MapEntry(
          'image1',
          await dio.MultipartFile.fromFile(
            assessmentImage1Path,
            filename: _fileName(assessmentImage1Path),
          ),
        ),
      );
    }

    if (assessmentImage2Path != null &&
        assessmentImage2Path.isNotEmpty &&
        File(assessmentImage2Path).existsSync()) {
      formData.files.add(
        MapEntry(
          'image2',
          await dio.MultipartFile.fromFile(
            assessmentImage2Path,
            filename: _fileName(assessmentImage2Path),
          ),
        ),
      );
    }

    final dio.Options options = dio.Options(
      headers: <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      contentType: 'multipart/form-data',
    );

    try {
      final dio.Response<dynamic> res = await _updateDio.post(
        '/assessment/update',
        data: formData,
        options: options,
      );
      return _cast(res.data);
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Assessment update failed: $msg');
      throw AuthException(msg);
    }
  }

  String _fileName(String path) => path.split('/').last;

  String _mapDioError(dio.DioException e) {
    if (e.type == dio.DioExceptionType.connectionTimeout ||
        e.type == dio.DioExceptionType.receiveTimeout ||
        e.type == dio.DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }
    if (e.type == dio.DioExceptionType.connectionError) {
      return 'No internet connection. Check your network and try again.';
    }
    if (e.response != null) {
      try {
        final Map<String, dynamic> data = _cast(e.response!.data);
        final String message = (data['message'] as String?) ?? 'Request failed';
        return message;
      } catch (_) {
        return 'Request failed (${e.response!.statusCode}).';
      }
    }
    return e.message ?? 'Unexpected error occurred.';
  }

  void _logFormData(
    dio.FormData formData,
    Map<String, dynamic> fields,
    Map<String, dynamic>? registryItems,
    List<String>? assessmentImagePaths,
  ) {
    // ignore: avoid_print
    print(
      '\n╔════════════════════════════════════════════════════════════════╗',
    );
    // ignore: avoid_print
    print('║           COMPLETE FORMDATA PAYLOAD STRUCTURE                  ║');
    // ignore: avoid_print
    print(
      '╚════════════════════════════════════════════════════════════════╝\n',
    );

    // Log all form fields
    // ignore: avoid_print
    print('┌─── FORM FIELDS (${formData.fields.length} fields) ───');
    for (final field in formData.fields) {
      // ignore: avoid_print
      print('│ ${field.key}: "${field.value}"');
    }
    // ignore: avoid_print
    print('└─────────────────────────────────────────────────────\n');

    // Log all files
    // ignore: avoid_print
    print('┌─── FILES (${formData.files.length} files) ───');
    for (final file in formData.files) {
      // ignore: avoid_print
      print('│ ${file.key}: ${file.value.filename ?? "unnamed"}');
      // ignore: avoid_print
      print('│   └─ Length: ${file.value.length} bytes');
    }
    // ignore: avoid_print
    print('└─────────────────────────────────────────────────────\n');

    // Log registry items structure
    if (registryItems != null && registryItems.isNotEmpty) {
      // ignore: avoid_print
      print('┌─── REGISTRY ITEMS (${registryItems.length} meters) ───');
      for (final entry in registryItems.entries) {
        // ignore: avoid_print
        print('│ Meter ${entry.key}:');
        if (entry.value is Map) {
          final item = entry.value as Map;
          // ignore: avoid_print
          print('│   ├─ meter_number: ${item['meter_number'] ?? "N/A"}');
          // ignore: avoid_print
          print('│   └─ meter_image: ${item['meter_image'] ?? "N/A"}');
        }
      }
      // ignore: avoid_print
      print('└─────────────────────────────────────────────────────\n');
    }

    // Log assessment images
    if (assessmentImagePaths != null && assessmentImagePaths.isNotEmpty) {
      // ignore: avoid_print
      print(
        '┌─── ASSESSMENT IMAGES (${assessmentImagePaths.length} images) ───',
      );
      for (int i = 0; i < assessmentImagePaths.length; i++) {
        // ignore: avoid_print
        print('│ Image ${i + 1}: ${assessmentImagePaths[i]}');
      }
      // ignore: avoid_print
      print('└─────────────────────────────────────────────────────\n');
    }

    // Log original fields map for reference
    // ignore: avoid_print
    print('┌─── ORIGINAL FIELDS MAP ───');
    for (final entry in fields.entries) {
      if (entry.value is List) {
        // ignore: avoid_print
        print('│ ${entry.key}: ${entry.value}');
      } else {
        // ignore: avoid_print
        print('│ ${entry.key}: "${entry.value}"');
      }
    }
    // ignore: avoid_print
    print('└─────────────────────────────────────────────────────\n');

    // ignore: avoid_print
    print('╔════════════════════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║                  END OF FORMDATA PAYLOAD                       ║');
    // ignore: avoid_print
    print(
      '╚════════════════════════════════════════════════════════════════╝\n',
    );
  }
}
