// lib/screens/collection/game_collection_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';

import '../../../models/game/game_collection.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/main/game/collection/game_collection_service.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import '../../../widgets/components/screen/game/card/base_game_card.dart';
import '../../../widgets/ui/common/error_widget.dart'; // Import error widgets
import '../../../widgets/ui/common/loading_widget.dart'; // Import loading widgets

class GameCollectionListScreen extends StatefulWidget {
  final String collectionType;
  final String title;

  const GameCollectionListScreen({
    super.key,
    required this.collectionType,
    required this.title,
  });

  @override
  _GameCollectionListScreenState createState() =>
      _GameCollectionListScreenState();
}

class _GameCollectionListScreenState extends State<GameCollectionListScreen> {
  List<GameWithCollection> _games = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCollectionGames(); // Load games directly in initState
  }

  Future<void> _loadCollectionGames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isLoggedIn) {
        setState(() {
          _errorMessage = '请先登录后再查看收藏';
          _isLoading = false;
        });
        return;
      }

      String status;
      switch (widget.collectionType) {
        case 'wantToPlay':
          status = GameCollectionStatus.wantToPlay;
          break;
        case 'playing':
          status = GameCollectionStatus.playing;
          break;
        case 'played':
          status = GameCollectionStatus.played;
          break;
        case 'all':
          status = 'all'; // Consider a more robust way to handle "all"
          break;
        default:
          status = widget.collectionType; // Should not normally happen
      }
      final collectionService = context.read<GameCollectionService>();

      final games = await collectionService.getUserGamesByStatus(status);
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
        return LoginPromptWidget();
      }
      return CustomErrorWidget(
          errorMessage: _errorMessage, onRetry: _refreshData);
    }

    if (_isLoading) {
      return LoadingWidget.fullScreen(message: "正在加载收藏数据"); // Use consistent loading widget
    }

    if (_games.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: DeviceUtils.calculateCardRatio(context),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final item = _games[index];
        return BaseGameCard(
          game: item.game,
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
            onPressed: () => NavigationUtils.pushReplacementNamed(
                context, AppRoutes.gamesList),
            label: '发现游戏',
            icon: Icons.find_in_page_outlined,
          ),
        ],
      ),
    );
  }
}
