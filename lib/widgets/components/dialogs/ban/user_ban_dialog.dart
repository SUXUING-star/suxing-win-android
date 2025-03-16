// lib/widgets/dialogs/user_ban_dialog.dart

import 'package:flutter/material.dart';
import '../../../models/user/user_ban.dart';

class UserBanDialog extends StatelessWidget {
  final UserBan ban;

  const UserBanDialog({
    Key? key,
    required this.ban,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 禁止返回键关闭对话框
      child: AlertDialog(
        title: Text('账号已被封禁'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '您的账号已被封禁',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text('封禁原因：${ban.reason}'),
              SizedBox(height: 8),
              Text('封禁时间：${ban.banTime.toString().split('.')[0]}'),
              if (!ban.isPermanent) ...[
                SizedBox(height: 8),
                Text('解封时间：${ban.endTime.toString().split('.')[0]}'),
              ],
              SizedBox(height: 16),
              Text(
                ban.isPermanent ? '当前账号已被永久封禁' : '账号暂时被封禁',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // TextButton(
          //   onPressed: () {
          //     // 注销当前用户
          //     Navigator.of(context).pushNamedAndRemoveUntil(
          //       '/login',
          //           (route) => false,
          //     );
          //   },
          //   child: Text('退出登录'),
          // ),
        ],
      ),
    );
  }
}