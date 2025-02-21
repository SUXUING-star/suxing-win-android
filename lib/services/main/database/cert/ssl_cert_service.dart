// lib/services/ssl_cert_service.dart

import 'package:flutter/services.dart';
import 'dart:io';

class SSLCertService {
  static final SSLCertService _instance = SSLCertService._internal();
  factory SSLCertService() => _instance;
  SSLCertService._internal();

  File? _tempCertFile;

  Future<String> setupClientCertificate() async {
    try {
      // 从assets加载证书
      final cert = await rootBundle.load('assets/certs/client.pem');
      final certBytes = cert.buffer.asUint8List();

      // 创建临时目录和文件
      final tempDir = await Directory.systemTemp.createTemp('mongodb_certs');
      _tempCertFile = File('${tempDir.path}/client.pem');
      await _tempCertFile!.writeAsBytes(certBytes);

      return _tempCertFile!.path;
    } catch (e) {
      print('SSL certificate setup error: $e');
      throw Exception('Failed to setup SSL certificate');
    }
  }

  Future<void> cleanup() async {
    try {
      if (_tempCertFile != null) {
        final tempDir = _tempCertFile!.parent;
        await tempDir.delete(recursive: true);
        _tempCertFile = null;
      }
    } catch (e) {
      print('SSL certificate cleanup error: $e');
    }
  }
}