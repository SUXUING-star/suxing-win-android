// 文件路径: lib/widgets/components/screen/game/collection/game_reviews_section.dart

import 'dart:async'; // 引入 FutureOr

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/game/game.dart';
// 确保导入了 GameReview 模型
import 'package:suxingchahui/models/game/game_review.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/main/game/collection/game_collection_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
// UserInfoBadge 用于显示用户信息
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
// UI 组件
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 注意：这里用了你自己的 InlineErrorWidget
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';

class GameReviewSection extends StatefulWidget {
  final Game game;

  const GameReviewSection({super.key, required this.game});

  @override
  GameReviewSectionState createState() => GameReviewSectionState();
}

class GameReviewSectionState extends State<GameReviewSection> {
  // 服务实例
  final GameCollectionService _collectionService = GameCollectionService();

  // 状态变量
  List<GameReview> _reviews = []; // *** 使用 GameReview 模型 ***
  bool _isLoading = true; // 整体加载状态 (初始/刷新/更多)
  String? _error; // 错误信息 (主要用于第一页加载)
  int _page = 1; // 当前页码
  final int _pageSize = 10; // 每页数量
  bool _hasMoreReviews = true; // 是否还有更多评论可加载

  // 并发控制
  bool _isProcessingPageOne = false; // 锁：防止第一页操作 (初始/刷新) 并发
  int _loadReviewsCallCount = 0; // 调试计数器 (可选)

  @override
  void initState() {
    super.initState();
    // print(">>> GRS (${widget.game.id}): initState CALLED.");
    // 组件初始化时加载第一页数据
    _loadReviews(isInitialLoad: true);
  }

  @override
  void dispose() {
    // print(">>> GRS (${widget.game.id}): dispose CALLED.");
    // 清理资源 (如果需要，例如取消订阅)
    super.dispose();
  }

  @override
  void didUpdateWidget(GameReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 检查传入的 game 对象是否发生变化
    bool gameIdChanged = oldWidget.game.id != widget.game.id;
    // 检查评分相关数据是否变化 (用于仅更新UI)
    bool ratingDataChanged = widget.game.rating != oldWidget.game.rating ||
        widget.game.ratingCount != oldWidget.game.ratingCount;

    // print(">>> GRS (${widget.game.id}): didUpdateWidget. GameId changed: $gameIdChanged, Rating changed: $ratingDataChanged");

    if (gameIdChanged) {
      // 如果游戏 ID 变了，说明是展示另一个游戏的评论了，需要刷新数据
      // print(">>> GRS (${widget.game.id}): Game ID changed. Calling refresh().");
      refresh(); // 调用刷新方法，它会重置状态并加载第一页
    } else if (ratingDataChanged && mounted) {
      // 如果只是评分数据变了 (例如用户刚提交了评分)，只需要更新UI显示新的评分
      // print(">>> GRS (${widget.game.id}): Rating data changed. Calling internal setState() for UI rebuild ONLY.");
      setState(() {}); // 触发 UI 重建以显示最新的 widget.game 数据
    }
  }

  /// 公开的刷新方法 (供外部调用，如父组件或下拉刷新)
  void refresh() {
    final callId = DateTime.now().millisecondsSinceEpoch; // 调试 ID
    // print(">>> GRS (${widget.game.id}): refresh() CALLED [$callId]. Current lock status: $_isProcessingPageOne");

    // 1. 检查是否已经在处理第一页，如果是，则忽略本次刷新请求，防止重复刷新
    if (_isProcessingPageOne) {
      // print(">>> GRS (${widget.game.id}): refresh() ABORTED [$callId] - Already processing page 1.");
      return;
    }

    // 2. 检查组件是否还挂载，防止在已卸载的 Widget 上操作
    if (!mounted) {
      // print(">>> GRS (${widget.game.id}): refresh() ABORTED [$callId] - Widget not mounted.");
      return;
    }

    // 3. 重置状态，准备刷新
    // print(">>> GRS (${widget.game.id}): refresh() PROCEEDING [$callId]. Resetting state.");
    setState(() {
      _page = 1; // 重置到第一页
      _reviews = []; // 清空现有评论
      _isLoading = true; // *** 进入加载状态 ***
      _error = null; // 清除旧错误
      _hasMoreReviews = true; // 假设有更多数据，加载后会更新
      // 注意：不在此处设置 _isProcessingPageOne，交由 _loadReviews 统一处理
    });

    // 4. 调用加载逻辑，标记为初始加载 (因为它加载的是第一页)
    _loadReviews(isInitialLoad: true, debugCallId: callId);
  }

  /// 内部加载数据的方法 (核心逻辑)
  /// [isInitialLoad] 标记是否由 initState 或 refresh 触发 (即加载第一页)
  /// [debugCallId] 仅用于调试追踪
  Future<void> _loadReviews(
      {bool isInitialLoad = false, int? debugCallId}) async {
    _loadReviewsCallCount++;
    final currentCallCount = _loadReviewsCallCount; // 调试用
    // 判断这次调用是否是针对第一页的操作z
    final bool forPageOne = isInitialLoad || _page == 1;

    // --- 防并发和重复加载 ---
    // 1. 如果是针对第一页的操作 (Initial Load 或 Refresh)
    if (forPageOne) {
      if (_isProcessingPageOne) {
        // 如果第一页锁已被占用 (例如快速连续点击刷新)，则阻止本次执行
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] ABORTED - Already processing page 1 (lock held).");
        return;
      } else {
        // 如果没有锁，则获取锁，标记正在处理第一页
        _isProcessingPageOne = true;
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] ACQUIRED page 1 lock.");
        // 确保 UI 处于加载状态。refresh() 可能已经设置了 isLoading=true，这里再确认一下。
        if (!_isLoading && mounted) {
          setState(() {
            _isLoading = true;
          });
        } else if (!mounted) {
          // 如果在获取锁后、调用 API 前就 unmounted 了，释放锁并退出
          // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] ABORTED - Widget unmounted after acquiring lock.");
          _isProcessingPageOne = false;
          return;
        }
      }
    }
    // 2. 如果是加载更多页 (不是第一页)
    else {
      // 加载更多必须同时满足：a) 当前不在加载中 b) 还有更多数据
      if (_isLoading) {
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] (Load More) ABORTED - Already loading.");
        return; // 防止重复触发加载更多
      }
      if (!_hasMoreReviews) {
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] (Load More) ABORTED - No more reviews.");
        return; // 没有更多了，不加载
      }
      // 加载更多时，不需要关心 _isProcessingPageOne 锁
      // 设置整体加载状态
      if (mounted) {
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] (Load More) - Setting isLoading = true.");
        setState(() {
          _isLoading = true;
        });
      } else {
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] (Load More) ABORTED - Widget not mounted before API call.");
        return; // 组件已卸载
      }
    }
    // --- 防并发检查结束 ---

    // 再次检查组件挂载状态，防止在 API 调用前卸载
    if (!mounted) {
      // 如果是第一页的操作，并且在 API 调用前 unmounted，需要释放锁
      if (forPageOne && _isProcessingPageOne) {
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] RELEASING page 1 lock (unmounted before API).");
        _isProcessingPageOne = false;
      }
      return;
    }

    // *** 开始 API 请求 ***
    try {
      // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - Calling API for page $_page...");
      // 调用修改后的 Service 方法，它返回 List<GameReview>
      final List<GameReview> fetchedReviews = await _collectionService
          .getGameReviews(widget.game.id, page: _page, limit: _pageSize);

      // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - API call finished. Fetched ${fetchedReviews.length} reviews.");

      // API 返回后再次检查是否挂载
      if (!mounted) {
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - Widget unmounted after API call. State update skipped.");
        // finally 块会负责处理锁
        return;
      }

      // 处理成功结果
      setState(() {
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - Updating state (page: $_page).");
        if (_page == 1) {
          // 如果是第一页，直接替换列表
          _reviews = fetchedReviews;
        } else {
          // 如果是加载更多，追加到列表末尾
          _reviews.addAll(fetchedReviews);
        }
        // 判断是否还有更多数据
        _hasMoreReviews = fetchedReviews.length >= _pageSize;
        _error = null; // 清除错误状态
        // _isLoading = false; // 加载状态在 finally 中统一处理
      });
    } catch (e, s) {
      // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - API call FAILED: $e\n$s");
      // API 调用失败或处理响应时出错
      if (!mounted) {
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - Widget unmounted after API error. State update skipped.");
        // finally 块会处理锁
        return;
      }
      // 处理错误结果
      setState(() {
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - Updating state with error (page: $_page).");
        // _isLoading = false; // 加载状态在 finally 中统一处理
        if (_page == 1) {
          // 如果是第一页加载失败，显示错误信息
          _error = '加载评价失败: ${e.toString().split(':').last.trim()}'; // 简化错误信息
          _reviews = []; // 清空列表
        } else {
          // 如果是加载更多失败，用 Snackbar 提示用户，不直接显示错误区域
          if (context.mounted) {
            // 再次检查 context 是否可用
            AppSnackBar.showError(context, '加载更多评价失败');
          }
          _hasMoreReviews = false; // 标记没有更多了，避免用户继续尝试
        }
      });
    } finally {
      // *** 无论成功失败，最终执行 ***
      // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - Entering finally block.");
      final bool stillMounted = mounted; // 记录当前挂载状态，因为 await 后状态可能改变
      // 标记：是否需要在 finally 块结束后释放锁 (仅当这次调用是针对第一页且持有锁时)
      bool shouldReleaseLock = false;
      if (forPageOne && _isProcessingPageOne) {
        shouldReleaseLock = true;
      }

      if (stillMounted) {
        // 如果组件还挂载，安全地调用 setState 更新状态
        setState(() {
          // *** 释放页面 1 的锁（仅当这个调用是处理页面1且持有锁时）***
          if (shouldReleaseLock) {
            // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] RELEASING page 1 lock (in finally).");
            _isProcessingPageOne = false;
          }
          // *** 总是重置整体加载状态 ***
          _isLoading = false;
          // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - Setting isLoading = false (in finally).");
        });
      } else {
        // 如果组件已卸载，不能调用 setState，但需要确保锁状态被更新
        if (shouldReleaseLock) {
          // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] RELEASING page 1 lock (in finally, unmounted).");
          _isProcessingPageOne = false; // 直接修改成员变量
        }
        // _isLoading 在卸载后无所谓
        // print(">>> GRS (${widget.game.id}): _loadReviews [$currentCallCount] - Widget unmounted in finally. isLoading state not updated.");
      }
    }
  }

  /// 加载更多评论（由按钮触发）
  void _loadMoreReviews() {
    // print(">>> GRS (${widget.game.id}): _loadMoreReviews CALLED. isLoading: $_isLoading, hasMore: $_hasMoreReviews");
    // 必须同时满足：不在加载中 + 还有更多
    // 注意：加载更多不关心 _isProcessingPageOne 锁
    if (!_isLoading && _hasMoreReviews) {
      // 先增加页码
      setState(() {
        _page++;
      });
      // print(">>> GRS (${widget.game.id}): Incremented page to $_page. Calling _loadReviews for more.");
      _loadReviews(); // 调用加载逻辑
    } else {
      // print(">>> GRS (${widget.game.id}): Load more request ignored (already loading or no more reviews).");
    }
  }

  // --- UI 构建方法 ---
  @override
  Widget build(BuildContext context) {
    // 使用 Card 组件作为容器，增加视觉分割和阴影
    return Card(
      elevation: 1, // 轻微阴影
      margin: const EdgeInsets.only(bottom: 16), // 与下方元素的间距
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // 圆角
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // 内边距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 内容左对齐
          children: [
            // 1. 区域标题
            _buildHeader(),
            const SizedBox(height: 12), // 间距

            // 2. 平均评分显示
            _buildAverageRatingDisplay(),
            const SizedBox(height: 16), // 间距

            // 3. 分割线
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 8), // 间距

            // 4. 评论列表内容区域 (加载中/错误/空/列表)
            _buildContent(),

            // 5. 加载更多按钮或加载指示器
            _buildLoadMoreSection(),
          ],
        ),
      ),
    );
  }

  // 构建区域标题 ("玩家评价")
  Widget _buildHeader() {
    return Row(
      children: [
        // 左侧装饰条
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor, // 使用主题色
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8), // 间距
        // 标题文本
        Text(
          '玩家评价',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[850], // 深灰色
          ),
        ),
      ],
    );
  }

  // 构建平均评分和评分数量显示
  Widget _buildAverageRatingDisplay() {
    final game = widget.game; // 获取当前游戏对象
    final bool hasRating = game.ratingCount > 0; // 是否有评分
    final int currentLoadedReviews = _reviews.length; // 当前已加载的评论数

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 两端对齐
      crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中
      children: [
        // 左侧: 星星图标和平均分
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.star_rate_rounded,
                color: Colors.amber, size: 22), // 黄色星星
            const SizedBox(width: 6),
            // 如果有评分，显示 "X.X / 10"
            if (hasRating)
              Text.rich(
                // 使用 Text.rich 实现不同样式
                TextSpan(
                  children: [
                    TextSpan(
                      text: game.rating.toStringAsFixed(1), // 保留一位小数
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: ' / 10', // 总分
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            // 如果没有评分，显示 "暂无评分"
            else
              Text(
                '暂无评分',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic, // 斜体
                ),
              ),
          ],
        ),
        // 右侧: 评分总数和评论条数
        Column(
          crossAxisAlignment: CrossAxisAlignment.end, // 右对齐
          children: [
            // 显示 "共有 X 份评分"
            if (hasRating)
              Text(
                '共有 ${game.ratingCount} 份评分',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            // 显示 "X 条评价" (只有在已加载评论且不在初始加载时显示)
            if (currentLoadedReviews > 0 && !(_isLoading && _page == 1))
              Padding(
                padding:
                    EdgeInsets.only(top: hasRating ? 4.0 : 0), // 如果有评分，稍微向下一点
                child: Text(
                  // 注意：这里显示的是当前加载的评论数，可能不是总评论数
                  '$currentLoadedReviews 条评价',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 构建主要内容区域 (根据状态显示不同 Widget)
  Widget _buildContent() {
    // 1. 初始加载状态 (仅第一页)
    if (_isLoading && _page == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0), // 上下边距
        child: LoadingWidget.inline(message: '正在加载评价...'), // 显示行内加载指示器
      );
    }
    // 2. 第一页加载错误状态
    if (_error != null && _page == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        // 使用你的 InlineErrorWidget，并传入刷新方法作为重试回调
        child: InlineErrorWidget(errorMessage: _error!, onRetry: refresh),
      );
    }
    // 3. 空状态 (第一页加载成功，但没有评论)
    if (_reviews.isEmpty && !_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        // 使用你的 EmptyStateWidget
        child: EmptyStateWidget(message: '暂无玩家评价，快来抢沙发吧！'),
      );
    }
    // 4. 显示评论列表
    // 使用 ListView.separated 构建列表，带分割线
    return ListView.separated(
        shrinkWrap: true, // 让 ListView 高度自适应内容
        physics:
            const NeverScrollableScrollPhysics(), // 禁用 ListView 自身的滚动，由外层滚动
        itemCount: _reviews.length, // 列表项数量
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey[200], height: 1), // 分割线
        itemBuilder: (context, index) {
          // Log index for debugging potential list issues
          // print(">>> GRS (${widget.game.id}): Building review item at index $index");
          // 构建单个评论项，传入 GameReview 对象
          return _buildReviewItem(_reviews[index]);
        });
  }

  // 构建单个评论项 Widget
  Widget _buildReviewItem(GameReview review) {
    // *** 参数类型为 GameReview ***
    // *** 使用点语法访问属性，安全且清晰 ***
    final String userId = review.userId;
    final DateTime updateTime = review.updateTime; // 模型中保证非空
    final double? rating = review.rating; // 评分可能为空
    final String reviewText = review.review; // 评论文本，模型中保证非空 (默认为 "")
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // print("Building review for User ID: $userId, Rating: $rating, Text: ${reviewText.substring(0, min(reviewText.length, 20))}"); // Debug log

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0), // 上下边距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 内容左对齐
        children: [
          // 第一行: 用户信息徽章 和 更新时间
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 两端对齐
            crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
            children: [
              // 用户信息徽章 (使用你现有的 UserInfoBadge)
              Expanded(
                // 让徽章占据可用空间，防止时间戳被挤下去
                child: UserInfoBadge(
                  userId: userId, // 传入用户 ID
                  showFollowButton: false, // 这里不显示关注按钮
                  mini: true, // 使用迷你样式
                ),
              ),
              const SizedBox(width: 8), // 徽章和时间戳之间的间距
              // 更新时间 (使用相对时间格式)
              Text(
                DateTimeFormatter.formatRelative(updateTime),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),

          // 第二行: 评分星星 (如果有评分)
          if (rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0), // 上下边距
              child: Row(
                children: List.generate(5, (index) {
                  // 生成 5 个星星
                  double starValue = rating / 2.0; // 将 10 分制转为 5 星制
                  IconData starIcon;
                  Color starColor = Colors.amber; // 默认亮色
                  if (index < starValue.floor()) {
                    // 完整星星
                    starIcon = Icons.star_rounded;
                  } else if (index < starValue && (starValue - index) >= 0.25) {
                    // 半个星星 (阈值设为 0.25，可以调整)
                    starIcon = Icons.star_half_rounded;
                  } else {
                    // 空星星
                    starIcon = Icons.star_border_rounded;
                    starColor = Colors.grey[400]!; // 暗色
                  }
                  return Icon(starIcon, size: 16, color: starColor);
                }),
              ),
            ),

          // 第三行: 评论文本 (如果有评论)
          if (reviewText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0), // 与上方元素的间距
              child: Text(
                reviewText, // 显示评论内容
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[800], height: 1.5), // 行高
                // 可以考虑添加 maxLines 和 overflow 来限制显示长度
                // maxLines: 5,
                // overflow: TextOverflow.ellipsis,
              ),
            ),

          if (review.notes != null &&
              review.notes!.isNotEmpty &&
              review.userId == authProvider.currentUserId)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "我做的笔记: ${review.notes}",
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  // 构建底部的 "加载更多" 按钮 或 加载指示器
  Widget _buildLoadMoreSection() {
    // 1. 正在加载更多时 (isLoading=true, 且不是第一页)
    //    注意：用 !_isProcessingPageOne 确保不是第一页的加载状态
    if (_isLoading && !_isProcessingPageOne && _page > 1) {
      return Padding(
          padding: const EdgeInsets.only(top: 16.0), // 与列表的间距
          child: LoadingWidget.inline(size: 20, message: "加载中...") // 显示小的加载指示器
          );
    }
    // 2. 显示 "加载更多" 按钮的条件：
    //    a) 不在加载中 (!isLoading)
    //    b) 还有更多评论 (_hasMoreReviews)
    //    c) 已经加载了至少一些评论 (_reviews.isNotEmpty)
    if (!_isLoading && _hasMoreReviews && _reviews.isNotEmpty) {
      return Center(
        // 居中显示按钮
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0), // 与列表的间距
          child: FunctionalButton(
            onPressed: _loadMoreReviews, // 点击时调用加载更多方法
            label: '加载更多评价',
          ),
        ),
      );
    }
    // 3. 其他情况 (如没有更多了，或列表为空时) 不显示任何东西
    return const SizedBox.shrink(); // 返回一个空的小部件
  }
}
