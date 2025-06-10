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

  // --- 新增：创建空实例的方法 ---
  /// 返回一个表示空数据的分页实例。
  static PaginationData empty() {
    return PaginationData(page: 1, limit: 0, total: 0, pages: 0);
  }

  /// 在后端未提供分页信息时，根据给定的项目列表和当前页码来创建分页数据。
  static PaginationData fromItemList(
    List<dynamic> items,
    int currentPage, {
    int pageSize = 20, // 提供一个默认的页面大小
  }) {
    final totalItems = items.length;
    final limit = pageSize > 0 ? pageSize : 20;
    final totalPages = (totalItems == 0) ? 0 : (totalItems / limit).ceil();

    return PaginationData(
      page: currentPage,
      limit: limit,
      total: totalItems,
      pages: totalPages,
    );
  }

  factory PaginationData.fromJson(Map<String, dynamic> json) {
    int pageValue = (json['page'] as num?)?.toInt() ?? 1;

    int limitValue;
    if (json.containsKey('limit') && json['limit'] != null) {
      limitValue = (json['limit'] as num).toInt();
    } else if (json.containsKey('pageSize') && json['pageSize'] != null) {
      limitValue = (json['pageSize'] as num).toInt();
    } else {
      limitValue = 20;
    }
    if (limitValue <= 0) limitValue = 1;

    int totalValue = (json['total'] as num?)?.toInt() ?? 0;
    if (totalValue < 0) totalValue = 0;

    int calculatedPagesBasedOnTotalAndLimit =
        (totalValue <= 0 || limitValue <= 0)
            ? 1
            : (totalValue / limitValue).ceil();

    int? backendProvidedTotalPages;
    if (json.containsKey('pages') && json['pages'] != null) {
      backendProvidedTotalPages = (json['pages'] as num).toInt();
    } else if (json.containsKey('totalPages') && json['totalPages'] != null) {
      backendProvidedTotalPages = (json['totalPages'] as num).toInt();
    }

    int finalTotalPages;
    if (backendProvidedTotalPages != null) {
      finalTotalPages =
          backendProvidedTotalPages < calculatedPagesBasedOnTotalAndLimit
              ? calculatedPagesBasedOnTotalAndLimit
              : backendProvidedTotalPages;
      if (totalValue == 0 && backendProvidedTotalPages == 0) {
        finalTotalPages = 0;
      }
    } else {
      finalTotalPages = calculatedPagesBasedOnTotalAndLimit;
      if (totalValue == 0) {
        finalTotalPages = 0;
      }
    }

    if (pageValue < 1) pageValue = 1;
    if (finalTotalPages > 0 && pageValue > finalTotalPages) {
      pageValue = finalTotalPages;
    }
    if (finalTotalPages == 0 && pageValue > 1 && totalValue == 0) {
      pageValue = 1;
    }

    return PaginationData(
      page: pageValue,
      limit: limitValue,
      total: totalValue,
      pages: finalTotalPages,
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

  PaginationData copyWith({
    int? page,
    int? limit,
    int? total,
    int? pages,
  }) {
    int newTotal = total ?? this.total;
    int newLimit = limit ?? this.limit;
    int newPages = pages ?? this.pages;

    if (pages == null && (total != null || limit != null)) {
      if (newTotal <= 0 || newLimit <= 0) {
        newPages = (newTotal == 0) ? 0 : 1;
      } else {
        newPages = (newTotal / newLimit).ceil();
      }
    }

    int newCurrentPage = page ?? this.page;
    if (newPages > 0 && newCurrentPage > newPages) {
      newCurrentPage = newPages;
    } else if (newPages == 0 && newCurrentPage > 1 && newTotal == 0) {
      newCurrentPage = 1;
    }
    if (newCurrentPage < 1) newCurrentPage = 1;

    return PaginationData(
      page: newCurrentPage,
      limit: newLimit,
      total: newTotal,
      pages: newPages,
    );
  }

  bool hasNextPage() {
    return page < pages;
  }

  bool hasPreviousPage() {
    return page > 1;
  }
}
