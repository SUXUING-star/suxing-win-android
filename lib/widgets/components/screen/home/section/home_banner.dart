// lib/widgets/components/screen/home/section/home_banner.dart

/// 该文件定义了 HomeBanner 组件，用于显示主页的横幅广告或图片。
/// HomeBanner 在一个可滑动的 PageView 中展示图片。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法

/// `HomeBanner` 类：主页横幅组件。
///
/// 该组件在一个带边框和渐变遮罩的 PageView 中展示图片。
class HomeBanner extends StatelessWidget {
  final String bannerImagePath; // 横幅图片的资源路径

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [bannerImagePath]：要显示的横幅图片的资源路径。
  const HomeBanner({
    super.key,
    required this.bannerImagePath,
  });

  /// 构建 Widget。
  ///
  /// 渲染一个带约束和宽高比的 PageView，用于展示横幅图片。
  @override
  Widget build(BuildContext context) {
    return Center(
      // 居中显示
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 8.0), // 设置水平和垂直内边距
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200.0, // 限制最大宽度
            maxHeight: 250.0, // 限制最大高度
          ),
          child: AspectRatio(
            aspectRatio: 1536 / 1024, // 设置宽高比
            child: PageView.builder(
              itemCount: 3, // 页面数量
              itemBuilder: (context, index) {
                // 页面构建器
                return Container(
                  padding: const EdgeInsets.all(5.0), // 页面容器，作为画框厚度
                  decoration: BoxDecoration(
                    color: Colors.grey[850], // 主体颜色
                    borderRadius: BorderRadius.circular(14.0), // 圆角
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9.0), // 最内层圆角裁剪
                    child: Stack(
                      fit: StackFit.expand, // 子项填充 Stack
                      children: [
                        Image.asset(
                          bannerImagePath, // 从本地资源加载图片
                          fit: BoxFit.cover, // 图片填充模式
                        ),
                        Container(
                          // 渐变遮罩容器
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0), // 遮罩圆角
                            gradient: LinearGradient(
                              // 线性渐变
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withSafeOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
