// lib/widgets/components/screen/game/coverImage/game_cover_image.dart
import 'package:flutter/material.dart';
import '../../../../common/image/safe_cached_image.dart';

class GameCoverImage extends StatelessWidget {
  final String imageUrl;

  // 添加可选参数控制样式
  final double borderRadius;
  final bool hasShadow;
  final double? height;

  const GameCoverImage({
    Key? key,
    required this.imageUrl,
    this.borderRadius = 12.0, // 默认圆角大小
    this.hasShadow = true,    // 默认启用阴影
    this.height,              // 可选高度
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget coverImage = SafeCachedImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: height,
      memCacheWidth: 640,
      backgroundColor: Colors.grey[300],
      borderRadius: BorderRadius.circular(borderRadius),
      onError: (url, error) {
        print('游戏封面图片加载失败: $url, 错误: $error');
      },
    );

    // 添加装饰效果（边框和阴影）
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.grey[400]!,
          width: 2.0,
        ),
        boxShadow: hasShadow ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 2), // 调整内部圆角以适应边框
        child: coverImage,
      ),
    );

    return coverImage;
  }
}