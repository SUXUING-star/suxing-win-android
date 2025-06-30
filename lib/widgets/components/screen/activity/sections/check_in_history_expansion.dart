// lib/widgets/components/screen/activity/sections/check_in_history_expansion.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/models/activity/activity.dart';
import 'package:suxingchahui/models/activity/activity_extension.dart';

class CheckInHistoryExpansion extends StatefulWidget {
  final Activity activity;

  const CheckInHistoryExpansion({
    super.key,
    required this.activity,
  });

  @override
  State<CheckInHistoryExpansion> createState() =>
      _CheckInHistoryExpansionState();
}

class _CheckInHistoryExpansionState extends State<CheckInHistoryExpansion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final checkInDetails = widget.activity.checkInDetails;

    if (!widget.activity.enrichActivityType.isCheckIn ||
        checkInDetails == null ||
        checkInDetails.recentCheckIns.isEmpty) {
      return const SizedBox.shrink();
    }

    // 后端返回的 recentCheckIns 列表已按最新在前排序。
    // 如果列表只有一个元素（即本次签到），则没有“更早的”历史可供展开。
    // 我们要展示的是除了最新一次（通常是列表中的第一个）之外的历史记录。
    final List<DateTime> historyToShow =
        checkInDetails.recentCheckIns.length > 1
            ? checkInDetails.recentCheckIns.sublist(1) // 获取除第一个元素外的所有元素
            : []; // 如果只有一个或没有，则历史列表为空

    if (historyToShow.isEmpty) {
      return const SizedBox.shrink(); // 没有更早的历史记录可显示
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isExpanded
                        ? '收起签到历史'
                        : '查看最近 ${historyToShow.length} 次签到历史',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                  top: 8.0, left: 16.0, right: 16.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: historyToShow.map((dateTime) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Text(
                      ' - ${DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
