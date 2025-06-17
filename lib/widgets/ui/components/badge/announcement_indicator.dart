// lib/widgets/ui/components/badge/announcement_indicator.dart

/// 该文件定义了 AnnouncementIndicator 组件，一个显示公告状态的指示器。
/// AnnouncementIndicator 监听公告服务，根据未读公告数量显示不同 UI，并支持点击查看公告。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/models/announcement/announcement.dart'; // 公告模型
import 'package:suxingchahui/widgets/components/dialogs/announcement/announcement_dialog.dart'; // 公告对话框
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件
import 'package:suxingchahui/widgets/ui/snackBar/app_snackBar.dart'; // 应用 Snackbar
import 'package:suxingchahui/services/main/announcement/announcement_service.dart'; // 公告服务
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 认证 Provider

bool _isDialogSequenceActive = false; // 标识公告对话框序列是否正在激活

/// `AnnouncementIndicator` 类：公告状态指示器。
///
/// 该组件通过 `StreamBuilder` 监听公告服务，
/// 根据未读公告数量显示不同的指示器样式，并支持点击查看公告。
class AnnouncementIndicator extends StatelessWidget {
  final AuthProvider authProvider; // 认证 Provider 实例
  final AnnouncementService announcementService; // 公告服务实例

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [announcementService]：公告服务实例。
  /// [authProvider]：认证 Provider 实例。
  const AnnouncementIndicator({
    super.key,
    required this.announcementService,
    required this.authProvider,
  });

  /// 处理指示器点击事件。
  ///
  /// [context]：Build 上下文。
  /// 获取未读公告，并显示公告对话框序列或提示无新公告。
  Future<void> _handleTap(BuildContext context) async {
    if (_isDialogSequenceActive) {
      // 对话框序列正在激活时直接返回
      return;
    }

    try {
      await announcementService.getActiveAnnouncements(
          forceRefresh: false); // 获取活动公告
      final unread = announcementService.getUnreadAnnouncements(); // 获取未读公告

      if (!context.mounted) return; // 上下文未挂载时返回
      if (unread.isNotEmpty) {
        // 有未读公告时
        _showAnnouncementsDialogs(context, unread); // 显示公告对话框序列
      } else {
        // 无未读公告时
        AppSnackBar.showInfo('没有新的公告'); // 显示信息提示
      }
    } catch (e) {
      AppSnackBar.showError('获取公告失败,${e.toString()}'); // 捕获错误时显示错误提示
    }
  }

  /// 显示公告对话框序列。
  ///
  /// [context]：Build 上下文。
  /// [announcementsToShow]：要显示的公告列表。
  /// 遍历公告列表，逐个显示公告对话框。
  void _showAnnouncementsDialogs(
      BuildContext context, List<Announcement> announcementsToShow) async {
    if (!context.mounted || announcementsToShow.isEmpty) {
      // 上下文未挂载或公告列表为空时
      _isDialogSequenceActive = false; // 重置对话框序列激活标记
      return;
    }

    _isDialogSequenceActive = true; // 设置对话框序列为激活状态
    try {
      for (int i = 0; i < announcementsToShow.length; i++) {
        // 遍历公告列表
        if (!context.mounted) {
          // 上下文未挂载时
          _isDialogSequenceActive = false; // 重置对话框序列激活标记
          return;
        }
        final announcement = announcementsToShow[i]; // 获取当前公告
        bool continueToNext = await _showSingleAnnouncementDialog(
            context, announcement); // 显示单个公告对话框
        if (!continueToNext || !context.mounted) {
          // 不继续或上下文未挂载时
          _isDialogSequenceActive = false; // 重置对话框序列激活标记
          return;
        }
        if (i < announcementsToShow.length - 1 && context.mounted) {
          // 不是最后一个公告且上下文挂载时
          await Future.delayed(const Duration(milliseconds: 300)); // 延迟 300 毫秒
        }
      }
    } finally {
      _isDialogSequenceActive = false; // 最终重置对话框序列激活标记
    }
  }

  /// 显示单个公告对话框。
  ///
  /// [context]：Build 上下文。
  /// [announcement]：要显示的公告。
  /// 返回一个 Future，表示对话框是否成功关闭。
  Future<bool> _showSingleAnnouncementDialog(
      BuildContext context, Announcement announcement) async {
    final completer = Completer<bool>(); // 创建 Completer
    if (!context.mounted) {
      // 上下文未挂载时
      completer.complete(false); // 完成 Completer 并返回 false
      return completer.future;
    }

    showAnnouncementDialog(
      // 显示公告对话框
      context,
      announcementService,
      announcement,
      onClose: () async {
        // 对话框关闭回调
        if (context.mounted) {
          // 上下文挂载时
          await announcementService.markAsRead(announcement.id); // 标记公告为已读
        }
        if (!completer.isCompleted) {
          // Completer 未完成时
          completer.complete(true); // 完成 Completer 并返回 true
        }
      },
    );
    return completer.future; // 返回 Completer 的 Future
  }

  /// 构建公告指示器 UI。
  ///
  /// [context]：Build 上下文。
  /// [snapshot]：包含 `AnnouncementIndicatorData` 的 AsyncSnapshot。
  /// 根据公告数据状态显示不同 UI。
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AnnouncementIndicatorData>(
      // 监听公告服务指示器数据流
      stream: announcementService.indicatorDataStream, // 监听指示器数据
      initialData: AnnouncementIndicatorData.initial(), // 初始数据
      builder: (context, snapshot) {
        // 构建器函数
        final data = snapshot.data; // 获取公告指示器数据

        if (snapshot.hasError || data == null) {
          // 发生错误或数据为空时
          return GestureDetector(
            // 可点击手势检测器
            onTap: () => _handleTap(context), // 点击处理
            child: Container(
              // 容器样式
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[400], // 灰色背景
                shape: BoxShape.circle, // 圆形
              ),
              child: Center(
                // 内容居中
                child: Icon(Icons.campaign_outlined, // 公告图标
                    size: 16,
                    color: Colors.white),
              ),
            ),
          );
        }

        if (data.isLoading && data.unreadCount == 0) {
          // 正在加载且无未读消息时
          return SizedBox(
              // 显示加载指示器
              width: 24,
              height: 24,
              child: const LoadingWidget(size: 12));
        }

        if (data.unreadCount > 0) {
          // 有未读消息时
          return GestureDetector(
            // 可点击手势检测器
            onTap: () => _handleTap(context), // 点击处理
            child: Container(
              // 容器样式
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.orange, // 橙色背景
                shape: BoxShape.circle, // 圆形
              ),
              child: Center(
                // 内容居中
                child: Text(
                  // 文本显示未读数量
                  data.unreadCount > 9
                      ? '9+'
                      : '${data.unreadCount}', // 超过 9 显示 9+
                  style: TextStyle(
                    // 文本样式
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          // 无未读消息时
          onTap: () => _handleTap(context), // 点击处理
          child: Container(
            // 容器样式
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.lightGreen[400], // 浅绿色背景
              shape: BoxShape.circle, // 圆形
            ),
            child: Center(
              // 内容居中
              child:
                  Icon(Icons.campaign, size: 16, color: Colors.white), // 公告图标
            ),
          ),
        );
      },
    );
  }
}
