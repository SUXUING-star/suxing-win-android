import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';

class EnrichCollapseMode implements IconDataExtension, TextLabelExtension {
  static const String all = 'all';

  static const String byUser = 'byUser';

  static const String byType = 'byType';

  final String mode;

  const EnrichCollapseMode({
    required this.mode,
  });

  factory EnrichCollapseMode.fromType(String type) =>
      EnrichCollapseMode(mode: type);

  @override
  String getTextLabel() => getCollapseModeText(mode);

  @override
  IconData getIconData() => getCollapseModeIcon(mode);

  /// Gets the display text for the current collapse mode.
  static String getCollapseModeText(String type) {
    switch (type) {
      case all:
        return '标准视图';
      case byType:
        return '按类型折叠';
      case byUser:
        return '按用户折叠';
      default:
        return '标准视图'; // Fallback
    }
  }

  /// Gets the icon for the current collapse mode.
  static IconData getCollapseModeIcon(String type) {
    switch (type) {
      case all:
        return Icons.view_agenda_outlined; // Use outlined icons for consistency
      case byType:
        return Icons.category_outlined;
      case byUser:
        return Icons.person_outline;
      default:
        return Icons.view_agenda_outlined; // Fallback
    }
  }

  bool get isAll => mode == all;

  bool get isByUser => mode == byUser;

  bool get isByType => mode == byType;

  static getNextMode(String type) {
    switch (type) {
      case all:
        return byType; // Use outlined icons for consistency
      case byType:
        return byUser;
      case byUser:
        return all;
      default:
        return all; // Fallback
    }
  }

  String get nextMode => getNextMode(mode);

  EnrichCollapseMode get nextEnrichMode =>
      EnrichCollapseMode.fromType(getNextMode(mode));

  static const enrichAll = EnrichCollapseMode(mode: all);
  static const enrichUser = EnrichCollapseMode(mode: byUser);
  static const enrichType = EnrichCollapseMode(mode: byType);
}
