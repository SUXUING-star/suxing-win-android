import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../widgets/game/card/game_card.dart';
import '../../utils/loading_route_observer.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/common/custom_app_bar.dart';


class LatestGamesScreen extends StatefulWidget {
  @override
  _LatestGamesScreenState createState() => _LatestGamesScreenState();
}

class _LatestGamesScreenState extends State<LatestGamesScreen> {
  final GameService _gameService = GameService();
  List<Game> _games = [];  // 使用List初始化
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      _loadGames().then((_) {
        loadingObserver.hideLoading();
      });
    });
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final games = await _gameService.getLatestGames().first;
      setState(() {
        _games = games;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败：${e.toString()}';
        _games = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadGames();
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '最新发布',
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }

    if (_isLoading) {
      return _buildLoading();
    }

    if (_games.isEmpty) {
      return _buildEmptyState('暂无最新游戏');
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),  // 移除 controller
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: DeviceUtils.calculateCardRatio(context),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        return GameCard(game: _games[index]);
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.games_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}