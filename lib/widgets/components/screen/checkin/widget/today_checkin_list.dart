// lib/widgets/components/screen/checkin/widget/today_checkin_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_data_status.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../models/user/user_checkin.dart';
import '../../../../../services/main/user/user_checkin_service.dart';
import '../../../../ui/badges/user_info_badge.dart'; // 导入 UserInfoBadge

class TodayCheckInList extends StatefulWidget {
  final User? currentUser;
  final double maxHeight;
  final bool showTitle;

  const TodayCheckInList({
    super.key,
    required this.currentUser,
    this.maxHeight = 250, // 默认最大高度
    this.showTitle = true, // 默认显示标题
  });

  @override
  _TodayCheckInListState createState() => _TodayCheckInListState();
}

class _TodayCheckInListState extends State<TodayCheckInList> {
  bool _isLoading = true;
  CheckInUserList? _checkInList; // 类型是 CheckInUserList，内部 users 是 List<String>
  late UserCheckInService _checkInService;

  @override
  void initState() {
    super.initState();
    // 获取 Provider 服务，不监听变化，因为加载逻辑在本组件内处理
    _checkInService = Provider.of<UserCheckInService>(context, listen: false);
    _loadData(); // 初始化时加载数据
  }

  // 异步加载今日签到列表数据
  Future<void> _loadData() async {
    if (!mounted) return; // 防止在已卸载的 Widget 上调用 setState
    setState(() {
      _isLoading = true; // 开始加载，显示 Loading
    });

    try {
      // 调用 service 获取数据，这里返回的是适配后的 CheckInUserList
      final list = await _checkInService.getTodayCheckInList();
      if (mounted) {
        setState(() {
          _checkInList = list;
          _isLoading = false; // 加载完成
        });
      }
    } catch (e) {
      //print('加载今日签到列表失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; // 加载失败也要结束 Loading 状态
          // 可以考虑在这里显示错误提示，或者让 _buildContent 处理 _checkInList 为 null 的情况
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // 卡片阴影
      margin: EdgeInsets.zero, // 可以根据需要调整外边距
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 圆角
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 内容左对齐
        mainAxisSize: MainAxisSize.min, // 高度自适应内容
        children: [
          // --- 标题区域 ---
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // 标题内边距
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 两端对齐
                children: [
                  // 标题文字
                  Text(
                    '今日签到名单',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold // 加粗一点
                            ),
                  ),
                  // 人数和刷新按钮组合
                  Row(
                    mainAxisSize: MainAxisSize.min, // 包裹内容
                    children: [
                      // 显示总人数 (如果数据已加载)
                      if (_checkInList != null && !_isLoading)
                        Text('共 ${_checkInList!.count} 人', // 使用后端返回的 count
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 8), // 间隔
                      // 刷新按钮 (使用 InkWell 增加点击效果和更小的尺寸)
                      InkWell(
                        onTap: _isLoading ? null : _loadData, // 加载中时禁用按钮
                        borderRadius: BorderRadius.circular(20), // 点击波纹范围
                        child: Padding(
                          padding: const EdgeInsets.all(4.0), // 给图标一点触摸区域
                          child: Icon(Icons.refresh,
                              size: 20,
                              color: _isLoading
                                  ? Colors.grey[400]
                                  : Colors.grey[600] // 加载中置灰
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // --- 内容区域 ---
          _buildContent(),
        ],
      ),
    );
  }

  // 构建列表内容或状态显示的 Widget
  Widget _buildContent() {
    final userInfoProvider = context.watch<UserInfoProvider>();
    // --- 加载中状态 ---
    if (_isLoading) {
      return SizedBox(
        // 给 Loading 一个最小高度，避免界面跳动
        height: widget.maxHeight < 100 ? widget.maxHeight : 100,
        child: LoadingWidget.inline(), // 使用内联 Loading
      );
    }

    // --- 空状态或错误状态 ---
    // (_checkInList 为 null 也可能是加载失败，这里统一处理为空列表的情况)
    if (_checkInList == null || _checkInList!.users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 30.0, horizontal: 16.0), // 给空状态一些垂直空间
        child: const EmptyStateWidget(
          message: '今天还没有小伙伴签到呢~', // 提示语可以更活泼点
          iconData: Icons.emoji_people_outlined, // 换个图标
        ),
      );
    }

    // --- 列表内容 ---
    return Container(
      // 限制列表的最大高度
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: ListView.builder(
        itemCount: _checkInList!.users.length, // 列表项数量
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 列表内边距
        shrinkWrap: true, // 让 ListView 高度包裹内容 (如果内容少于 maxHeight)
        // 根据列表项数量和估算高度决定是否需要滚动
        physics: _checkInList!.users.length >
                (widget.maxHeight / 50).floor() // 假设每项高约50
            ? const AlwaysScrollableScrollPhysics() // 内容多，允许滚动
            : const NeverScrollableScrollPhysics(), // 内容少，禁用滚动
        itemBuilder: (context, index) {
          final String userId = _checkInList!.users[index];
          userInfoProvider.ensureUserInfoLoaded(userId);
          final UserDataStatus userDataStatus =
              userInfoProvider.getUserStatus(userId);

          // 构建每一行列表项
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0), // 列表项之间的垂直间距
            child: Row(
              children: [
                // --- 排名/序号 ---
                Container(
                  width: 24, // 固定宽度
                  height: 24, // 固定高度
                  alignment: Alignment.center, // 文字居中
                  decoration: BoxDecoration(
                    color: LevelUtils.getLevelColor(index + 1), // 根据排名获取颜色
                    shape: BoxShape.circle, // 圆形背景
                  ),
                  child: Text(
                    '${index + 1}', // 显示排名
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8), // 排名和用户信息的间距

                // --- 用户信息 Badge ---
                // 使用 Expanded 填充剩余空间
                Expanded(
                  child: UserInfoBadge(
                    currentUser: widget.currentUser,
                    userDataStatus: userDataStatus,
                    userId: userId, // **传递 userId 给 Badge**
                    showFollowButton: true, // 显示关注按钮 (如果需要)
                    mini: true, // 使用紧凑样式
                    showLevel: true, // 显示等级信息
                    backgroundColor: Colors.transparent, // 背景透明，融入卡片
                    padding: EdgeInsets.zero, // Badge 内部不需要额外 padding
                    showCheckInStats: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
