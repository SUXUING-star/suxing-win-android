// // lib/providers/ui/desktop_actions_provider.dart
// import 'package:flutter/material.dart';
// import 'package:collection/collection.dart'; // 导入 collection 包进行深度比较
//
// class DesktopActionsProvider extends ChangeNotifier {
//   List<Widget> _actions = [];
//   bool _showBackButton = false;
//
//   List<Widget> get actions => _actions;
//   bool get showBackButton => _showBackButton;
//
//   // 使用 DeepCollectionEquality 来比较 Widget 列表（更可靠，但可能稍慢）
//   final DeepCollectionEquality _equality = const DeepCollectionEquality();
//
//   void setActions(List<Widget>? newActions, {bool showBackButton = false}) {
//     final effectiveActions = newActions ?? [];
//
//     // *** 比较状态是否有实际变化 ***
//     // 如果 actions 列表内容或 showBackButton 状态没有变化，就不需要通知
//     if (_equality.equals(_actions, effectiveActions) && _showBackButton == showBackButton) {
//       // print("DesktopActionsProvider: State unchanged, skipping notify."); // 调试日志
//       return; // 状态未变，直接返回
//     }
//
//     // *** 先立即更新内部状态 ***
//     _actions = effectiveActions;
//     _showBackButton = showBackButton;
//
//     // *** 使用 Future.delayed 将 notifyListeners() 推迟到下一事件循环 ***
//     // 这可以避免 "setState() or markNeedsBuild() called during build" 错误
//     Future.delayed(Duration.zero, () {
//       // 在延迟回调中检查 Provider 是否还在活跃 (可选但更安全)
//       // if (hasListeners) { // 或者直接调用，让 ChangeNotifier 内部处理
//       // print("DesktopActionsProvider: Notifying listeners (delayed)"); // 调试日志
//       notifyListeners();
//       // }
//     });
//   }
// }
//
