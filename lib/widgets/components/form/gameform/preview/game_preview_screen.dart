// lib/widgets/components/form/gameform/preview/game_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/widgets/components/screen/game/game_detail_layout.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class GamePreviewScreen extends StatelessWidget {
  final GameService gameService;
  final GameCollectionService gameCollectionService;
  final AuthProvider authProvider;
  final WindowStateProvider windowStateProvider;
  final SidebarProvider sidebarProvider;
  final Game game;
  final User? currentUser;
  final InputStateService inputStateService;
  final UserInfoService infoService;
  final UserFollowService followService;
  final GameListFilterProvider gameListFilterProvider;

  const GamePreviewScreen({
    super.key,
    required this.gameCollectionService,
    required this.windowStateProvider,
    required this.gameService,
    required this.authProvider,
    required this.sidebarProvider,
    required this.currentUser,
    required this.game,
    required this.inputStateService,
    required this.infoService,
    required this.followService,
    required this.gameListFilterProvider,
  });

  @override
  Widget build(BuildContext context) {
    return LazyLayoutBuilder(
      windowStateProvider: windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = DeviceUtils.isDesktopInThisWidth(screenWidth);

        return isDesktop
            ? _buildDesktopLayout(context, isDesktop)
            : _buildMobileLayout(context, isDesktop);
      },
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.of(context).pop(),
      label: Text('返回继续编辑'),
      icon: Icon(Icons.edit),
    );
  }

  Widget _buildGameContent(BuildContext context,bool isDesktop) {
    return GameDetailLayout(
      sidebarProvider: sidebarProvider,
      gameListFilterProvider: gameListFilterProvider,
      gameCollectionService: gameCollectionService,
      authProvider: authProvider,
      inputStateService: inputStateService,
      followService: followService,
      infoService: infoService,
      isDesktop: isDesktop,
      currentUser: currentUser,
      gameService: gameService,
      game: game,
      isPreviewMode: true,
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDesktop) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '预览: ${game.title}',
        actions: [],
      ),
      body: Column(
        children: [
          // Preview banner
          Container(
            width: double.infinity,
            color: Colors.amber.withSafeOpacity(0.2),
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: AppText(
                '预览模式 - 这是您保存后的游戏详情页效果预览',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Use the actual game detail content widget with Expanded to fill available space
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: _buildGameContent(context, isDesktop),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDesktop) {
    return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (game.coverImage.isNotEmpty)
                      Image.network(
                        game.coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black54,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: Colors.amber.withSafeOpacity(0.2),
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: AppText(
                    '预览模式 - 实时预览效果',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverToBoxAdapter(
                child: _buildGameContent(context, isDesktop),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(context));
  }
}
