// lib/constants/post/post_constants.dart

/// 该文件定义了帖子相关的常量和工具类。
/// 它包含帖子标签枚举、标签扩展以及帖子相关的通用规则。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架

/// `PostTag` 枚举：定义帖子的标签类型。
enum PostTag {
  discussion, // 讨论标签
  guide, // 攻略标签
  sharing, // 分享标签
  help, // 求助标签
  patch, // 补丁标签
  other, // 其他标签
}

/// `PostTagExtension` 扩展：为 `PostTag` 枚举提供显示文本和颜色。
extension PostTagExtension on PostTag {
  /// 获取标签对应的显示文本（中文）。
  String get displayText {
    switch (this) {
      case PostTag.discussion:
        return '讨论';
      case PostTag.guide:
        return '攻略';
      case PostTag.sharing:
        return '分享';
      case PostTag.help:
        return '求助';
      case PostTag.patch:
        return '补丁';
      case PostTag.other:
        return '其他';
    }
  }

  /// 获取标签对应的颜色。
  Color get color {
    switch (this) {
      case PostTag.discussion:
        return const Color(0xFF4FC3F7);
      case PostTag.guide:
        return const Color(0xFFFFB74D);
      case PostTag.sharing:
        return const Color(0xFF81C784);
      case PostTag.help:
        return const Color(0xFFE57373);
      case PostTag.patch:
        return const Color(0xFFBA68C8);
      case PostTag.other:
        return const Color(0xFF90A4AE);
    }
  }
}

/// `PostConstants` 类：定义帖子相关的常量。
class PostConstants {
  /// 所有可用的 `PostTag` 枚举值列表。
  static const List<PostTag> availablePostTags = PostTag.values;

  /// 表示“全部”标签的字符串。
  static const String allTag = '全部';

  /// 用于过滤器的标签显示文本列表（包含“全部”）。
  /// 该列表通过枚举动态生成。
  static final List<String> filterTags = [
    allTag,
    ...PostTag.values.map((tag) => tag.displayText)
  ];

  /// 帖子发布指南规则列表。
  static const List<String> postGuideRules = [
    '请确保帖子内容符合社区规范',
    '标题请简明扼要地概括主题',
    '请选择适当的标签以便其他用户查找',
    '发布后可在24小时内编辑内容',
  ];
}

/// `PostTagsUtils` 类：提供帖子标签相关的工具方法。
class PostTagsUtils {
  /// 根据背景颜色计算合适的文本颜色。
  ///
  /// [backgroundColor]：背景颜色。
  /// 返回黑色或白色，以确保文本可读性。
  static Color getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
  }

  /// 从字符串转换回 `PostTag` 枚举。
  ///
  /// [tagString]：标签字符串。
  /// 返回对应的 `PostTag` 枚举，未找到匹配项则返回 `PostTag.other`。
  static PostTag tagFromString(String tagString) {
    for (var tag in PostTag.values) {
      if (tag.displayText == tagString) {
        return tag;
      }
    }
    return PostTag.other; // 未找到匹配项时返回 `PostTag.other`
  }

  /// 将 `PostTag` 枚举列表转换为其对应的显示文本字符串列表。
  ///
  /// [tags]：`PostTag` 枚举列表。
  /// 返回包含显示文本的字符串列表。
  static List<String> tagsToStringList(List<PostTag> tags) {
    return tags.map((tag) => tag.displayText).toList(); // 映射为显示文本并转换为列表
  }

  /// 将字符串列表转换为 `PostTag` 枚举列表。
  ///
  /// [tagStrings]：包含标签显示文本的字符串列表。
  /// 返回对应的 `PostTag` 枚举列表。
  static List<PostTag> stringsToTagList(List<String> tagStrings) {
    List<PostTag> result = []; // 初始化结果列表
    for (String tagString in tagStrings) {
      // 遍历字符串列表
      PostTag tag = tagFromString(tagString); // 转换为 PostTag 枚举
      result.add(tag); // 添加到结果列表
    }
    return result; // 返回枚举列表
  }
}
