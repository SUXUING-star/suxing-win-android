// lib/screens/collection/game_collection_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/game/game_collection.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/main/game/collection/game_collection_service.dart';
import '../../../utils/device/device_utils.dart';
import '../../../widgets/common/appbar/custom_app_bar.dart';
import '../../../widgets/components/screen/game/card/game_card.dart';
import '../../../widgets/components/common/error_widget.dart'; // Import error widgets
import '../../../widgets/components/common/loading_widget.dart'; // Import loading widgets

class GameCollectionListScreen extends StatefulWidget {
  final String collectionType;
  final String title;

  const GameCollectionListScreen({
    Key? key,
    required this.collectionType,
    required this.title,
  }) : super(key: key);

  @override
  _GameCollectionListScreenState createState() => _GameCollectionListScreenState();
}

class _GameCollectionListScreenState extends State<GameCollectionListScreen> {
  final GameCollectionService _collectionService = GameCollectionService();
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
          status = widget.collectionType;  // Should not normally happen
      }

      final games = await _collectionService.getUserGamesByStatus(status);
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
        return CustomErrorWidget(
          errorMessage: _errorMessage,
          onRetry: () {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        );
      }
      return CustomErrorWidget(errorMessage: _errorMessage, onRetry: _refreshData);
    }

    if (_isLoading) {
      return LoadingWidget.fullScreen(); // Use consistent loading widget
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
        return GameCard(
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
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.gamesList);
            },
            child: Text('发现游戏'),
          ),
        ],
      ),
    );
  }
}