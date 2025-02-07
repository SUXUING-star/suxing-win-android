// lib/utils/file_upload.dart (替换原来的 oss_upload.dart)
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:mime_type/mime_type.dart';
import '../config/app_config.dart';

class FileUpload {
  static final String baseUrl = 'http://${AppConfig.ipaddress}:${AppConfig.fileupload_port}';

  // 上传图片（替换原来的 uploadImage 方法）
  static Future<String> uploadImage(
      File imageFile, {
        String? folder,
        int? maxWidth,
        int? maxHeight,
        int? quality,
      }) async {
    try {
      // 打印文件信息
      print('准备上传文件: ${imageFile.path}');
      print('文件是否存在: ${imageFile.existsSync()}');
      print('文件大小: ${imageFile.lengthSync()} 字节');

      final uri = Uri.parse('$baseUrl/upload');
      var request = http.MultipartRequest('POST', uri);

      final mimeType = mime(imageFile.path) ?? 'image/jpeg';
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      // 确保 folder 有值
      request.fields['folder'] = folder ?? 'avatars';

      if (maxWidth != null) request.fields['width'] = maxWidth.toString();
      if (maxHeight != null) request.fields['height'] = maxHeight.toString();
      if (quality != null) request.fields['quality'] = quality.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('上传响应状态码: ${response.statusCode}');
      print('上传响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      } else {
        throw Exception('上传失败: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('上传错误: $e');
      rethrow;
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