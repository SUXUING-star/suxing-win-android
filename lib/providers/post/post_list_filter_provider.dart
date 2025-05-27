// lib/providers/post/post_list_filter_provider.dart
import 'package:flutter/foundation.dart';

class PostListFilterProvider with ChangeNotifier {
  String? _selectedTagString; // 存储标签的字符串形式 (e.g., "技术分享", "Gaming")
  bool _tagHasBeenSet = false;

  // --- Getters ---
  String? get selectedTagString => _selectedTagString;
  bool get tagHasBeenSet => _tagHasBeenSet;

  // --- Setter ---
  /// 设置选中的标签 (字符串形式)。
  void setTag(String? newTagString) {
    // 只有当新标签与当前标签不同时才更新
    if (_selectedTagString != newTagString) {
      _selectedTagString = newTagString;
      _tagHasBeenSet = true; // 标记 Tag 已设置
      notifyListeners(); // 通知监听者
    } else if (newTagString != null && !_tagHasBeenSet) {
      _tagHasBeenSet = true;
    }
  }

  // --- 清除方法 ---
  /// 清除选中的标签。
  void clearTag() {
    setTag(null); // 调用 setTag(null) 会自动更新 _tagHasBeenSet 和 notifyListeners
  }

  // --- 重置标记 ---
  /// 重置 Tag 的 "已设置" 标记。当 UI 处理完 Tag 变化后调用。
  void resetTagFlag() {
    _tagHasBeenSet = false;
    // 注意：这里不调用 notifyListeners，因为它只是重置内部状态，不应触发 UI 重建
  }
}
