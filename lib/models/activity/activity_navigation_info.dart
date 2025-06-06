// lib/models/activity/activity_navigation_info.dart

import 'package:flutter/foundation.dart';


class ActivityNavigationInfo {
  final String? previousId;
  final String? previousTitle;
  final String? nextId;
  final String? nextTitle;

  const ActivityNavigationInfo({
    this.previousId,
    this.previousTitle,
    this.nextId,
    this.nextTitle,
  });

  factory ActivityNavigationInfo.fromJson(Map<String, dynamic> json) {
    String? getString(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        if (value.isEmpty || value.toLowerCase() == "null") {
          return null;
        }
        return value;
      }
      return value.toString();
    }

    return ActivityNavigationInfo(
      previousId: getString(json['previousId']),
      previousTitle: getString(json['previousTitle']),
      nextId: getString(json['nextId']),
      nextTitle: getString(json['nextTitle']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (previousId != null) map['previousId'] = previousId;
    if (previousTitle != null) map['previousTitle'] = previousTitle;
    if (nextId != null) map['nextId'] = nextId;
    if (nextTitle != null) map['nextTitle'] = nextTitle;
    return map;
  }

  ActivityNavigationInfo copyWith({
    ValueGetter<String?>? previousId,
    ValueGetter<String?>? previousTitle,
    ValueGetter<String?>? nextId,
    ValueGetter<String?>? nextTitle,
  }) {
    return ActivityNavigationInfo(
      previousId: previousId != null ? previousId() : this.previousId,
      previousTitle:
          previousTitle != null ? previousTitle() : this.previousTitle,
      nextId: nextId != null ? nextId() : this.nextId,
      nextTitle: nextTitle != null ? nextTitle() : this.nextTitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityNavigationInfo &&
          runtimeType == other.runtimeType &&
          previousId == other.previousId &&
          previousTitle == other.previousTitle &&
          nextId == other.nextId &&
          nextTitle == other.nextTitle;

  @override
  int get hashCode =>
      previousId.hashCode ^
      previousTitle.hashCode ^
      nextId.hashCode ^
      nextTitle.hashCode;

  @override
  String toString() {
    return 'ActivityNavigationInfo{previousId: $previousId, previousTitle: $previousTitle, nextId: $nextId, nextTitle: $nextTitle}';
  }

  bool get isEmpty =>
      previousId == null &&
      previousTitle == null &&
      nextId == null &&
      nextTitle == null;
  bool get isNotEmpty => !isEmpty;
}
