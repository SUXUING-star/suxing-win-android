// lib/screens/linkstools/linkstools_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';
// --- 确保引入正确的 Service ---
import '../../models/linkstools/link.dart';
import '../../models/linkstools/tool.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/components/form/linkform/link_form_dialog.dart';
import '../../widgets/components/form/toolform/tool_form_dialog.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/linkstools/links_section.dart';
import '../../widgets/components/screen/linkstools/tools_section.dart';
import '../../widgets/ui/common/loading_widget.dart';
import '../../widgets/ui/common/error_widget.dart';
import '../../widgets/ui/animation/fade_in_slide_up_item.dart';

class LinksToolsScreen extends StatefulWidget {
  final AuthProvider? authProvider;
  const LinksToolsScreen({
    super.key,
    this.authProvider,
  });

  @override
  _LinksToolsScreenState createState() => _LinksToolsScreenState();
}

class _LinksToolsScreenState extends State<LinksToolsScreen>
    with WidgetsBindingObserver {
  // --- 数据状态 (保持不变) ---
  List<Link>? _links;
  List<Tool>? _tools;
  String? _errorMessage;

  // --- 懒加载核心状态 (保持不变) ---
  bool _isInitialized = false;
  bool _hasInitializedDependencies = false;
  bool _isVisible = false;
  bool _isLoadingData = false; // 这个状态仍然控制加载指示器

  late final LinkToolService _linkToolService;
  late final AuthProvider _authProvider;

  String? _currentUserId;

  final double _desktopBreakpoint = 900.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _linkToolService = context.read<LinkToolService>();

      _authProvider = widget.authProvider ??
          Provider.of<AuthProvider>(context, listen: false);
      _currentUserId = _authProvider.currentUserId;
      _hasInitializedDependencies = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      if (_currentUserId != _authProvider.currentUserId) {
        setState(() {
          _currentUserId = _authProvider.currentUserId;
        });
      }
      _loadData();
    }
  }

  @override
  void didUpdateWidget(covariant LinksToolsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != oldWidget.authProvider?.currentUserId ||
        _currentUserId != _authProvider.currentUserId) {
      if (mounted) {
        setState(() {
          _currentUserId = _authProvider.currentUserId;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  // --- 核心：触发首次数据加载 (保持不变) ---
  void _triggerInitialLoad() {
    // 逻辑完全不变
    if (_isVisible && !_isInitialized && mounted) {
      _isInitialized = true;
      _loadData(); // 调用时不带任何参数
    }
  }

  // --- 加载链接和工具数据 ---
  Future<void> _loadData() async {
    if (_isLoadingData || !mounted) return; // 逻辑不变
    setState(() {
      // 状态更新逻辑不变
      _isLoadingData = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _linkToolService.getLinks(), // 直接调用，不传 forceRefresh
        _linkToolService.getTools(), // 直接调用，不传 forceRefresh
      ]);

      if (!mounted) return; // 逻辑不变
      setState(() {
        // 状态更新逻辑不变
        // Future.wait 返回的是 List<dynamic>
        _links = List<Link>.from(results[0] as List? ?? []);
        _tools = List<Tool>.from(results[1] as List? ?? []);
        _isLoadingData = false;
      });
    } catch (e, s) {
      // 错误处理逻辑不变
      print('LinksToolsScreen: Load data error: $e\nStackTrace: $s');
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载失败：${e.toString()}';
        _links = []; // 或保持旧数据？按原逻辑设为空
        _tools = [];
        _isLoadingData = false;
      });
    }
  }

  // --- _launchURL (保持不变) ---
  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw '无法打开链接 $url';
      }
    } catch (e) {
      print("Error launching URL $url: $e");
    }
  }

  // --- _showAddLinkDialog (保持不变, 调用 _loadData 时不传参数) ---
  void _showAddLinkDialog(BuildContext context) {
    showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => LinkFormDialog()).then((linkData) async {
      if (linkData != null) {
        try {
          await _linkToolService.addLink(Link.fromJson(linkData));
          await _loadData();
          if (!mounted) return;
          AppSnackBar.showSuccess(this.context, '添加链接成功');
        } catch (e) {
          if (mounted) {
            AppSnackBar.showError(this.context, '添加链接失败: ${e.toString()}');
          }
        }
      }
    });
  }

  // --- _showAddToolDialog (保持不变, 调用 _loadData 时不传参数) ---
  void _showAddToolDialog(BuildContext context) {
    showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ToolFormDialog()).then((toolData) async {
      if (toolData != null) {
        try {
          await _linkToolService.addTool(Tool.fromJson(toolData));
          if (mounted) await _loadData();

          if (mounted) {
            AppSnackBar.showSuccess(this.context, '添加工具成功');
          }
        } catch (e) {
          if (mounted) {
            AppSnackBar.showError(this.context, "添加失败 ${e.toString()}");
          }
        }
      }
    });
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    if (!mounted) return;
    final bool currentlyVisible = info.visibleFraction > 0;
    if (_currentUserId != _authProvider.currentUserId) {
      setState(() {
        _currentUserId = _authProvider.currentUserId;
      });
    }
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
          } else {}
        }
      });
    }
  }

  // --- build 方法 (保持不变, RefreshIndicator 调用 _loadData 时不传参数) ---
  @override
  Widget build(BuildContext context) {
    final isAdmin = _authProvider.isAdmin;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    return VisibilityDetector(
      key: Key('linkstools_screen_visibility'),
      onVisibilityChanged: _handleVisibilityChange,
      child: Scaffold(
        appBar: CustomAppBar(title: '实用工具'), // actions 移除不变
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: _buildLinksToolsContent(isAdmin, isDesktop), // 内部逻辑不变
        ),
        floatingActionButton: _buildFloatButtons(isAdmin, context), // 逻辑不变
      ),
    );
  }

  // --- _buildFloatButtons (保持不变) ---
  Widget _buildFloatButtons(bool isAdmin, BuildContext context) {
    if (!isAdmin) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
      child: FloatingActionButtonGroup(
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

  // --- _buildLinksToolsContent (保持不变, 重试调用 _loadData 时不传参数) ---
  Widget _buildLinksToolsContent(bool isAdmin, bool isDesktop) {
    // State 1: 未初始化 (逻辑不变)
    if (!_isInitialized && !_isLoadingData) {
      return LoadingWidget.fullScreen(message: "等待加载...");
    }
    // State 2: 加载中 (逻辑微调以匹配原意)
    else if (_isLoadingData && (_links == null || _tools == null)) {
      // 仅在首次加载且数据为 null 时显示全屏 Loading
      return LoadingWidget.fullScreen(message: "正在加载工具和链接...");
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
      if (isDesktop) {
        return _buildDesktopLayout(isAdmin);
      } else {
        return _buildMobileLayout(isAdmin);
      }
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
    final linkToolService = context.read<LinkToolService>();
    if (_links == null && _isLoadingData) {
      // 首次加载中
      return SliverFillRemaining(child: LoadingWidget.inline());
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
      onRefresh: _loadData, // *** 调用恢复原样 ***
      onLaunchURL: (url) => _launchURL(context, url),
      linkToolService: linkToolService, // 传递 service 用于编辑删除
    );
  }

  // --- _buildToolsContent (保持不变, 重试调用 _loadData()) ---
  Widget _buildToolsContent(bool isAdmin) {
    if (_tools == null && _isLoadingData) {
      // 首次加载中
      return SliverFillRemaining(child: LoadingWidget.inline());
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
                onRetry: _loadData, // *** 调用恢复原样 ***
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
      onLaunchURL: (url) => _launchURL(context, url),
      // linkToolService, // ToolsSection 不需要 service
    );
  }
}
