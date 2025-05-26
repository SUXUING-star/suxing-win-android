// lib/widgets/forum/post_guidelines.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

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
        AppText(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withSafeOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withSafeOpacity(0.3),
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
            child: AppText(
              text,
              style: TextStyle(
                 fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}