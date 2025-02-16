// lib/screens/linkstools/linkstools_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/link_tool_service.dart';
import '../../models/link.dart';
import '../../models/tool.dart';
import '../../widgets/common/toaster.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/form/linkform/link_form_dialog.dart';
import '../../widgets/form/toolform/tool_form_dialog.dart';
import '../../utils/loading_route_observer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/linkstools/links_section.dart';
import '../../widgets/linkstools/tools_section.dart';

class LinksToolsScreen extends StatefulWidget {
  @override
  _LinksToolsScreenState createState() => _LinksToolsScreenState();
}

class _LinksToolsScreenState extends State<LinksToolsScreen> {
  final LinkToolService _linkToolService = LinkToolService();
  List<Link>? _links;
  List<Tool>? _tools;
  String? _errorMessage;

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

    return Scaffold(
      appBar: CustomAppBar(
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
        child: CustomScrollView(
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
            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Center(child: Text(_errorMessage!)),
              )
            else if (_links == null)
              SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_links!.isEmpty)
                SliverToBoxAdapter(
                  child: Center(child: Text('暂无链接')),
                )
              else
                LinksSection(
                  links: _links!,
                  isAdmin: isAdmin,
                  onRefresh: _loadData,
                  onLaunchURL: (url) => _launchURL(context, url),
                  linkToolService: _linkToolService,
                ),

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
            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Center(child: Text(_errorMessage!)),
              )
            else if (_tools == null)
              SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tools!.isEmpty)
                SliverToBoxAdapter(
                  child: Center(child: Text('暂无工具')),
                )
              else
                ToolsSection(
                  tools: _tools!,
                  isAdmin: isAdmin,
                  onLaunchURL: (url) => _launchURL(context, url),
                ),
          ],
        ),
      ),
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
      barrierDismissible: false, // 防止误触关闭
      builder: (context) => ToolFormDialog(),
    ).then((toolData) async {
      if (toolData != null) {
        try {
          final loadingObserver = Navigator.of(context)
              .widget.observers
              .whereType<LoadingRouteObserver>()
              .first;
          loadingObserver.showLoading();

          await _linkToolService.addTool(Tool.fromJson(toolData));
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