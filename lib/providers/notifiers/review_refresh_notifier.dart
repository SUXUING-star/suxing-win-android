// (可以放在一个新的文件里，比如 lib/providers/notifiers/review_refresh_notifier.dart)
import 'package:flutter/foundation.dart';

class ReviewRefreshNotifier extends ChangeNotifier {
  String? _lastNotifiedGameId; // 可选：记录上次通知的游戏ID
  DateTime? _lastNotifyTime; // 可选：记录上次通知时间

  // 通知需要刷新评价列表
  void notifyRefreshNeeded(String gameId) {
    // 可选的防抖/节流逻辑：如果短时间内对同一个游戏ID重复通知，可以忽略
    final now = DateTime.now();
    if (_lastNotifiedGameId == gameId &&
        _lastNotifyTime != null &&
        now.difference(_lastNotifyTime!) < const Duration(milliseconds: 500)) {
      return; // 短时间内重复通知，忽略
    }

    _lastNotifiedGameId = gameId;
    _lastNotifyTime = now;
    notifyListeners(); // 通知所有监听者
  }
}
