// lib/widgets/components/screen/checkin/widget/today_checkin_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/level/level_color.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../models/user/user_checkin.dart'; // 导入修改后的 CheckInUser
import '../../../../../services/main/user/user_checkin_service.dart';
import '../../../../ui/badges/user_info_badge.dart'; // **导入 UserInfoBadge**

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
    setState(() { _isLoading = true; });

    try {
      // getTodayCheckInList 返回的是包含精简后 CheckInUser 的列表
      final list = await _checkInService.getTodayCheckInList();
      if (mounted) {
        setState(() {
          _checkInList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载今日签到列表失败: $e');
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题部分 (不变)
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('今日签到名单', style: Theme.of(context).textTheme.titleSmall),
                  if (_checkInList != null) Text('共${_checkInList!.count}人', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  IconButton(icon: Icon(Icons.refresh, size: 20), padding: EdgeInsets.zero, constraints: BoxConstraints(), onPressed: _loadData),
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
      // 使用内联 Loading，并限制高度
      return SizedBox(
        height: widget.maxHeight < 100 ? widget.maxHeight : 100, // 限制最小高度
        child: LoadingWidget.inline(),
      );
    }

    if (_checkInList == null || _checkInList!.users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0), // 给空状态一些空间
        child: const EmptyStateWidget(
          message: '今天还没有用户签到',
          iconData: Icons.calendar_today_outlined, // 可以换个图标
        ),
      );
    }

    // 列表内容
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: ListView.builder(
        itemCount: _checkInList!.users.length,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 调整内边距
        shrinkWrap: true,
        // 根据列表长度决定是否可滚动
        physics: _checkInList!.users.length > (widget.maxHeight / 50).floor() // 粗略估计每项高度约50
            ? AlwaysScrollableScrollPhysics()
            : NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          // 使用修改后的 CheckInUser，它只有 userId
          final checkInUser = _checkInList!.users[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0), // 列表项垂直间距
            child: Row(
              children: [
                // --- 排名/序号 ---
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // 使用 LevelColor 或你喜欢的颜色逻辑
                    color: LevelColor.getLevelColor(index + 1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                SizedBox(width: 8),

                // --- 核心改动：使用 UserInfoBadge 显示用户信息 ---
                Expanded(
                  child: UserInfoBadge(
                    userId: checkInUser.userId, // **传递 userId**
                    showFollowButton: true,      // 根据需要看是否显示关注按钮
                    mini: true,                  // 使用 mini 样式
                    showLevel: true,             // 显示等级
                    backgroundColor: Colors.transparent, // 背景透明
                    padding: EdgeInsets.zero,     // 不需要额外 padding
                  ),
                ),
                // --- 结束改动 ---

                // --- 签到时间和经验值 (不变) ---
                SizedBox(width: 8), // 与 UserInfoBadge 间隔
                Text(
                  checkInUser.formattedTime, // 显示签到时间
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Container(
                  margin: EdgeInsets.only(left: 8),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${checkInUser.experienceGained}', // 显示本次获得经验
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // --- 结束签到时间和经验值 ---
              ],
            ),
          );
        },
      ),
    );
  }


}