// lib/services/update_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class UpdateService extends ChangeNotifier {
  bool _isChecking = false;
  String? _latestVersion;
  String? _currentVersion;
  String? _updateUrl;
  bool _updateAvailable = false;
  bool _forceUpdate = false;
  String? _updateMessage;
  List<String>? _changelog;

  bool get isChecking => _isChecking;
  bool get updateAvailable => _updateAvailable;
  bool get forceUpdate => _forceUpdate;
  String? get latestVersion => _latestVersion;
  String? get updateUrl => _updateUrl;
  String? get updateMessage => _updateMessage;
  List<String>? get changelog => _changelog;

  Future<void> checkForUpdates() async {
    if (_isChecking) return;

    try {
      _isChecking = true;
      notifyListeners();

      // 获取当前版本
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      print("当前版本: $_currentVersion");

      final githubName = AppConfig.githubName;
      final reponame = AppConfig.repoName;

      // 检查 GitHub Release
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubName/$reponame/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = data['tag_name'].toString().replaceAll('v', '');
        _updateUrl = data['html_url'];

        // 解析 body 中的自定义字段
        // 在 GitHub Release 的描述中使用特定格式:
        // [force_update: true/false]
        // [update_message: 这是一个重要更新，请立即更新]
        // [changelog]
        // - 修复了xxx问题
        // - 新增了xxx功能
        // [/changelog]
        final body = data['body'] as String? ?? '';

        // 解析强制更新标记
        final forceUpdateMatch = RegExp(r'\[force_update:\s*(true|false)\]')
            .firstMatch(body);
        _forceUpdate = forceUpdateMatch?.group(1) == 'true';

        // 解析更新消息
        final messageMatch = RegExp(r'\[update_message:\s*(.*?)\]')
            .firstMatch(body);
        _updateMessage = messageMatch?.group(1)?.trim();

        // 解析更新日志
        final changelogMatch = RegExp(r'\[changelog\]([\s\S]*?)\[/changelog\]')
            .firstMatch(body);
        if (changelogMatch != null) {
          _changelog = changelogMatch.group(1)
              ?.split('\n')
              .map((line) => line.trim())
              .where((line) => line.startsWith('-'))
              .map((line) => line.substring(1).trim())
              .toList();
        }

        print("最新版本: $_latestVersion");
        // 比较版本号
        _updateAvailable = _compareVersions(_currentVersion!, _latestVersion!);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  bool _compareVersions(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}