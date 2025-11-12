import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' show Get;
import '../services/auth_service.dart';
import '../utils/api_config.dart';

class PropertyService {
  PropertyService._();
  static final PropertyService _instance = PropertyService._();
  factory PropertyService() => _instance;

  final dio.Dio _dio = dio.Dio(
    dio.BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      contentType: ApiConfig.contentType,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
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
          formData.fields.add(MapEntry('${key}[]', v.toString()));
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
    ),
  );

  Future<Map<String, dynamic>> updateLandlord({
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
        '/landloard/update',
        data: payload,
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
          formData.fields.add(MapEntry('${key}[]', v.toString()));
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

    // Add all fields
    fields.forEach((key, value) {
      if (value == null || value.toString().isEmpty) return;
      formData.fields.add(MapEntry(key, value.toString()));
    });

    // Handle meter data
    if (meterData != null) {
      for (int i = 0; i < meterData.length; i++) {
        final Map<String, dynamic> meter = meterData[i];
        
        // Existing meter (has id)
        if (meter.containsKey('id')) {
          formData.fields.add(MapEntry('meterData[$i][id]', meter['id'].toString()));
          formData.fields.add(MapEntry('meterData[$i][property_id]', meter['property_id'].toString()));
          formData.fields.add(MapEntry('meterData[$i][number]', meter['number'].toString()));
          
          // If image is a file path (new image), upload it
          if (meter.containsKey('imageFile') && meter['imageFile'] != null) {
            final String imagePath = meter['imageFile'].toString();
            if (File(imagePath).existsSync()) {
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
          } else if (meter.containsKey('image') && meter['image'] != null) {
            // Existing image URL/path (keep existing)
            formData.fields.add(MapEntry('meterData[$i][image]', meter['image'].toString()));
          }
        } else {
          // New meter (no id)
          formData.fields.add(MapEntry('meterData[$i][number]', meter['number'].toString()));
          
          // Upload new image
          if (meter.containsKey('imageFile') && meter['imageFile'] != null) {
            final String imagePath = meter['imageFile'].toString();
            if (File(imagePath).existsSync()) {
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
      final dio.Response<dynamic> res = await _updateDio.post(
        '/geolocation/update',
        data: formData,
        options: options,
      );
      return _cast(res.data);
    } on dio.DioException catch (e) {
      final String msg = _mapDioError(e);
      Get.log('Geo location update failed: $msg');
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
}
