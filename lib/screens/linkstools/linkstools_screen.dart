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
      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      _loadData().then((_) {
        loadingObserver.hideLoading();
      });
    });
  }

  Future<void> _loadData() async {
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
    }
  }

  Future<void> _refreshData() async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadData();
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
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            // 链接区域标题
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '常用链接',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            _buildLinksSection(context, isAdmin),

            // 工具区域标题
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  '实用工具',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            _buildToolsSection(context, isAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksSection(BuildContext context, bool isAdmin) {
    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(child: Text(_errorMessage!)),
      );
    }

    if (_links == null) {
      return SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_links!.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(child: Text('暂无链接')),
      );
    }

    return SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
    sliver: SliverList(
    delegate: SliverChildBuilderDelegate(
    (context, index) {
    final link = _links![index];
    return Card(
    margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(link.color.replaceFirst('#', '0xFF'))),
          child: Icon(Icons.link, color: Colors.white),
        ),
        title: Text(link.title),
        subtitle: Text(
          link.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.open_in_new),
              onPressed: () => _launchURL(context, link.url),
            ),
            if (isAdmin)
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => LinkFormDialog(link: link),
                  ).then((linkData) async {
                    if (linkData != null) {
                      try {
                        await _linkToolService.updateLink(Link.fromJson(linkData));
                        Toaster.show(context, message: '更新链接成功');
                        await _loadData();
                      } catch (e) {
                        Toaster.show(context, message: '更新链接失败: $e', isError: true);
                      }
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
    },
      childCount: _links!.length,
    ),
    ),
    );
  }

  Widget _buildToolsSection(BuildContext context, bool isAdmin) {
    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(child: Text(_errorMessage!)),
      );
    }

    if (_tools == null) {
      return SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tools!.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(child: Text('暂无工具')),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final tool = _tools![index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                      int.parse(tool.color.replaceFirst('#', '0xFF'))),
                  child: Icon(
                    Icons.build,
                    color: Colors.white,
                  ),
                ),
                title: Text(tool.name),
                subtitle: Text(
                  tool.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // trailing: isAdmin
                //     ? IconButton(
                //   icon: Icon(Icons.edit),
                //   onPressed: () {
                //     showDialog(
                //       context: context,
                //       builder: (context) => ToolFormDialog(tool: tool),
                //     ).then((toolData) async {
                //       if (toolData != null) {
                //         print('toolData before update: $toolData');  // 打印
                //         try {
                //           await _linkToolService.updateTool(Tool.fromJson(toolData));
                //           Toaster.show(context, message: '更新工具成功');
                //           await _loadData();
                //         } catch (e) {
                //           Toaster.show(context, message: '更新工具失败: $e', isError: true);
                //         }
                //       }
                //     });
                //   },
                // )
                //     : null,
                children: [
                  if (tool.downloads.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: tool.downloads
                            .map((download) => ListTile(
                          title: Text(download['name'] ?? ''),
                          subtitle:
                          Text(download['description'] ?? ''),
                          trailing: IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () {
                              if (download['url'] != null) {
                                _launchURL(
                                    context, download['url']);
                              }
                            },
                          ),
                        ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            );
          },
          childCount: _tools!.length,
        ),
      ),
    );
  }
}