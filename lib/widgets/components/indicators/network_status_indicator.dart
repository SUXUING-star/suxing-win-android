// lib/widgets/components/indicators/network_status_indicator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/network/network_manager.dart';


class NetworkStatusIndicator extends StatefulWidget {
  final VoidCallback? onReconnect;

  const NetworkStatusIndicator({
    super.key,
    this.onReconnect,
  });

  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkManager>(
      builder: (context, networkManager, _) {
        final isConnected = networkManager.isConnected;

        if (_isLoading) {
          return SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        }

        return Tooltip(
          message: isConnected ? '网络已连接' : '点击重新连接',
          child: GestureDetector(
            onTap: () => _handleTap(networkManager),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap(NetworkManager networkManager) async {
    // 如果已连接，不做任何操作
    if (networkManager.isConnected && !_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 尝试重新连接
      final bool success = await networkManager.reconnect();
      // 注意：现在NetworkManager.reconnect()会在成功连接时自动调用onNetworkRestored回调

      if (success && widget.onReconnect != null) {
        widget.onReconnect!();
      }

      if (mounted) {
        // 显示结果提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '网络已重新连接' : '连接失败，请稍后再试'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重连失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}