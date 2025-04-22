// lib/widgets/form/gameform/components/loading_overlay.dart

import 'package:flutter/material.dart';
import '../../../../../utils/font/font_config.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  '正在上传图片...',
                  style: TextStyle(
                      fontFamily: FontConfig.defaultFontFamily,
                      fontSize: 16
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}