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
    int pageValue = (json['page'] as num?)?.toInt() ?? 1;

    int limitValue;
    // 优先用 'limit'，其次 'pageSize'
    if (json.containsKey('limit') && json['limit'] != null) {
      limitValue = (json['limit'] as num).toInt();
    } else if (json.containsKey('pageSize') && json['pageSize'] != null) {
      limitValue = (json['pageSize'] as num).toInt();
    } else {
      limitValue = 20; // 默认值
    }
    // 确保 limit 至少为1，避免计算错误
    if (limitValue <= 0) limitValue = 1;

    int totalValue = (json['total'] as num?)?.toInt() ?? 0;
    if (totalValue < 0) totalValue = 0; // 总数不能为负

    // 根据 total 和 limit 计算出的页数
    // 沿用你的逻辑：如果 total <= 0，则 calculatedPages = 1 (除非后端明确说0页)
    int calculatedPagesBasedOnTotalAndLimit =
        (totalValue <= 0 || limitValue <= 0)
            ? 1
            : (totalValue / limitValue).ceil();

    int? backendProvidedTotalPages;
    // 优先用 'pages'，其次 'totalPages'
    if (json.containsKey('pages') && json['pages'] != null) {
      backendProvidedTotalPages = (json['pages'] as num).toInt();
    } else if (json.containsKey('totalPages') && json['totalPages'] != null) {
      backendProvidedTotalPages = (json['totalPages'] as num).toInt();
    }

    int finalTotalPages;
    if (backendProvidedTotalPages != null) {
      // 如果后端提供了总页数，使用你的比较逻辑
      finalTotalPages =
          backendProvidedTotalPages < calculatedPagesBasedOnTotalAndLimit
              ? calculatedPagesBasedOnTotalAndLimit
              : backendProvidedTotalPages;
      // 特殊情况：如果总项目数为0，且后端明确告知总页数为0，则采纳0
      if (totalValue == 0 && backendProvidedTotalPages == 0) {
        finalTotalPages = 0;
      }
    } else {
      // 如果后端未提供总页数，使用计算值
      finalTotalPages = calculatedPagesBasedOnTotalAndLimit;
      // 如果总项目数为0，计算出的页数可能是1，修正为0更合理
      if (totalValue == 0) {
        finalTotalPages = 0;
      }
    }

    // 确保当前页码在有效范围内
    if (pageValue < 1) pageValue = 1;
    if (finalTotalPages > 0 && pageValue > finalTotalPages) {
      pageValue = finalTotalPages;
    }
    // 如果总页数是0 (通常意味着没有数据)，当前页码通常是1
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
      'limit': limit, // 对外统一用 'limit'
      'total': total,
      'pages': pages, // 对外统一用 'pages'
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
        newPages = (newTotal == 0) ? 0 : 1; // 如果总数为0，则页数为0，否则至少1页
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
