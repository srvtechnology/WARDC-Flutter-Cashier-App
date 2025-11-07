import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' show Get;
import '../services/auth_service.dart';

class PropertyService {
  PropertyService._();
  static final PropertyService _instance = PropertyService._();
  factory PropertyService() => _instance;

  final dio.Dio _dio = dio.Dio(
    dio.BaseOptions(
      baseUrl: 'https://wardc.srvtechnology.com/public/api',
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
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
