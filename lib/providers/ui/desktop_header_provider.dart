// lib/providers/ui/desktop_header_provider.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // flutter pub add collection

// (DesktopHeaderInfo class 和 DesktopHeaderProvider class 保持和上个回答中的一致)
// ...确保它包含 title, leading, actions, onBackButtonPressed, isEmpty, ==, hashCode ...
// ...确保 updateHeaderFromAppBar 和 resetHeader 方法也存在...
class DesktopHeaderInfo {
  final String? title;
  final Widget? leading; // 存储实际的 leading widget
  final List<Widget>? actions;
  final VoidCallback? onBackButtonPressed; // 存储实际的回调

  DesktopHeaderInfo({
    this.title,
    this.leading,
    this.actions,
    this.onBackButtonPressed,
  });

  // 用于比较，避免不必要的更新
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DesktopHeaderInfo &&
              runtimeType == other.runtimeType &&
              title == other.title &&
              leading == other.leading && // Widget 比较是引用比较
              ListEquality().equals(actions, other.actions) && // 比较列表内容
              onBackButtonPressed == other.onBackButtonPressed;

  @override
  int get hashCode =>
      title.hashCode ^
      leading.hashCode ^
      ListEquality().hash(actions) ^ // 使用列表内容的哈希
      onBackButtonPressed.hashCode;

  bool get isEmpty => title == null && leading == null && (actions == null || actions!.isEmpty);
}

class DesktopHeaderProvider with ChangeNotifier {
  DesktopHeaderInfo _headerInfo = DesktopHeaderInfo();
  bool _isUpdatingFromAppBar = false;

  DesktopHeaderInfo get headerInfo => _headerInfo;

  void updateHeaderFromAppBar(BuildContext context, {
    required String appBarTitle,
    List<Widget>? appBarActions,
    Widget? appBarLeading,
    bool automaticallyImplyLeading = true,
  }) {
    if (_isUpdatingFromAppBar) return;

    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    final bool useCloseButton = parentRoute is PageRoute<dynamic> && parentRoute.fullscreenDialog;

    Widget? effectiveLeading = appBarLeading;
    VoidCallback? backCallback;

    // 检查是否需要自动添加返回按钮
    if (effectiveLeading == null && automaticallyImplyLeading && canPop) {
      // 修改：创建一个 IconButton 来表示返回按钮，以便在侧边栏中渲染
      effectiveLeading = IconButton(
        icon: Icon(useCloseButton ? Icons.close : Icons.arrow_back),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip, // 使用本地化 tooltip
        onPressed: () { // onPressed 直接包含逻辑
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      );
      backCallback = (effectiveLeading as IconButton).onPressed; // 提取回调
    } else if (effectiveLeading is IconButton) {
      backCallback = effectiveLeading.onPressed;
    } else if (effectiveLeading is BackButton) {
      effectiveLeading = IconButton(icon: Icon(Icons.arrow_back), onPressed: effectiveLeading.onPressed); // 转为 IconButton
      backCallback = effectiveLeading.onPressed ?? () { if (Navigator.canPop(context)) Navigator.pop(context); };
    } else if (effectiveLeading is CloseButton) {
      effectiveLeading = IconButton(icon: Icon(Icons.close), onPressed: effectiveLeading.onPressed); // 转为 IconButton
      backCallback = effectiveLeading.onPressed ?? () { if (Navigator.canPop(context)) Navigator.pop(context); };
    }


    final newInfo = DesktopHeaderInfo(
      title: appBarTitle,
      leading: effectiveLeading, // 存储计算后的 leading widget (通常是 IconButton)
      actions: appBarActions,
      onBackButtonPressed: backCallback, // 存储计算后的返回回调
    );

    if (_headerInfo != newInfo) {
      _headerInfo = newInfo;
      _isUpdatingFromAppBar = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          print("DesktopHeaderProvider: Notifying listeners. Title=${_headerInfo.title}");
          notifyListeners();
        }
        _isUpdatingFromAppBar = false;
      });
    }
  }

  void resetHeader() {
    if (!_headerInfo.isEmpty) {
      print("DesktopHeaderProvider: Resetting header.");
      _headerInfo = DesktopHeaderInfo();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }
}