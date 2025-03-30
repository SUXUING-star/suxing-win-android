import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/game/game.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../ui/image/safe_cached_image.dart';
import '../../../../../services/main/game/game_service.dart';

class HomeLatest extends StatefulWidget {
  final Stream<List<Game>>? gamesStream;

  const HomeLatest({
    Key? key,
    required this.gamesStream,
  }) : super(key: key);

  @override
  _HomeLatestState createState() => _HomeLatestState();
}

class _HomeLatestState extends State<HomeLatest> {
  // 保存数据以避免重复请求
  List<Game>? _cachedGames;
  bool _isLoading = false;
  String? _errorMessage;

  // 如果没有传入流，就创建自己的GameService
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  @override
  void didUpdateWidget(HomeLatest oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当流改变时重新加载数据
    if (widget.gamesStream != oldWidget.gamesStream) {
      _loadGames();
    }
  }

  // 加载游戏数据
  void _loadGames() {
    // 如果外部提供了流，使用外部流
    if (widget.gamesStream != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 从流中只取第一个事件以避免频繁更新
      widget.gamesStream!.first.then((games) {
        if (mounted) {
          setState(() {
            _cachedGames = games;
            _isLoading = false;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _errorMessage = '加载失败：$error';
            _isLoading = false;
          });
        }
      });
    }
    // 否则从本地缓存或服务获取
    else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 使用带缓存的getLatestGames
      _gameService.getLatestGames().first.then((games) {
        if (mounted) {
          setState(() {
            _cachedGames = games;
            _isLoading = false;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _errorMessage = '加载失败：$error';
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '最新发布',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      NavigationUtils.pushNamed(context, AppRoutes.latestGames);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '更多',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildGameList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGameList(BuildContext context) {
    // 显示加载状态
    if (_isLoading) {
      return _buildLoading();
    }

    // 显示错误
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }

    // 没有数据
    if (_cachedGames == null || _cachedGames!.isEmpty) {
      return _buildEmptyState('暂无最新游戏');
    }

    // 显示游戏列表
    return _buildVerticalGameList(_cachedGames!, context);
  }

  Widget _buildVerticalGameList(List<Game> games, BuildContext context) {
    final displayGames = games.take(3).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: displayGames.length,
      separatorBuilder: (context, index) => Divider(
        height: 16,
        indent: 40,
        endIndent: 0,
        color: Colors.grey.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        final game = displayGames[index];
        return _buildGameListItem(game, context);
      },
    );
  }

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
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Hero(
              tag: 'game_image_${game.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SafeCachedImage(
                  imageUrl: game.coverImage,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  memCacheWidth: 140, // 2倍于显示宽度
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: Colors.grey[300],
                  onError: (url, error) {
                    print('最新游戏列表图片加载失败: $url, 错误: $error');
                  },
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    game.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.remove_red_eye_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                SizedBox(height: 4),
                Text(
                  '${game.viewCount}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGames,
              child: Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}