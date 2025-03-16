import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AvatarCropperBridge {
  // 单例模式
  static final AvatarCropperBridge _instance = AvatarCropperBridge._internal();

  factory AvatarCropperBridge() {
    return _instance;
  }

  AvatarCropperBridge._internal();

  // 与原生代码通信的通道
  static const MethodChannel _channel = MethodChannel('com.suxingchahui/avatar_cropper');

  /// 裁剪头像为圆形
  ///
  /// [inputFile] 输入图像文件
  /// [sourceX] 源图像的X坐标
  /// [sourceY] 源图像的Y坐标
  /// [sourceWidth] 源图像的宽度
  /// [sourceHeight] 源图像的高度
  /// [outputSize] 输出图像的大小（像素）
  ///
  /// 返回裁剪后的图像文件
  Future<File?> cropAvatarCircle({
    required File inputFile,
    required double sourceX,
    required double sourceY,
    required double sourceWidth,
    required double sourceHeight,
    int outputSize = 300,
  }) async {
    if (!Platform.isWindows) {
      throw PlatformException(
          code: 'UNSUPPORTED_PLATFORM',
          message: '当前平台不支持此功能，仅支持Windows平台'
      );
    }

    // 创建临时输出文件
    final tempDir = Directory.systemTemp;
    final outputPath = '${tempDir.path}/cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      final result = await _channel.invokeMethod<String>('cropAvatar', {
        'inputPath': inputFile.path,
        'outputPath': outputPath,
        'sourceX': sourceX,
        'sourceY': sourceY,
        'sourceWidth': sourceWidth,
        'sourceHeight': sourceHeight,
        'outputSize': outputSize,
      });

      if (result != null) {
        return File(result);
      }
      return null;
    } catch (e) {
      debugPrint('头像裁剪失败: $e');
      return null;
    }
  }
}