// lib/widgets/ui/components/post/post_tag_item.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/post/post_constants.dart';
import 'package:suxingchahui/widgets/ui/components/base_tag_view.dart'; // 卧槽，必须引入这个牛逼的基类
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

/// 可复用的帖子标签项 Widget。
///
/// 现在这个b玩意儿内部调用了 BaseTagView，代码干净得一逼。
/// 它只负责处理业务逻辑（比如颜色转换、点击事件），显示的事儿全权交给 BaseTagView。
class PostTagItem extends StatelessWidget {
  /// 要显示的标签字符串 (来自 Post 模型的 tags 列表)
  final String tagString;

  /// 标签的计数值 (可选, 来自统计)
  final int? count;

  /// 是否被选中 (由父组件控制)
  final bool isSelected;

  /// 点击回调 (传递 PostTag?, 类型安全)
  final ValueChanged<PostTag?>? onTap;

  /// 是否使用迷你模式
  final bool isMini;

  const PostTagItem({
    super.key,
    required this.tagString,
    this.count,
    this.isSelected = false,
    this.onTap,
    this.isMini = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 字符串转枚举，'全部' 特殊处理
    final PostTag? tagEnum =
        (tagString == '全部') ? null : PostTagsUtils.tagFromString(tagString);

    // 2. 确定基础颜色。这颜色就是传给 BaseTagView 的核心参数
    final Color baseColor = (tagEnum == null) // 如果是 "全部"
        ? Theme.of(context).colorScheme.secondary // 用主题色
        : tagEnum.color; // 否则用枚举对应的颜色

    // 3. 准备好点击时要回传的数据
    final PostTag? tagToPassOnClick = tagEnum;

    // --- 视图渲染层 ---
    // 把所有样式计算全扔了，直接用 InkWell 包裹 BaseTagView

    return InkWell(
      // 点击事件直接绑定，清爽
      onTap: onTap != null ? () => onTap!(tagToPassOnClick) : null,
      // 圆角直接用 BaseTagView 里的常量，保证水波纹和背景的圆角他妈的完全一致
      borderRadius: BorderRadius.circular(
          isMini ? BaseTagView.miniRadius : BaseTagView.normalRadius),
      splashColor: baseColor.withSafeOpacity(0.3),
      highlightColor: baseColor.withSafeOpacity(0.2),
      child: BaseTagView(
        // 把计算好的数据喂给 BaseTagView 就完事了
        text: tagString,
        baseColor: baseColor,
        isMini: isMini,
        count: count,
        // 选中时 (isSelected=true)，我们要实心效果，所以 isFrosted=false。
        // 未选中时 (isSelected=false)，我们要磨砂效果，所以 isFrosted=true。
        isFrosted: !isSelected,
      ),
    );
  }
}
