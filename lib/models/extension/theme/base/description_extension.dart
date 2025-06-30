// lib/models/extension/theme/base/description_extension.dart

abstract class DescriptionExtension {
  String getDescription();
}

extension EasilyGetDescriptionExtension<T extends DescriptionExtension> on T {
  String get description => getDescription();
}
