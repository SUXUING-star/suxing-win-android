// lib/screens/collection/game_collection_list_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/collection/collection_item_with_game.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';

import 'package:suxingchahui/models/game/collection/collection_item.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/components/screen/game/card/base_game_card.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // Import error widgets
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart'; // Import loading widgets

class GameCollectionListScreen extends StatefulWidget {
  final String collectionType;
  final String title;
  final AuthProvider authProvider;
  final GameCollectionService gameCollectionService;
  final SidebarProvider sidebarProvider;
  final WindowStateProvider windowStateProvider;

  const GameCollectionListScreen({
    super.key,
    required this.collectionType,
    required this.title,
    required this.authProvider,
    required this.sidebarProvider,
    required this.gameCollectionService,
    required this.windowStateProvider,
  });

  @override
  _GameCollectionListScreenState createState() =>
      _GameCollectionListScreenState();
}

class _GameCollectionListScreenState extends State<GameCollectionListScreen> {
  List<CollectionItemWithGame> _games = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasInitializedDependencies = false;

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
      _loadCollectionGames(); // Load games directly in initState
    }
  }

  Future<void> _loadCollectionGames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!widget.authProvider.isLoggedIn) {
        setState(() {
          _errorMessage = '请先登录后再查看收藏';
          _isLoading = false;
        });
        return;
      }

      String status;
      switch (widget.collectionType) {
        case 'wantToPlay':
          status = CollectionItem.statusWantToPlay;
          break;
        case 'playing':
          status = CollectionItem.statusPlaying;
          break;
        case 'played':
          status = CollectionItem.statusPlayed;
          break;
        case 'all':
          status = 'all'; // Consider a more robust way to handle "all"
          break;
        default:
          status = widget.collectionType; // Should not normally happen
      }

      final games =
          await widget.gameCollectionService.getUserGamesByStatus(status);
      setState(() {
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载收藏游戏失败：$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadCollectionGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      if (_errorMessage == '请先登录后再查看收藏') {
        return const LoginPromptWidget();
      }
      return CustomErrorWidget(
          errorMessage: _errorMessage, onRetry: _refreshData);
    }

    if (_isLoading) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    if (_games.isEmpty) {
      return _buildEmptyState(context);
    }

    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            childAspectRatio: DeviceUtils.calculateGameCardRatio(context),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _games.length,
          itemBuilder: (context, index) {
            final item = _games[index];
            final game = item.game;
            if (game == null) {
              return const SizedBox.shrink();
            }
            return BaseGameCard(
              currentUser: widget.authProvider.currentUser,
              game: game,
            );
          },
        );
      },
    );
  }

  // The _buildCollectionStatus method is not used, so it's removed

  Widget _buildEmptyState(BuildContext context) {
    String message;
    IconData icon;

    switch (widget.collectionType) {
      case 'wantToPlay':
        message = '还没有想玩的游戏';
        icon = Icons.star_border;
        break;
      case 'playing':
        message = '还没有在玩的游戏';
        icon = Icons.videogame_asset;
        break;
      case 'played':
        message = '还没有玩过的游戏';
        icon = Icons.check_circle;
        break;
      default:
        message = '还没有收藏任何游戏';
        icon = Icons.collections_bookmark;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 24),
          FunctionalButton(
            onPressed: () => NavigationUtils.navigateToHome(
                widget.sidebarProvider, context,
                tabIndex: 1),
            label: '发现游戏',
            icon: Icons.find_in_page_outlined,
          ),
        ],
      ),
    );
  }
}
