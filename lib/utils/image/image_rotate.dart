import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;

/// 图片旋转过滤器
/// 用于在竖屏模式下对图片进行旋转处理
class ImageRotateFilter extends StatelessWidget {
  /// 图片资源路径
  final String imagePath;

  /// 图片索引，用于确定旋转方向
  /// 0: 顺时针旋转90度
  /// 1: 逆时针旋转90度
  final int? index;

  /// 图片填充方式
  final BoxFit fit;

  /// 图片宽度
  final double? width;

  /// 图片高度
  final double? height;

  /// 是否强制旋转（忽略平台和方向检查）
  final bool forceRotate;

  const ImageRotateFilter({
    Key? key,
    required this.imagePath,
    this.index,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.forceRotate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 强制旋转或在Android竖屏模式下进行旋转
    if (forceRotate || (Platform.isAndroid &&
        MediaQuery.of(context).orientation == Orientation.portrait &&
        index != null)) {
      return Transform.rotate(
        angle: index == 0 ? math.pi / 2 : -math.pi / 2,
        child: Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          filterQuality: FilterQuality.high,
        ),
      );
    }

    // 其他情况直接返回原图
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}