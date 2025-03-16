// lib/widgets/components/screen/profile/error_widget.dart
import 'package:flutter/material.dart';
import '../../../../utils/font/font_config.dart';

class ProfileErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ProfileErrorWidget({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(
              '重新加载',
              style: TextStyle(
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

