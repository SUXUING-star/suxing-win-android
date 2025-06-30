// lib/models/common/to_json_extension.dart

// 接口，用于 toJson 扩展
abstract class ToJsonExtension {
  Map<String, dynamic> toJson();
}

extension ListToJsonExtension<T extends ToJsonExtension> on List<T> {
  List<Map<String, dynamic>> toListJson() {
    return map((item) => item.toJson()).toList();
  }
}




