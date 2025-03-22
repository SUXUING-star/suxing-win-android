// lib/widgets/components/screen/activity/activity_stats_card.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ActivityStatsCard extends StatelessWidget {
  final Map<String, int> activityStats;
  final bool isLoading;
  final String Function(String) getActivityTypeName;
  final Color Function(String) getActivityTypeColor;

  const ActivityStatsCard({
    Key? key,
    required this.activityStats,
    required this.isLoading,
    required this.getActivityTypeName,
    required this.getActivityTypeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (activityStats.isEmpty) {
      return Container(
        height: 80,
        child: Center(child: Text('无法加载统计数据')),
      );
    }

    // 提取主要统计数据
    final totalActivities = activityStats['totalActivities'] ?? 0;

    // 按照数量排序获取前三种类型的活动
    final typeCounts = <String, int>{};
    activityStats.forEach((key, value) {
      if (key != 'totalActivities') {
        typeCounts[key] = value;
      }
    });

    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // 总动态数
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue.shade700),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总动态数',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$totalActivities 条',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // 动态类型分布
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: math.min(3, sortedTypes.length),
            itemBuilder: (context, index) {
              final type = sortedTypes[index].key;
              final count = sortedTypes[index].value;
              final typeName = getActivityTypeName(type);
              final color = getActivityTypeColor(type);

              return Container(
                width: 90,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      typeName,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}