// lib/widgets/ui/components/post/post_tag_item.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/post/post_constants.dart'; // 需要 PostTag 和工具类

/// 可复用的帖子标签项 Widget
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
    required this.tagString, // 接收字符串
    this.count,
    this.isSelected = false,
    this.onTap,
    this.isMini = false,
  });

  @override
  Widget build(BuildContext context) {
    // --- 内部转换 String 到 Enum (用于获取颜色) ---
    // 尝试将字符串转换为 PostTag 枚举。如果转换失败或字符串是 '全部', 则 tagEnum 为 null 或 PostTag.other
    final PostTag? tagEnum = (tagString == '全部') ? null : PostTagsUtils.tagFromString(tagString);

    // --- 确定显示属性 ---
    final String displayText = tagString; // 直接使用传入的字符串作为显示文本

    // 确定背景色: '全部' 用主题色, 其他根据转换后的枚举或 other 的颜色
    final Color tagColor = (tagEnum == null) // 如果是 "全部"
        ? Theme.of(context).colorScheme.secondary // 用 secondary color
        : tagEnum.color; // 否则用枚举对应的颜色

    // 确定选中和未选中时的背景色
    final Color selectedBgColor = tagColor;
    final Color unselectedBgColor = tagColor.withOpacity(0.08);

    // 确定选中和未选中时的文本颜色
    final Color selectedTextColor = PostTagsUtils.getTextColorForBackground(selectedBgColor);
    final Color unselectedTextColor = tagColor; // 未选中时用标签自身的颜色

    // 根据 isMini 调整样式
    final double horizontalPadding = isMini ? 8 : 10;
    final double verticalPadding = isMini ? 4 : 5;
    final double fontSize = isMini ? 11 : 12;
    final double countFontSize = isMini ? 9 : 10;
    final double countHPadding = isMini ? 4 : 5;
    final double countVPadding = isMini ? 1 : 1;
    final double borderRadius = isMini ? 12 : 16;
    final double elevation = isSelected ? (isMini ? 0.5 : 1.0) : 0.0;

    // onTap 回调时传递的是转换后的 PostTag? (null 代表 '全部')
    final PostTag? tagToPassOnClick = tagEnum; // 因为 '全部' 转换后 tagEnum 就是 null

    return Material(
      color: isSelected ? selectedBgColor : unselectedBgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      elevation: elevation,
      child: InkWell(
        onTap: onTap != null ? () => onTap!(tagToPassOnClick) : null, // 传递 PostTag?
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: tagColor.withOpacity(0.3),
        highlightColor: tagColor.withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min, // 包裹内容
            children: [
              // 标签文本
              Text(
                displayText, // 显示传入的字符串
                style: TextStyle(
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              // 计数值 (如果提供了 count)
              if (count != null) ...[
                SizedBox(width: isMini ? 4 : 5),
                Container(
                  padding: EdgeInsets.symmetric( horizontal: countHPadding, vertical: countVPadding,),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedTextColor.withOpacity(0.2) : tagColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text( '$count',
                    style: TextStyle(
                      color: isSelected ? selectedTextColor : unselectedTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: countFontSize,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}