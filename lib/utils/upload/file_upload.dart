// lib/utils/file_upload.dart (替换原来的 oss_upload.dart)
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:mime_type/mime_type.dart';
import '../../config/app_config.dart';

class FileUpload {
  static final String baseUrl = 'http://${AppConfig.ipAddress}:${AppConfig.fileUploadPort}';

  // 上传图片（替换原来的 uploadImage 方法）
  static Future<String> uploadImage(
      File imageFile, {
        String? folder,
        int? maxWidth,
        int? maxHeight,
        int? quality,
      }) async {
    try {
      // 设置默认值
      quality = quality ?? 80;  // 默认80%质量
      maxWidth = maxWidth ?? 1200;  // 默认最大宽度
      maxHeight = maxHeight ?? 1200; // 默认最大高度

      final uri = Uri.parse('$baseUrl/upload');
      var request = http.MultipartRequest('POST', uri);

      final mimeType = mime(imageFile.path) ?? 'image/jpeg';
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);
      request.fields['folder'] = folder ?? 'avatars';
      request.fields['width'] = maxWidth.toString();
      request.fields['height'] = maxHeight.toString();
      request.fields['quality'] = quality.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      } else {
        throw Exception('上传失败，请稍后重试');  // 统一的错误信息
      }
    } catch (e) {
      print('上传错误: $e');  // 只在日志中记录具体错误
      throw Exception('上传失败，请稍后重试');  // 向用户显示友好的错误信息
    }
  }

  // 上传多个文件（替换原来的 uploadFiles 方法）
  static Future<List<String>> uploadFiles(
      List<File> files, {
        String? folder,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload-multiple');
      var request = http.MultipartRequest('POST', uri);

      for (var file in files) {
        final mimeType = mime(file.path) ?? 'image/jpeg';
        final multipartFile = await http.MultipartFile.fromPath(
          'files',
          file.path,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      if (folder != null) request.fields['folder'] = folder;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['urls']);
      } else {
        throw Exception('上传失败: ${response.statusCode}');
      }
    } catch (e) {
      print('上传错误: $e');
      rethrow;
    }
  }
}