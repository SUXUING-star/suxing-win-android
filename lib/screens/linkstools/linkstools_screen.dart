// lib/screens/linkstools/linkstools_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:suxingchahui/models/linkstools/site_link.dart';
import 'package:suxingchahui/models/linkstools/tool.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/widgets/components/form/linkform/link_form_dialog.dart';
import 'package:suxingchahui/widgets/components/form/toolform/tool_form_dialog.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/components/screen/linkstools/links_section.dart';
import 'package:suxingchahui/widgets/components/screen/linkstools/tools_section.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';

class LinksToolsScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final LinkToolService linkToolService;
  final InputStateService inputStateService;
  final WindowStateProvider windowStateProvider;

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
  List<SiteLink>? _links;
  List<Tool>? _tools;
  String? _errorMessage;

  // --- 懒加载核心状态  ---
  bool _isInitialized = false;
  bool _hasInitializedDependencies = false;
  bool _isVisible = false;
  bool _isLoadingData = false;
  DateTime? _lastLoadingTime;
  Timer? _refreshDebounceTimer;
  bool _needsRefresh = false; // 是否需要在变为可见或后台恢复时刷新
  static const Duration _maxLoadingDuration = Duration(seconds: 10);

  static const Duration _cacheDebounceDuration = Duration(seconds: 2); // 缓存防抖时长

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId;
      _hasInitializedDependencies = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    _checkAuthStateChange();
    _checkLoadingTimeout();
    if (state == AppLifecycleState.resumed) {
      if (_isVisible) {
        if (_needsRefresh) {
          // 需要刷新时
          _refreshDataIfNeeded(reason: "应用恢复且需要刷新"); // 刷新数据
          _needsRefresh = false; // 重置刷新标记
        }
      } else {
        // 屏幕不可见时
        _needsRefresh = true; // 标记，等可见时刷新
      }
    } else if (state == AppLifecycleState.paused) {
      // 应用暂停时
      _needsRefresh = true; // 标记需要刷新
    }
  }

  @override
  void didUpdateWidget(covariant LinksToolsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAuthStateChange();
    _checkLoadingTimeout();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    if (!mounted) return;
    final bool currentlyVisible = info.visibleFraction > 0;
    _checkAuthStateChange();
    _checkLoadingTimeout();
    if (currentlyVisible != _isVisible) {
      Future.microtask(() {
        if (mounted) {
          setState(() => _isVisible = currentlyVisible);
        } else {
          _isVisible = currentlyVisible;
        }
        if (_isVisible) {
          if (!_isInitialized) {
            _triggerInitialLoad(); // 内部调用 _loadData()
          } else {
            if (_needsRefresh) {
              // 需要刷新时
              _refreshDataIfNeeded(reason: "应用恢复且需要刷新"); // 刷新数据
              _needsRefresh = false; // 重置刷新标记
            }
          }
        } else {
          // 屏幕不可见时
          _needsRefresh = true; // 标记，等可见时刷新
        }
      });
    }
  }

  void _checkAuthStateChange() {
    if (!mounted) return;
    if (_currentUserId != widget.authProvider.currentUserId) {
      setState(() {
        _currentUserId = widget.authProvider.currentUserId;
      });
    }
  }

  void _checkLoadingTimeout() {
    if (!mounted) return;
    final now = DateTime.now();
    // 超过最大时长直接关闭
    if (_isLoadingData &&
        _lastLoadingTime != null &&
        now.difference(_lastLoadingTime!) > _maxLoadingDuration) {
      setState(() {
        _lastLoadingTime = null;
        _isLoadingData = false;
      });
    }
  }

  // --- 触发首次数据加载  ---
  void _triggerInitialLoad() {
    // 逻辑完全不变
    if (_isVisible && !_isInitialized && mounted) {
      _isInitialized = true;
      _loadData(); // 调用时不带任何参数
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
    if (!mounted) return; // 组件未挂载时返回
    _refreshDebounceTimer?.cancel(); // 取消旧的防抖计时器
    _refreshDebounceTimer = Timer(_cacheDebounceDuration, () {
      // 启动新的防抖计时器
      if (!mounted) return; // 组件未挂载时返回
      if (!_isVisible) {
        // 屏幕不可见时
        _needsRefresh = true; // 标记需要刷新
        return;
      }
      if (_isLoadingData) {
        // 正在加载数据时
        if (isCacheUpdated) {
          // 如果是缓存更新触发
          return;
        } else {
          _needsRefresh = true; // 标记需要刷新
          return;
        }
      }
      _loadData(); // 加载帖子数据
    });
  }

  // --- 加载链接和工具数据 ---
  Future<void> _loadData() async {
    if (_lastLoadingTime != null) _lastLoadingTime = null;
    if (_isLoadingData || !mounted) return; // 逻辑不变
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
      _lastLoadingTime = DateTime.now();
    });
    try {
      final results = await Future.wait([
        widget.linkToolService.getLinks(),
        widget.linkToolService.getTools(),
      ]);

      if (!mounted) return; // 逻辑不变
      setState(() {
        // 状态更新逻辑不变
        // Future.wait 返回的是 List<dynamic>
        _links = List<SiteLink>.from(results[0] as List? ?? []);
        _tools = List<Tool>.from(results[1] as List? ?? []);
        _isLoadingData = false;
      });
    } catch (e) {
      // 错误处理逻辑不变
      //print('LinksToolsScreen: Load data error: $e\nStackTrace: $s');
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载失败：${e.toString()}';
        _links = []; // 或保持旧数据？按原逻辑设为空
        _tools = [];
        _isLoadingData = false;
        _lastLoadingTime = null;
      });
    }
  }

  // --- _showAddLinkDialog ---
  void _showAddLinkDialog(BuildContext context) {
    if (!_checkCanEditOrDelete()) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => LinkFormDialog(
              inputStateService: widget.inputStateService,
            )).then((linkData) async {
      if (linkData != null) {
        try {
          await widget.linkToolService.addLink(SiteLink.fromJson(linkData));
          await _loadData();
          if (!mounted) return;
          AppSnackBar.showSuccess('添加链接成功');
        } catch (e) {
          AppSnackBar.showError('添加链接失败: ${e.toString()}');
        }
      }
    });
  }

  bool _checkCanEditOrDelete() {
    return widget.authProvider.isAdmin;
  }

  // --- _showAddToolDialog  ---
  void _showAddToolDialog(BuildContext context) {
    if (!_checkCanEditOrDelete()) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ToolFormDialog(
              inputStateService: widget.inputStateService,
            )).then((toolData) async {
      if (toolData != null) {
        try {
          await widget.linkToolService.addTool(Tool.fromJson(toolData));
          if (mounted) await _loadData();

          AppSnackBar.showSuccess('添加工具成功');
        } catch (e) {
          AppSnackBar.showError("添加失败 ${e.toString()}");
        }
      }
    });
  }

  // --- build 方法  ---
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: widget.authProvider.currentUserStream,
        initialData: widget.authProvider.currentUser,
        builder: (context, authSnapshot) {
          final currentUser = authSnapshot.data;

          final isAdmin = currentUser?.isAdmin ?? false;

          return VisibilityDetector(
            key: Key('linkstools_screen_visibility'),
            onVisibilityChanged: _handleVisibilityChange,
            child: Scaffold(
              appBar: const CustomAppBar(title: '实用工具'),
              body: RefreshIndicator(
                onRefresh: _loadData,
                child: _buildLinksToolsContent(isAdmin),
              ),
              floatingActionButton: _buildFloatButtons(isAdmin, context),
            ),
          );
        });
  }

  // --- _buildFloatButtons  ---
  Widget _buildFloatButtons(bool isAdmin, BuildContext context) {
    if (!isAdmin) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
      child: FloatingActionButtonGroup(
        toggleButtonHeroTag: "link_tool_heroTags",
        spacing: 16.0,
        alignment: MainAxisAlignment.end,
        children: [
          GenericFloatingActionButton(
            onPressed: () => _showAddLinkDialog(context),
            icon: Icons.add_link,
            tooltip: '添加链接',
            heroTag: 'link_list_fab',
          ),
          GenericFloatingActionButton(
            onPressed: () => _showAddToolDialog(context),
            icon: Icons.add_box_outlined,
            tooltip: '添加工具',
            heroTag: 'tool_list_fab',
          )
        ],
      ),
    );
  }

  Widget _buildLinksToolsContent(bool isAdmin) {
    // State 1: 未初始化 (逻辑不变)
    if (!_isInitialized && !_isLoadingData) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "等待加载...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }
    // State 2: 加载中
    else if (_isLoadingData && (_links == null || _tools == null)) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }
    // State 3: 错误 (逻辑不变, 重试调用 _loadData())
    else if (_errorMessage != null) {
      return FadeInSlideUpItem(
        child: CustomErrorWidget(
          errorMessage: _errorMessage!,
          onRetry: _loadData, // *** 调用恢复原样 ***
        ),
      );
    }
    // State 4: 加载成功 (逻辑不变)
    else {
      return LazyLayoutBuilder(
        windowStateProvider: widget.windowStateProvider,
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isDesktop = DeviceUtils.isDesktopInThisWidth(screenWidth);
          return isDesktop
              ? _buildDesktopLayout(isAdmin)
              : _buildMobileLayout(isAdmin);
        },
      );
    }
  }

  // --- _buildDesktopLayout (保持不变) ---
  Widget _buildDesktopLayout(bool isAdmin) {
    const Duration titleDelay1 = Duration(milliseconds: 150);
    const Duration titleDelay2 = Duration(milliseconds: 250);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FadeInSlideUpItem(
                  delay: titleDelay1,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('常用链接',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (isAdmin)
                          IconButton(
                              icon: Icon(Icons.add_link),
                              onPressed: () => _showAddLinkDialog(context),
                              tooltip: '添加链接',
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              _buildLinksContent(isAdmin),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: VerticalDivider(
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
                  delay: titleDelay2,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('实用工具',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (isAdmin)
                          IconButton(
                              icon: Icon(Icons.add_box_outlined),
                              onPressed: () => _showAddToolDialog(context),
                              tooltip: '添加工具',
                              color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              _buildToolsContent(isAdmin),
            ],
          ),
        ),
      ],
    );
  }

  // --- _buildMobileLayout (保持不变) ---
  Widget _buildMobileLayout(bool isAdmin) {
    const Duration titleDelay1 = Duration(milliseconds: 150);
    const Duration titleDelay2 = Duration(milliseconds: 250);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: FadeInSlideUpItem(
            delay: titleDelay1,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text('常用链接',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        _buildLinksContent(isAdmin),
        SliverToBoxAdapter(
          child: FadeInSlideUpItem(
            delay: titleDelay2, // 延迟出现
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text('实用工具',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        _buildToolsContent(isAdmin),
        SliverToBoxAdapter(
            child: SizedBox(
                height: MediaQuery.of(context).padding.bottom +
                    80)), // 增加底部安全区域或间距，防止内容被遮挡 (FAB)
      ],
    );
  }

  // --- _buildLinksContent (保持不变, 重试调用 _loadData()) ---
  Widget _buildLinksContent(bool isAdmin) {
    if (_links == null && _isLoadingData) {
      // 首次加载中
      return const SliverFillRemaining(
          child: LoadingWidget(
        size: 24,
      ));
    } else if (_links == null || _links!.isEmpty) {
      // 加载失败或为空
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Center(
            child: FadeInSlideUpItem(
              child: CustomErrorWidget(
                errorMessage: _errorMessage ?? '暂无链接', // 显示错误信息或空状态
                icon: Icons.link_off,
                onRetry: _loadData, // *** 调用恢复原样 ***
              ),
            ),
          ),
        ),
      );
    }
    // LinksSection 内部将处理列表项动画
    return LinksSection(
      links: _links!,
      isAdmin: isAdmin,
      onRefresh: _loadData,
      linkToolService: widget.linkToolService, // 传递 service 用于编辑删除
      inputStateService: widget.inputStateService,
    );
  }

  // --- _buildToolsContent (保持不变, 重试调用 _loadData()) ---
  Widget _buildToolsContent(bool isAdmin) {
    if (_tools == null && _isLoadingData) {
      // 首次加载中
      return const SliverFillRemaining(child: LoadingWidget());
    } else if (_tools == null || _tools!.isEmpty) {
      // 加载失败或为空
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Center(
            child: FadeInSlideUpItem(
              child: CustomErrorWidget(
                errorMessage: _errorMessage ?? '暂无工具',
                icon: Icons.build_circle_outlined,
                onRetry: _loadData,
              ),
            ),
          ),
        ),
      );
    }
    // ToolsSection 内部将处理列表项动画
    return ToolsSection(
      tools: _tools!,
      isAdmin: isAdmin,
      // linkToolService, // ToolsSection 不需要 service
    );
  }
}
