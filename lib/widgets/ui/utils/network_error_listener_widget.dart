// lib/widgets/ui/utils/network_error_listener_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/network/network_manager.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/app.dart'; // 为了 mainNavigatorKey

class NetworkErrorListenerWidget extends StatefulWidget {
  final Widget child;

  const NetworkErrorListenerWidget({super.key, required this.child});

  @override
  State<NetworkErrorListenerWidget> createState() =>
      _NetworkErrorListenerWidgetState();
}

class _NetworkErrorListenerWidgetState
    extends State<NetworkErrorListenerWidget> {
  NetworkManager? _networkManager;
  // 用于跟踪我们是否“打算”显示网络错误对话框，以避免重复打开或管理错误的弹窗实例
  bool _isNetworkErrorDialogIntended = false;
  // 用于存储 BaseInputDialog.show 返回的 Future，以便在需要时可以等待它
  Future<void>? _dialogFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _networkManager = Provider.of<NetworkManager>(context, listen: false);
        _networkManager?.addListener(_handleNetworkChange);
        _networkManager?.onNetworkRestored = _handleNetworkRestored;

        // 初始检查: 如果 NetworkManager 已初始化且当前未连接
        if (_networkManager != null &&
            _networkManager!.isInitialized &&
            !_networkManager!.isConnected) {
          _handleNetworkChange();
        }
      } catch (e) {
        print(
            "NetworkErrorListener: Error obtaining NetworkManager or setting listener: $e");
      }
    });
  }

  @override
  void dispose() {
    _networkManager?.removeListener(_handleNetworkChange);
    if (_networkManager != null) {
      _networkManager!.onNetworkRestored = null;
    }
    // 如果对话框仍在显示，理论上应该在 dispose 时尝试关闭它，但 BaseInputDialog 的管理方式使得这有点复杂。
    // 通常，当 widget dispose 时，其弹出的对话框也应该被处理。
    // 但由于我们使用全局 navigatorKey，对话框的生命周期可能超出此 widget。
    // _hideNetworkErrorDialog(); // 考虑是否需要，以及其影响。
    super.dispose();
  }

  void _handleNetworkChange() {
    if (!mounted || _networkManager == null) return;

    final bool isConnected = _networkManager!.isConnected;

    if (!isConnected) {
      // 网络断开，并且我们还没有打算显示对话框，或者上一个对话框已关闭
      if (!_isNetworkErrorDialogIntended) {
        _showNetworkErrorDialog();
      }
    } else {
      // 网络已连接，并且我们之前打算显示/已显示对话框
      if (_isNetworkErrorDialogIntended) {
        _hideNetworkErrorDialog();
      }
    }
  }

  void _handleNetworkRestored() {
    if (!mounted) return;
    // 网络恢复，如果对话框仍然是我们“打算”显示的，则隐藏它
    if (_isNetworkErrorDialogIntended) {
      _hideNetworkErrorDialog();
    }
  }

  Future<void> _showNetworkErrorDialog() async {
    // 如果已经打算显示，或者 navigator context 不可用，则不执行
    if (_isNetworkErrorDialogIntended ||
        !mounted ||
        mainNavigatorKey.currentContext == null) {
      return;
    }

    _isNetworkErrorDialogIntended = true;

    // BaseInputDialog.show 返回一个 Future，它在对话框关闭时完成。
    // 我们保存这个 future，以便知道对话框何时关闭。
    _dialogFuture = BaseInputDialog.show<bool>(
      context: mainNavigatorKey.currentContext!, // 使用全局 NavigatorKey
      title: "网络连接异常",
      contentBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: AppText(
              "无法连接到服务器，请检查您的网络连接或稍后重试。",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(ctx)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withSafeOpacity(0.8)),
            ),
          ),
          LoadingWidget.inline(
            size: 32.0,
            color: Theme.of(ctx).colorScheme.primary,
          ),
        ],
      ),
      confirmButtonText: "重试",
      confirmButtonColor:
          Theme.of(mainNavigatorKey.currentContext!).colorScheme.primary,
      onConfirm: () async {
        if (_networkManager != null) {
          bool success = await _networkManager!.reconnect();
          // 不论成功与否，BaseInputDialog 都会在 onConfirm 执行后关闭。
          // NetworkManager 会 notifyListeners，_handleNetworkChange 会被触发。
          return success; // 返回给 BaseInputDialog 的处理逻辑
        }
        return false;
      },
      showCancelButton: false,
      barrierDismissible: false,
      allowDismissWhenNotProcessing: false,
      isDraggable: false, // 网络错误对话框通常不需要拖拽
      isScalable: false, // 也不需要缩放
    );

    // 等待对话框关闭
    await _dialogFuture;

    // 当对话框关闭后（无论是通过确认按钮还是其他方式——虽然这里我们禁用了其他方式），
    // 我们重置 _isNetworkErrorDialogIntended 标志。
    // 这样做是为了，如果网络在重试后仍然没有恢复，
    // _handleNetworkChange (由 NetworkManager 的监听器触发) 能够再次检测到
    // "!isConnected" 和 "!_isNetworkErrorDialogIntended"，从而再次调用 _showNetworkErrorDialog。
    if (mounted) {
      _isNetworkErrorDialogIntended = false;
      // 此处不需要手动调用 _handleNetworkChange，因为 _networkManager.reconnect()
      // 内部的 _updateConnectionStatus() 会 notifyListeners()，从而触发 _handleNetworkChange。
    }
  }

  void _hideNetworkErrorDialog() {
    // 只有当我们“打算”显示对话框时，才尝试关闭
    if (!mounted ||
        mainNavigatorKey.currentContext == null ||
        !_isNetworkErrorDialogIntended) {
      return;
    }

    // 尝试关闭通过 mainNavigatorKey 推送的顶层路由（应该是我们的对话框）
    // Navigator.canPop 是一个好习惯
    if (Navigator.canPop(mainNavigatorKey.currentContext!)) {
      Navigator.pop(mainNavigatorKey.currentContext!);
    }

    // 无论是否真的 pop 成功（可能已经被 BaseInputDialog 自己关闭了），
    // 我们都更新意图标志，表示我们不再“打算”显示这个对话框了。
    _isNetworkErrorDialogIntended = false;
  }

  @override
  Widget build(BuildContext context) {
    // 这个 Widget 本身不渲染任何UI，它只是一个监听器和对话框控制器。
    // 它将其 child 直接返回。
    return widget.child;
  }
}
