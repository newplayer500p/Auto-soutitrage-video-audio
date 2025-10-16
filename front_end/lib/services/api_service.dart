import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class ApiService {
  final Dio _dio;
  final String baseUrl;
  ApiService(this.baseUrl, [Dio? dio]) : _dio = dio ?? Dio();

  Future<Map<String, dynamic>> uploadVideo({
    required PlatformFile videoFile,
    required String language,
    required String position,
    required String fontName,
    required int fontSize,
    required String fontColor, // <-- ajouté
    required String outlineColor, // <-- ajouté
    String? fond, // ex "#000000" => envoyé en champ 'fond'
    PlatformFile? fondFile, // envoyé en champ 'fond_file'
  }) async {
    final url = '$baseUrl/video/process';
    final form = FormData();

    form.fields.add(MapEntry('language', language));
    form.fields.add(MapEntry('position', position));
    form.fields.add(MapEntry('font_name', fontName));
    form.fields.add(MapEntry('font_size', fontSize.toString()));
    form.fields.add(MapEntry('font_color', fontColor));
    form.fields.add(MapEntry('font_outline_color', outlineColor));

    if (fond != null && fond.isNotEmpty) {
      form.fields.add(MapEntry('fond', fond));
    }

    if ((fond == null || fond.isEmpty) && fondFile != null) {
      if (kIsWeb || fondFile.path == null) {
        final bytes = fondFile.bytes;
        if (bytes == null) throw Exception('Fond image bytes are null (web).');
        final mp = MultipartFile.fromBytes(bytes, filename: fondFile.name);
        form.files.add(MapEntry('fond_file', mp));
      } else {
        final mp = await MultipartFile.fromFile(
          fondFile.path!,
          filename: p.basename(fondFile.name),
        );
        form.files.add(MapEntry('fond_file', mp));
      }
    }

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

  /// Récupère tous les jobs enregistrés
  Future<List<Map<String, dynamic>>> getJobs() async {
    final url = '$baseUrl/jobs';
    final response = await _dio.get(url);

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      if (response.data is Map<String, dynamic>) {
        // On s'attend à {"count": N, "jobs": [...]}
        final jobs = response.data['jobs'];
        if (jobs is List) {
          return List<Map<String, dynamic>>.from(jobs);
        } else {
          throw Exception('Jobs data invalid format');
        }
      } else if (response.data is String) {
        final decoded =
            json.decode(response.data as String) as Map<String, dynamic>;
        final jobs = decoded['jobs'];
        if (jobs is List) return List<Map<String, dynamic>>.from(jobs);
        throw Exception('Jobs data invalid format');
      } else {
        throw Exception(
          'Unexpected response type: ${response.data.runtimeType}',
        );
      }
    } else {
      throw Exception(
        'Failed to fetch jobs: ${response.statusCode} ${response.statusMessage}',
      );
    }
  }

  /// Optionnel : récupérer un job spécifique par jobId
  Future<Map<String, dynamic>> getJobById(String jobId) async {
    final url = '$baseUrl/jobs/$jobId';
    final response = await _dio.get(url);

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      } else if (response.data is String) {
        return json.decode(response.data as String) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Unexpected response type: ${response.data.runtimeType}',
        );
      }
    } else {
      throw Exception(
        'Failed to fetch job: ${response.statusCode} ${response.statusMessage}',
      );
    }
  }
}
