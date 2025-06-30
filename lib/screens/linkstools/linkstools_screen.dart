// lib/screens/linkstools/linkstools_screen.dart

/// 该文件定义了 LinksToolsScreen 页面，用于显示常用链接和实用工具。
/// LinksToolsScreen 负责加载、管理并展示链接和工具数据。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/user/user/user.dart'; // 用户模型所需
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider 所需
import 'package:suxingchahui/providers/windows/window_state_provider.dart'; // 窗口状态 Provider 所需
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart'; // 链接工具服务所需
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类所需
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 淡入动画组件所需
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart'; // 浮动按钮组组件所需
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart'; // 通用浮动按钮组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart'; // 懒加载布局构建器所需
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // 提示条组件所需
import 'package:visibility_detector/visibility_detector.dart'; // 可见性检测器所需
import 'package:suxingchahui/models/linkstools/site_link.dart'; // 站点链接模型所需
import 'package:suxingchahui/models/linkstools/tool.dart'; // 工具模型所需
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 认证 Provider 所需
import 'package:suxingchahui/widgets/components/form/linkform/link_form_dialog.dart'; // 链接表单对话框所需
import 'package:suxingchahui/widgets/components/form/toolform/tool_form_dialog.dart'; // 工具表单对话框所需
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 自定义应用栏组件所需
import 'package:suxingchahui/widgets/components/screen/linkstools/links_section.dart'; // 链接区域组件所需
import 'package:suxingchahui/widgets/components/screen/linkstools/tools_section.dart'; // 工具区域组件所需
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件所需
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件所需
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 淡入上滑动画组件所需

/// `LinksToolsScreen` 类：显示常用链接和实用工具的页面。
///
/// 该页面负责加载、管理并展示链接和工具数据。
class LinksToolsScreen extends StatefulWidget {
  final AuthProvider authProvider; // 认证 Provider
  final LinkToolService linkToolService; // 链接工具服务
  final InputStateService inputStateService; // 输入状态服务
  final WindowStateProvider windowStateProvider; // 窗口状态 Provider

  /// 构造函数。
  const LinksToolsScreen({
    super.key,
    required this.authProvider,
    required this.linkToolService,
    required this.inputStateService,
    required this.windowStateProvider,
  });

  @override
  _LinksToolsScreenState createState() => _LinksToolsScreenState();
}

class _LinksToolsScreenState extends State<LinksToolsScreen>
    with WidgetsBindingObserver {
  // --- 数据状态 ---
  List<SiteLink>? _links; // 站点链接列表
  List<Tool>? _tools; // 工具列表
  String? _errorMessage; // 错误消息

  // --- 懒加载核心状态 ---
  bool _isInitialized = false; // 是否已初始化标记
  bool _hasInitializedDependencies = false; // 依赖是否已初始化标记
  bool _isVisible = false; // 页面是否可见标记
  bool _isLoadingData = false; // 数据是否正在加载标记
  DateTime? _lastLoadingTime; // 上次加载数据的时间
  Timer? _refreshDebounceTimer; // 刷新防抖计时器
  bool _needsRefresh = false; // 是否需要刷新数据的标记
  static const Duration _maxLoadingDuration = Duration(seconds: 10); // 最大加载时长

  static const Duration _cacheDebounceDuration = Duration(seconds: 2); // 缓存防抖时长

  static const _ctxScreen = 'link_tool';

  String? _currentUserId; // 当前用户ID

  @override
  void initState() {
    super.initState(); // 调用父类 initState
    WidgetsBinding.instance.addObserver(this); // 添加 WidgetsBinding 观察者
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies(); // 调用父类 didChangeDependencies
    if (!_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId; // 获取当前用户ID
      _hasInitializedDependencies = true; // 标记依赖已初始化
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state); // 调用父类 didChangeAppLifecycleState
    if (!mounted) return; // 组件未挂载时退出
    _checkAuthStateChange(); // 检查认证状态变化
    _checkLoadingTimeout(); // 检查加载超时
    if (state == AppLifecycleState.resumed) {
      // 应用恢复到前台
      if (_isVisible) {
        if (_needsRefresh) {
          // 需要刷新时
          _refreshDataIfNeeded(reason: "应用恢复且需要刷新"); // 刷新数据
          _needsRefresh = false; // 重置刷新标记
        }
      } else {
        _needsRefresh = true; // 标记需要刷新
      }
    } else if (state == AppLifecycleState.paused) {
      // 应用暂停
      _needsRefresh = true; // 标记需要刷新
    }
  }

  @override
  void didUpdateWidget(covariant LinksToolsScreen oldWidget) {
    super.didUpdateWidget(oldWidget); // 调用父类 didUpdateWidget
    _checkAuthStateChange(); // 检查认证状态变化
    _checkLoadingTimeout(); // 检查加载超时
  }

  @override
  void dispose() {
    super.dispose(); // 调用父类 dispose
    WidgetsBinding.instance.removeObserver(this); // 移除 WidgetsBinding 观察者
  }

  /// 处理页面可见性变化。
  ///
  /// [info]：可见性信息。
  void _handleVisibilityChange(VisibilityInfo info) {
    if (!mounted) return; // 组件未挂载时退出
    final bool currentlyVisible = info.visibleFraction > 0; // 判断当前是否可见
    _checkAuthStateChange(); // 检查认证状态变化
    _checkLoadingTimeout(); // 检查加载超时
    if (currentlyVisible != _isVisible) {
      // 可见性状态改变时
      Future.microtask(() {
        if (mounted) {
          setState(() => _isVisible = currentlyVisible); // 更新可见性状态
        } else {
          _isVisible = currentlyVisible; // 更新可见性状态
        }
        if (_isVisible) {
          // 页面变为可见
          if (!_isInitialized) {
            _triggerInitialLoad(); // 触发首次加载
          } else {
            if (_needsRefresh) {
              // 需要刷新时
              _refreshDataIfNeeded(reason: "应用恢复且需要刷新"); // 刷新数据
              _needsRefresh = false; // 重置刷新标记
            }
          }
        } else {
          _needsRefresh = true; // 标记需要刷新
        }
      });
    }
  }

  /// 检查认证状态是否变化。
  ///
  /// 如果当前用户ID与认证 Provider 中的用户ID不同，则更新状态。
  void _checkAuthStateChange() {
    if (!mounted) return; // 组件未挂载时退出
    if (_currentUserId != widget.authProvider.currentUserId) {
      // 检查用户ID是否变化
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
        });
      }
    }
  }

  /// 检查加载是否超时。
  ///
  /// 如果数据正在加载且超过最大加载时长，则重置加载状态。
  void _checkLoadingTimeout() {
    if (!mounted) return; // 组件未挂载时退出
    final now = DateTime.now(); // 获取当前时间
    if (_isLoadingData &&
        _lastLoadingTime != null &&
        now.difference(_lastLoadingTime!) > _maxLoadingDuration) {
      // 检查是否超时
      if (mounted) {
        setState(() {
          _lastLoadingTime = null; // 清除上次加载时间
          _isLoadingData = false; // 清除加载中状态
        });
      }
    }
  }

  /// 触发首次数据加载。
  ///
  /// 仅当页面可见且未初始化时执行。
  void _triggerInitialLoad() {
    if (_isVisible && !_isInitialized && mounted) {
      // 检查可见性、初始化状态和挂载状态
      _isInitialized = true; // 标记为已初始化
      _loadData(); // 加载数据
    }
  }

  /// 刷新数据，带防抖控制。
  ///
  /// [reason]：刷新原因。
  /// [isCacheUpdated]：是否因缓存更新触发。
  void _refreshDataIfNeeded({
    required String reason,
    bool isCacheUpdated = false,
  }) {
    if (!mounted) return; // 组件未挂载时退出
    _refreshDebounceTimer?.cancel(); // 取消旧的防抖计时器
    _refreshDebounceTimer = Timer(_cacheDebounceDuration, () {
      // 启动新的防抖计时器
      if (!mounted) return; // 组件未挂载时退出
      if (!_isVisible) {
        // 屏幕不可见时
        _needsRefresh = true; // 标记需要刷新
        return;
      }
      if (_isLoadingData) {
        // 正在加载数据时
        if (isCacheUpdated) {
          // 因缓存更新触发
          return;
        } else {
          _needsRefresh = true; // 标记需要刷新
          return;
        }
      }
      _loadData(); // 加载数据
    });
  }

  /// 加载链接和工具数据。
  Future<void> _loadData() async {
    if (_lastLoadingTime != null) _lastLoadingTime = null; // 清除上次加载时间
    if (_isLoadingData || !mounted) return; // 正在加载或组件未挂载时退出
    setState(() {
      _isLoadingData = true; // 设置为加载中状态
      _errorMessage = null; // 清除错误消息
      _lastLoadingTime = DateTime.now(); // 记录上次加载时间
    });
    try {
      final links = await widget.linkToolService.getLinks(); // 获取链接数据
      final tools = await widget.linkToolService.getTools(); // 获取工具数据

      if (!mounted) return; // 组件未挂载时退出
      setState(() {
        _links = links; // 更新链接数据
        _tools = tools; // 更新工具数据
        _isLoadingData = false; // 清除加载中状态
      });
    } catch (e) {
      if (!mounted) return; // 组件未挂载时退出
      setState(() {
        _errorMessage = '加载失败：${e.toString()}'; // 设置错误消息
        _links = []; // 清空链接数据
        _tools = []; // 清空工具数据
        _isLoadingData = false; // 清除加载中状态
        _lastLoadingTime = null; // 清除上次加载时间
      });
    }
  }

  /// 显示添加链接对话框。
  ///
  /// [context]：Build 上下文。
  void _showAddLinkDialog(BuildContext context) {
    if (!_checkCanEditOrDelete()) {
      // 检查编辑/删除权限
      AppSnackBar.showPermissionDenySnackBar(); // 显示权限不足提示
      return;
    }
    showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => LinkFormDialog(
              // 显示链接表单对话框
              inputStateService: widget.inputStateService,
            )).then((linkData) async {
      if (linkData != null) {
        // 链接数据不为空时
        try {
          await widget.linkToolService
              .addLink(SiteLink.fromJson(linkData)); // 添加链接
          await _loadData(); // 重新加载数据
          if (!mounted) return; // 组件未挂载时退出
          AppSnackBar.showSuccess('添加链接成功'); // 显示成功提示
        } catch (e) {
          AppSnackBar.showError('添加链接失败: ${e.toString()}'); // 显示错误提示
        }
      }
    });
  }

  /// 检查当前用户是否具有编辑或删除权限。
  ///
  /// 返回 true 表示具有权限，false 表示没有权限。
  bool _checkCanEditOrDelete() {
    return widget.authProvider.isAdmin; // 判断是否为管理员
  }

  /// 显示添加工具对话框。
  ///
  /// [context]：Build 上下文。
  void _showAddToolDialog(BuildContext context) {
    if (!_checkCanEditOrDelete()) {
      // 检查编辑/删除权限
      AppSnackBar.showPermissionDenySnackBar(); // 显示权限不足提示
      return;
    }
    showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ToolFormDialog(
              // 显示工具表单对话框
              inputStateService: widget.inputStateService,
            )).then((toolData) async {
      if (toolData != null) {
        // 工具数据不为空时
        try {
          await widget.linkToolService.addTool(Tool.fromJson(toolData)); // 添加工具
          if (mounted) await _loadData(); // 重新加载数据

          AppSnackBar.showSuccess('添加工具成功'); // 显示成功提示
        } catch (e) {
          AppSnackBar.showError("添加失败 ${e.toString()}"); // 显示错误提示
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream, // 监听当前用户 Stream
      initialData: widget.authProvider.currentUser, // 初始用户数据
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data; // 当前用户
        final isAdmin = currentUser?.isAdmin ?? false; // 判断是否为管理员

        // 加载成功时显示内容
        return LazyLayoutBuilder(
          windowStateProvider: widget.windowStateProvider, // 窗口状态 Provider
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth; // 屏幕宽度
            final isDesktop =
                DeviceUtils.isDesktopInThisWidth(screenWidth); // 判断是否为桌面宽度
            return VisibilityDetector(
              key: const Key('${_ctxScreen}_visibility'), // 可见性检测器的键
              onVisibilityChanged: _handleVisibilityChange, // 可见性变化回调
              child: Scaffold(
                appBar: const CustomAppBar(title: '实用工具'), // 自定义应用栏
                body: RefreshIndicator(
                  onRefresh: () => _loadData(), // 下拉刷新回调
                  child: _buildLinksToolsContent(isAdmin, isDesktop), // 构建内容
                ),
                floatingActionButton:
                    _buildFloatButtons(isAdmin, isDesktop), // 构建浮动按钮
              ),
            );
          },
        );
      },
    );
  }

  String _makeHeroTag(
      {required bool isDesktopLayout, required String mainCtx}) {
    final ctxDevice = isDesktopLayout ? 'desktop' : 'mobile';
    return '${_ctxScreen}_${ctxDevice}_${mainCtx}_${widget.authProvider.currentUserId}';
  }

  /// 构建浮动按钮组。
  ///
  /// [isAdmin]：是否为管理员。
  /// [context]：Build 上下文。
  /// 返回一个浮动按钮组 Widget。
  Widget _buildFloatButtons(bool isAdmin, bool isDesktopLayout) {
    if (!isAdmin) return const SizedBox.shrink(); // 非管理员时隐藏按钮
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0), // 内边距
      child: FloatingActionButtonGroup(
        toggleButtonHeroTag: '${_ctxScreen}_heroTags', // 切换按钮的 Hero Tag
        spacing: 16.0, // 按钮间距
        alignment: MainAxisAlignment.end, // 对齐方式
        children: [
          GenericFloatingActionButton(
            onPressed: () => _showAddLinkDialog(context), // 添加链接回调
            icon: Icons.add_link, // 图标
            tooltip: '添加链接', // 工具提示
            heroTag: _makeHeroTag(
                isDesktopLayout: isDesktopLayout, mainCtx: 'add_link'),
          ),
          GenericFloatingActionButton(
            onPressed: () => _showAddToolDialog(context), // 添加工具回调
            icon: Icons.add_box_outlined, // 图标
            tooltip: '添加工具', // 工具提示
            heroTag: _makeHeroTag(
                isDesktopLayout: isDesktopLayout, mainCtx: 'add_tool'),
          )
        ],
      ),
    );
  }

  /// 构建链接和工具内容区域。
  ///
  /// [isAdmin]：是否为管理员。
  /// 根据加载状态和错误信息显示不同的 UI。
  Widget _buildLinksToolsContent(
    bool isAdmin,
    bool isDesktop,
  ) {
    if (!_isInitialized && !_isLoadingData) {
      // 未初始化且未加载数据时显示初始加载
      return const FadeInItem(
        child: LoadingWidget(
          isOverlay: true,
          message: "等待加载",
          overlayOpacity: 0.4,
          size: 36,
        ),
      );
    } else if (_isLoadingData && (_links == null || _tools == null)) {
      // 正在加载数据时显示加载中
      return const FadeInItem(
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中",
          overlayOpacity: 0.4,
          size: 36,
        ),
      );
    } else if (_errorMessage != null) {
      // 加载失败时显示错误信息
      return FadeInSlideUpItem(
        child: CustomErrorWidget(
          errorMessage: _errorMessage!, // 错误消息
          onRetry: _loadData, // 重试回调
        ),
      );
    } else {
      return isDesktop
          ? _buildDesktopLayout(isAdmin) // 桌面布局
          : _buildMobileLayout(isAdmin); // 移动布局
    }
  }

  /// 构建桌面布局。
  ///
  /// [isAdmin]：是否为管理员。
  /// 返回一个包含链接和工具部分的桌面布局。
  Widget _buildDesktopLayout(bool isAdmin) {
    const Duration titleDelay1 = Duration(milliseconds: 150); // 标题延迟
    const Duration titleDelay2 = Duration(milliseconds: 250); // 标题延迟

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FadeInSlideUpItem(
                  delay: titleDelay1, // 延迟动画
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('常用链接',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (isAdmin) // 管理员时显示添加链接按钮
                          IconButton(
                              icon: const Icon(Icons.add_link),
                              onPressed: () =>
                                  _showAddLinkDialog(context), // 添加链接回调
                              tooltip: '添加链接', // 工具提示
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              _buildLinksContent(isAdmin), // 构建链接内容
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: VerticalDivider(
              // 垂直分割线
              width: 32,
              thickness: 1,
              color: Theme.of(context).dividerColor.withSafeOpacity(0.15),
              indent: 8,
              endIndent: 8),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FadeInSlideUpItem(
                  delay: titleDelay2, // 延迟动画
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('实用工具',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (isAdmin) // 管理员时显示添加工具按钮
                          IconButton(
                              icon: const Icon(Icons.add_box_outlined),
                              onPressed: () =>
                                  _showAddToolDialog(context), // 添加工具回调
                              tooltip: '添加工具', // 工具提示
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              _buildToolsContent(isAdmin), // 构建工具内容
            ],
          ),
        ),
      ],
    );
  }

  /// 构建移动布局。
  ///
  /// [isAdmin]：是否为管理员。
  /// 返回一个包含链接和工具部分的移动布局。
  Widget _buildMobileLayout(bool isAdmin) {
    const Duration titleDelay1 = Duration(milliseconds: 150); // 标题延迟
    const Duration titleDelay2 = Duration(milliseconds: 250); // 标题延迟

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: FadeInSlideUpItem(
            delay: titleDelay1, // 延迟动画
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text('常用链接',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        _buildLinksContent(isAdmin), // 构建链接内容
        SliverToBoxAdapter(
          child: FadeInSlideUpItem(
            delay: titleDelay2, // 延迟动画
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text('实用工具',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        _buildToolsContent(isAdmin), // 构建工具内容
        SliverToBoxAdapter(
            child: SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom + 80)), // 增加底部安全区域
      ],
    );
  }

  /// 构建链接内容区域。
  ///
  /// [isAdmin]：是否为管理员。
  /// 根据加载状态、数据是否为空或错误信息显示不同的 UI。
  Widget _buildLinksContent(bool isAdmin) {
    if (_links == null && _isLoadingData) {
      // 首次加载中
      return const SliverFillRemaining(
          child: LoadingWidget(
        size: 32,
      ));
    } else if (_links == null || _links!.isEmpty) {
      // 加载失败或链接为空
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Center(
            child: FadeInSlideUpItem(
              child: CustomErrorWidget(
                errorMessage: _errorMessage ?? '暂无链接', // 错误消息或空状态消息
                icon: Icons.link_off, // 图标
                onRetry: _loadData, // 重试回调
              ),
            ),
          ),
        ),
      );
    }
    return LinksSection(
      // 显示链接列表
      links: _links!, // 链接数据
      isAdmin: isAdmin, // 是否为管理员
      onRefresh: _loadData, // 刷新回调
      linkToolService: widget.linkToolService, // 链接工具服务
      inputStateService: widget.inputStateService, // 输入状态服务
    );
  }

  /// 构建工具内容区域。
  ///
  /// [isAdmin]：是否为管理员。
  /// 根据加载状态、数据是否为空或错误信息显示不同的 UI。
  Widget _buildToolsContent(bool isAdmin) {
    if (_tools == null && _isLoadingData) {
      // 首次加载中
      return const SliverFillRemaining(
        child: LoadingWidget(
          size: 32,
        ),
      );
    } else if (_tools == null || _tools!.isEmpty) {
      // 加载失败或工具为空
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Center(
            child: FadeInSlideUpItem(
              child: CustomErrorWidget(
                errorMessage: _errorMessage ?? '暂无工具', // 错误消息或空状态消息
                icon: Icons.build_circle_outlined, // 图标
                onRetry: _loadData, // 重试回调
              ),
            ),
          ),
        ),
      );
    }
    return ToolsSection(
      // 显示工具列表
      tools: _tools!, // 工具数据
      isAdmin: isAdmin, // 是否为管理员
    );
  }
}
