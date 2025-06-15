/// lib/models/common/filter.dart

/// 该文件定义了通用的筛选和分页数据模型。
/// FilterData 用于封装 API 请求中常见的分页和排序参数。
library;

import 'package:suxingchahui/models/util_json.dart';

/// `FilterData` 类：通用筛选和分页数据模型。
///
/// 用于构建和序列化 API 请求中的分页和排序参数。
class FilterData {
  /// 当前页码，默认为 1。
  final int page;

  /// 每页大小，默认为 10。
  final int pageSize;

  /// 排序字段。
  final String? sortBy;

  /// 是否降序排序，默认为 true。
  final bool descending;

  /// 构造函数。
  const FilterData({
    this.page = 1,
    this.pageSize = 10,
    this.sortBy,
    this.descending = true,
  });

  /// 从 JSON 对象创建 `FilterData` 实例。
  ///
  /// 该工厂构造函数使用 UtilJson 进行安全解析，并智能处理 `pageSize` 和 `descending` 字段，
  /// 兼容多种常见的 JSON key。
  factory FilterData.fromJson(Map<String, dynamic> json) {
    return FilterData(
      page: UtilJson.parseIntSafely(json['page']),
      pageSize: UtilJson.parseIntSafely(json['pageSize'] ?? json['limit']),
      sortBy: UtilJson.parseNullableStringSafely(json['sortBy']),
      descending: UtilJson.parseBoolSafely(
        json['descending'] ?? json['sortDesc'],
        defaultValue: true,
      ),
    );
  }

  /// 将 `FilterData` 实例转换为 JSON 对象。
  ///
  /// 该方法允许自定义分页大小和排序方向的 JSON key，以提供最大的灵活性。
  ///
  Map<String, dynamic> toJson({
    String limitJsonKeyName = 'pageSize',
    String descendingJsonKeyName = 'sortDesc',
  }) {
    final Map<String, dynamic> data = {
      'page': page,
      limitJsonKeyName: pageSize,
      descendingJsonKeyName: descending, // --- 使用参数化的 key ---
    };

    if (sortBy != null && sortBy!.isNotEmpty) {
      data['sortBy'] = sortBy;
    }
    return data;
  }

  /// 创建一个新的 `FilterData` 实例，并根据提供的参数进行更新。
  FilterData copyWith({
    int? page,
    int? pageSize,
    String? sortBy,
    bool? descending,
  }) {
    return FilterData(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
    );
  }

  @override
  String toString() {
    return 'FilterData(page: $page, pageSize: $pageSize, sortBy: $sortBy, descending: $descending)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FilterData &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.sortBy == sortBy &&
        other.descending == descending;
  }

  @override
  int get hashCode {
    return page.hashCode ^
        pageSize.hashCode ^
        sortBy.hashCode ^
        descending.hashCode;
  }
}
