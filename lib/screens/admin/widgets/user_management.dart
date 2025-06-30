import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/models/user/user/user_with_ban_status.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/services/main/user/user_ban_service.dart';
import 'package:intl/intl.dart';

class UserManagement extends StatefulWidget {
  final User? currentUser;
  final UserService userService;
  final InputStateService inputStateService;
  final UserFollowService followService;
  final UserInfoService infoService;
  final WindowStateProvider windowStateProvider;

  const UserManagement({
    super.key,
    required this.currentUser,
    required this.userService,
    required this.inputStateService,
    required this.followService,
    required this.infoService,
    required this.windowStateProvider,
  });

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final ScrollController _scrollController = ScrollController();
  final List<UserWithBanStatus> _users = [];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  bool _operationLoading = false;

  late final UserBanService _banService;
  User? _currentUser;
  bool _dependenciesInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesInitialized) {
      _banService = context.read<UserBanService>();
      _fetchUsers();
      _dependenciesInitialized = true;
    }
  }

  @override
  void didUpdateWidget(covariant UserManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchUsers(isLoadMore: true);
    }
  }

  Future<void> _fetchUsers({bool isLoadMore = false}) async {
    if ((isLoadMore && _isLoadingMore) ||
        (!isLoadMore && _isLoading && _users.isNotEmpty)) {
      return;
    }
    setState(() {
      if (isLoadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _error = null;
      }
    });
    try {
      final result = await widget.userService.getAllUsersWithPagination(
        page: isLoadMore ? _currentPage + 1 : 1,
      );
      if (!mounted) return;
      setState(() {
        if (!isLoadMore) _users.clear();
        _users.addAll(result.users);
        _currentPage = result.pagination.page;
        _hasMore = result.pagination.hasNextPage();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchUsers();
  }

  Future<void> _showBanDialog(
      BuildContext invokerContext, UserWithBanStatus userWithStatus) async {
    final user = userWithStatus.user;
    final reasonController = TextEditingController();
    DateTime? endTime;
    bool isPermanent = true;

    await showDialog(
      context: invokerContext, // 使用传入的 context
      builder: (dialogContext) => StatefulBuilder(
        builder: (stfContext, setStateDialog) => AlertDialog(
          title: Text('封禁用户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('确定要封禁用户 ${user.username} 吗？'),
                const SizedBox(height: 16),
                TextInputField(
                  inputStateService: widget.inputStateService,
                  controller: reasonController,
                  decoration: const InputDecoration(
                      labelText: '封禁原因', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                CheckboxListTile(
                  title: Text('永久封禁'),
                  value: isPermanent,
                  onChanged: (value) {
                    setStateDialog(() {
                      isPermanent = value!;
                      if (!isPermanent && endTime == null) {
                        endTime = DateTime.now().add(const Duration(days: 7));
                      }
                    });
                  },
                ),
                if (!isPermanent)
                  ListTile(
                    title: const Text('解封时间'),
                    subtitle: Text(endTime != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(endTime!)
                        : '请选择'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final now = DateTime.now();
                      final initialDate = (endTime == null)
                          ? now.add(const Duration(days: 7))
                          : (endTime!.isBefore(now) ? now : endTime!);

                      final date = await showDatePicker(
                          context: stfContext,
                          initialDate: initialDate,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365 * 10)));
                      // --- 修复：在 await 后立刻检查 mounted ---
                      if (!stfContext.mounted || date == null) return;

                      final time = await showTimePicker(
                          context: stfContext,
                          initialTime: TimeOfDay.fromDateTime(
                              endTime ?? now.add(const Duration(days: 7))));
                      // --- 修复：在 await 后立刻检查 mounted ---
                      if (!mounted || time == null) return;

                      setStateDialog(() {
                        endTime = DateTime(date.year, date.month, date.day,
                            time.hour, time.minute);
                        if (endTime!.isBefore(DateTime.now())) {
                          endTime =
                              DateTime.now().add(const Duration(minutes: 5));
                          AppSnackBar.showError('解封时间不能早于当前时间');
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => NavigationUtils.pop(dialogContext),
                child: const Text('取消')),
            ElevatedButton(
              onPressed: _operationLoading
                  ? null
                  : () async {
                      if (reasonController.text.trim().isEmpty) {
                        AppSnackBar.showWarning('请输入封禁原因');
                        return;
                      }
                      if (!isPermanent && endTime == null) {
                        AppSnackBar.showWarning('请选择解封时间');
                        return;
                      }
                      if (!isPermanent &&
                          endTime != null &&
                          endTime!.isBefore(DateTime.now())) {
                        AppSnackBar.showWarning('解封时间不能早于当前时间');
                        return;
                      }

                      setState(() => _operationLoading = true);

                      try {
                        await _banService.banUser(
                            userId: user.id,
                            reason: reasonController.text.trim(),
                            endTime: isPermanent ? null : endTime,
                            bannedBy: _currentUser!.id);
                        // --- 修复：在 await 后立刻检查 mounted ---
                        if (!dialogContext.mounted) return;
                        NavigationUtils.pop(dialogContext);
                        AppSnackBar.showSuccess('用户 ${user.username} 已被封禁');
                        _handleRefresh();
                      } catch (e) {
                        if (mounted) AppSnackBar.showError('封禁失败：$e');
                      } finally {
                        if (mounted) setState(() => _operationLoading = false);
                      }
                    },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUnbanDialog(
      BuildContext invokerContext, UserWithBanStatus userWithStatus) async {
    final user = userWithStatus.user;
    await showDialog(
      context: invokerContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('解除封禁'),
        content: Text('确定要解除用户 ${user.username} 的封禁吗？'),
        actions: [
          TextButton(
              onPressed: () => NavigationUtils.pop(dialogContext),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: _operationLoading
                ? null
                : () async {
                    setState(() => _operationLoading = true);
                    try {
                      await _banService.unbanUser(user.id);
                      // --- 修复：在 await 后立刻检查 mounted ---
                      if (!mounted) return;
                      NavigationUtils.pop(context);
                      AppSnackBar.showSuccess('已解除用户 ${user.username} 的封禁');
                      _handleRefresh();
                    } catch (e) {
                      if (mounted) AppSnackBar.showError('操作失败：$e');
                    } finally {
                      if (mounted) setState(() => _operationLoading = false);
                    }
                  },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _setAdminStatus(
      UserWithBanStatus userWithStatus, bool value) async {
    if (!(_currentUser?.isSuperAdmin ?? false)) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    setState(() => _operationLoading = true);
    try {
      await widget.userService
          .updateUserAdminStatus(userWithStatus.user.id, value);
      // --- 修复：在 await 后立刻检查 mounted ---
      if (!mounted) return;
      AppSnackBar.showSuccess(
          '用户 ${userWithStatus.user.username} 已${value ? '设置' : '取消'}管理员');
      _handleRefresh();
    } catch (e) {
      if (mounted) AppSnackBar.showError('操作失败: $e');
    } finally {
      if (mounted) setState(() => _operationLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!(_currentUser?.isSuperAdmin ?? false)) {
      return const CustomErrorWidget(errorMessage: '只有超级管理员可以访问用户管理');
    }
    if (_isLoading && _users.isEmpty) {
      return const LoadingWidget();
    }
    if (_error != null && _users.isEmpty) {
      return InlineErrorWidget(errorMessage: '加载用户列表失败: $_error\n请尝试下拉刷新。');
    }
    if (_users.isEmpty) {
      return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Stack(children: [
            ListView(), // To make RefreshIndicator work
            const EmptyStateWidget(message: '没有用户数据')
          ]));
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: LazyLayoutBuilder(
          windowStateProvider: widget.windowStateProvider,
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final crossAxisCount = (availableWidth / 300).floor().clamp(1, 5);

            // 把加载更多的逻辑从 item 本身移到 GridView 的 children 里
            final List<Widget> gridItems = _users
                .where((userWithStatus) =>
                    userWithStatus.user.id != _currentUser?.id)
                .map(
                    (userWithStatus) => _buildUserCard(context, userWithStatus))
                .toList();

            return ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              children: [
                AnimatedContentGrid<Widget>(
                  items: gridItems,
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  itemBuilder: (context, index, item) => item,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: LoadingWidget(),
                  ),
              ],
            );
          }),
    );
  }

  /// 构建单个用户卡片
  Widget _buildUserCard(
      BuildContext context, UserWithBanStatus userWithStatus) {
    final targetUser = userWithStatus.user;
    final banInfo = userWithStatus.banInfo;
    final isAdmin = targetUser.isAdmin;
    final isBanned = banInfo != null;

    String banStatusText = '';
    if (isBanned) {
      banStatusText = '已封禁';
      if (banInfo.isPermanent) {
        banStatusText += ' (永久)';
      } else if (banInfo.endTime != null) {
        banStatusText +=
            ' (至: ${DateFormat('yyyy-MM-dd').format(banInfo.endTime!)})';
      }
    }

    return Card(
      key: ValueKey(targetUser.id),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息徽章
            Expanded(
              child: UserInfoBadge(
                infoService: widget.infoService,
                followService: widget.followService,
                targetUserId: targetUser.id,
                currentUser: _currentUser,
                showFollowButton: false, // 管理页面不显示关注按钮
                showLevel: true,
              ),
            ),
            // 分割线和状态信息
            const Divider(height: 16),
            if (isBanned)
              Tooltip(
                message: '原因: ${banInfo.reason}',
                child: Text(
                  banStatusText,
                  style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // 操作按钮行
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 切换管理员
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('管理员', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 20,
                      width: 36,
                      child: Switch(
                        value: isAdmin,
                        onChanged: _operationLoading
                            ? null
                            : (value) => _setAdminStatus(userWithStatus, value),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                // 封禁/解封按钮
                FunctionalButton(
                  label: isBanned ? '解封' : '封禁',
                  onPressed: _operationLoading
                      ? null
                      : () => isBanned
                          ? _showUnbanDialog(context, userWithStatus)
                          : _showBanDialog(context, userWithStatus),
                  icon: isBanned ? Icons.lock_open : Icons.block,
                  backgroundColor:
                      isBanned ? Colors.orange.shade700 : Colors.red.shade700,
                  fontSize: 12,
                  foregroundColor: Colors.white,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
