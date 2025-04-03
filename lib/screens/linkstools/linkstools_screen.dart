// lib/screens/linkstools/linkstools_screen.dart
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart'; // <--- 引入懒加载库
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/main/linktool/link_tool_service.dart';
import '../../models/linkstools/link.dart';
import '../../models/linkstools/tool.dart';
import '../../widgets/common/toaster/toaster.dart'; // 假设 Toaster 存在
import '../../providers/auth/auth_provider.dart';
import '../../widgets/components/form/linkform/link_form_dialog.dart'; // 假设 LinkFormDialog 存在
import '../../widgets/components/form/toolform/tool_form_dialog.dart'; // 假设 ToolFormDialog 存在
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/linkstools/links_section.dart'; // 假设 LinksSection 存在
import '../../widgets/components/screen/linkstools/tools_section.dart'; // 假设 ToolsSection 存在
import '../../widgets/ui/common/loading_widget.dart'; // <--- 引入 LoadingWidget
import '../../widgets/ui/common/error_widget.dart'; // <--- 引入 ErrorWidget

class LinksToolsScreen extends StatefulWidget {
  // 接收 Key 用于 VisibilityDetector
  const LinksToolsScreen({Key? key}) : super(key: key);

  @override
  _LinksToolsScreenState createState() => _LinksToolsScreenState();
}

class _LinksToolsScreenState extends State<LinksToolsScreen> {
  final LinkToolService _linkToolService = LinkToolService();

  // --- 数据状态 ---
  List<Link>? _links;
  List<Tool>? _tools;
  String? _errorMessage;

  // --- 懒加载核心状态 ---
  bool _isInitialized = false; // 是否已完成首次加载
  bool _isVisible = false;     // 当前 Widget 是否可见
  bool _isLoadingData = false; // 是否正在进行加载操作 (首次或刷新)
  // --- 结束懒加载状态 ---

  // 布局断点
  final double _desktopBreakpoint = 900.0;

  @override
  void initState() {
    super.initState();
    // --- 不在 initState 中加载数据 ---
    print("LinksToolsScreen initState: Initialized, waiting for visibility.");
  }

  @override
  void dispose() {
    // 如果有 Timer 或 Controller 需要在这里 dispose
    print("LinksToolsScreen dispose: Cleaned up.");
    super.dispose();
  }

  // --- 核心：触发首次数据加载 ---
  void _triggerInitialLoad() {
    // 仅在 Widget 变得可见且尚未初始化时执行
    if (_isVisible && !_isInitialized) {
      print("LinksToolsScreen: Now visible and not initialized. Triggering initial load.");
      _isInitialized = true; // 标记为已初始化
      _loadData(); // 调用实际加载方法
    }
  }

  // --- 加载链接和工具数据 ---
  Future<void> _loadData() async {
    // 防止重复加载
    if (_isLoadingData) {
      print("LinksToolsScreen: Load skipped, already loading.");
      return;
    }
    if (!mounted) return; // 检查 Widget 是否还在树中

    print("LinksToolsScreen: Loading links and tools...");
    setState(() {
      _isLoadingData = true; // 开始加载
      _errorMessage = null; // 清除旧错误
    });

    try {
      // 使用 Future.wait 并行获取链接和工具
      final results = await Future.wait([
        // 假设 getLinks/getTools 返回 Future 或 Stream.first
        _linkToolService.getLinks().first,
        _linkToolService.getTools().first,
      ]);

      if (!mounted) return; // 异步操作后再次检查

      // 更新状态
      setState(() {
        // 安全地转换类型，并处理 null 情况
        _links = List<Link>.from(results[0] as List? ?? []);
        _tools = List<Tool>.from(results[1] as List? ?? []);
        _isLoadingData = false; // 加载完成
        print("LinksToolsScreen: Load successful. Links: ${_links?.length}, Tools: ${_tools?.length}");
      });
    } catch (e, s) { // 捕获错误和堆栈
      print('LinksToolsScreen: Load data error: $e\nStackTrace: $s');
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载失败：${e.toString()}'; // 设置错误信息
        _links = []; // 出错时设置为空列表
        _tools = [];
        _isLoadingData = false; // 加载失败
      });
    }
  }

  // --- 打开 URL ---
  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      // 检查是否可以启动 URL
      if (await canLaunchUrl(uri)) {
        // 使用 launchUrl (推荐) 而不是 launch
        await launchUrl(uri, mode: LaunchMode.externalApplication); // 在外部应用中打开
      } else {
        // 如果无法启动，抛出错误
        throw '无法打开链接 $url';
      }
    } catch (e) {
      // 显示错误提示
      print("Error launching URL $url: $e");
      if (mounted) { // 检查 mounted 状态
        Toaster.show(context, message: '打开链接失败: $e', isError: true);
      }
    }
  }

  // --- 显示添加链接对话框 ---
  void _showAddLinkDialog(BuildContext context) {
    showDialog<Map<String, dynamic>>( // 指定对话框返回类型
      context: context,
      builder: (context) => LinkFormDialog(), // 显示你的链接表单对话框
    ).then((linkData) async { // 处理对话框关闭后的结果
      if (linkData != null) { // 如果用户保存了数据
        try {
          // 将 Map 转换为 Link 对象
          final newLink = Link.fromJson(linkData);
          // 调用 Service 添加链接
          await _linkToolService.addLink(newLink);
          if(mounted) Toaster.show(context, message: '添加链接成功');
          // 刷新数据以显示新链接
          await _loadData();
        } catch (e) {
          print("Error adding link: $e");
          if(mounted) Toaster.show(context, message: '添加链接失败: $e', isError: true);
        }
      }
    });
  }

  // --- 显示添加工具对话框 ---
  void _showAddToolDialog(BuildContext context) {
    showDialog<Map<String, dynamic>>( // 指定返回类型
      context: context,
      barrierDismissible: false, // 禁止点击外部关闭
      builder: (context) => ToolFormDialog(), // 显示你的工具表单对话框
    ).then((toolData) async { // 处理结果
      if (toolData != null) { // 如果用户保存了数据
        try {
          // 将 Map 转换为 Tool 对象
          final newTool = Tool.fromJson(toolData);
          // 调用 Service 添加工具
          await _linkToolService.addTool(newTool);
          if(mounted) Toaster.show(context, message: '添加工具成功');
          // 刷新数据以显示新工具
          await _loadData();
        } catch (e) {
          print('Error adding tool: $e');
          if(mounted) Toaster.show(context, message: '添加工具失败: $e', isError: true);
        }
      }
    });
  }

  // --- 主构建方法 ---
  @override
  Widget build(BuildContext context) {
    // 获取管理员状态和屏幕尺寸信息
    final isAdmin = context.select<AuthProvider, bool>((auth) => auth.isAdmin);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    // 使用 VisibilityDetector 实现懒加载
    return VisibilityDetector(
      key: Key('linkstools_screen_visibility'), // 唯一的 Key
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        if (currentlyVisible != _isVisible) {
          // 使用 microtask 确保 setState 在 build 之后执行
          Future.microtask(() {
            if (mounted) {
              setState(() { _isVisible = currentlyVisible; });
            } else { _isVisible = currentlyVisible; } // 更新变量

            // 如果变得可见，尝试触发初始加载
            if (_isVisible) { _triggerInitialLoad(); }
          });
        }
      },
      // 构建实际的 UI 内容
      child: Scaffold(
        // AppBar 仅在移动端显示
        appBar: isDesktop
            ? null // 桌面端不显示 AppBar
            : CustomAppBar( // 移动端 AppBar
          title: '实用工具',
          actions: [
            // 仅管理员可见的添加按钮
            if (isAdmin) ..._buildAdminActions(context),
          ],
        ),
        // Body 部分包含下拉刷新和条件渲染的内容
        body: RefreshIndicator(
          onRefresh: _loadData, // 下拉刷新直接调用加载数据方法
          child: _buildLinksToolsContent(isAdmin, isDesktop), // 构建主体内容
        ),
      ),
    );
  }

  // --- 构建 Body 内容的逻辑 ---
  Widget _buildLinksToolsContent(bool isAdmin, bool isDesktop) {
    // State 1: Not yet initialized (Waiting for visibility or initial load failed silently)
    if (!_isInitialized && !_isLoadingData) {
      return Center(child: LoadingWidget(message: "等待加载..."));
    }
    // State 2: Loading initial data or refreshing
    else if (_isLoadingData) {
      return Center(child: LoadingWidget(message: "正在加载工具和链接..."));
    }
    // State 3: Error occurred
    else if (_errorMessage != null) {
      return Center(
        child: CustomErrorWidget( // 或者 InlineErrorWidget
          // title: '加载失败', // 可选标题
          errorMessage: _errorMessage!,
          onRetry: _loadData, // 重试按钮调用加载数据
        ),
      );
    }
    // State 4: Data loaded successfully (list might be populated or empty)
    else {
      // 根据设备类型选择布局
      if (isDesktop) {
        return _buildDesktopLayout(isAdmin);
      } else {
        return _buildMobileLayout(isAdmin);
      }
    }
  }

  // --- 提取 AppBar 的 Admin Actions ---
  List<Widget> _buildAdminActions(BuildContext context) {
    // 返回包含添加链接和添加工具按钮的列表
    return [
      IconButton(
        icon: Icon(Icons.add_link),
        onPressed: () => _showAddLinkDialog(context),
        tooltip: '添加链接',
      ),
      IconButton(
        icon: Icon(Icons.add_box_outlined), // 使用 outline 图标示例
        onPressed: () => _showAddToolDialog(context),
        tooltip: '添加工具',
      ),
    ];
  }


  // --- 构建桌面端布局 ---
  Widget _buildDesktopLayout(bool isAdmin) {
    // 使用 Row 左右分割布局
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
      children: [
        // --- 左侧：常用链接 ---
        Expanded( // 左侧占据一半空间
          child: CustomScrollView( // 使用 CustomScrollView 以便未来可能添加 SliverAppBar 等
            slivers: [
              // 区域标题和添加按钮 (桌面版按钮放在标题旁边)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 16), // 内边距
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // 标题居左，按钮居右
                    children: [
                      Text(
                        '常用链接',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // 仅管理员可见的添加链接按钮
                      if (isAdmin)
                        IconButton(
                          icon: Icon(Icons.add_link),
                          onPressed: () => _showAddLinkDialog(context),
                          tooltip: '添加链接',
                          color: Theme.of(context).colorScheme.primary, // 按钮颜色
                        ),
                    ],
                  ),
                ),
              ),
              // 链接内容区域
              _buildLinksContent(isAdmin),
            ],
          ),
        ),

        // --- 中间分割线 ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0), // 上下留白
          child: VerticalDivider( // 垂直分割线
            width: 32, // 分割线宽度（包括左右间距）
            thickness: 1, // 线条粗细
            color: Theme.of(context).dividerColor.withOpacity(0.15), // 颜色和透明度
            indent: 8, // 顶端缩进
            endIndent: 8, // 底端缩进
          ),
        ),

        // --- 右侧：实用工具 ---
        Expanded( // 右侧占据另一半空间
          child: CustomScrollView(
            slivers: [
              // 区域标题和添加按钮
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
                      // 仅管理员可见的添加工具按钮
                      if (isAdmin)
                        IconButton(
                          icon: Icon(Icons.add_box_outlined),
                          onPressed: () => _showAddToolDialog(context),
                          tooltip: '添加工具',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
              // 工具内容区域
              _buildToolsContent(isAdmin),
            ],
          ),
        ),
      ],
    );
  }

  // --- 构建移动端布局 ---
  Widget _buildMobileLayout(bool isAdmin) {
    // 使用 CustomScrollView 将两个部分垂直排列
    return CustomScrollView(
      slivers: [
        // --- 常用链接标题 ---
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16), // 内边距
            child: Text(
              '常用链接',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // --- 链接内容 ---
        _buildLinksContent(isAdmin),

        // --- 实用工具标题 ---
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16), // 内边距
            child: Text(
              '实用工具',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // --- 工具内容 ---
        _buildToolsContent(isAdmin),
      ],
    );
  }

  // --- 构建链接区域内容 ---
  Widget _buildLinksContent(bool isAdmin) {
    // 检查链接数据是否有效且非空
    if (_links == null || _links!.isEmpty) {
      // 如果没有链接，显示提示信息
      return SliverToBoxAdapter( // 必须返回 Sliver 类型
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0), // 内边距
          child: Center( // 居中显示
            child: InlineErrorWidget( // 使用你的错误/空状态提示 Widget
              errorMessage: '暂无常用链接',
              icon: Icons.link_off, // 相关图标
              retryText: '刷新试试',
              onRetry: _loadData, // 刷新按钮调用加载数据
            ),
          ),
        ),
      );
    }

    // 如果有链接数据，使用 LinksSection 组件显示
    // (假设 LinksSection 接收 List<Link> 并且返回 Sliver 类型)
    return LinksSection(
      links: _links!, // 传递链接列表 (确保非空)
      isAdmin: isAdmin, // 传递管理员状态
      onRefresh: _loadData, // 传递刷新回调
      onLaunchURL: (url) => _launchURL(context, url), // 传递启动 URL 回调
      linkToolService: _linkToolService, // 传递 Service 用于删除/编辑操作
    );
  }

  // --- 构建工具区域内容 ---
  Widget _buildToolsContent(bool isAdmin) {
    // 检查工具数据是否有效且非空
    if (_tools == null || _tools!.isEmpty) {
      // 如果没有工具，显示提示信息
      return SliverToBoxAdapter( // 必须返回 Sliver 类型
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Center(
            child: InlineErrorWidget(
              errorMessage: '暂无实用工具',
              icon: Icons.build_circle_outlined, // 相关图标
              retryText: '刷新试试',
              onRetry: _loadData,
            ),
          ),
        ),
      );
    }

    // 如果有工具数据，使用 ToolsSection 组件显示
    // (假设 ToolsSection 接收 List<Tool> 并且返回 Sliver 类型)
    return ToolsSection(
      tools: _tools!, // 传递工具列表 (确保非空)
      isAdmin: isAdmin, // 传递管理员状态
      onLaunchURL: (url) => _launchURL(context, url), // 传递启动 URL 回调
      // 可能还需要传递 Service 用于删除/编辑
      // toolService: _linkToolService, // (如果需要的话)
    );
  }
}