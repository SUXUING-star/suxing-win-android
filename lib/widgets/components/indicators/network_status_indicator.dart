// lib/widgets/components/indicators/network_status_indicator.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/main/network/network_manager.dart';

class NetworkStatusIndicator extends StatefulWidget {
  final VoidCallback? onReconnect;

  const NetworkStatusIndicator({
    Key? key,
    this.onReconnect,
  }) : super(key: key);

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

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isLoading ? null : () => _handleTap(networkManager),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getBackgroundColor(isConnected),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  if (_isLoading)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    )
                  else
                    Text(
                      isConnected ? '已连接' : '重连',
                      style: TextStyle(
                        fontSize: 12,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(bool isConnected) {
    return isConnected
        ? Colors.green.withOpacity(0.1)
        : Colors.red.withOpacity(0.1);
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