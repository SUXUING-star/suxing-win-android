// lib/widgets/forum/post_guidelines.dart
import 'package:flutter/material.dart';
import '../../../../../utils/font/font_config.dart';

class PostGuidelines extends StatelessWidget {
  final List<String> guidelines;
  final String title;

  const PostGuidelines({
    super.key,
    required this.guidelines,
    this.title = '发布指南',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: guidelines
                .map((item) => _buildGuidelineItem(item))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}