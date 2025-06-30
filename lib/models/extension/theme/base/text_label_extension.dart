// lib/models/extension/theme/base/text_label_extension.dart

abstract class TextLabelExtension {
  String getTextLabel();
}

extension EasilyGetTextLabelExtension<T extends TextLabelExtension> on T {
  String get textLabel => getTextLabel();
}
