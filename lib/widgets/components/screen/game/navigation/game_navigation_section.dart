// Create a new file: lib/widgets/components/screen/game/navigation/game_navigation_section.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/game/game.dart';
import '../../../../../services/main/game/game_service.dart';

class GameNavigationSection extends StatefulWidget {
  final String currentGameId;
  final Function(String gameId)? onNavigate;

  const GameNavigationSection({
    Key? key,
    required this.currentGameId,
    this.onNavigate,
  }) : super(key: key);

  @override
  _GameNavigationSectionState createState() => _GameNavigationSectionState();
}

class _GameNavigationSectionState extends State<GameNavigationSection> {
  final GameService _gameService = GameService();
  Map<String, String>? _navigationData;
  Map<String, Game?>? _navigationGames;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNavigationData();
  }

  @override
  void didUpdateWidget(GameNavigationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentGameId != oldWidget.currentGameId) {
      _loadNavigationData();
    }
  }

  Future<void> _loadNavigationData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get navigation IDs
      final navData = await _gameService.getGameNavigation(widget.currentGameId);

      if (navData != null) {
        setState(() {
          _navigationData = navData;
        });

        // Pre-fetch game details for previews
        _navigationGames = {};

        if (navData.containsKey('previousId') && navData['previousId']!.isNotEmpty) {
          _navigationGames!['previousId'] = await _gameService.getGameById(navData['previousId']!);
        }

        if (navData.containsKey('nextId') && navData['nextId']!.isNotEmpty) {
          _navigationGames!['nextId'] = await _gameService.getGameById(navData['nextId']!);
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error loading navigation data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToGame(String gameId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(gameId);
    } else {
      NavigationUtils.pushReplacementNamed(
        context,
        '/games/detail',
        arguments: gameId,
      );
    }
  }

  Widget _buildNavigationButton({
    required bool isPrevious,
    required String? gameId,
    required Game? game,
  }) {
    if (gameId == null || gameId.isEmpty) {
      return const SizedBox.shrink();
    }

    final icon = isPrevious ? Icons.arrow_back : Icons.arrow_forward;
    final label = isPrevious ? '上一篇' : '下一篇';

    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: InkWell(
          onTap: () => _navigateToGame(gameId),
          child: Row(
            mainAxisAlignment: isPrevious
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              if (isPrevious)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(icon, size: 24),
                ),
              if (game != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: isPrevious
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isPrevious ? TextAlign.left : TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: isPrevious ? TextAlign.left : TextAlign.right,
                    ),
                  ),
                ),
              if (!isPrevious)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(icon, size: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_navigationData == null ||
        (_navigationData!['previousId']?.isEmpty ?? true) &&
            (_navigationData!['nextId']?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),

        ),
        Row(
          children: [
            _buildNavigationButton(
              isPrevious: true,
              gameId: _navigationData?['previousId'],
              game: _navigationGames?['previousId'],
            ),
            const SizedBox(width: 12),
            _buildNavigationButton(
              isPrevious: false,
              gameId: _navigationData?['nextId'],
              game: _navigationGames?['nextId'],
            ),
          ],
        ),
      ],
    );
  }
}