// lib/utils/oss_upload.dart
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../config/app_config.dart';

class OSSUpload {
  // 生成OSS需要的GMT格式时间
  static String _getGMTDate() {
    return HttpDate.format(DateTime.now().toUtc());
  }

  // 计算Content-MD5
  static Future<String> _calculateMD5(List<int> bytes) async {
    final digest = md5.convert(bytes);
    return base64.encode(digest.bytes);
  }

  // 生成签名
  static String _generateSignature({
    required String method,
    required String contentMd5,
    required String contentType,
    required String date,
    required String canonicalizedOSSHeaders,
    required String canonicalizedResource,
  }) {
    final stringToSign = [
      method,
      contentMd5,
      contentType,
      date,
      canonicalizedOSSHeaders,
      canonicalizedResource,
    ].join('\n');

    print('StringToSign:\n$stringToSign'); // 用于调试

    final key = utf8.encode(AppConfig.aliyunOssAccessKeySecret);
    final bytes = utf8.encode(stringToSign);
    final hmacSha1 = Hmac(sha1, key);
    final digest = hmacSha1.convert(bytes);
    return base64.encode(digest.bytes);
  }

  // 生成唯一的文件名
  static String _generateUniqueFilename(String originalFilename) {
    final extension = path.extension(originalFilename);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 1000;
    return '$timestamp$random$extension';
  }

  // 上传单个文件
  static Future<String> uploadFile(File file, {String? folder}) async {
    try {
      final filename = _generateUniqueFilename(file.path);
      final objectKey = folder != null ? '$folder/$filename' : filename;
      final contentType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final date = _getGMTDate();
      final bytes = await file.readAsBytes();
      final contentMd5 = await _calculateMD5(bytes);

      final canonicalizedResource = '/${AppConfig.aliyunOssBucket}/$objectKey';
      const canonicalizedOSSHeaders = 'x-oss-storage-class:Standard';

      final signature = _generateSignature(
        method: 'PUT',
        contentMd5: contentMd5,
        contentType: contentType,
        date: date,
        canonicalizedOSSHeaders: canonicalizedOSSHeaders,
        canonicalizedResource: canonicalizedResource,
      );

      final url = 'https://${AppConfig.aliyunOssBucket}.${AppConfig.aliyunOssEndpoint}/$objectKey';
      final uri = Uri.parse(url);

      final request = http.Request('PUT', uri);
      request.headers.addAll({
        'Authorization': 'OSS ${AppConfig.aliyunOssAccessKeyId}:$signature',
        'Content-Type': contentType,
        'Content-MD5': contentMd5,
        'Date': date,
        'x-oss-storage-class': 'Standard',
        'Host': uri.host,
      });

      request.bodyBytes = bytes;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return url;
      } else {
        print('OSS Error Response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to upload file: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  // 上传多个文件
  static Future<List<String>> uploadFiles(List<File> files, {String? folder}) async {
    final uploadFutures = files.map((file) => uploadFile(file, folder: folder));
    return await Future.wait(uploadFutures);
  }

  // 上传图片
  static Future<String> uploadImage(File imageFile, {
    String? folder,
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      // 这里可以添加图片压缩处理逻辑
      return await uploadFile(imageFile, folder: folder ?? 'images');
    } catch (e) {
      print('Upload image error: $e');
      rethrow;
    }
  }

  // 删除文件
  static Future<void> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final objectKey = uri.path.substring(1);
      final date = _getGMTDate();

      final canonicalizedResource = '/${AppConfig.aliyunOssBucket}/$objectKey';
      const canonicalizedOSSHeaders = '';

      final signature = _generateSignature(
        method: 'DELETE',
        contentMd5: '',
        contentType: '',
        date: date,
        canonicalizedOSSHeaders: canonicalizedOSSHeaders,
        canonicalizedResource: canonicalizedResource,
      );

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'OSS ${AppConfig.aliyunOssAccessKeyId}:$signature',
          'Date': date,
          'Host': uri.host,
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete file: ${response.statusCode}');
      }
    } catch (e) {
      print('Delete file error: $e');
      rethrow;
    }
  }
}