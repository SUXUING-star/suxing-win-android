// lib/widgets/components/indicators/announcement_indicator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../services/main/announcement/announcement_service.dart';
import '../dialogs/announcement/announcement_dialog.dart';
import '../../../providers/auth/auth_provider.dart';

class AnnouncementIndicator extends StatefulWidget {
  const AnnouncementIndicator({super.key});

  @override
  State<AnnouncementIndicator> createState() => _AnnouncementIndicatorState();
}

class _AnnouncementIndicatorState extends State<AnnouncementIndicator> {
  bool _isInitialized = false;
  bool _wasLoggedIn = false;
  bool _isCheckingAnnouncements = false;
  DateTime? _lastCheckTime;
  bool _hasInitializedDependencies = false;
  late final AuthProvider _authProvider;
  late final AnnouncementService _announcementService;

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
    if (!_hasInitializedDependencies) {
      _announcementService =
          Provider.of<AnnouncementService>(context, listen: false);
      // 检查用户登录状态变化
      _authProvider = Provider.of<AuthProvider>(context, listen: true);
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      // 如果用户登录状态发生变化，在下一帧再重新初始化公告服务
      if (!_isInitialized || _authProvider.isLoggedIn != _wasLoggedIn) {
        _wasLoggedIn = _authProvider.isLoggedIn;

        // 使用 addPostFrameCallback 确保在构建完成后执行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkAnnouncements();
          }
        });
      }
    }
  }

  // 检查公告，添加节流和并发控制
  Future<void> _checkAnnouncements() async {
    if (!mounted) return;

    // 防止并发请求
    if (_isCheckingAnnouncements) {
      return;
    }

    // 添加检查间隔限制
    if (_lastCheckTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
      if (timeSinceLastCheck < _minCheckInterval) {
        return;
      }
    }

    _isCheckingAnnouncements = true;

    try {
      // 确保服务已初始化
      if (!_announcementService.isInitialized) {
        await _announcementService.init();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }

      // 获取公告，确保组件仍然挂载
      if (mounted) {
        await _announcementService.getActiveAnnouncements(forceRefresh: false);
        _lastCheckTime = DateTime.now();
      }
    } catch (e) {
      // print('检查公告失败: $e');

      // 如果遇到已销毁的服务错误，尝试重置并重新初始化
      if (e.toString().contains('disposed') && mounted) {
        try {
          await _announcementService.reset(); // 使用我们添加的reset方法
          await _announcementService.init();

          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            await _announcementService.getActiveAnnouncements(
                forceRefresh: false);
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
      final unreadAnnouncements = _announcementService.getUnreadAnnouncements();

      if (unreadAnnouncements.isEmpty) {
        if (mounted) {
          AppSnackBar.showInfo(context, '没有未读公告');
        }
        return;
      }

      // 使用静态变量跟踪正在显示的公告，避免重复显示
      if (_isShowingAnnouncement) {
        //print('公告指示器: 已有公告正在显示，跳过');
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
      _isShowingAnnouncement = false;

      // 如果遇到错误，显示提示
      if (mounted) {
        AppSnackBar.showError(context, '加载公告失败，请稍后再试');
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
      _isShowingAnnouncement = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnouncementService>(
      builder: (context, service, child) {
        // 如果是loading状态显示loading指示器
        if (service.isLoading) {
          return SizedBox(
              width: 24,
              height: 24,
              child: LoadingWidget.inline(
                size: 12,
              ));
        }

        // 如果有未读公告，显示未读数量指示器
        if (service.unreadCount > 0) {
          return GestureDetector(
            onTap: _showAnnouncements,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.orange,
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
          );
        }

        // 默认显示公告图标
        return GestureDetector(
          onTap: _showAnnouncements,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.lightGreen[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.campaign,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

