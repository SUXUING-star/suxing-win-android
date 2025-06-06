// lib/widgets/ui/utils/network_error_listener_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/network/network_manager.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/app.dart';

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

  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _networkManager = Provider.of<NetworkManager>(context, listen: false);
      _networkManager?.addListener(_handleNetworkChange);

      if (_networkManager != null && !_networkManager!.isConnected) {
        _handleNetworkChange();
      }
    });
  }

  @override
  void dispose() {
    _networkManager?.removeListener(_handleNetworkChange);
    super.dispose();
  }

  void _handleNetworkChange() {
    if (!mounted || _networkManager == null) return;

    final isConnected = _networkManager!.isConnected;

    if (!isConnected && !_isDialogShowing) {
      _showNetworkErrorDialog();
    } else if (isConnected && _isDialogShowing) {
      _hideNetworkErrorDialog();
    }
  }

  void _showNetworkErrorDialog() {
    if (_isDialogShowing || !mounted || mainNavigatorKey.currentContext == null) {
      return;
    }

    _isDialogShowing = true;
    final ValueNotifier<bool> isRetryingNotifier = ValueNotifier<bool>(false);

    BaseInputDialog.show<void>(
      context: mainNavigatorKey.currentContext!,
      title: "网络连接异常",
      contentBuilder: (dialogContext) {
        return ValueListenableBuilder<bool>(
          valueListenable: isRetryingNotifier,
          builder: (context, isRetrying, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: AppText(
                    isRetrying
                        ? "正在尝试重新连接..."
                        : "无法连接到服务器，请检查您的网络连接或稍后重试。",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withSafeOpacity(0.8)),
                  ),
                ),
                if (isRetrying)
                  LoadingWidget.inline(
                    size: 32.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            );
          },
        );
      },
      confirmButtonText: "重试",
      confirmButtonColor:
      Theme.of(mainNavigatorKey.currentContext!).colorScheme.primary,
      onConfirm: () async {
        if (isRetryingNotifier.value) {
          return;
        }

        isRetryingNotifier.value = true;
        await _networkManager?.reconnect();

        if (mounted) {
          isRetryingNotifier.value = false;
        }
      },
      showCancelButton: false,
      barrierDismissible: false,
    ).then((_) {
      if (mounted) {
        _isDialogShowing = false;
        isRetryingNotifier.dispose();
      }
    });
  }

  void _hideNetworkErrorDialog() {
    if (!mounted || mainNavigatorKey.currentContext == null || !_isDialogShowing) {
      return;
    }

    if (Navigator.canPop(mainNavigatorKey.currentContext!)) {
      Navigator.pop(mainNavigatorKey.currentContext!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}