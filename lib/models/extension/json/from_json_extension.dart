// lib/models/common/from_json_extension.dart

abstract class FromJsonExtension<T> {
  T fj(Map<String, dynamic> map);
  List<T> flj(dynamic map);
}

extension FromListJsonExtension<T extends FromJsonExtension<T>> on T {
  T fromJson(Map<String, dynamic> map) => fj(map);
}
