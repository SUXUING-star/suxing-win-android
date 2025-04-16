// lib/widgets/components/screen/game/favorite/favorite_game_grid_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/game/game.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../ui/image/safe_cached_image.dart';

/// 为游戏收藏屏幕的网格视图设计的卡片组件
class FavoriteGameGridCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onFavoritePressed;

  const FavoriteGameGridCard({
    Key? key,
    required this.game,
    this.onFavoritePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          NavigationUtils.pushNamed(
            context,
            AppRoutes.gameDetail,
            arguments: game,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 游戏封面
                  SafeCachedImage(
                    imageUrl: game.coverImage,
                    fit: BoxFit.cover,
                    onError: (url, error) {
                      //print('收藏游戏封面加载失败: $url, 错误: $error');
                    },
                  ),

                  // 类别标签
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        game.category,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 收藏按钮
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                      onPressed: onFavoritePressed,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.7),
                        padding: EdgeInsets.all(8),
                      ),
                    ),
                  ),

                  // 统计信息
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.thumb_up, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            game.likeCount.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            game.viewCount.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 游戏信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      game.summary,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 标签区域
                    if (game.tags.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: game.tags.take(3).map((tag) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}