// lib/widgets/components/screen/game/collection/game_reviews_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart'; // 确认路径正确
import 'package:suxingchahui/services/main/game/collection/game_collection_service.dart'; // 确认路径正确
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 确认路径正确
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 确认路径正确

class GameReviewSection extends StatefulWidget {
  final Game game;

  const GameReviewSection({
    Key? key, // 接受 Key
    required this.game,
  }) : super(key: key); // 传递 Key 给 super

  @override
  // State 类名改为公开，并且去掉下划线
  GameReviewSectionState createState() => GameReviewSectionState();
}

// State 类名改为公开，去掉下划线
class GameReviewSectionState extends State<GameReviewSection> {
  final GameCollectionService _collectionService = GameCollectionService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _error; // 或者用 String? 存储错误信息，选择一种与你原代码一致的方式
  int _page = 1;
  final int _pageSize = 5; // 保持你原来设定的分页大小
  bool _hasMoreReviews = true; // 保持你原来判断是否有更多数据的逻辑

  @override
  void initState() {
    super.initState();
    // _loadReviews(); // 保持原来的调用方式
    _loadReviews(isInitialLoad: true); // 传递一个标志，首次加载
  }

  @override
  void didUpdateWidget(GameReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {

      // 重置状态，保持你原来的方式
      setState(() {
        _reviews = []; // 清空
        _page = 1;    // 页码归1
        _isLoading = true; // 显示加载
        _error = null; // 清除错误
        _hasMoreReviews = true; // 重新假设有更多
      });
      _loadReviews(); // 加载新游戏的数据
    }
  }

  // --- 公开的刷新方法 ---
  void refresh() {
    print("GameReviewSection (${widget.game.id}): refresh() called.");
    // 检查 mounted 避免在已卸载的 Widget 上调用 setState
    if (mounted) {
      setState(() {
        _page = 1; // 重置到第一页
        _reviews = []; // 清空旧数据
        _isLoading = true; // 开始加载，显示 Loading
        _error = null; // 清除之前的错误状态
        _hasMoreReviews = true; // 假设可能有更多数据
      });
      _loadReviews(); // 开始加载数据
    } else {

    }
  }

  Future<void> _loadReviews({bool isInitialLoad = false}) async {
    // 防止重复加载或在没有更多数据时加载 (保持原有逻辑)
    if (_isLoading && !isInitialLoad) return;
    if (!_hasMoreReviews && _page > 1) return;


    // 开始加载前设置状态（如果需要，并检查 mounted）
    if (mounted && !isInitialLoad) { // 只有非首次加载时，在这里设置 Loading
      setState(() { _isLoading = true; _error = null; });
    } else if (!mounted) {
      return; // Widget 已卸载
    }


    try {
      print("GameReviewSection (${widget.game.id}): Fetching reviews page $_page...");
      // *** 调用 Service 时传递分页参数 ***
      final reviews = await _collectionService.getGameReviews(widget.game.id, page: _page);
      // final reviews = await _collectionService.getGameReviews(widget.game.id); // 如果你的 Service 不支持分页，就用这个


      if (!mounted) return; // 在 await 后、setState 前检查

      setState(() {
        // 恢复你原来的分页逻辑
        final fetchedList = List<Map<String, dynamic>>.from(reviews);
        if (_page == 1) {
          _reviews = fetchedList; // 第一页直接赋值
        } else {
          _reviews.addAll(fetchedList); // 其他页追加
        }

        // 恢复你原来的判断逻辑
        _hasMoreReviews = fetchedList.length >= _pageSize;
        _isLoading = false; // 加载完成
        if(_hasMoreReviews) { // 如果返回的数量等于或超过分页大小，认为可能有更多，页码+1
          _page++;
        }

        // _hasError = false; // 如果用 boolean 标记错误，在这里重置
        _error = null; // 如果用 String? 标记，在这里清空
      });
    } catch (e, s) { // 捕获异常和堆栈
      if (!mounted) return; // 在 catch 块内的 setState 前检查

      setState(() {
        _isLoading = false;
        // _hasError = true; // 如果用 boolean 标记
        if (_page == 1) { // 只在第一页失败时设置错误状态，避免覆盖已有数据
          _error = e.toString(); // 记录错误信息
        } else {
          // 加载更多失败，可以选择性地显示提示，例如用 SnackBar
         AppSnackBar.showError(context,'加载更多评价失败');
          // 或者什么都不做，让用户可以再次尝试点击加载更多
        }
      });
    }
  }

  // --- build 方法及其子方法保持你原来的结构和样式 ---
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1, // 保持原来的 elevation
      margin: const EdgeInsets.only(bottom: 16), // 保持原来的 margin
      shape: RoundedRectangleBorder( // 保持原来的 shape
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // 保持原来的 padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(), // 保持原来的 Header
            const SizedBox(height: 16), // 保持原来的间距
            _buildContent(), // 保持原来的 Content 构建逻辑
            // 保持原来的“加载更多”按钮显示逻辑
            // 这里确保 _isLoading 检查只影响加载更多按钮本身，不影响已加载列表的显示
            if (_hasMoreReviews && _reviews.isNotEmpty) // 稍微优化：仅当有内容且有更多时才显示加载按钮
              _buildLoadMoreButton(),
            // 可选：如果正在加载“更多”，可以在底部显示一个小的指示器，不影响Card结构
            if (_isLoading && _page > 1)
              LoadingWidget.inline(size: 16,)
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // --- 严格使用你原来的 Header Row 结构和样式 ---
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
        SizedBox(width: 8),
        Text(
          '玩家评价', // 保持原来的文本
          style: TextStyle( // 保持原来的 TextStyle
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8),
        // 保持原来的显示条数逻辑和样式
        if (_reviews.isNotEmpty)
          Text(
            '共${_reviews.length} 条评价',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    // --- 严格根据你原来的逻辑构建内容区域 ---

    // 1. 首次加载时的 Loading (保持原来的 Center + Padding + Indicator)
    if (_isLoading && _page == 1) { // 改为判断 _page == 1 来确定是否首次加载
      return LoadingWidget.inline();
    }

    // 2. 加载出错时的显示 (根据你用 _hasError 还是 _error 判断)
    // if (_hasError && _reviews.isEmpty) { // 如果你用 boolean
    if (_error != null && _reviews.isEmpty) { // 如果你用 String?
      return InlineErrorWidget(
        errorMessage: '加载评价时出错',
        onRetry: refresh, // 调用 refresh 方法
      );
    }

    // 3. 没有评价时的显示 (保持原来的 Center + Padding + Text)
    if (_reviews.isEmpty && !_isLoading) { // 确保不是在加载中才显示“暂无”
      return EmptyStateWidget(message: '暂无玩家评价');
    }

    // 4. 显示评价列表 (保持原来的 ListView.separated)
    return ListView.separated(
      shrinkWrap: true, // 保持 shrinkWrap
      physics: const NeverScrollableScrollPhysics(), // 保持 physics
      itemCount: _reviews.length, // 保持 itemCount
      separatorBuilder: (context, index) => const Divider(), // 保持原来的 Divider
      itemBuilder: (context, index) => _buildReviewItem(_reviews[index]), // 调用你原来的 Item 构建方法
    );
  }

  // --- _buildReviewItem 保持你原来的实现和样式 ---
  Widget _buildReviewItem(Map<String, dynamic> review) {
    // 提取数据逻辑尽量保持，只做必要的 null safety 检查
    final user = review['user'] as Map<String, dynamic>? ?? {}; // 安全获取 user map
    final userId = user['userId']?.toString() ?? ''; // 安全获取 userId
    // 同样安全获取 updateTime, rating, reviewText
    DateTime? updateTime;
    final updateTimeString = review['updateTime'] as String?;
    if (updateTimeString != null) {
      try { updateTime = DateTime.parse(updateTimeString).toLocal(); } catch (_) {}
    }
    final dynamic rawRating = review['rating'];
    final double? rating = (rawRating is num) ? rawRating.toDouble() : null;
    final String reviewText = review['review'] as String? ?? '';


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 保持原来的 Padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 保持原来的 UserInfoBadge
              UserInfoBadge(
                userId: userId, // 传递安全获取的 userId
                showFollowButton: false, // 保持你的设置
                mini: true, // 保持你的设置
              ),
              // 保持原来的时间显示
              if (updateTime != null)
                Text(
                  DateTimeFormatter.formatRelative(updateTime),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          // 保持原来的评分显示逻辑和样式
          if (rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐星星和数字
                children: [
                  Icon(
                    Icons.star, // 用实心星星
                    size: 18,
                    color: Colors.amber, // 标准黄色
                  ),
                  const SizedBox(width: 4),
                  Text(
                    // 显示为 X.Y / 10 格式
                    '${rating.toStringAsFixed(1)}/10',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      // fontSize: 14, // 可以稍微调整字体大小
                    ),
                  ),
                ],
              ),
            ),
          // 保持原来的评价文本显示逻辑和样式
          if (reviewText.isNotEmpty) // 确保 reviewText 不为空字符串
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                reviewText,
                style: TextStyle( // 保持原来的 TextStyle
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4, // 可以调整行高让阅读更舒适
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- _buildLoadMoreButton 保持你原来的实现和样式 ---
  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0), // 保持原来的 Padding
        child: TextButton(
          onPressed: _isLoading ? null : _loadReviews, // 加载中则禁用
          child: _isLoading && _page > 1 // 只在加载更多时显示 Loading 状态
              ? Row( // 保持原来的 Loading Row 结构
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text('加载中...'), // 保持原来的文本
            ],
          )
              : Text('加载更多'), // 保持原来的文本
        ),
      ),
    );
  }
}