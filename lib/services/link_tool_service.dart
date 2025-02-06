// lib/services/link_tool_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/link.dart';
import '../models/tool.dart';
import 'db_connection_service.dart';

class LinkToolService {
  static final LinkToolService _instance = LinkToolService._internal();
  factory LinkToolService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();

  LinkToolService._internal();

  // Links
  Stream<List<Link>> getLinks() async* {
    try {
      while (true) {
        final links = await _dbConnectionService.links
            .find(where.eq('isActive', true).sortBy('order'))
            .map((doc) => Link.fromJson(_dbConnectionService.convertDocument(doc)))
            .toList();
        yield links;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get links error: $e');
      yield [];
    }
  }

  Future<void> addLink(Link link) async {
    try {
      final linkDoc = link.toJson();
      linkDoc.remove('_id');  // 移除id，让MongoDB自动生成
      linkDoc['createTime'] = DateTime.now();
      await _dbConnectionService.links.insertOne(linkDoc);
    } catch (e) {
      print('Add link error: $e');
      rethrow;
    }
  }

  Future<void> updateLink(Link link) async {
    try {
      final linkDoc = link.toJson();
      // 移除 _id 字段，因为 MongoDB 更新操作中不能包含 _id
      linkDoc.remove('_id');

      // 保存更新时间
      linkDoc['updateTime'] = DateTime.now();

      // 确保不覆盖原始的创建时间
      linkDoc.remove('createTime');

      await _dbConnectionService.links.updateOne(
        where.eq('_id', ObjectId.fromHexString(link.id)),
        {r'$set': linkDoc},
      );

      // 打印更新操作的结果，用于调试
      print('Update link document: $linkDoc');
    } catch (e) {
      print('Update link error: $e');
      rethrow;
    }
  }

  Future<void> deleteLink(String id) async {
    try {
      await _dbConnectionService.links.deleteOne(
        where.eq('_id', ObjectId.fromHexString(id)),
      );
    } catch (e) {
      print('Delete link error: $e');
      rethrow;
    }
  }

  // Tools
  Stream<List<Tool>> getTools() async* {
    try {
      while (true) {
        final tools = await _dbConnectionService.tools
            .find(where.eq('isActive', true).sortBy('createTime', descending: true))
            .map((doc) => Tool.fromJson(_dbConnectionService.convertDocument(doc)))
            .toList();
        yield tools;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get tools error: $e');
      yield [];
    }
  }

  Future<void> addTool(Tool tool) async {
    try {
      final toolDoc = tool.toJson();
      toolDoc.remove('_id');  // 移除id，让MongoDB自动生成
      toolDoc['createTime'] = DateTime.now();
      await _dbConnectionService.tools.insertOne(toolDoc);
    } catch (e) {
      print('Add tool error: $e');
      rethrow;
    }
  }

  Future<void> updateTool(Tool tool) async {
    try {
      final toolDoc = tool.toJson();
      // 移除id，不更新
      toolDoc.remove("_id");

      // 获取原始工具数据，保留 createTime
      final originalToolDoc = await _dbConnectionService.tools.findOne(
          where.eq('_id', ObjectId.fromHexString(tool.id))
      );

      // 如果找到原始数据，保留原始的 createTime
      if (originalToolDoc != null) {
        toolDoc['createTime'] = originalToolDoc['createTime'];
      }

      await _dbConnectionService.tools.updateOne(
        where.eq('_id', ObjectId.fromHexString(tool.id)),
        {r'$set': toolDoc},
      );
    } catch (e) {
      print('Update tool error: $e');
      rethrow;
    }
  }

  Future<void> deleteTool(String id) async {
    try {
      await _dbConnectionService.tools.deleteOne(
        where.eq('_id', ObjectId.fromHexString(id)),
      );
    } catch (e) {
      print('Delete tool error: $e');
      rethrow;
    }
  }
}