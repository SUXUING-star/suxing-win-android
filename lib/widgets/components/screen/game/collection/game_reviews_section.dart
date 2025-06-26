// lib/widgets/components/screen/game/collection/game_reviews_section.dart

/// 该文件定义了 GameReviewSection 组件，用于显示游戏的评价和动态。
/// GameReviewSection 负责加载、展示玩家动态，并提供分页加载功能。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/common/pagination.dart'; // 分页数据模型
import 'package:suxingchahui/models/game/game.dart'; // 游戏模型
import 'package:suxingchahui/models/game/game_collection_review.dart'; // 游戏评价项模型
import 'package:suxingchahui/models/game/game_collection_review_pagination.dart'; // 游戏评价分页模型
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息服务
import 'package:suxingchahui/services/main/game/game_collection_service.dart'; // 游戏收藏服务
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 功能按钮组件
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 空状态组件
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件
import 'package:suxingchahui/widgets/ui/components/game/review/game_review_item.dart'; // 游戏评价项组件
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // 提示条组件

/// `GameReviewSection` 类：显示游戏玩家动态的 StatefulWidget。
///
/// 该组件负责加载、展示游戏评价列表，并管理分页和加载状态。
class GameReviewSection extends StatefulWidget {
  final Game game; // 游戏数据
  final User? currentUser; // 当前登录用户
  final GameCollectionService gameCollectionService; // 游戏收藏服务
  final UserFollowService followService; // 用户关注服务
  final UserInfoService infoService; // 用户信息服务

  /// 构造函数。
  const GameReviewSection({
    super.key,
    required this.game,
    required this.currentUser,
    required this.followService,
    required this.gameCollectionService,
    required this.infoService,
  });

  @override
  GameReviewSectionState createState() => GameReviewSectionState();
}

class GameReviewSectionState extends State<GameReviewSection> {
  List<GameCollectionReviewEntry> _reviews = []; // 存储游戏评价列表
  PaginationData? _paginationData; // 存储分页数据
  bool _isLoading = true; // 加载状态
  String? _error; // 错误信息
  int _page = 1; // 当前页码
  static const int _pageSize =
      GameCollectionService.gameCollectionReviewsLimit; // 每页数量
  bool _isProcessingPageOne = false; // 标识是否正在处理第一页加载
  bool _hasInitializedDependencies = false; // 依赖是否已初始化标记
  User? _currentUser; // 当前用户

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _currentUser = widget.currentUser;
      if (_reviews.isEmpty && mounted) {
        _loadReviews(isInitialLoad: true); // 加载评论
      }
    }
  }

  @override
  void dispose() {
    _reviews = []; // 清空评论列表
    _paginationData = null; // 清空分页数据
    super.dispose();
  }

  @override
  void didUpdateWidget(GameReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool gameIdChanged = oldWidget.game.id != widget.game.id; // 检查游戏ID是否改变

    if (gameIdChanged) {
      refresh(); // 游戏ID改变时刷新
    }

    if (_currentUser != widget.currentUser ||
        widget.currentUser != oldWidget.currentUser) {
      if (mounted) {
        setState(() {
          _currentUser = widget.currentUser; // 更新当前用户
        });
      }
    }
  }

  /// 刷新评论列表。
  ///
  /// 如果正在处理第一页加载或组件未挂载，则阻止刷新。
  void refresh() {
    if (_isProcessingPageOne || !mounted) return; // 阻止刷新
    if (mounted) {
      setState(() {
        _page = 1; // 重置页码
        _reviews = []; // 清空评论列表
        _paginationData = null; // 清空分页数据
        _isLoading = true; // 设置加载状态
        _error = null; // 清空错误信息
      });
    }
    _loadReviews(isInitialLoad: true); // 加载第一页评论
  }

  /// 加载游戏评论。
  ///
  /// [isInitialLoad]：是否为首次加载。
  /// 根据加载类型和状态管理加载过程。
  Future<void> _loadReviews({bool isInitialLoad = false}) async {
    final bool forPageOne = isInitialLoad || _page == 1; // 判断是否为第一页加载

    if (forPageOne) {
      if (_isProcessingPageOne) return; // 正在处理第一页加载则阻止
      _isProcessingPageOne = true; // 设置为正在处理第一页加载
      if (!_isLoading && mounted) {
        setState(() => _isLoading = true); // 设置加载状态
      } else if (!mounted) {
        _isProcessingPageOne = false; // 未挂载时重置状态
        return;
      }
    } else {
      if (_isLoading || !(_paginationData?.hasNextPage() ?? false)) {
        return; // 正在加载或无下一页时阻止
      }
      if (mounted) {
        setState(() => _isLoading = true); // 设置加载状态
      } else {
        return;
      }
    }

    if (!mounted) {
      // 再次检查挂载状态
      if (forPageOne && _isProcessingPageOne) {
        _isProcessingPageOne = false; // 重置第一页加载状态
      }
      return;
    }

    try {
      final GameCollectionReviewPagination reviewListResult = await widget
          .gameCollectionService
          .getGameCollectionReviews(widget.game.id,
              page: _page, limit: _pageSize); // 获取游戏评论列表

      if (!mounted) return; // 检查挂载状态

      setState(() {
        if (_page == 1) {
          _reviews = reviewListResult.reviews; // 第一页时直接赋值
        } else {
          _reviews.addAll(reviewListResult.reviews); // 追加评论
        }
        _paginationData = reviewListResult.pagination; // 更新分页数据
        _error = null; // 清空错误信息
      });
    } catch (e) {
      if (!mounted) return; // 检查挂载状态
      setState(() {
        if (_page == 1) {
          _error = '加载动态失败: ${e.toString().split(':').last.trim()}'; // 设置错误信息
          _reviews = []; // 清空评论列表
          _paginationData = PaginationData(
              page: _page, limit: _pageSize, total: 0, pages: 0); // 重置分页数据
        } else {
          AppSnackBar.showError("操作失败,${e.toString()}"); // 显示错误提示
        }
      });
    } finally {
      final bool stillMounted = mounted; // 记录挂载状态
      bool shouldReleaseLock = forPageOne && _isProcessingPageOne; // 判断是否需要释放锁
      if (stillMounted) {
        setState(() {
          if (shouldReleaseLock) _isProcessingPageOne = false; // 释放锁
          _isLoading = false; // 清除加载状态
        });
      } else {
        if (shouldReleaseLock) _isProcessingPageOne = false; // 释放锁
      }
    }
  }

  /// 加载更多评论。
  ///
  /// 如果当前未加载且有下一页，则增加页码并加载。
  void _loadMoreReviews() {
    if (!_isLoading && (_paginationData?.hasNextPage() ?? false)) {
      // 检查加载状态和是否有下一页
      if (mounted) {
        setState(() => _page++); // 增加页码
      }
      _loadReviews(); // 加载评论
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(), // 构建头部
            const SizedBox(height: 12),
            _buildAverageRatingDisplay(), // 构建平均评分显示
            const SizedBox(height: 16),
            Divider(color: Colors.grey[200], height: 1), // 分割线
            const SizedBox(height: 8),
            _buildContent(), // 构建内容区
            _buildLoadMoreSection(), // 构建加载更多区域
          ],
        ),
      ),
    );
  }

  /// 构建评论区头部。
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '玩家动态',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[850],
          ),
        ),
      ],
    );
  }

  /// 构建平均评分显示区域。
  Widget _buildAverageRatingDisplay() {
    final game = widget.game;
    final bool hasGameRating = game.ratingCount > 0; // 判断游戏是否有评分
    final int totalReviewCount = _paginationData?.total ?? 0; // 获取总评论数
    final bool hasReviewsToShow = totalReviewCount > 0 ||
        (_reviews.isNotEmpty && _paginationData == null); // 判断是否有评论显示

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.star_rate_rounded,
                color: Colors.amber, size: 22), // 星星图标
            const SizedBox(width: 6),
            if (hasGameRating) // 有评分时显示评分
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: game.rating.toStringAsFixed(1), // 格式化评分
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: ' / 10', // 满分标识
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else // 无评分时显示暂无评分
              Text(
                '暂无评分',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasGameRating) // 有评分时显示评分人数
              Text(
                '共有 ${game.ratingCount} 份评分',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (hasReviewsToShow &&
                !(_isLoading && _page == 1 && _reviews.isEmpty)) // 有评论显示时显示评论数量
              Padding(
                padding: EdgeInsets.only(top: hasGameRating ? 4.0 : 0),
                child: Text(
                  '${_paginationData != null ? _paginationData!.total : _reviews.length} 条动态', // 显示评论总数
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 构建评论内容区域。
  Widget _buildContent() {
    if (_isLoading && _page == 1 && _reviews.isEmpty) {
      // 首次加载且无评论时显示加载中
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: LoadingWidget(size: 18, message: "正在加载"),
      );
    }
    if (_error != null && _page == 1) {
      // 首次加载有错误时显示错误信息
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: InlineErrorWidget(
            errorMessage: _error!, onRetry: refresh), // 内联错误组件
      );
    }
    if (_reviews.isEmpty && !_isLoading) {
      // 无评论且加载完成时显示空状态
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: EmptyStateWidget(message: '暂无评价'), // 空状态组件
      );
    }
    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _reviews.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey[200], height: 1), // 分隔线
        itemBuilder: (context, index) {
          return GameReviewItemWidget(
            // 评论项组件
            review: _reviews[index],
            currentUser: widget.currentUser,
            followService: widget.followService,
            infoService: widget.infoService,
          );
        });
  }

  /// 构建加载更多区域。
  Widget _buildLoadMoreSection() {
    if (_isLoading && !_isProcessingPageOne && _page > 1) {
      // 正在加载更多评论时显示加载中
      return const Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: LoadingWidget(size: 20, message: "加载中"),
      );
    }
    if (!_isLoading &&
        (_paginationData?.hasNextPage() ?? false) &&
        _reviews.isNotEmpty) {
      // 有更多评论可加载时显示加载更多按钮
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: FunctionalButton(
            onPressed: _loadMoreReviews, // 点击加载更多
            label: '加载更多动态',
          ),
        ),
      );
    }
    return const SizedBox.shrink(); // 不显示时返回空盒子
  }
}
