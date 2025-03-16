// lib/widgets/components/screen/profile/edit_profile_dialog.dart
import 'package:flutter/material.dart';
import '../../../../models/user/user.dart';
import '../../../../utils/font/font_config.dart';

class EditProfileDialog extends StatelessWidget {
  final User user;
  final Function(String) onSave;

  const EditProfileDialog({
    Key? key,
    required this.user,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController usernameController = TextEditingController(text: user.username);

    return AlertDialog(
      title: Text(
        '编辑个人资料',
        style: TextStyle(
          fontFamily: FontConfig.defaultFontFamily,
          fontFamilyFallback: FontConfig.fontFallback,
        ),
      ),
      content: TextField(
        controller: usernameController,
        style: TextStyle(
          fontFamily: FontConfig.defaultFontFamily,
          fontFamilyFallback: FontConfig.fontFallback,
        ),
        decoration: InputDecoration(
          labelText: '用户名',
          hintText: '输入新的用户名',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '取消',
            style: TextStyle(
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            onSave(usernameController.text);
            Navigator.of(context).pop();
          },
          child: Text(
            '保存',
            style: TextStyle(
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
          ),
        ),
      ],
    );
  }
}