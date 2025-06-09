// lib/widgets/ui/utils/network_error_listener_widget.dart

/// 该文件定义了 NetworkErrorListenerWidget，一个用于监听网络错误的 StatefulWidget。
/// NetworkErrorListenerWidget 在检测到网络连接异常时，显示重试对话框。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/services/main/network/network_manager.dart'; // 网络管理器
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载指示器组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart'; // 基础输入对话框
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 应用文本组件
import 'package:suxingchahui/app.dart'; // 导入主应用入口，获取 NavigatorKey

/// `NetworkErrorListenerWidget` 类：网络错误监听器。
///
/// 该 Widget 负责监听网络连接状态，并在网络断开时显示错误对话框。
class NetworkErrorListenerWidget extends StatefulWidget {
  final NetworkManager networkManager; // 网络管理器实例
  final Widget child; // 子 Widget

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [child]：要渲染的子 Widget。
  /// [networkManager]：网络管理器实例。
  const NetworkErrorListenerWidget({
    super.key,
    required this.child,
    required this.networkManager,
  });

  @override
  State<NetworkErrorListenerWidget> createState() =>
      _NetworkErrorListenerWidgetState();
}

/// `_NetworkErrorListenerWidgetState` 类：`NetworkErrorListenerWidget` 的状态管理。
class _NetworkErrorListenerWidgetState
    extends State<NetworkErrorListenerWidget> {
  bool _isDialogShowing = false; // 标记网络错误对话框是否正在显示

  StreamSubscription<bool>? _networkSubscription; // 网络连接状态变化的订阅器

  /// 依赖项发生变化时调用。
  ///
  /// 订阅网络连接状态 Stream，根据连接状态显示或隐藏对话框。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _networkSubscription ??= // 如果订阅器为空，则进行订阅
        widget.networkManager.connectionStatusStream.listen((isConnected) {
      if (!mounted) return; // Widget 未挂载时直接返回

      if (!isConnected && !_isDialogShowing) {
        // 网络断开且对话框未显示
        _showNetworkErrorDialog(); // 显示网络错误对话框
      } else if (isConnected && _isDialogShowing) {
        // 网络恢复且对话框已显示
        _hideNetworkErrorDialog(); // 隐藏网络错误对话框
      }
    });
  }

  /// 销毁状态。
  ///
  /// 取消网络订阅。
  @override
  void dispose() {
    _networkSubscription?.cancel(); // 取消网络订阅
    super.dispose(); // 调用父类销毁方法
  }

  /// 显示网络错误对话框。
  ///
  /// 该方法在网络断开时调用，显示一个可重试的提示对话框。
  void _showNetworkErrorDialog() {
    if (_isDialogShowing || // 对话框已显示
        !mounted || // Widget 未挂载
        mainNavigatorKey.currentContext == null) {
      // 导航器上下文为空
      return;
    }

    _isDialogShowing = true; // 标记对话框正在显示
    final ValueNotifier<bool> isRetryingNotifier =
        ValueNotifier<bool>(false); // 重试状态通知器

    BaseInputDialog.show<void>(
      context: mainNavigatorKey.currentContext!, // 对话框上下文
      title: "网络连接异常", // 对话框标题
      contentBuilder: (dialogContext) {
        // 内容构建器
        return ValueListenableBuilder<bool>(
          valueListenable: isRetryingNotifier, // 监听重试状态变化
          builder: (context, isRetrying, child) {
            return Column(
              mainAxisSize: MainAxisSize.min, // 垂直方向最小尺寸
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0), // 底部内边距
                  child: AppText(
                    isRetrying
                        ? "正在尝试重新连接..."
                        : "无法连接到服务器，请检查您的网络连接或稍后重试。", // 根据重试状态显示不同消息
                    textAlign: TextAlign.center, // 文本居中
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withSafeOpacity(0.8)), // 文本样式
                  ),
                ),
                if (isRetrying) // 重试时显示加载指示器
                  const LoadingWidget(
                    size: 32.0, // 加载指示器尺寸
                  ),
              ],
            );
          },
        );
      },
      confirmButtonText: "重试", // 确认按钮文本
      confirmButtonColor: Theme.of(mainNavigatorKey.currentContext!)
          .colorScheme
          .primary, // 确认按钮颜色
      onConfirm: () async {
        // 确认按钮点击回调
        if (isRetryingNotifier.value) {
          // 正在重试时阻止重复操作
          return;
        }

        isRetryingNotifier.value = true; // 设置为正在重试
        await widget.networkManager.reconnect(); // 尝试重新连接

        if (mounted) {
          // Widget 挂载时重置重试状态
          isRetryingNotifier.value = false;
        }
      },
      showCancelButton: false, // 不显示取消按钮
      barrierDismissible: false, // 强制用户交互
    ).then((_) {
      // 对话框关闭后的回调
      if (mounted) {
        // Widget 挂载时重置对话框状态和销毁通知器
        _isDialogShowing = false;
        isRetryingNotifier.dispose();
      }
    });
  }

  /// 隐藏网络错误对话框。
  ///
  /// 当网络恢复时调用，通过导航器关闭对话框。
  void _hideNetworkErrorDialog() {
    if (!mounted || // Widget 未挂载
        mainNavigatorKey.currentContext == null || // 导航器上下文为空
        !_isDialogShowing) {
      // 对话框未显示
      return;
    }

    if (Navigator.canPop(mainNavigatorKey.currentContext!)) {
      // 导航器可以弹出时
      Navigator.pop(mainNavigatorKey.currentContext!); // 弹出对话框
    }
  }

  /// 构建 Widget。
  ///
  /// 返回 Widget 的子 Widget。
  @override
  Widget build(BuildContext context) {
    return widget.child; // 渲染子 Widget
  }
}
