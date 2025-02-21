import 'package:flutter/material.dart';
import '../../widgets/components/screen/home/field/home_hot.dart';
import '../../widgets/components/screen/home/field/home_latest.dart';
import '../../utils/load/loading_route_observer.dart';
import '../../widgets/components/screen/home/banner/home_banner.dart';
import '../../models/game/game.dart';
import '../../services/main/game/game_service.dart';

class HomeScreen extends StatefulWidget {

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService _gameService = GameService();
  Stream<List<Game>>? _hotGamesStream;
  Stream<List<Game>>? _latestGamesStream;

  @override
  void initState() {
    super.initState();
    // 统一初始化数据流
    _hotGamesStream = _gameService.getHotGames();
    _latestGamesStream = _gameService.getLatestGames();
  }

  Future<void> _refreshData() async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      // 在这里添加实际的数据刷新逻辑
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              HomeBanner(),
              // 传入已初始化的流
              HomeHot(gamesStream: _hotGamesStream),
              HomeLatest(gamesStream: _latestGamesStream),
            ],
          ),
        ),
      ),
    );
  }
}