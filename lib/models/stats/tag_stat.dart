// lib/models/stats/tag_stat.dart

import 'package:meta/meta.dart';

@immutable
class TagStat {
  final String name;
  final int count;

  const TagStat({
    required this.name,
    required this.count,
  });
}