// lib/widgets/components/screen/activity/card/activity_type_filter.dart

import 'package:flutter/material.dart';

class ActivityTypeFilter extends StatelessWidget {
  final String? selectedType;
  final Function(String?) onTypeSelected;

  const ActivityTypeFilter({
    Key? key,
    this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(context, null, '全部'),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'gameComment', '游戏评论'),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'gameLike', '游戏点赞'),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'gameCollection', '游戏收藏'),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'postReply', '帖子回复'),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'userFollow', '用户关注'),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'checkIn', '签到'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String? type, String label) {
    final bool isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onTypeSelected(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}