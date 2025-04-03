// lib/screens/mygames/my_games_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../models/game/game.dart'; // 确保这里引用的是你正确的模型路径
import '../../../services/main/game/game_service.dart';
import '../../../widgets/components/screen/game/card/base_game_card.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';

class MyGamesScreen extends StatefulWidget {
  const MyGamesScreen({Key? key}) : super(key: key);

  @override
  _MyGamesScreenState createState() => _MyGamesScreenState();
}

class _MyGamesScreenState extends State<MyGamesScreen> {
  final GameService _gameService = GameService();
  final ScrollController _scrollController = ScrollController();

  List<Game> _myGames = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true; // For initial load
  bool _isFetchingMore = false; // For pagination loading indicator
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialGames();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // --- Data Loading ---

  Future<void> _loadInitialGames() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 1; // Reset page number for refresh/initial load
      _myGames.clear(); // Clear existing games on refresh/initial load
    });

    try {
      final result = await _gameService.getMyGamesWithInfo(
        page: 1, // Always load page 1 initially
        pageSize: 10, // Or your preferred page size
        // sortBy: 'updateTime', // Example sorting, adjust as needed
        // descending: true,
      );

      if (!mounted) return;

      setState(() {
        _myGames = result['games'];
        _totalPages = result['pagination']?['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('加载我的游戏失败 (Initial): $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '加载我的游戏列表失败: $e';
      });
    }
  }

  Future<void> _loadMoreGames() async {
    // Prevent multiple fetches and fetching beyond last page
    if (_isFetchingMore ||
        _currentPage >= _totalPages ||
        _isLoading ||
        _hasError) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _gameService.getMyGamesWithInfo(
        page: nextPage,
        pageSize: 10,
        // sortBy: 'updateTime', // Consistent sorting
        // descending: true,
      );

      if (!mounted) return;

      setState(() {
        _myGames.addAll(result['games']);
        _currentPage = nextPage;
        _totalPages = result['pagination']?['totalPages'] ??
            _totalPages; // Update total pages if needed
        _isFetchingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('加载更多我的游戏失败: $e');
      // Optionally show a snackbar or allow retry
      setState(() {
        _isFetchingMore = false;
        // Keep existing games, maybe show error briefly
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载更多失败'), duration: Duration(seconds: 2)),
        );
      });
    }
  }

  void _scrollListener() {
    // Trigger load more when near the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreGames();
    }
  }

  // --- Actions ---

  Future<void> _resubmitGame(Game game) async {
    if (game.approvalStatus != 'rejected') return; // Safety check

    try {
      await _gameService.resubmitGame(game.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('《${game.title}》已重新提交审核')),
      );
      // Refresh the entire list to reflect the status change potentially
      _loadInitialGames();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('重新提交失败: $e')),
      );
    }
  }

  // --- UI Building ---

  // Helper to get display properties based on status
  Map<String, dynamic> _getStatusDisplay(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return {'text': '审核中', 'color': Colors.orange};
      case 'approved':
        return {'text': '已通过', 'color': Colors.green};
      case 'rejected':
        return {'text': '已拒绝', 'color': Colors.red};
      default:
        // Handle null or unexpected status
        return {'text': '未知', 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '我的游戏', // Changed title
        // No bottom TabBar needed
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialGames, // Pull to refresh loads page 1
        child: _buildBody(),
      ),
      floatingActionButton: GenericFloatingActionButton(
        onPressed: () async {
          // Navigate and potentially refresh list after returning
          final result =
              await NavigationUtils.pushNamed(context, AppRoutes.addGame);
          if (result == true) {
            // Check if add game screen indicates success
            _loadInitialGames();
          }
        },
        icon: Icons.add,
        tooltip: '提交新游戏',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingWidget.inline();
    }

    if (_hasError) {
      return InlineErrorWidget(
        onRetry: _loadInitialGames,
        errorMessage: _errorMessage,
      );
    }

    if (_myGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gamepad_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('您还没有提交过游戏', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('点击右下角按钮创建您的第一个游戏吧！', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            FunctionalButton(
                onPressed: () {
                  NavigationUtils.pushNamed(context, AppRoutes.addGame)
                      .then((_) => _loadInitialGames());
                },
                label: '创建新游戏',
                icon: Icons.videogame_asset_rounded),
          ],
        ),
      );
    }

    // Use ListView + GridView.builder for pagination indicator
    return ListView(
        controller: _scrollController,
        padding: EdgeInsets.all(8),
        children: [
          GridView.builder(
            shrinkWrap: true, // Important for ListView nesting
            physics:
                NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250, // Max width for each card
              childAspectRatio:
                  0.70, // Adjust aspect ratio to fit status/buttons
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
            ),
            itemCount: _myGames.length,
            itemBuilder: (context, index) {
              final game = _myGames[index];
              return _buildGameCard(game);
            },
          ),
          // Loading indicator at the bottom
          if (_isFetchingMore)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ]);
  }

  Widget _buildGameCard(Game game) {
    final statusInfo = _getStatusDisplay(game.approvalStatus);
    final bool isRejected = game.approvalStatus?.toLowerCase() == 'rejected';
    final bool showComment = isRejected &&
        game.reviewComment != null &&
        game.reviewComment!.isNotEmpty;

    return Stack(
      children: [
        // Base card content
        BaseGameCard(
          game: game,
          showTags: true, // Or false based on your preference
          maxTags: 1,
          // Adjust padding if needed to make space for overlays
        ),

        // Status Badge
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: (statusInfo['color'] as Color).withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  // Optional subtle shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  )
                ]),
            child: Text(
              statusInfo['text'],
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10, // Slightly smaller font size
              ),
            ),
          ),
        ),

        // Resubmit Button (Only for rejected)
        if (isRejected)
          Positioned(
            bottom: 8,
            right: 8,
            child: Tooltip(
              // Add tooltip
              message: '重新提交审核',
              child: FloatingActionButton.small(
                heroTag: 'resubmit_${game.id}', // Unique heroTag
                onPressed: () => _resubmitGame(game),
                backgroundColor: Colors.blue.shade600,
                child: Icon(Icons.refresh, size: 18), // Slightly larger icon
              ),
            ),
          ),

        // Review Comment Overlay (Only for rejected with comment)
        if (showComment)
          Positioned(
            // Adjust position to avoid overlapping the resubmit button too much
            bottom:
                isRejected ? 55 : 8, // Lift up if resubmit button is present
            left: 8,
            right: 8,
            child: GestureDetector(
              // Allow tapping to potentially show full comment
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('拒绝原因'),
                    content:
                        SingleChildScrollView(child: Text(game.reviewComment!)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('关闭'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      )
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Fit content
                  children: [
                    Text(
                      '拒绝原因:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      game.reviewComment!,
                      style: TextStyle(fontSize: 10, color: Colors.black87),
                      maxLines: 2, // Show preview
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
