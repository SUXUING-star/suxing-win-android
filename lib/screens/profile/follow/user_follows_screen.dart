// lib/screens/profile/follow/user_follows_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'dart:async';
import '../../../services/main/user/user_follow_service.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/components/screen/profile/follow/responsive_follows_layout.dart';

class UserFollowsScreen extends StatefulWidget {
  final String userId;
  final String username;
  final bool initialShowFollowing; // true 显示关注列表，false 显示粉丝列表

  const UserFollowsScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialShowFollowing = true,
  });

  @override
  _UserFollowsScreenState createState() => _UserFollowsScreenState();
}

class _UserFollowsScreenState extends State<UserFollowsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _followings = [];
  List<Map<String, dynamic>> _followers = [];

  // 跟踪加载状态
  bool _followingsLoaded = false;
  bool _followersLoaded = false;
  bool _isLoadingFollowings = false;
  bool _isLoadingFollowers = false;
  String? _errorMessage;

  // 控制刷新频率
  DateTime? _lastFollowingsRefresh;
  DateTime? _lastFollowersRefresh;
  static const Duration _minRefreshInterval = Duration(minutes: 5);

  StreamSubscription? _followStatusSubscription;
  bool _mounted = true; // 防止setState调用在组件销毁后

  bool _hasInitializedDependencies = false;
  late final UserFollowService _followService;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialShowFollowing ? 0 : 1,
    );

    // 监听标签切换
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitializedDependencies) {
      _followService = context.read<UserFollowService>();
      _authProvider = Provider.of<AuthProvider>(context);
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      // 监听关注状态变化
      _followStatusSubscription =
          _followService.followStatusStream.listen((userId) {
        if (_mounted) {
          // 关注状态变化时重新加载数据
          _refreshCurrentTab(forceRefresh: true);
        }
      });
      // 只加载当前选中标签页的数据
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _followStatusSubscription?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // 标签切换监听器
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    final currentTab = _tabController.index;
    if (currentTab == 0 && !_followingsLoaded && !_isLoadingFollowings) {
      _loadFollowings();
    } else if (currentTab == 1 && !_followersLoaded && !_isLoadingFollowers) {
      _loadFollowers();
    }
  }

  // 初始化加载当前选中标签的数据
  Future<void> _loadInitialData() async {
    // 在桌面模式下，同时加载关注和粉丝列表
    if (DeviceUtils.isDesktop ||
        (DeviceUtils.isTablet(context) && DeviceUtils.isLandscape(context))) {
      await Future.wait([
        _loadFollowings(),
        _loadFollowers(),
      ]);
    } else {
      // 移动端模式下，只加载当前选中标签页的数据
      final currentTab = _tabController.index;
      if (currentTab == 0) {
        await _loadFollowings();
      } else {
        await _loadFollowers();
      }
    }
  }

  // 加载关注列表
  Future<void> _loadFollowings() async {
    if (_isLoadingFollowings || !_mounted) return;

    setState(() {
      _isLoadingFollowings = true;
      _errorMessage = null;
    });

    try {
      // 使用普通加载方法，优先使用缓存
      final data = await _followService.getFollowing(widget.userId);

      if (_mounted) {
        setState(() {
          _followings = data;
          _followingsLoaded = true;
          _isLoadingFollowings = false;
        });
      }
    } catch (e) {
      print('加载关注列表失败: $e');
      if (_mounted) {
        setState(() {
          _isLoadingFollowings = false;
          _errorMessage = '加载失败，请重试';
        });
      }
    }
  }

  // 加载粉丝列表
  Future<void> _loadFollowers() async {
    if (_isLoadingFollowers || !_mounted) return;

    setState(() {
      _isLoadingFollowers = true;
      _errorMessage = null;
    });

    try {
      // 使用普通加载方法，优先使用缓存
      final data = await _followService.getFollowers(widget.userId);

      if (_mounted) {
        setState(() {
          _followers = data;
          _followersLoaded = true;
          _isLoadingFollowers = false;
        });
      }
    } catch (e) {
      print('加载粉丝列表失败: $e');
      if (_mounted) {
        setState(() {
          _isLoadingFollowers = false;
          _errorMessage = '加载失败，请重试';
        });
      }
    }
  }

  // 刷新当前标签页
  Future<void> _refreshCurrentTab({bool forceRefresh = false}) async {
    final currentTab = _tabController.index;

    // 桌面模式下，刷新两个列表
    if (DeviceUtils.isDesktop ||
        (DeviceUtils.isTablet(context) && DeviceUtils.isLandscape(context))) {
      await Future.wait([
        _refreshFollowings(forceRefresh: forceRefresh),
        _refreshFollowers(forceRefresh: forceRefresh),
      ]);
    } else {
      // 移动端模式下，只刷新当前标签页
      if (currentTab == 0) {
        await _refreshFollowings(forceRefresh: forceRefresh);
      } else {
        await _refreshFollowers(forceRefresh: forceRefresh);
      }
    }
  }

  // 强制刷新关注列表 (API请求)
  Future<void> _refreshFollowings({bool forceRefresh = false}) async {
    // 检查是否需要刷新
    final now = DateTime.now();
    if (!forceRefresh && _lastFollowingsRefresh != null) {
      final timeSinceLastRefresh = now.difference(_lastFollowingsRefresh!);
      if (timeSinceLastRefresh < _minRefreshInterval) {
        print('关注列表刷新太频繁，跳过');
        return;
      }
    }

    if (_isLoadingFollowings || !_mounted) return;

    setState(() {
      _isLoadingFollowings = true;
      _errorMessage = null;
    });

    try {
      final data = await _followService.refreshFollowing(widget.userId);
      _lastFollowingsRefresh = now;

      if (_mounted) {
        setState(() {
          _followings = data;
          _followingsLoaded = true;
          _isLoadingFollowings = false;
        });
      }
    } catch (e) {
      print('刷新关注列表失败: $e');
      if (_mounted) {
        setState(() {
          _isLoadingFollowings = false;
          _errorMessage = '刷新失败，请重试';
        });
      }
    }
  }

  // 强制刷新粉丝列表 (API请求)
  Future<void> _refreshFollowers({bool forceRefresh = false}) async {
    // 检查是否需要刷新
    final now = DateTime.now();
    if (!forceRefresh && _lastFollowersRefresh != null) {
      final timeSinceLastRefresh = now.difference(_lastFollowersRefresh!);
      if (timeSinceLastRefresh < _minRefreshInterval) {
        return;
      }
    }

    if (_isLoadingFollowers || !_mounted) return;

    setState(() {
      _isLoadingFollowers = true;
      _errorMessage = null;
    });

    try {
      // 使用强制刷新方法，从API获取最新数据
      final followService = context.read<UserFollowService>();
      final data = await followService.refreshFollowers(widget.userId);
      _lastFollowersRefresh = now;

      if (_mounted) {
        setState(() {
          _followers = data;
          _followersLoaded = true;
          _isLoadingFollowers = false;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _isLoadingFollowers = false;
          _errorMessage = '刷新失败，请重试';
        });
      }
    }
  }

  // 处理下拉刷新
  Future<void> _handlePullToRefresh() async {
    await _refreshCurrentTab(forceRefresh: true);
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    // 判断是否桌面布局
    final isDesktop = DeviceUtils.isDesktop;
    final isTablet = DeviceUtils.isTablet(context);
    final isLandscape = DeviceUtils.isLandscape(context);
    final isDesktopLayout = isDesktop || (isTablet && isLandscape);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.username,
        // 在桌面布局中不显示底部标签栏
        bottom: isDesktopLayout
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: '关注 ${_followings.length}'),
                  Tab(text: '粉丝 ${_followers.length}'),
                ],
              ),
      ),
      body: ResponsiveFollowsLayout(
        currentUser: _authProvider.currentUser,
        tabController: _tabController,
        followings: _followings,
        followers: _followers,
        isLoadingFollowings: _isLoadingFollowings,
        isLoadingFollowers: _isLoadingFollowers,
        followingsLoaded: _followingsLoaded,
        followersLoaded: _followersLoaded,
        errorMessage: _errorMessage,
        currentUserId: widget.userId,
        onRefresh: _handlePullToRefresh,
        refreshFollowings: _refreshFollowings,
        refreshFollowers: _refreshFollowers,
      ),
    );
  }
}
