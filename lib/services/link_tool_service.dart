// lib/services/link_tool_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/linkstools/link.dart';
import '../models/linkstools/tool.dart';
import 'db_connection_service.dart';
import 'cache/links_tools_cache_service.dart';

// lib/services/link_tool_service.dart

class LinkToolService {
  static final LinkToolService _instance = LinkToolService._internal();
  factory LinkToolService() => _instance;

  final DBConnectionService _dbConnectionService = DBConnectionService();
  final LinksToolsCacheService _cache = LinksToolsCacheService();

  LinkToolService._internal();

  // Links
  Stream<List<Link>> getLinks() async* {
    try {
      while (true) {
        // 首先尝试从缓存获取
        final cachedLinks = await _cache.getLinks();
        if (cachedLinks != null) {
          yield cachedLinks;
        } else {
          // 如果缓存中没有，从数据库获取
          final links = await _dbConnectionService.links
              .find(where.eq('isActive', true).sortBy('order'))
              .map((doc) => Link.fromJson(_dbConnectionService.convertDocument(doc)))
              .toList();

          // 存入缓存
          await _cache.setLinks(links);
          yield links;
        }
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
      linkDoc.remove('_id');
      linkDoc['createTime'] = DateTime.now();
      await _dbConnectionService.links.insertOne(linkDoc);
      // 清除缓存
      await _cache.clearCache();
    } catch (e) {
      print('Add link error: $e');
      rethrow;
    }
  }

  Future<void> updateLink(Link link) async {
    try {
      final linkDoc = link.toJson();
      linkDoc.remove('_id');
      linkDoc['updateTime'] = DateTime.now();
      linkDoc.remove('createTime');

      await _dbConnectionService.links.updateOne(
        where.eq('_id', ObjectId.fromHexString(link.id)),
        {r'$set': linkDoc},
      );

      // 清除缓存
      await _cache.clearCache();
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
      // 清除缓存
      await _cache.clearCache();
    } catch (e) {
      print('Delete link error: $e');
      rethrow;
    }
  }

  // Tools
  Stream<List<Tool>> getTools() async* {
    try {
      while (true) {
        // 首先尝试从缓存获取
        final cachedTools = await _cache.getTools();
        if (cachedTools != null) {
          yield cachedTools;
        } else {
          // 如果缓存中没有，从数据库获取
          final tools = await _dbConnectionService.tools
              .find(where.eq('isActive', true).sortBy('createTime', descending: true))
              .map((doc) => Tool.fromJson(_dbConnectionService.convertDocument(doc)))
              .toList();

          // 存入缓存
          await _cache.setTools(tools);
          yield tools;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Get tools error: $e');
      yield [];
    }
  }

  Future<void> addTool(Tool tool) async {
    try {
      final toolDoc = {
        '_id': ObjectId.fromHexString(tool.id),
        'name': tool.name,
        'description': tool.description,
        'color': tool.color,
        'icon': tool.icon,
        'type': tool.type,
        'downloads': tool.downloads.map((download) => {
          'name': download.name,
          'description': download.description,
          'url': download.url,
        }).toList(),
        'createTime': DateTime.now(),
        'isActive': tool.isActive,
      };

      await _dbConnectionService.tools.insertOne(toolDoc);
      // 清除缓存
      await _cache.clearCache();
    } catch (e) {
      print('Add tool error: $e');
      rethrow;
    }
  }
  Future<void> updateTool(Tool tool) async {
    try {
      final toolDoc = {
        'name': tool.name,
        'description': tool.description,
        'color': tool.color,
        'icon': tool.icon,
        'type': tool.type,
        'downloads': tool.downloads.map((download) => {
          'name': download.name,
          'description': download.description,
          'url': download.url,
        }).toList(),
        'isActive': tool.isActive,
        'updateTime': DateTime.now(),
      };

      await _dbConnectionService.tools.updateOne(
        where.eq('_id', ObjectId.fromHexString(tool.id)),
        {r'$set': toolDoc},
      );

      // 清除缓存
      await _cache.clearCache();
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
      // 清除缓存
      await _cache.clearCache();
    } catch (e) {
      print('Delete tool error: $e');
      rethrow;
    }
  }
}