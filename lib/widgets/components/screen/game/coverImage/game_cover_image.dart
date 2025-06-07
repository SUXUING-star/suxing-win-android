// lib/widgets/components/screen/game/coverImage/game_cover_image.dart

/// 该文件定义了 GameCoverImage 组件，一个用于显示游戏封面图片的 StatelessWidget。
/// GameCoverImage 封装了 SafeCachedImage，并添加了边框、阴影和圆角装饰。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart'; // 导入安全缓存图片组件

/// `GameCoverImage` 类：显示游戏封面图片的组件。
///
/// 该组件封装了 SafeCachedImage，并添加了边框、阴影和圆角装饰。
class GameCoverImage extends StatelessWidget {
  final String imageUrl; // 封面图片 URL
  final double borderRadius; // 圆角大小
  final bool hasShadow; // 是否显示阴影
  final double? height; // 图片高度
  final double? width; // 图片宽度
  final BoxFit fit; // 图片填充模式

  /// 构造函数。
  ///
  /// [imageUrl]：图片 URL。
  /// [borderRadius]：圆角。
  /// [hasShadow]：是否有阴影。
  /// [height]：高度。
  /// [width]：宽度。
  /// [fit]：填充模式。
  const GameCoverImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 12.0,
    this.hasShadow = true,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  /// 构建游戏封面图片组件。
  @override
  Widget build(BuildContext context) {
    Widget coverImage = SafeCachedImage(
      imageUrl: imageUrl, // 图片 URL
      fit: fit, // 填充模式
      width: width ?? double.infinity, // 宽度
      height: height, // 高度
      memCacheWidth: 640, // 内存缓存宽度
      backgroundColor: Colors.grey[200], // 背景色
      borderRadius: BorderRadius.circular(borderRadius), // 圆角
      onError: (url, error) {
        // 错误回调
        // 错误处理
      },
    );

    return Container(
      width: width, // 宽度
      height: height, // 高度
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius), // 圆角
        border: Border.all(
          color: Colors.grey[300]!, // 边框颜色
          width: 1.0, // 边框宽度
        ),
        boxShadow: hasShadow // 阴影
            ? [
                BoxShadow(
                  color: Colors.black.withSafeOpacity(0.15), // 阴影颜色
                  spreadRadius: 1, // 扩散半径
                  blurRadius: 8, // 模糊半径
                  offset: const Offset(0, 3), // 偏移
                ),
              ]
            : null,
        color: Colors.grey[200], // 背景色
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1), // 裁剪圆角
        child: coverImage, // 封面图片
      ),
    );
  }
}
