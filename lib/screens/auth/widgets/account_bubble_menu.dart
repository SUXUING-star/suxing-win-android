// lib/widgets/auth/account_bubble_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/models/user/account.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../services/main/user/cache/account_cache_service.dart';
import '../../../widgets/ui/badges/safe_user_avatar.dart';

class AccountBubbleMenu extends StatelessWidget {
  final Function(SavedAccount) onAccountSelected;
  final BuildContext anchorContext;
  final Offset? anchorOffset;
  final Color? backgroundColor;

  const AccountBubbleMenu({
    super.key,
    required this.onAccountSelected,
    required this.anchorContext,
    this.anchorOffset,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final accountCache = Provider.of<AccountCacheService>(context);
    final accounts = accountCache.getAllAccounts();

    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;

    // 气泡菜单宽度，如果屏幕较窄则适当缩小
    final menuWidth = screenWidth < 400 ? screenWidth * 0.8 : 320.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 半透明背景，点击关闭菜单
          Positioned.fill(
            child: GestureDetector(
              onTap: () => NavigationUtils.of(context).pop(),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // 气泡菜单
          Positioned(
            left: anchorOffset?.dx ?? 0,
            top: (anchorOffset?.dy ?? 0) + 10, // 向下偏移一点，营造出从按钮弹出的感觉
            child: Container(
              width: menuWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 标题
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        border: Border(
                          bottom: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '选择账号',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 账号列表
                    if (accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '没有保存的账号',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];

                            // 特殊处理最后一个项目，不显示分隔线
                            final bool isLastItem =
                                index == accounts.length - 1;

                            return InkWell(
                              onTap: () {
                                NavigationUtils.of(context).pop();
                                onAccountSelected(account);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: !isLastItem
                                      ? Border(
                                          bottom: BorderSide(
                                            color: Theme.of(context)
                                                .dividerColor
                                                .withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                        )
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    // 头像
                                    SafeUserAvatar(
                                      userId: account.userId ?? '',
                                      avatarUrl: account.avatarUrl,
                                      username:
                                          account.username ?? account.email,
                                      radius: 16,
                                    ),
                                    const SizedBox(width: 12),

                                    // 用户信息
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            account.username ?? account.email,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            account.email,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 等级标签
                                    if (account.level != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getLevelColor(account.level!),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Lv.${account.level}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // 底部按钮
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          '使用其他账号',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 根据等级返回不同的颜色
  Color _getLevelColor(int level) {
    return LevelUtils.getLevelColor(level);
  }
}
