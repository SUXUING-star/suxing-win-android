// lib/models/stats/category_stat.dart

import 'package:meta/meta.dart';

@immutable
class CategoryStat {
  final String name;
  final int count;

  const CategoryStat({
    required this.name,
    required this.count,
  });
}