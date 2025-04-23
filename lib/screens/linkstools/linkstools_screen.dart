// lib/screens/linkstools/linkstools_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/main/linktool/link_tool_service.dart';
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

// --- 引入动画组件 ---
import '../../widgets/ui/animation/fade_in_slide_up_item.dart';
// --- 结束引入 ---

class LinksToolsScreen extends StatefulWidget {
  const LinksToolsScreen({super.key});

  @override
  _LinksToolsScreenState createState() => _LinksToolsScreenState();
}

class _LinksToolsScreenState extends State<LinksToolsScreen> {
  final LinkToolService _linkToolService = LinkToolService();


  // --- 数据状态 (保持不变) ---
  List<Link>? _links;
  List<Tool>? _tools;
  String? _errorMessage;

  // --- 懒加载核心状态 (保持不变) ---
  bool _isInitialized = false;
  bool _isVisible = false;
  bool _isLoadingData = false;

  final double _desktopBreakpoint = 900.0;

  @override
  void initState() {
    super.initState();
    print("LinksToolsScreen initState: Initialized, waiting for visibility.");
  }

  @override
  void dispose() {
    print("LinksToolsScreen dispose: Cleaned up.");
    super.dispose();
  }

  // --- 核心：触发首次数据加载 (保持不变) ---
  void _triggerInitialLoad() {
    if (_isVisible && !_isInitialized && mounted) {
      // 添加 mounted 检查
      print(
          "LinksToolsScreen: Now visible and not initialized. Triggering initial load.");
      _isInitialized = true;
      _loadData();
    }
  }

  // --- 加载链接和工具数据 (保持不变) ---
  Future<void> _loadData() async {
    if (_isLoadingData || !mounted) return;
    print("LinksToolsScreen: Loading links and tools...");
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _linkToolService.getLinks().first,
        _linkToolService.getTools().first,
      ]);
      if (!mounted) return;
      setState(() {
        _links = List<Link>.from(results[0] as List? ?? []);
        _tools = List<Tool>.from(results[1] as List? ?? []);
        _isLoadingData = false;
      });
    } catch (e, s) {
      print('LinksToolsScreen: Load data error: $e\nStackTrace: $s');
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载失败：${e.toString()}';
        _links = [];
        _tools = [];
        _isLoadingData = false;
      });
    }
  }

  // --- _launchURL, _showAddLinkDialog, _showAddToolDialog (保持不变) ---
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
      if (mounted) AppSnackBar.showError(context, '打开链接失败: $e');
    }
  }

  void _showAddLinkDialog(BuildContext context) {
    showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => LinkFormDialog()).then((linkData) async {
      if (linkData != null) {
        try {
          await _linkToolService.addLink(Link.fromJson(linkData));
          if (mounted) AppSnackBar.showSuccess(context, '添加链接成功');
          await _loadData();
        } catch (e) {
          if (mounted) AppSnackBar.showError(context, '添加链接失败: $e');
        }
      }
    });
  }

  void _showAddToolDialog(BuildContext context) {
    showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ToolFormDialog()).then((toolData) async {
      if (toolData != null) {
        try {
          await _linkToolService.addTool(Tool.fromJson(toolData));
          if (mounted) AppSnackBar.showSuccess(context, '添加工具成功');
          await _loadData();
        } catch (e) {
          if (mounted) AppSnackBar.showError(context, '添加工具失败: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context,listen: false);
    final isAdmin = authProvider.isAdmin;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    return VisibilityDetector(
      key: Key('linkstools_screen_visibility'),
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        if (currentlyVisible != _isVisible) {
          Future.microtask(() {
            // 确保在 build 之后执行
            if (mounted) {
              setState(() => _isVisible = currentlyVisible);
            } else {
              _isVisible = currentlyVisible;
            }
            if (_isVisible) {
              _triggerInitialLoad();
            }
          });
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(title: '实用工具', actions: [
          //if (isAdmin) ..._buildAdminActions(context),
          // 不要了太丑了
        ]),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: _buildLinksToolsContent(isAdmin, isDesktop),
        ),
        floatingActionButton: _buildFloatButtons(isAdmin, context),
      ),
    );
  }

  Widget _buildFloatButtons(bool isAdmin, BuildContext context) {
    if (!isAdmin) return SizedBox.shrink();
    return Padding(
      // 给整个按钮组添加统一的外边距
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
      child: FloatingActionButtonGroup(
        spacing: 16.0, // 按钮间距
        alignment: MainAxisAlignment.end, // 底部对齐
        children: [
          GenericFloatingActionButton(
            onPressed: () =>
                _showAddLinkDialog(context), // onPressed 是 VoidCallback?
            icon: Icons.add_link,
            tooltip: '添加链接',
            heroTag: 'link_list_fab',
            //mini: true,
          ),
          GenericFloatingActionButton(
            onPressed: () => _showAddToolDialog(context),
            icon: Icons.add_box_outlined,
            tooltip: '添加工具',
            heroTag: 'tool_list_fab',
            //mini: true,
          )
        ],
      ),
    );
  }

  // --- 构建 Body 内容的逻辑 (应用动画) ---
  Widget _buildLinksToolsContent(bool isAdmin, bool isDesktop) {
    // State 1: 未初始化
    if (!_isInitialized && !_isLoadingData) {
      // --- 修改：添加动画 ---
      return LoadingWidget.fullScreen(message: "等待加载...");
      // --- 结束修改 ---
    }
    // State 2: 加载中
    else if (_isLoadingData) {
      // --- 修改：添加动画 ---
      return LoadingWidget.fullScreen(message: "正在加载工具和链接...");
      // --- 结束修改 ---
    }
    // State 3: 错误
    else if (_errorMessage != null) {
      // --- 修改：添加动画 ---
      return FadeInSlideUpItem(
        child: InlineErrorWidget(
          errorMessage: _errorMessage!,
          onRetry: _loadData,
        ),
      );
      // --- 结束修改 ---
    }
    // State 4: 加载成功
    else {
      if (isDesktop) {
        return _buildDesktopLayout(isAdmin); // 内部组件将应用动画
      } else {
        return _buildMobileLayout(isAdmin); // 内部组件将应用动画
      }
    }
  }

  // --- 构建桌面端布局 (应用标题动画) ---
  Widget _buildDesktopLayout(bool isAdmin) {
    // 定义动画延迟
    const Duration titleDelay1 = Duration(milliseconds: 150);
    const Duration titleDelay2 = Duration(milliseconds: 250);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Links
        Expanded(
          child: CustomScrollView(
            slivers: [
              // --- 修改：为标题行添加动画 ---
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
              // --- 结束修改 ---
              // 链接内容区域 (内部将添加动画)
              _buildLinksContent(isAdmin),
            ],
          ),
        ),
        // Separator (保持不变)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: VerticalDivider(
              width: 32,
              thickness: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.15),
              indent: 8,
              endIndent: 8),
        ),
        // Right: Tools
        Expanded(
          child: CustomScrollView(
            slivers: [
              // --- 修改：为标题行添加动画 ---
              SliverToBoxAdapter(
                child: FadeInSlideUpItem(
                  delay: titleDelay2, // 稍微延迟出现
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
              // --- 结束修改 ---
              // 工具内容区域 (内部将添加动画)
              _buildToolsContent(isAdmin),
            ],
          ),
        ),
      ],
    );
  }

  // --- 构建移动端布局 (应用标题动画) ---
  Widget _buildMobileLayout(bool isAdmin) {
    // 定义动画延迟
    const Duration titleDelay1 = Duration(milliseconds: 150);
    const Duration titleDelay2 = Duration(milliseconds: 250); // 第二个标题延迟

    return CustomScrollView(
      slivers: [
        // --- 修改：为标题添加动画 ---
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
        // --- 结束修改 ---
        // 链接内容 (内部将添加动画)
        _buildLinksContent(isAdmin),

        // --- 修改：为标题添加动画 ---
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
        // --- 结束修改 ---
        // 工具内容 (内部将添加动画)
        _buildToolsContent(isAdmin),

        // 增加底部安全区域或间距，防止内容被遮挡
        SliverToBoxAdapter(
            child:
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16)),
      ],
    );
  }

  // --- 构建链接区域内容 (应用空状态动画) ---
  Widget _buildLinksContent(bool isAdmin) {
    if (_links == null || _links!.isEmpty) {
      // --- 修改：为空状态添加动画 ---
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Center(
            child: FadeInSlideUpItem(
              // 添加动画
              child: InlineErrorWidget(
                errorMessage: '暂无常用链接',
                icon: Icons.link_off,
                // retryText: '刷新试试', // 可以简化，下拉刷新效果更好
                onRetry: _loadData,
              ),
            ),
          ),
        ),
      );
      // --- 结束修改 ---
    }
    // LinksSection 内部将处理列表项动画
    return LinksSection(
      links: _links!,
      isAdmin: isAdmin,
      onRefresh: _loadData,
      onLaunchURL: (url) => _launchURL(context, url),
      linkToolService: _linkToolService,
    );
  }

  // --- 构建工具区域内容 (应用空状态动画) ---
  Widget _buildToolsContent(bool isAdmin) {
    if (_tools == null || _tools!.isEmpty) {
      // --- 修改：为空状态添加动画 ---
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Center(
            // 居中显示
            child: FadeInSlideUpItem(
              // 添加动画
              child: InlineErrorWidget(
                errorMessage: '暂无实用工具',
                icon: Icons.build_circle_outlined,
                // retryText: '刷新试试',
                onRetry: _loadData,
              ),
            ),
          ),
        ),
      );
      // --- 结束修改 ---
    }
    // ToolsSection 内部将处理列表项动画
    return ToolsSection(
      tools: _tools!,
      isAdmin: isAdmin,
      onLaunchURL: (url) => _launchURL(context, url),
    );
  }
}
