// lib/utils/upload/file_upload.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:mime_type/mime_type.dart';
import '../../config/app_config.dart';

class FileUpload {
  static final String baseUrl = 'http://${AppConfig.ipAddress}:${AppConfig.bridgeServerPort}';

  // 上传图片（支持删除旧图片）
  static Future<String> uploadImage(
      File imageFile, {
        String? folder,
        int? maxWidth,
        int? maxHeight,
        int? quality,
        String? oldImageUrl, // 添加旧图片URL参数
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

      // 如果有旧图像URL，将其添加到请求中以便服务器删除
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        request.fields['oldFileUrl'] = oldImageUrl;
      }

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

  // 上传多个文件（支持删除旧文件）
  static Future<List<String>> uploadFiles(
      List<File> files, {
        String? folder,
        List<String>? oldFileUrls, // 添加旧文件URL列表参数
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

      // 如果有旧文件URL，将其添加到请求中以便服务器删除
      if (oldFileUrls != null && oldFileUrls.isNotEmpty) {
        request.fields['oldFileUrls'] = jsonEncode(oldFileUrls);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files = data['files'] as List<dynamic>;
        // 从每个文件对象中提取 url
        return files.map((file) => file['url'] as String).toList();
      } else {
        throw Exception('上传失败: ${response.statusCode}');
      }
    } catch (e) {
      print('上传错误: $e');
      rethrow;
    }
  }

  // 删除文件方法
  static Future<bool> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/delete-file');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': fileUrl}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('删除文件失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('删除文件错误: $e');
      return false;
    }
  }
}