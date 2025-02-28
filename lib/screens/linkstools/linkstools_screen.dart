// lib/screens/linkstools/linkstools_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/main/linktool/link_tool_service.dart';
import '../../models/linkstools/link.dart';
import '../../models/linkstools/tool.dart';
import '../../widgets/common/toaster.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/form/linkform/link_form_dialog.dart';
import '../../widgets/form/toolform/tool_form_dialog.dart';
import '../../utils/load/loading_route_observer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/components/screen/linkstools/links_section.dart';
import '../../widgets/components/screen/linkstools/tools_section.dart';

class LinksToolsScreen extends StatefulWidget {
  @override
  _LinksToolsScreenState createState() => _LinksToolsScreenState();
}

class _LinksToolsScreenState extends State<LinksToolsScreen> {
  final LinkToolService _linkToolService = LinkToolService();
  List<Link>? _links;
  List<Tool>? _tools;
  String? _errorMessage;

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
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      final links = await _linkToolService.getLinks().first;
      final tools = await _linkToolService.getTools().first;

      setState(() {
        _links = links;
        _tools = tools;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败：${e.toString()}';
        _links = [];
        _tools = [];
      });
    } finally {
      loadingObserver.hideLoading();
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

  // Desktop layout with side-by-side sections
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

  // Original mobile layout (stacked vertically)
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

  // Common links section content
  Widget _buildLinksContent(bool isAdmin) {
    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(child: Text(_errorMessage!)),
      );
    } else if (_links == null) {
      return SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_links!.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(child: Text('暂无链接')),
      );
    } else {
      return LinksSection(
        links: _links!,
        isAdmin: isAdmin,
        onRefresh: _loadData,
        onLaunchURL: (url) => _launchURL(context, url),
        linkToolService: _linkToolService,
      );
    }
  }

  // Common tools section content
  Widget _buildToolsContent(bool isAdmin) {
    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(child: Text(_errorMessage!)),
      );
    } else if (_tools == null) {
      return SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_tools!.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(child: Text('暂无工具')),
      );
    } else {
      return ToolsSection(
        tools: _tools!,
        isAdmin: isAdmin,
        onLaunchURL: (url) => _launchURL(context, url),
      );
    }
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
    showDialog<Tool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ToolFormDialog(),
    ).then((tool) async {
      if (tool != null) {
        try {
          final loadingObserver = Navigator.of(context)
              .widget.observers
              .whereType<LoadingRouteObserver>()
              .first;
          loadingObserver.showLoading();

          await _linkToolService.addTool(tool);
          Toaster.show(context, message: '添加工具成功');
          await _loadData();
        } catch (e) {
          Toaster.show(context, message: '添加工具失败: $e', isError: true);
        } finally {
          Navigator.of(context)
              .widget.observers
              .whereType<LoadingRouteObserver>()
              .first
              .hideLoading();
        }
      }
    });
  }
}