// lib/widgets/indicators/announcement_indicator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/main/announcement/announcement_service.dart';
import '../dialogs/announcement/announcement_dialog.dart';
import '../../../providers/auth/auth_provider.dart';

class AnnouncementIndicator extends StatefulWidget {
  const AnnouncementIndicator({Key? key}) : super(key: key);

  @override
  State<AnnouncementIndicator> createState() => _AnnouncementIndicatorState();
}

class _AnnouncementIndicatorState extends State<AnnouncementIndicator> {
  bool _isInitialized = false;
  bool _wasLoggedIn = false;
  bool _isCheckingAnnouncements = false;
  DateTime? _lastCheckTime;

  // 最小检查间隔
  static const Duration _minCheckInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();

    // 延迟执行，等待构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAnnouncements();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 检查用户登录状态变化
    final authProvider = Provider.of<AuthProvider>(context, listen: true);

    // 如果用户登录状态发生变化，在下一帧再重新初始化公告服务
    if (!_isInitialized || authProvider.isLoggedIn != _wasLoggedIn) {
      _wasLoggedIn = authProvider.isLoggedIn;

      // 使用 addPostFrameCallback 确保在构建完成后执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkAnnouncements();
        }
      });
    }
  }

  // 检查公告，添加节流和并发控制
  Future<void> _checkAnnouncements() async {
    if (!mounted) return;

    // 防止并发请求
    if (_isCheckingAnnouncements) {
      print('公告指示器: 检查已在进行中，跳过');
      return;
    }

    // 添加检查间隔限制
    if (_lastCheckTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
      if (timeSinceLastCheck < _minCheckInterval) {
        print('公告指示器: 距离上次检查只过了 ${timeSinceLastCheck.inSeconds} 秒，跳过本次检查');
        return;
      }
    }

    _isCheckingAnnouncements = true;

    try {
      final announcementService = Provider.of<AnnouncementService>(context, listen: false);

      // 确保服务已初始化
      if (!announcementService.isInitialized) {
        await announcementService.init();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }

      // 获取公告，确保组件仍然挂载
      if (mounted) {
        await announcementService.getActiveAnnouncements(forceRefresh: false);
        _lastCheckTime = DateTime.now();
      }
    } catch (e) {
      print('检查公告失败: $e');

      // 如果遇到已销毁的服务错误，尝试重置并重新初始化
      if (e.toString().contains('disposed') && mounted) {
        try {
          final announcementService = AnnouncementService();
          await announcementService.reset(); // 使用我们添加的reset方法
          await announcementService.init();

          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            await announcementService.getActiveAnnouncements(forceRefresh: false);
            _lastCheckTime = DateTime.now();
          }
        } catch (e2) {
          print('重新初始化公告服务失败: $e2');
        }
      }
    } finally {
      if (mounted) {
        _isCheckingAnnouncements = false;
      }
    }
  }

  // 显示公告列表，避免重复创建对话框
  void _showAnnouncements() {
    if (!mounted) return;

    try {
      final announcementService = Provider.of<AnnouncementService>(context, listen: false);
      final unreadAnnouncements = announcementService.getUnreadAnnouncements();

      if (unreadAnnouncements.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有未读公告')),
          );
        }
        return;
      }

      // 使用静态变量跟踪正在显示的公告，避免重复显示
      if (_isShowingAnnouncement) {
        print('公告指示器: 已有公告正在显示，跳过');
        return;
      }

      _isShowingAnnouncement = true;

      // 显示第一条公告
      if (mounted) {
        showAnnouncementDialog(
          context,
          unreadAnnouncements.first,
          onClose: () {
            _isShowingAnnouncement = false;
            // 如果有多条公告，继续显示下一条
            if (unreadAnnouncements.length > 1 && mounted) {
              _showNextAnnouncement(unreadAnnouncements, 1);
            }
          },
        );
      }
    } catch (e) {
      print('显示公告失败: $e');
      _isShowingAnnouncement = false;

      // 如果遇到错误，显示提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载公告失败，请稍后再试')),
        );
      }
    }
  }

  // 跟踪是否正在显示公告
  static bool _isShowingAnnouncement = false;

  // 递归显示下一条公告，添加错误处理
  void _showNextAnnouncement(List<dynamic> announcements, int index) {
    if (!mounted || index >= announcements.length) {
      _isShowingAnnouncement = false;
      return;
    }

    try {
      _isShowingAnnouncement = true;
      showAnnouncementDialog(
        context,
        announcements[index],
        onClose: () {
          // 先重置显示状态，防止在关闭时出现问题
          _isShowingAnnouncement = false;

          if (index < announcements.length - 1 && mounted) {
            // 短暂延迟，避免对话框连续弹出
            Future.delayed(Duration(milliseconds: 300), () {
              _showNextAnnouncement(announcements, index + 1);
            });
          }
        },
      );
    } catch (e) {
      print('显示下一条公告失败: $e');
      _isShowingAnnouncement = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnouncementService>(
      builder: (context, service, child) {
        // 如果正在加载或没有未读公告，不显示指示器
        if (service.isLoading || service.unreadCount == 0) {
          return const SizedBox.shrink();
        }

        // 显示未读数量指示器
        return GestureDetector(
          onTap: _showAnnouncements,
          child: Tooltip(
            message: '您有 ${service.unreadCount} 条未读公告',
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  service.unreadCount > 9 ? '9+' : '${service.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 公告检查工具类，添加错误处理和节流
class AnnouncementChecker {
  // 最近一次检查时间
  static DateTime? _lastCheckTime;
  // 最小检查间隔
  static const Duration _minCheckInterval = Duration(minutes: 5);
  // 是否正在检查
  static bool _isChecking = false;

  // 检查并显示最重要的一条公告
  static Future<void> checkAnnouncement(BuildContext context) async {
    // 避免在构建过程中调用，使用 addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;

      // 防止并发请求
      if (_isChecking) {
        print('公告检查器: 检查已在进行中，跳过');
        return;
      }

      // 检查间隔限制
      if (_lastCheckTime != null) {
        final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
        if (timeSinceLastCheck < _minCheckInterval) {
          print('公告检查器: 距离上次检查只过了 ${timeSinceLastCheck.inSeconds} 秒，跳过本次检查');
          return;
        }
      }

      _isChecking = true;

      try {
        final service = Provider.of<AnnouncementService>(context, listen: false);

        // 确保初始化完成
        if (!service.isInitialized) {
          await service.init();
        }

        // 检查组件是否还挂载
        if (!context.mounted) {
          _isChecking = false;
          return;
        }

        // 获取公告
        await service.getActiveAnnouncements(forceRefresh: false);
        _lastCheckTime = DateTime.now();

        // 获取未读公告
        final unreadAnnouncements = service.getUnreadAnnouncements();

        // 如果有未读公告，显示第一条
        if (unreadAnnouncements.isNotEmpty && context.mounted) {
          // 避免重复显示
          if (!_AnnouncementIndicatorState._isShowingAnnouncement) {
            _AnnouncementIndicatorState._isShowingAnnouncement = true;
            showAnnouncementDialog(
              context,
              unreadAnnouncements.first,
              onClose: () {
                _AnnouncementIndicatorState._isShowingAnnouncement = false;
              },
            );
          }
        }
      } catch (e) {
        print('检查公告失败: $e');

        // 如果出现服务已销毁的错误，尝试重置
        if (e.toString().contains('disposed') && context.mounted) {
          try {
            final service = AnnouncementService();
            await service.reset();
            await service.init();

            if (context.mounted) {
              final unreadAnnouncements = service.getUnreadAnnouncements();
              if (unreadAnnouncements.isNotEmpty &&
                  !_AnnouncementIndicatorState._isShowingAnnouncement) {
                _AnnouncementIndicatorState._isShowingAnnouncement = true;
                showAnnouncementDialog(
                  context,
                  unreadAnnouncements.first,
                  onClose: () {
                    _AnnouncementIndicatorState._isShowingAnnouncement = false;
                  },
                );
              }
            }
          } catch (e2) {
            print('重置公告服务失败: $e2');
          }
        }
      } finally {
        _isChecking = false;
      }
    });
  }
}