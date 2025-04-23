// lib/widgets/components/screen/checkin/today_checkin_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../models/user/user_checkin.dart';
import '../../../../../services/main/user/user_checkin_service.dart';
import '../../../../ui/badges/user_info_badge.dart';

class TodayCheckInList extends StatefulWidget {
  final double maxHeight;
  final bool showTitle;

  const TodayCheckInList({
    super.key,
    this.maxHeight = 250,
    this.showTitle = true,
  });

  @override
  _TodayCheckInListState createState() => _TodayCheckInListState();
}

class _TodayCheckInListState extends State<TodayCheckInList> {
  bool _isLoading = true;
  CheckInUserList? _checkInList;
  late UserCheckInService _checkInService;

  @override
  void initState() {
    super.initState();
    _checkInService = Provider.of<UserCheckInService>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final list = await _checkInService.getTodayCheckInList();

      if (mounted) {
        setState(() {
          _checkInList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '今日签到名单',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (_checkInList != null)
                    Text(
                      '共${_checkInList!.count}人',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: _loadData,
                  ),
                ],
              ),
            ),

          // 内容区域
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return LoadingWidget.inline();
    }

    if (_checkInList == null || _checkInList!.users.isEmpty) {
      return const EmptyStateWidget(
        message: '今天还没有用户签到',
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.maxHeight,
      ),
      child: ListView.builder(
        itemCount: _checkInList!.users.length,
        padding: EdgeInsets.all(12),
        shrinkWrap: true,
        physics: _checkInList!.users.length > 5
            ? AlwaysScrollableScrollPhysics()
            : NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final user = _checkInList!.users[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                // 序号
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _getRankColor(index + 1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // 用户信息
                Expanded(
                  child: UserInfoBadge(
                    userId: user.userId,
                    showFollowButton: false,
                    mini: true,
                  ),
                ),

                // 签到时间
                Text(
                  user.formattedTime,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),

                // 经验值
                Container(
                  margin: EdgeInsets.only(left: 8),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${user.experienceGained}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.blueGrey.shade300;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.grey.shade400;
    }
  }
}
