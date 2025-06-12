// lib/widgets/ui/components/post/post_tag_item.dart

/// 该文件定义了 PostTagItem 组件，用于显示可点击的帖子标签。
/// PostTagItem 根据标签字符串、选中状态和模式，渲染不同样式的标签。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/constants/post/post_constants.dart'; // 帖子常量
import 'package:suxingchahui/widgets/ui/components/base_tag_view.dart'; // 基础标签视图组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法

/// `PostTagItem` 类：可复用的帖子标签项组件。
///
/// 该组件处理标签的业务逻辑，并将其显示交给 `BaseTagView`。
class PostTagItem extends StatelessWidget {
  final String tagString; // 要显示的标签字符串
  final int? count; // 标签的计数值
  final bool isSelected; // 是否被选中
  final ValueChanged<PostTag?>? onTap; // 点击回调
  final bool isMini; // 是否使用迷你模式

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [tagString]：要显示的标签字符串。
  /// [count]：标签的计数值。
  /// [isSelected]：是否被选中。
  /// [onTap]：点击回调。
  /// [isMini]：是否使用迷你模式。
  const PostTagItem({
    super.key,
    required this.tagString,
    this.count,
    this.isSelected = false,
    this.onTap,
    this.isMini = false,
  });

  /// 构建 Widget。
  ///
  /// 根据标签字符串确定基础颜色，并构建可点击的 `BaseTagView`。
  @override
  Widget build(BuildContext context) {
    // 1. 字符串转枚举，'全部' 特殊处理。
    final PostTag? tagEnum =
        (tagString == '全部') ? null : PostTagsUtils.tagFromString(tagString);

    // 2. 确定基础颜色。
    final Color baseColor = (tagEnum == null) // 如果是 "全部" 标签
        ? Theme.of(context).colorScheme.secondary // 使用主题的次级颜色
        : tagEnum.color; // 否则使用枚举对应的颜色

    // 3. 准备点击时回传的数据。
    final PostTag? tagToPassOnClick = tagEnum;

    // 视图渲染层。
    return InkWell(
      onTap: onTap != null ? () => onTap!(tagToPassOnClick) : null, // 绑定点击事件
      borderRadius: BorderRadius.circular(
          isMini ? BaseTagView.miniRadius : BaseTagView.normalRadius), // 设置圆角
      splashColor: baseColor.withSafeOpacity(0.3), // 水波纹颜色
      highlightColor: baseColor.withSafeOpacity(0.2), // 高亮颜色
      child: BaseTagView(
        text: tagString, // 标签文本
        baseColor: baseColor, // 基础颜色
        isMini: isMini, // 是否迷你模式
        count: count, // 计数
        isFrosted: !isSelected, // 根据选中状态设置磨砂效果
      ),
    );
  }
}
