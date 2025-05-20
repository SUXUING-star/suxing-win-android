// lib/providers/gamelist/game_list_filter_provider.dart
import 'package:flutter/foundation.dart';

class GameListFilterProvider with ChangeNotifier {
  String? _selectedTag;
  bool _tagHasBeenSet = false;

  String? _selectedCategory;
  bool _categoryHasBeenSet = false;

  // --- Getters ---
  String? get selectedTag => _selectedTag;
  bool get tagHasBeenSet => _tagHasBeenSet;

  String? get selectedCategory => _selectedCategory;
  bool get categoryHasBeenSet => _categoryHasBeenSet;

  // --- Setters (包含互斥逻辑) ---

  /// 设置选中的标签。如果设置了非 null 的标签，会自动清除选中的分类。
  void setTag(String? newTag) {
    // 只有当新标签与当前标签不同时才更新
    if (_selectedTag != newTag) {
      print('GameListFilterProvider: Setting tag to -> $newTag');
      _selectedTag = newTag;
      _tagHasBeenSet = true; // 标记 Tag 已设置

      // *** 互斥逻辑: 设置 Tag 时清除 Category ***
      if (newTag != null && _selectedCategory != null) {
        print('GameListFilterProvider: Clearing category because tag was set.');
        _selectedCategory = null;
        _categoryHasBeenSet = false; // 分类被清除了，重置标记
      }
      notifyListeners(); // 通知监听者
    } else if (newTag != null && !_tagHasBeenSet) {
      // 如果标签相同，但之前未被主动设置过，也标记为已设置
      _tagHasBeenSet = true;
      // 这里可能不需要 notifyListeners，因为值没变
      //print('GameListFilterProvider: Tag "$newTag" re-confirmed.');
    }
  }

  /// 设置选中的分类。如果设置了非 null 的分类，会自动清除选中的标签。
  void setCategory(String? newCategory) {
    // 只有当新分类与当前分类不同时才更新
    if (_selectedCategory != newCategory) {
      _selectedCategory = newCategory;
      _categoryHasBeenSet = true; // 标记 Category 已设置

      // *** 互斥逻辑: 设置 Category 时清除 Tag ***
      if (newCategory != null && _selectedTag != null) {
        _selectedTag = null;
        _tagHasBeenSet = false; // 标签被清除了，重置标记
      }
      notifyListeners(); // 通知监听者
    } else if (newCategory != null && !_categoryHasBeenSet) {
      // 如果分类相同，但之前未被主动设置过，也标记为已设置
      _categoryHasBeenSet = true;
      //print('GameListFilterProvider: Category "$newCategory" re-confirmed.');
    }
  }

  // --- 清除方法 ---

  /// 清除选中的标签 (不影响分类)。
  void clearTag() {
    setTag(null);
  }

  /// 清除选中的分类 (不影响标签)。
  void clearCategory() {
    setCategory(null);
  }

  // --- 重置标记 ---

  /// 重置 Tag 的 "已设置" 标记。当 UI 处理完 Tag 变化后调用。
  void resetTagFlag() {
    //print("GameListFilterProvider: Resetting tag flag.");
    _tagHasBeenSet = false;
    // 注意：这里不调用 notifyListeners，因为它只是重置内部状态，不应触发 UI 重建
  }

  /// 重置 Category 的 "已设置" 标记。当 UI 处理完 Category 变化后调用。
  void resetCategoryFlag() {
    //print("GameListFilterProvider: Resetting category flag.");
    _categoryHasBeenSet = false;
    // 注意：同样不调用 notifyListeners
  }

  /// 重置所有 "已设置" 标记。
  void resetFlags() {
    //bool changed = _tagHasBeenSet || _categoryHasBeenSet;
    _tagHasBeenSet = false;
    _categoryHasBeenSet = false;;
  }
}