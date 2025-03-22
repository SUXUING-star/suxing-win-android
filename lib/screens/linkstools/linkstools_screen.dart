// lib/screens/linkstools/linkstools_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/main/linktool/link_tool_service.dart';
import '../../models/linkstools/link.dart';
import '../../models/linkstools/tool.dart';
import '../../widgets/common/toaster/toaster.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/components/form/linkform/link_form_dialog.dart';
import '../../widgets/components/form/toolform/tool_form_dialog.dart';
import '../../widgets/common/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/linkstools/links_section.dart';
import '../../widgets/components/screen/linkstools/tools_section.dart';
import '../../widgets/components/common/loading_widget.dart';
import '../../widgets/components/common/error_widget.dart';

class LinksToolsScreen extends StatefulWidget {
  @override
  _LinksToolsScreenState createState() => _LinksToolsScreenState();
}

class _LinksToolsScreenState extends State<LinksToolsScreen> {
  final LinkToolService _linkToolService = LinkToolService();
  List<Link>? _links;
  List<Tool>? _tools;
  String? _errorMessage;
  bool _isLoading = true;

  // Define breakpoint for desktop layout
  final double _desktopBreakpoint = 900.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final links = await _linkToolService.getLinks().first;
      final tools = await _linkToolService.getTools().first;

      setState(() {
        _links = links;
        _tools = tools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败：${e.toString()}';
        _links = [];
        _tools = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw '无法打开链接';
      }
    } catch (e) {
      Toaster.show(context, message: '打开链接失败: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>((auth) => auth.isAdmin);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    // 处理加载状态
    if (_isLoading) {
      return Scaffold(
        appBar: isDesktop ? null : CustomAppBar(title: '实用工具'),
        body: LoadingWidget.fullScreen(message: '正在加载工具和链接...'),
      );
    }

    // 处理错误状态
    if (_errorMessage != null) {
      return Scaffold(
        appBar: isDesktop ? null : CustomAppBar(title: '实用工具'),
        body: CustomErrorWidget(
          errorMessage: _errorMessage!,
          onRetry: _loadData,
          title: '加载失败',
        ),
      );
    }

    return Scaffold(
      // AppBar only for mobile layout
      appBar: isDesktop
          ? null
          : CustomAppBar(
        title: '实用工具',
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: Icon(Icons.add_link),
              onPressed: () => _showAddLinkDialog(context),
              tooltip: '添加链接',
            ),
            IconButton(
              icon: Icon(Icons.add_box),
              onPressed: () => _showAddToolDialog(context),
              tooltip: '添加工具',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isDesktop
            ? _buildDesktopLayout(isAdmin)
            : _buildMobileLayout(isAdmin),
      ),
    );
  }

  // 桌面端布局 (代码保持不变)
  Widget _buildDesktopLayout(bool isAdmin) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Links Section (Left side)
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '常用链接',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Add link button for desktop on the left side
                      if (isAdmin)
                        IconButton(
                          icon: Icon(Icons.add_link),
                          onPressed: () => _showAddLinkDialog(context),
                          tooltip: '添加链接',
                        ),
                    ],
                  ),
                ),
              ),
              _buildLinksContent(isAdmin),
            ],
          ),
        ),

        // Improved vertical divider with elegant desktop styling
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: VerticalDivider(
            width: 32,
            thickness: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.15),
            indent: 8,
            endIndent: 8,
          ),
        ),

        // Tools Section (Right side)
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '实用工具',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Add tool button for desktop on the right side
                      if (isAdmin)
                        IconButton(
                          icon: Icon(Icons.add_box),
                          onPressed: () => _showAddToolDialog(context),
                          tooltip: '添加工具',
                        ),
                    ],
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

  // 移动端布局 (代码保持不变)
  Widget _buildMobileLayout(bool isAdmin) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              '常用链接',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildLinksContent(isAdmin),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              '实用工具',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildToolsContent(isAdmin),
      ],
    );
  }

  // 链接区域内容构建 (替换原有的错误和加载处理)
  Widget _buildLinksContent(bool isAdmin) {
    if (_links == null || _links!.isEmpty) {
      return SliverToBoxAdapter(
        child: CustomErrorWidget(
          errorMessage: '暂无链接',
          icon: Icons.link_off,
          title: '链接',
          retryText: '刷新',
          onRetry: _loadData,
        ),
      );
    }

    return LinksSection(
      links: _links!,
      isAdmin: isAdmin,
      onRefresh: _loadData,
      onLaunchURL: (url) => _launchURL(context, url),
      linkToolService: _linkToolService,
    );
  }

  // 工具区域内容构建 (替换原有的错误和加载处理)
  Widget _buildToolsContent(bool isAdmin) {
    if (_tools == null || _tools!.isEmpty) {
      return SliverToBoxAdapter(
        child: CustomErrorWidget(
          errorMessage: '暂无工具',
          icon: Icons.miscellaneous_services,
          title: '工具',
          retryText: '刷新',
          onRetry: _loadData,
        ),
      );
    }

    return ToolsSection(
      tools: _tools!,
      isAdmin: isAdmin,
      onLaunchURL: (url) => _launchURL(context, url),
    );
  }

  void _showAddLinkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LinkFormDialog(),
    ).then((linkData) async {
      if (linkData != null) {
        try {
          await _linkToolService.addLink(Link.fromJson(linkData));
          Toaster.show(context, message: '添加链接成功');
          await _loadData();
        } catch (e) {
          Toaster.show(context, message: '添加链接失败: $e', isError: true);
        }
      }
    });
  }

  void _showAddToolDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ToolFormDialog(),
    ).then((toolData) async {
      if (toolData != null) {
        try {
          final tool = Tool.fromJson(toolData);
          await _linkToolService.addTool(tool);

          Toaster.show(context, message: '添加工具成功');
          await _loadData();
        } catch (e) {
          print('添加工具错误: $e'); // 添加日志以便调试
          Toaster.show(context, message: '添加工具失败: $e', isError: true);
        }
      }
    });
  }
}