// lib/providers/gamelist/game_list_filter_provider.dart (新建文件)
import 'package:flutter/foundation.dart';

class GameListFilterProvider with ChangeNotifier {
  String? _selectedTag;
  bool _tagHasBeenSet = false; // 标记是否是主动设置的

  String? get selectedTag => _selectedTag;
  bool get tagHasBeenSet => _tagHasBeenSet;

  void setTag(String? newTag, {bool fromWidget = false}) {
    // fromWidget 用于区分是页面内操作(如清空按钮)还是外部导航触发
    // 避免在页面内点击标签后，再次触发不必要的加载

    // 只有当新标签与当前标签不同时才更新并通知
    if (_selectedTag != newTag) {
      print('GameListFilterProvider: Setting tag to -> $newTag');
      _selectedTag = newTag;
      _tagHasBeenSet = true; // 标记为已设置
      notifyListeners(); // 通知监听者 (GamesListScreen)
    } else if (newTag != null && !_tagHasBeenSet) {
      // 如果标签相同，但之前未被主动设置过（例如从 null -> 'tagA'，然后又导航到 'tagA'），
      // 也需要标记为已设置，以确保 GamesListScreen 能响应
      _tagHasBeenSet = true;
      // 也许还需要通知？取决于 GamesListScreen 的逻辑是否依赖 _tagHasBeenSet
      // notifyListeners(); // 可以考虑是否需要，如果 GamesListScreen 只看 tag 值可以不用
      //print('GameListFilterProvider: Tag "$newTag" re-confirmed.');
    } else {
      //print('GameListFilterProvider: Tag "$newTag" is the same as current. No change.');
    }
  }

  void clearTag() {
    setTag(null);
  }

  // 重置标记，当 GamesListScreen 处理完 tag 后可以调用
  void resetTagFlag() {
    _tagHasBeenSet = false;
  }
}