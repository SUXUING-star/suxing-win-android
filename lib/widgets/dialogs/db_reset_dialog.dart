// lib/widgets/dialogs/db_reset_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/db_state_provider.dart';

class DBResetDialog extends StatelessWidget {
  final VoidCallback onReset;

  const DBResetDialog({Key? key, required this.onReset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 防止返回键关闭对话框
      child: AlertDialog(
        title: Text('连接异常'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<DBStateProvider>(
              builder: (context, provider, child) {
                return Text(provider.errorMessage ?? '网络连接异常，需要重启应用');
              },
            ),
            SizedBox(height: 16),
            Text('请点击下方按钮关闭应用', style: TextStyle(fontSize: 14, color: Colors.white)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: onReset,
            child: Text('重启应用'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}