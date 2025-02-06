// lib/widgets/game/game_header.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';

class GameHeader extends StatelessWidget {
  final Game game;

  const GameHeader({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  game.category,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Spacer(),
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 4),
              Text(
                game.rating.toString(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            game.summary,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          _buildMetaInfo(),
        ],
      ),
    );
  }

  Widget _buildMetaInfo() {
    return Row(
      children: [
        Icon(Icons.remove_red_eye_outlined, size: 16),
        SizedBox(width: 4),
        Text(
          '${game.viewCount} 次浏览',
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(width: 16),
        Icon(Icons.access_time, size: 16),
        SizedBox(width: 4),
        Text(
          '发布于 ${DateFormatter.format(game.createTime)}',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
class DateFormatter {
  static String format(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}