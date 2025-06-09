// lib/providers/post/post_list_filter_provider.dart

/// 该文件定义了 PostListFilterProvider，一个管理帖子列表筛选器状态的 ChangeNotifier。
/// PostListFilterProvider 控制帖子列表的选中标签。
library;

/// `PostListFilterProvider` 类：管理帖子列表筛选器状态的 Provider。
///
/// 该类提供帖子列表的标签筛选状态。
class PostListFilterProvider {
  String? _selectedTagString; // 当前选中的标签字符串
  bool _tagHasBeenSet = false; // 标签是否已被显式设置的标记

  // --- 获取器 ---
  /// 获取当前选中的标签字符串。
  String? get selectedTagString => _selectedTagString;

  /// 获取标签是否已被设置的标记。
  bool get tagHasBeenSet => _tagHasBeenSet;

  // --- 设置器 ---
  /// 设置选中的标签。
  ///
  /// [newTagString]：新的标签字符串。
  /// 当新标签与当前标签不同时，更新标签并通知监听者。
  /// 当新标签非空且 `_tagHasBeenSet` 为 false 时，设置 `_tagHasBeenSet` 为 true。
  void setTag(String? newTagString) {
    if (_selectedTagString != newTagString) {
      // 检查新标签是否与当前标签不同
      _selectedTagString = newTagString; // 更新标签
      _tagHasBeenSet = true; // 设置标签已设置标记
    } else if (newTagString != null && !_tagHasBeenSet) {
      // 检查新标签非空且标记未设置
      _tagHasBeenSet = true; // 设置标签已设置标记
    }
  }

  // --- 清除方法 ---
  /// 清除选中的标签。
  ///
  /// 调用 `setTag(null)` 来清除标签状态。
  void clearTag() {
    setTag(null); // 清除标签
  }

  // --- 重置标记 ---
  /// 重置标签的 "已设置" 标记。
  ///
  /// 该方法不触发监听者通知。
  void resetTagFlag() {
    _tagHasBeenSet = false; // 重置标签已设置标记
  }
}
