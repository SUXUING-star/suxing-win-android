// lib/models/common/pagination.dart

class PaginationData {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationData({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) {
    // 计算 pages，防止后端不提供或提供错误
    int limit = (json['limit'] as num?)?.toInt() ?? 20;
    int total = (json['total'] as num?)?.toInt() ?? 0;
    int calculatedPages = (total <= 0 || limit <= 0) ? 1 : (total / limit).ceil();
    // 优先使用后端提供的 pages，但如果它不合理（比如比计算出来的小），则使用计算值
    int backendPages = (json['pages'] as num?)?.toInt() ?? calculatedPages;

    return PaginationData(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: limit,
      total: total,
      // 如果后端提供的 pages 比计算的小（不合理），用计算的，否则用后端的
      pages: backendPages < calculatedPages ? calculatedPages : backendPages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'pages': pages,
    };
  }

  /// 创建此 PaginationData 对象的一个副本，但用提供的值替换指定的字段。
  PaginationData copyWith({
    int? page,
    int? limit,
    int? total,
    int? pages,
  }) {
    // 基本的复制，不重新计算 pages
    int newTotal = total ?? this.total;
    int newLimit = limit ?? this.limit;
    int newPages = pages ?? this.pages;

    // 可选：如果 total 或 limit 改变，可以重新计算 pages
    // 如果 pages 没有被显式提供，并且 total 或 limit 改变了，则重新计算
    if (pages == null && (total != null || limit != null)) {
      newPages = (newTotal <= 0 || newLimit <= 0) ? 1 : (newTotal / newLimit).ceil();
    }


    return PaginationData(
      page: page ?? this.page,
      limit: newLimit,
      total: newTotal,
      pages: newPages, // 使用计算或提供的新页数
    );
  }



  bool hasNextPage() {
    return page < pages;
  }

  bool hasPreviousPage() {
    return page > 1;
  }
}