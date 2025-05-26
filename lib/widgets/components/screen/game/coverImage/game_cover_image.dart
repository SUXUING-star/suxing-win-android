// lib/widgets/components/screen/game/coverImage/game_cover_image.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';

class GameCoverImage extends StatelessWidget {
  final String imageUrl;
  final double borderRadius;
  final bool hasShadow;
  final double? height;
  final double? width;
  final BoxFit fit;

  const GameCoverImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 12.0, // 默认圆角大小
    this.hasShadow = true, // 默认启用阴影
    this.height, // 可选高度
    this.width, // 可选宽度
    this.fit = BoxFit.contain, // 默认使用contain以保持原始比例
  });

  @override
  Widget build(BuildContext context) {
    // 创建一个自适应比例的图片
    Widget coverImage = SafeCachedImage(
      imageUrl: imageUrl,
      fit: fit, // 使用contain而不是cover，保持图片原始比例
      width: width ?? double.infinity,
      height: height,
      memCacheWidth: 640,
      backgroundColor: Colors.grey[200], // 修改为浅灰色背景以便更好地显示图片
      borderRadius: BorderRadius.circular(borderRadius),
      onError: (url, error) {
        // print('游戏封面图片加载失败: $url, 错误: $error');
      },
    );

    // 添加装饰效果（边框和阴影）
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.grey[300]!, // 降低边框对比度
          width: 1.0, // 减小边框宽度
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withSafeOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        color: Colors.grey[200], // 添加背景色，与图片背景色匹配
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1), // 调整内部圆角以适应边框
        child: coverImage,
      ),
    );
  }
}
