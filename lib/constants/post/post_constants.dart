// lib/constants/post/post_constants.dart
import 'package:flutter/material.dart';

// --- 1. 定义 PostTag 枚举 ---
enum PostTag {
  discussion, // 讨论
  guide, // 攻略
  sharing, // 分享
  help, // 求助
  patch, // 补丁
  other, // 其他
}

// --- 2. 创建 PostTag 的扩展，方便获取显示文本和颜色 ---
extension PostTagExtension on PostTag {
  /// 获取标签对应的显示文本 (中文)
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

  /// 获取标签对应的颜色
  Color get color {
    switch (this) {
      case PostTag.discussion:
        return const Color(0xFF4FC3F7); // lightBlue[300]
      case PostTag.guide:
        return const Color(0xFFFFB74D); // orange[300]
      case PostTag.sharing:
        return const Color(0xFF81C784); // green[300]
      case PostTag.help:
        return const Color(0xFFE57373); // red[300]
      case PostTag.patch:
        return const Color(0xFFBA68C8); // purple[300]
      case PostTag.other:
        return const Color(0xFF90A4AE); // blueGrey[300]
    }
  }
}

// --- 3. PostConstants 类现在可以更简洁 ---
class PostConstants {
  /// 所有可用的 PostTag 枚举值列表
  static const List<PostTag> availablePostTags = PostTag.values;

  static const String allTag = '全部';

  /// 用于过滤器的标签显示文本列表 (包含 '全部')
  /// 通过枚举动态生成，确保和枚举定义一致
  static final List<String> filterTags = [
    allTag,
    // 遍历所有枚举值，获取它们的显示文本
    ...PostTag.values.map((tag) => tag.displayText)
  ];

  static const List<String> postGuideRules = [
    '请确保帖子内容符合社区规范',
    '标题请简明扼要地概括主题',
    '请选择适当的标签以便其他用户查找',
    '发布后可在24小时内编辑内容',
  ];
}

// --- 4. PostTagsUtils 类现在可以简化或增强 ---
class PostTagsUtils {
  // getTagColor 方法现在不需要了，颜色直接通过 PostTagExtension 获取 (tagEnum.color)

  /// 根据背景颜色计算合适的文本颜色（这个函数仍然有用）
  static Color getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
  }

  /// 从字符串转换回枚举的方法，方便处理后端数据或用户输入
  static PostTag tagFromString(String tagString) {
    for (var tag in PostTag.values) {
      // 比较显示文本或枚举名称 (取决于后端存储的是什么)
      // 假设后端存的是中文显示文本:
      if (tag.displayText == tagString) {
        return tag;
      }
    }
    // 如果没找到匹配的，返回 'other' 或抛出异常
    return PostTag.other;
  }

  /// 将 PostTag 枚举列表转换为其对应的显示文本字符串列表。
  ///
  /// [tags]: PostTag 枚举列表。
  /// returns: 包含显示文本的字符串列表。
  static List<String> tagsToStringList(List<PostTag> tags) {
    // 使用 map 遍历枚举列表，对每个枚举调用 displayText getter，最后转成 List<String>
    return tags.map((tag) => tag.displayText).toList();
  }

  /// 将字符串列表转换为 PostTag 枚举列表。
  ///
  /// [tagStrings]: 包含标签显示文本的字符串列表。
  /// returns: 对应的 PostTag 枚举列表。对于无法匹配的字符串，将忽略或转换为 PostTag.other。
  static List<PostTag> stringsToTagList(List<String> tagStrings) { // <-- 添加这个方法
    List<PostTag> result = [];
    for (String tagString in tagStrings) {
      // 尝试将每个字符串转换为 PostTag 枚举
      PostTag tag = tagFromString(tagString); // 复用已有的 tagFromString 方法
      // 如果 tagFromString 返回 PostTag.other，取决于你的需求是否要包含它
      // 这里的实现是包含所有转换成功的，包括 PostTag.other
      result.add(tag);
    }
    return result;
  }

}
