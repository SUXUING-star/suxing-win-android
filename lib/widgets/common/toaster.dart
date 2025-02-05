// lib/widgets/common/toaster.dart
import 'package:flutter/material.dart';

class Toaster {
  static void show(
      BuildContext context, {
        required String message,
        Duration duration = const Duration(seconds: 2),
        bool isError = false,
      }) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();

    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {
            scaffold.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}