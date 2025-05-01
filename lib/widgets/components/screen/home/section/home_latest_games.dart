// lib/widgets/components/screen/home/section/home_latest_games.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../models/game/game.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../ui/image/safe_cached_image.dart';
import '../../../../../services/main/game/game_service.dart'; // 引入 Service
import 'dart:async'; // 需要 Timer (如果之前没有)

class HomeLatestGames extends StatefulWidget {
  // 移除 Stream 参数
  const HomeLatestGames({super.key}); // 使用 Key
  @override
  _HomeLatestGamesState createState() => _HomeLatestGamesState();
}

class _HomeLatestGamesState extends State<HomeLatestGames> {

  // 恢复内部状态
  List<Game>? _cachedGames;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData(); // initState 获取数据
  }

  // 获取数据的 Future 方法
  Future<void> _fetchData() async {
    if (!mounted) return;
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final gameService = context.read<GameService>();
      final games = await gameService.getLatestGames();

      if (mounted && games.isNotEmpty) {
        setState(() {
          _cachedGames = games;
        });
      } else {
        _errorMessage = "加载最新游戏失败";
        setState(() {
          _isLoading = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载最新游戏失败'; // 简化错误信息
          // _isLoading = false; // 在 finally 处理
          _cachedGames = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 确保 isLoading 被重置
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 整体结构保持不变，使用内部状态构建列表 ---
    return Opacity(
      opacity: 0.9,
      child: Container(
        // margin: EdgeInsets.all(16), // 外层 Padding 会处理
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 标题栏保持不变 ---
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade200, width: 1))),
              child: Row(
                children: [
                  Container(
                      width: 6,
                      height: 22,
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(3))),
                  SizedBox(width: 12),
                  Text('最新发布',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900])),
                  Spacer(),
                  InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        NavigationUtils.pushNamed(
                            context, AppRoutes.latestGames);
                      },
                      child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(children: [
                            Text('更多',
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 14)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey[700])
                          ]))),
                ],
              ),
            ),
            SizedBox(height: 16),

            // --- 使用内部状态构建列表区域 ---
            _buildGameListArea(context),
          ],
        ),
      ),
    );
  }

  // 构建列表区域的辅助方法
  Widget _buildGameListArea(BuildContext context) {
    // 1. 加载状态
    if (_isLoading && _cachedGames == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: LoadingWidget.inline(message: '加载最新游戏...', size: 24),
      );
    }

    // 2. 错误状态
    if (_errorMessage != null && _cachedGames == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: InlineErrorWidget(
          errorMessage: _errorMessage!,
          onRetry: _fetchData,
        ),
      );
    }

    // 3. 空状态
    if (!_isLoading && (_cachedGames == null || _cachedGames!.isEmpty)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: EmptyStateWidget(
          message: '暂无最新游戏',
          iconData: Icons.inbox_outlined,
          iconSize: 40,
          iconColor: Colors.grey,
        ),
      );
    }

    // 4. 正常显示列表 (或加载中但有旧数据)
    final games = _cachedGames ?? []; // 使用缓存或空列表
    return Stack(
      // 使用 Stack 添加加载覆盖层
      children: [
        _buildVerticalGameList(games, context),
        // 加载覆盖层
        if (_isLoading && games.isNotEmpty)
          Positioned.fill(
              child: Container(
            color: Colors.white.withOpacity(0.5), // 半透明覆盖
            child: Center(child: LoadingWidget.inline(size: 30)),
          )),
      ],
    );
  }

  Widget _buildVerticalGameList(List<Game> games, BuildContext context) {
    final displayGames = games.take(3).toList();
    if (displayGames.isEmpty) {
      return SizedBox(
          height: 100,
          child: Center(
              child: Text("没有最新游戏可显示", style: TextStyle(color: Colors.grey))));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: displayGames.length,
      separatorBuilder: (context, index) => Divider(
          height: 16,
          indent: 88,
          endIndent: 16,
          color: Colors.grey.withOpacity(0.1)),
      itemBuilder: (context, index) {
        final game = displayGames[index];
        // *** 调用完整的列表项构建方法 ***
        return _buildGameListItem(game, context);
      },
    );
  }

  // *** 完整的 _buildGameListItem 方法 ***
  Widget _buildGameListItem(Game game, BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        NavigationUtils.pushNamed(
          context,
          AppRoutes.gameDetail,
          arguments: game,
        );
      },
      child: Padding(
        // 改用 Padding 增加点击区域
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // --- 图片 ---
            Hero(
              // 添加 _latest 避免 tag 冲突 (如果其他地方也用 game_image_ 前缀)
              tag: 'game_image_${game.id}_latest',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SafeCachedImage(
                  imageUrl: game.coverImage,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  memCacheWidth: 140, // 2倍于显示宽度
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: Colors.grey[300], // 占位背景色
                  // 可以添加错误处理回调（可选）
                  // onError: (url, error) => print('Image load error: $url, $error'),
                ),
              ),
            ),
            SizedBox(width: 16),
            // --- 中间文字 ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                children: [
                  Text(
                    game.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                    maxLines: 1, // 标题只显示一行
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6), // 增加一点间距
                  Text(
                    game.summary,
                    maxLines: 2, // 摘要最多显示两行
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13, // 减小字号
                      height: 1.3, // 调整行高
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            // --- 右侧统计信息 ---
            _buildStatsColumn(game), // 调用辅助方法构建
          ],
        ),
      ),
    );
  }

  // 抽取右侧统计信息的构建逻辑 (保持不变)
  Widget _buildStatsColumn(Game game) {
    // 确认 Game 模型中有 viewCount, ratingCount, likeCount 这些字段
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center, // 居中对齐
      children: [
        _buildStatItem(Icons.remove_red_eye_outlined, game.viewCount,
            Colors.blueGrey[300]),
        SizedBox(height: 6),
        _buildStatItem(Icons.star_border_purple500_outlined, game.ratingCount,
            Colors.orange[400]), // 收藏数改为 ratingCount? 确认下字段
        SizedBox(height: 6),
        _buildStatItem(Icons.thumb_up_off_alt_outlined, game.likeCount,
            Colors.redAccent[100]), // 点赞数改为 likeCount? 确认下字段
      ],
    );
  }

  // 抽取单个统计项的构建逻辑 (保持不变)
  Widget _buildStatItem(IconData icon, int count, Color? iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min, // 仅占据必要宽度
      children: [
        Icon(
          icon,
          color: iconColor ?? Colors.grey[500],
          size: 18, // 稍微减小图标
        ),
        SizedBox(width: 4), // 减小间距
        Text(
          '$count', // 直接显示数字
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} // End of _HomeLatestGamesState
