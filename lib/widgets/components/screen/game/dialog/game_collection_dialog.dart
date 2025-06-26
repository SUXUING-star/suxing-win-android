// lib/widgets/components/screen/game/dialog/game_collection_dialog.dart

/// 该文件定义了 GameCollectionDialog 组件，用于显示游戏的收藏编辑或添加对话框。
/// GameCollectionDialog 封装了收藏状态、笔记、评价和评分的表单功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/game/game_collection_form_data.dart'; // 游戏收藏表单数据模型所需
import 'package:suxingchahui/models/user/user.dart'; // 用户模型所需
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider 所需
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类所需
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类所需
import 'package:suxingchahui/widgets/components/form/game_collection/collection_form.dart'; // 收藏表单组件所需

/// `GameCollectionDialog` 类：显示游戏收藏对话框的 StatelessWidget。
///
/// 该类提供一个对话框，用于用户添加或编辑游戏的收藏状态、评分和笔记。
class GameCollectionDialog extends StatelessWidget {
  final String gameId; // 游戏的唯一ID
  final InputStateService inputStateService; // 输入状态服务
  final User? currentUser; // 当前登录用户
  final String gameName; // 游戏名称
  final String? currentStatus; // 当前收藏状态
  final String? currentNotes; // 当前收藏笔记
  final String? currentReview; // 当前收藏评价
  final double? currentRating; // 当前评分

  /// 构造函数。
  ///
  /// [gameId]：游戏的唯一ID。
  /// [inputStateService]：输入状态服务。
  /// [currentUser]：当前用户。
  /// [gameName]：游戏名称。
  /// [currentStatus]：当前收藏状态。
  /// [currentNotes]：当前收藏笔记。
  /// [currentReview]：当前收藏评价。
  /// [currentRating]：当前评分。
  const GameCollectionDialog({
    super.key,
    required this.gameId,
    required this.inputStateService,
    required this.currentUser,
    required this.gameName,
    this.currentStatus,
    this.currentNotes,
    this.currentReview,
    this.currentRating,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing =
        currentStatus != null && currentStatus!.isNotEmpty; // 判断是否为编辑模式
    final title = isEditing ? '编辑收藏' : '添加收藏'; // 对话框标题
    final screenSize = DeviceUtils.getScreenSize(context); // 获取屏幕尺寸
    final isDesktop =
        DeviceUtils.isDesktopInThisWidth(screenSize.width); // 判断是否为桌面宽度

    return Center(
      child: ConstrainedBox(
        // 限制对话框大小
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 500 : 400, // 最大宽度
          maxHeight: screenSize.height * 0.8, // 最大高度
          minWidth: 280, // 最小宽度
        ),
        child: Material(
          // 提供对话框的视觉样式
          color: Colors.white, // 背景色
          elevation: 6.0, // 阴影大小
          shadowColor: Colors.black26, // 阴影颜色
          shape: RoundedRectangleBorder(
            // 圆角边框
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias, // 裁剪行为

          child: Padding(
            // 设置对话框内部边距
            padding: const EdgeInsets.fromLTRB(16.0, 18.0, 18.0, 16.0),
            child: Column(
              // 垂直布局对话框内容
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, title), // 构建对话框头部
                Flexible(
                  child: SingleChildScrollView(
                    // 使表单内容可滚动
                    child: Column(
                      // 垂直布局表单内容
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            gameName, // 显示游戏名称
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GameCollectionForm(
                          // 游戏收藏表单组件
                          inputStateService: inputStateService,
                          currentUser: currentUser,
                          gameId: gameId,
                          initialStatus: currentStatus ?? '',
                          initialNotes: currentNotes,
                          initialReview: currentReview,
                          initialRating: currentRating,
                          showRemoveButton: isEditing, // 根据编辑模式显示移除按钮
                          onCancel: () =>
                              NavigationUtils.of(context).pop(), // 取消回调
                          onRemove: () {
                            // 移除回调
                            NavigationUtils.of(context).pop({
                              GameCollectionFormData(
                                gameId: gameId,
                                action: GameCollectionFormData
                                    .removeCollectionAction,
                              ),
                            });
                          },

                          onSubmit: (status, notes, review, rating) {
                            // 提交回调
                            NavigationUtils.of(context).pop({
                              GameCollectionFormData(
                                gameId: gameId,
                                action:
                                    GameCollectionFormData.setCollectionAction,
                                status: status,
                                notes: notes,
                                review: review,
                                rating: rating,
                              )
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建对话框的头部区域。
  ///
  /// [context]：Build 上下文。
  /// [title]：对话框标题。
  /// 返回一个包含标题和关闭按钮的 Widget。
  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary, // 头部背景色
      ),
      child: Row(
        // 头部行布局
        children: [
          Expanded(
            child: Text(
              title, // 标题文本
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            // 关闭按钮
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(), // 关闭对话框
          ),
        ],
      ),
    );
  }
}
