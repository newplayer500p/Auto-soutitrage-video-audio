import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class ApiService {
  final Dio _dio;
  ApiService([Dio? dio]) : _dio = dio ?? Dio();

  Future<Map<String, dynamic>> uploadVideo({
    String baseUrl = "http://localhost:8000",
    required PlatformFile videoFile,
    PlatformFile? transcriptFile,
    required String language,
    required String position,
    required String fontName,
    required int fontSize,
  }) async {
    final url = '$baseUrl/video/process';
    final form = FormData();

    form.fields.add(MapEntry('language', language));
    form.fields.add(MapEntry('position', position));
    form.fields.add(MapEntry('font_name', fontName));
    form.fields.add(MapEntry('font_size', fontSize.toString()));

    // video file
    if (kIsWeb || videoFile.path == null) {
      final bytes = videoFile.bytes;
      if (bytes == null) throw Exception('Video bytes are null (web).');
      final mp = MultipartFile.fromBytes(bytes, filename: videoFile.name);
      form.files.add(MapEntry('file', mp));
    } else {
      final mp = await MultipartFile.fromFile(
        videoFile.path!,
        filename: p.basename(videoFile.name),
      );
      form.files.add(MapEntry('file', mp));
    }

    // optional transcript
    if (transcriptFile != null) {
      if (kIsWeb || transcriptFile.path == null) {
        final tbytes = transcriptFile.bytes;
        if (tbytes == null) throw Exception('Transcript bytes are null (web).');
        final tmp = MultipartFile.fromBytes(
          tbytes,
          filename: transcriptFile.name,
        );
        form.files.add(MapEntry('transcript', tmp));
      } else {
        final tmp = await MultipartFile.fromFile(
          transcriptFile.path!,
          filename: p.basename(transcriptFile.name),
        );
        form.files.add(MapEntry('transcript', tmp));
      }
    }

    final response = await _dio.post(
      url,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      // Dio already decodes JSON responses into response.data
      if (response.data is Map<String, dynamic>) return response.data;
      // if response.data is string:
      if (response.data is String) {
        return json.decode(response.data as String) as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } else {
      throw Exception(
        'Upload failed: ${response.statusCode} ${response.statusMessage}',
      );
    }
  }
}
