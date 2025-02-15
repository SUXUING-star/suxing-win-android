// lib/widgets/dialogs/db_reset_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/connection/db_state_provider.dart';
import '../../utils/font_config.dart';
import '../../services/restart/restart_service.dart';

class DBResetDialog extends StatelessWidget {
  final VoidCallback onReset;

  const DBResetDialog({Key? key, required this.onReset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: Text(
          '连接异常',
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<DBStateProvider>(
              builder: (context, provider, child) {
                return Text(
                  provider.errorMessage ?? '网络连接异常，需要重启应用',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontFamily: FontConfig.defaultFontFamily,
                    fontFamilyFallback: FontConfig.fontFallback,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              '点击重启按钮将重新初始化应用',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                // 尝试应用内重启
                RestartWrapper.restartApp(context);
              } catch (e) {
                print('Restart failed: $e');
                // 如果重启失败，显示提示并退出应用
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('重启失败，即将关闭应用'),
                    duration: const Duration(seconds: 2),
                  ),
                );

                // 延迟一会再关闭，让用户看到提示
                await Future.delayed(const Duration(seconds: 2));

                if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                  exit(0);
                } else {
                  SystemNavigator.pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text(
              '重启应用',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                exit(0);
              } else {
                SystemNavigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text(
              '直接退出',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}