/// 定义了 LazyLayoutBuilder 组件。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

typedef LazyLayoutBuilderCallback = Widget Function(
    BuildContext context, BoxConstraints constraints);

/// 一个根据窗口调整状态来优化布局构建的组件。
///
/// 它是 [LayoutBuilder] 的高性能替代品。当窗口正在调整大小时，
/// 显示 [resizingPlaceholder]；否则，执行 [builder] 并提供布局约束 [BoxConstraints]。
class LazyLayoutBuilder extends StatelessWidget {
  /// [WindowStateProvider] 的引用，用于获取窗口是否正在调整大小的状态。
  final WindowStateProvider windowStateProvider;

  /// 用于构建正常UI的构建器，其签名与 [LayoutBuilder.builder] 完全相同。
  final LazyLayoutBuilderCallback builder;

  /// 在窗口调整大shims显示时的占位符 Widget。
  final Widget? resizingPlaceholder;

  /// 创建一个 [LazyLayoutBuilder] 实例。
  const LazyLayoutBuilder({
    super.key,
    required this.windowStateProvider,
    required this.builder,
    this.resizingPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    // 使用 StreamBuilder 监听窗口状态流。
    return StreamBuilder<bool>(
      stream: windowStateProvider.isResizingWindowStream,
      initialData: windowStateProvider.isResizingWindow,
      builder: (context, snapshot) {
        final bool isResizing = snapshot.data ?? false;

        if (isResizing) {
          // 正在调整大小时，显示占位符。
          return resizingPlaceholder ??
              const LoadingWidget(message: "正在调整布局...");
        } else {
          // 调整结束后，使用原生 LayoutBuilder 来获取约束并执行 builder。
          // 这里的 LayoutBuilder 是安全的，因为它仅在非调整状态下被构建。
          return LayoutBuilder(
            builder: builder,
          );
        }
      },
    );
  }
}
