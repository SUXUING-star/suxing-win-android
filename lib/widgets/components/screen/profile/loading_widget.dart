// lib/widgets/components/screen/profile/loading_widget.dart
import 'package:flutter/material.dart';
import '../../../../utils/font/font_config.dart';

class ProfileLoadingWidget extends StatelessWidget {
  final bool showText;

  const ProfileLoadingWidget({
    Key? key,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          if (showText) ...[
            SizedBox(height: 16),
            Text(
              '加载用户信息...',
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
          ],
        ],
      ),
    );
  }
}