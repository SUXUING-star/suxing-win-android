// lib/widgets/components/screen/checkin/checkin_rules_card.dart
import 'package:flutter/material.dart';

class CheckInRulesCard extends StatelessWidget {
  const CheckInRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '签到规则',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildRuleItem(
              icon: Icons.add_circle_outline,
              text: '每日签到可获得基础经验值10点',
              context: context,
            ),
            _buildRuleItem(
              icon: Icons.trending_up,
              text: '连续签到可获得额外奖励，每天增加5点',
              context: context,
            ),
            _buildRuleItem(
              icon: Icons.calendar_today,
              text: '连续签到7天达到最高奖励，可获得45点经验',
              context: context,
            ),
            _buildRuleItem(
              icon: Icons.warning_amber_outlined,
              text: '签到中断后，连续签到天数将重置',
              context: context,
            ),
            _buildRuleItem(
              icon: Icons.stars,
              text: '经验值可提升用户等级，解锁更多功能',
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String text,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
