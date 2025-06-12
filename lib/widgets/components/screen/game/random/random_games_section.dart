// lib/widgets/components/screen/game/random/random_games_section.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

/// 一个横向滚动的“猜你喜欢”游戏推荐区域。
///
/// 功能特性:
/// - 在移动端，支持手指左右滑动。
/// - 在桌面端，当鼠标悬停在此区域时：
///   1. 响应鼠标滚轮的上下滚动，并将其转换为列表的横向滚动。
///   2. 通过 [onHover] 回调，通知父组件锁定或解锁其自身的垂直滚动，以避免冲突。
class RandomGamesSection extends StatefulWidget {
  final String currentGameId;
  final GameService gameService;

  /// 当鼠标进入或离开此组件区域时触发的回调。
  /// `true` 表示进入，`false` 表示离开。
  final ValueChanged<bool>? onHover;

  const RandomGamesSection({
    super.key,
    required this.currentGameId,
    required this.gameService,
    this.onHover,
  });

  @override
  _RandomGamesSectionState createState() => _RandomGamesSectionState();
}

class _RandomGamesSectionState extends State<RandomGamesSection> {
  final ScrollController _scrollController = ScrollController();
  List<Game> _randomGames = [];
  bool _isLoading = true;
  String? _errMsg;

  @override
  void initState() {
    super.initState();
    _loadRandomGames();
  }

  @override
  void didUpdateWidget(covariant RandomGamesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentGameId != oldWidget.currentGameId) {
      _loadRandomGames();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRandomGames() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errMsg = null;
    });

    try {
      final games = await widget.gameService.getRandomGames(
        excludeId: widget.currentGameId,
      );
      if (!mounted) return;
      setState(() {
        _randomGames = games;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(size: 24);
    }
    if (_errMsg != null) {
      return InlineErrorWidget(
        onRetry: _loadRandomGames,
        retryText: "尝试重试",
        errorMessage: _errMsg,
      );
    }
    if (_randomGames.isEmpty) {
      return const EmptyStateWidget(message: "暂无推荐");
    }

    final isDesktop = DeviceUtils.isDesktopScreen(context);
    final double cardWidth = isDesktop ? 160.0 : 140.0;
    final double cardMargin = 12.0;
    final double sectionHeight = isDesktop ? 200.0 : 180.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '猜你喜欢',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- 核心实现区域 ---
          SizedBox(
            height: sectionHeight,
            // 1. MouseRegion 捕获鼠标进出事件，用于通知父组件
            child: MouseRegion(
              onEnter: (_) => widget.onHover?.call(true),
              onExit: (_) => widget.onHover?.call(false),
              // 2. Listener 捕获鼠标滚轮事件，并将其转换为横向滚动
              child: Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    final double scrollOffset =
                        pointerSignal.scrollDelta.dy.abs() >
                                pointerSignal.scrollDelta.dx.abs()
                            ? pointerSignal.scrollDelta.dy
                            : pointerSignal.scrollDelta.dx;

                    _scrollController.jumpTo(
                      _scrollController.offset + scrollOffset,
                    );
                  }
                },
                // 3. 内部的 ListView 正常处理触摸滑动
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _randomGames.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return Container(
                        width: cardWidth,
                        margin: EdgeInsets.only(
                            right: index < _randomGames.length - 1
                                ? cardMargin
                                : 0),
                        child: CommonGameCard(
                          game: _randomGames[index],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
