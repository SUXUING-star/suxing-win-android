// lib/providers/gamelist/game_list_filter_provider.dart

/// 该文件定义了 GameListFilterProvider，一个管理游戏列表筛选器状态的 ChangeNotifier。
/// GameListFilterProvider 控制游戏列表的选中标签和选中分类。
library;


/// `GameListFilterProvider` 类：管理游戏列表筛选器状态的 Provider。
///
/// 该类提供游戏列表的标签和分类筛选状态。
class GameListFilterProvider {
  String? _selectedTag; // 当前选中的标签字符串
  bool _tagHasBeenSet = false; // 标签是否已被显式设置的标记

  String? _selectedCategory; // 当前选中的分类字符串
  bool _categoryHasBeenSet = false; // 分类是否已被显式设置的标记

  // --- 获取器 ---
  /// 获取当前选中的标签字符串。
  String? get selectedTag => _selectedTag;

  /// 获取标签是否已被设置的标记。
  bool get tagHasBeenSet => _tagHasBeenSet;

  /// 获取当前选中的分类字符串。
  String? get selectedCategory => _selectedCategory;

  /// 获取分类是否已被设置的标记。
  bool get categoryHasBeenSet => _categoryHasBeenSet;

  // --- 设置器 (包含互斥逻辑) ---

  /// 设置选中的标签。
  ///
  /// [newTag]：新的标签字符串。
  /// 只有当新标签与当前标签不同时才更新。
  /// 设置非空标签时，自动清除选中的分类。
  void setTag(String? newTag) {
    if (_selectedTag != newTag) {
      // 检查新标签是否与当前标签不同
      _selectedTag = newTag; // 更新标签
      _tagHasBeenSet = true; // 设置标签已设置标记

      if (newTag != null && _selectedCategory != null) {
        // 设置非空标签时清除分类
        _selectedCategory = null; // 清除分类
        _categoryHasBeenSet = false; // 重置分类已设置标记
      }
    } else if (newTag != null && !_tagHasBeenSet) {
      // 标签相同时，如果未被主动设置过，也标记为已设置
      _tagHasBeenSet = true; // 设置标签已设置标记
    }
  }

  /// 设置选中的分类。
  ///
  /// [newCategory]：新的分类字符串。
  /// 只有当新分类与当前分类不同时才更新。
  /// 设置非空分类时，自动清除选中的标签。
  void setCategory(String? newCategory) {
    if (_selectedCategory != newCategory) {
      // 检查新分类是否与当前分类不同
      _selectedCategory = newCategory; // 更新分类
      _categoryHasBeenSet = true; // 设置分类已设置标记

      if (newCategory != null && _selectedTag != null) {
        // 设置非空分类时清除标签
        _selectedTag = null; // 清除标签
        _tagHasBeenSet = false; // 重置标签已设置标记
      }
    } else if (newCategory != null && !_categoryHasBeenSet) {
      // 分类相同时，如果未被主动设置过，也标记为已设置
      _categoryHasBeenSet = true; // 设置分类已设置标记
    }
  }

  // --- 清除方法 ---

  /// 清除选中的标签。
  void clearTag() {
    setTag(null); // 调用 setTag(null) 清除标签
  }

  /// 清除选中的分类。
  void clearCategory() {
    setCategory(null); // 调用 setCategory(null) 清除分类
  }

  // --- 重置标记 ---

  /// 重置标签的 "已设置" 标记。
  ///
  /// 该方法不触发监听者通知。
  void resetTagFlag() {
    _tagHasBeenSet = false; // 重置标签已设置标记
  }

  /// 重置分类的 "已设置" 标记。
  ///
  /// 该方法不触发监听者通知。
  void resetCategoryFlag() {
    _categoryHasBeenSet = false; // 重置分类已设置标记
  }

  /// 重置所有 "已设置" 标记。
  void resetFlags() {
    _tagHasBeenSet = false; // 重置标签已设置标记
    _categoryHasBeenSet = false; // 重置分类已设置标记
  }
}
