// lib/models/common/pagination.dart

import 'package:suxingchahui/models/util_json.dart';

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
    int page = UtilJson.parseIntSafely(json['page']);
    int limit = UtilJson.parseIntSafely(json['limit']);
    int total = UtilJson.parseIntSafely(json['total']);

    // 处理 limit 字段：优先 'limit'，其次 'pageSize'，最后默认 20
    if (limit <= 0) {
      limit = UtilJson.parseIntSafely(json['pageSize']);
    }
    if (limit <= 0) {
      limit = 20; // 默认值
    }

    // 确保 total 不为负数
    if (total < 0) {
      total = 0;
    }

    // 计算总页数
    int finalPages;
    // 如果总条目为 0，总页数就是 0，优先级最高
    if (total == 0) {
      finalPages = 0;
    } else {
      // 根据总条目和每页限制计算页数
      int calculatedPages = (total / limit).ceil();

      // 从后端获取的页数（可能是 'pages' 或 'totalPages'）
      int pagesFromBackend = UtilJson.parseIntSafely(json['pages']);
      if (pagesFromBackend <= 0) {
        pagesFromBackend = UtilJson.parseIntSafely(json['totalPages']);
      }

      // 如果后端提供的页数有效且大于计算页数，则使用后端值，否则使用计算值
      if (pagesFromBackend > 0 && pagesFromBackend > calculatedPages) {
        finalPages = pagesFromBackend;
      } else {
        finalPages = calculatedPages;
      }
    }

    // 修正当前页码
    if (page < 1) page = 1; // 页码不能小于 1
    if (finalPages > 0 && page > finalPages) {
      page = finalPages; // 页码不能超过总页数（如果总页数大于 0）
    }
    // 如果总条目为 0 且当前页码大于 1，则重置为 1
    if (total == 0 && page > 1) {
      page = 1;
    }

    return PaginationData(
      page: page,
      limit: limit,
      total: total,
      pages: finalPages,
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
