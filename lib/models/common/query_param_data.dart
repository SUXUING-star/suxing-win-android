// lib/models/common/query_param_data.dart

/// 该文件定义了通用的筛选和分页数据模型。
/// [QueryParamData] 用于封装 API 请求中常见的分页和排序参数。
library;

import 'package:suxingchahui/models/utils/util_json.dart';

/// [QueryParamData] 类：通用筛选和分页数据模型。
///
/// 用于构建和序列化 API 请求中的分页和排序参数。
class QueryParamData {
  static const String jsonKeyQuery = 'q';
  static const String jsonKeyCategory = 'category';
  static const String jsonKeyTag = 'tag';
  static const String jsonKeyAuthorId = 'authorId';
  static const String jsonKeyPage = 'page';
  static const String jsonKeyLimit = 'limit';
  static const String jsonKeyUser = 'user';
  static const String jsonKeyPageSize = 'pageSize';
  static const String jsonKeySortBy = 'sortBy';
  static const String jsonKeySortDesc = 'sortDesc';
  static const String jsonKeyDescending = 'descending';

  /// 当前页码，默认为 1。
  final int page;

  /// 每页大小，默认为 10。
  final int pageSize;

  /// 排序字段。
  final String? sortBy;

  /// 是否降序排序，默认为 true。
  final bool sortDesc;

  final String? filter;

  /// 构造函数。
  const QueryParamData({
    this.page = 1,
    this.pageSize = 10,
    this.sortBy,
    this.sortDesc = true,
    this.filter,
  });

  /// 从 JSON 对象创建 `FilterData` 实例。
  ///
  /// 该工厂构造函数使用 UtilJson 进行安全解析，并智能处理 `pageSize` 和 `descending` 字段，
  /// 兼容多种常见的 JSON key。
  factory QueryParamData.fromJson(Map<String, dynamic> json) {
    return QueryParamData(
        page: UtilJson.parseIntSafely(json[jsonKeyPage]),
        pageSize:
            UtilJson.parseIntSafely(json[jsonKeyPage] ?? json[jsonKeyLimit]),
        sortBy: UtilJson.parseNullableStringSafely(json[jsonKeySortBy]),
        sortDesc: UtilJson.parseBoolSafely(
          json[jsonKeyDescending] ?? json[jsonKeySortDesc],
          defaultValue: true,
        ),
        filter: UtilJson.parseNullableStringSafely(json[jsonKeyAuthorId] ??
            json[jsonKeyQuery] ??
            json[jsonKeyTag] ??
            json[jsonKeyCategory]));
  }

  /// 将 `FilterData` 实例转换为 JSON 对象。
  ///
  /// 该方法允许自定义分页大小和排序方向的 JSON key，以提供最大的灵活性。
  ///
  Map<String, dynamic> toJson({
    String limitJsonKeyName = jsonKeyPageSize,
    String descendingJsonKeyName = jsonKeySortDesc,
  }) {
    final Map<String, dynamic> data = {
      jsonKeyPage: page,
      limitJsonKeyName: pageSize,
      descendingJsonKeyName: sortDesc,
    };

    if (sortBy != null && sortBy!.isNotEmpty) {
      data[jsonKeySortBy] = sortBy;
    }
    if (filter != null && filter!.isNotEmpty) {
      data[jsonKeySortBy] = sortBy;
    }

    return data;
  }

  /// 创建一个新的 `FilterData` 实例，并根据提供的参数进行更新。
  QueryParamData copyWith({
    int? page,
    int? pageSize,
    String? sortBy,
    bool? sortDesc,
  }) {
    return QueryParamData(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortDesc: sortDesc ?? this.sortDesc,
    );
  }

  @override
  String toString() {
    return 'FilterData($jsonKeyPage: $page, $jsonKeyPageSize: $pageSize, $jsonKeySortBy: $sortBy, $jsonKeySortDesc: $sortDesc)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QueryParamData &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.sortBy == sortBy &&
        other.sortDesc == sortDesc;
  }

  @override
  int get hashCode {
    return page.hashCode ^
        pageSize.hashCode ^
        sortBy.hashCode ^
        sortDesc.hashCode;
  }
}
