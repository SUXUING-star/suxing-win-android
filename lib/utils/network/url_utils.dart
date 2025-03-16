// lib/utils/network/url_utils.dart
import 'dart:convert';

/// URL处理工具类
///
/// 提供处理URL的实用方法，特别是处理包含中文或特殊字符的URL
class UrlUtils {
  /// 将URL转换为安全的格式，适当处理路径中的特殊字符
  ///
  /// 参数:
  /// [url] - 原始URL
  ///
  /// 返回:
  /// 处理后的安全URL
  static String getSafeUrl(String url) {
    if (url.isEmpty) return url;

    try {
      // 解析URL
      Uri uri = Uri.parse(url);

      // 重新编码路径部分
      String newPath = uri.pathSegments.map((segment) {
        // 如果段已经包含%编码，则不再重新编码
        if (segment.contains('%')) return segment;
        return Uri.encodeComponent(segment);
      }).join('/');

      if (!newPath.startsWith('/')) {
        newPath = '/$newPath';
      }

      // 重建URL
      Uri safeUri = uri.replace(path: newPath);
      return safeUri.toString();
    } catch (e) {
      print('URL编码错误: $e');

      // 如果解析失败，尝试简单的编码
      try {
        // 分离协议和主机部分
        int protocolEnd = url.indexOf('://');
        if (protocolEnd > 0) {
          String protocol = url.substring(0, protocolEnd + 3);
          String remaining = url.substring(protocolEnd + 3);

          // 分离主机和路径
          int pathStart = remaining.indexOf('/');
          if (pathStart > 0) {
            String host = remaining.substring(0, pathStart);
            String path = remaining.substring(pathStart);

            // 编码路径部分，保留"/"
            List<String> segments = path.split('/');
            String encodedPath = segments.map((segment) {
              if (segment.isEmpty) return '';
              return Uri.encodeComponent(segment);
            }).join('/');

            return '$protocol$host$encodedPath';
          }
        }
      } catch (e) {
        print('简单URL编码失败: $e');
      }

      // 所有尝试都失败，返回原始URL
      return url;
    }
  }

  /// 检查URL是否有效
  ///
  /// 参数:
  /// [url] - 要检查的URL
  ///
  /// 返回:
  /// 布尔值表示URL是否有效
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute &&
          (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 构建完整URL
  ///
  /// 将相对路径与基础URL组合成完整URL
  ///
  /// 参数:
  /// [baseUrl] - 基础URL
  /// [path] - 相对路径
  ///
  /// 返回:
  /// 完整URL
  static String buildUrl(String baseUrl, String path) {
    if (baseUrl.isEmpty) return path;
    if (path.isEmpty) return baseUrl;

    // 确保baseUrl以/结尾，path不以/开头
    String base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    String relativePath = path.startsWith('/') ? path.substring(1) : path;

    return '$base$relativePath';
  }

  /// 从URL中提取文件名
  static String getFileNameFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    } catch (e) {
      // 如果解析失败，使用简单方法
      int lastSlash = url.lastIndexOf('/');
      if (lastSlash != -1 && lastSlash < url.length - 1) {
        return url.substring(lastSlash + 1);
      }
      return url;
    }
  }
}