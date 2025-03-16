// lib/widgets/components/screen/forum/community_guidelines.dart - 简化版本

import 'package:flutter/material.dart';

class CommunityGuidelines extends StatelessWidget {
  final bool useSeparateCard;

  const CommunityGuidelines({
    Key? key,
    this.useSeparateCard = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (useSeparateCard)
          const Text(
            '社区守则',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (useSeparateCard) const SizedBox(height: 16),
        _buildGuidelineItem(
          icon: Icons.sentiment_satisfied_alt,
          text: '友善交流，互相尊重',
          description: '对他人友善，避免人身攻击和侮辱性言论。',
        ),
        _buildGuidelineItem(
          icon: Icons.forum_outlined,
          text: '积极参与讨论',
          description: '提出建设性的观点，推动有意义的交流。',
        ),
        _buildGuidelineItem(
          icon: Icons.report_outlined,
          text: '发现问题及时举报',
          description: '看到不当内容，请使用举报功能提醒管理员。',
        ),
      ],
    );

    if (useSeparateCard) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String text,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}