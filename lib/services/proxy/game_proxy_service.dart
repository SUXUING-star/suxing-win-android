// lib/services/proxy/game_proxy_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/game/game.dart';
import '../../config/app_config.dart';

class GameProxyService {
  final String _baseUrl = AppConfig.redisProxyUrl;
  final _headers = {'Content-Type': 'application/json'};

  Future<List<Game>> findGames({
    Map<String, dynamic>? query,
    Map<String, dynamic>? sort,
    int? skip,
    int? limit
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/db/find/games'),
        headers: _headers,
        body: jsonEncode({
          'query': query ?? {},
          'options': {
            if (sort != null) 'sort': sort,
            if (skip != null) 'skip': skip,
            if (limit != null) 'limit': limit,
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch games: ${response.body}');
      }

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((game) => Game.fromJson(game)).toList();
    } catch (e) {
      print('GameProxyService findGames error: $e');
      rethrow;
    }
  }

  Future<Game?> findOne(Map<String, dynamic> query) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/db/findOne/games'),
        headers: _headers,
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch game: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data != null ? Game.fromJson(data) : null;
    } catch (e) {
      print('GameProxyService findOne error: $e');
      rethrow;
    }
  }

  Future<String> insertGame(Map<String, dynamic> gameDoc) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/db/insertOne/games'),
        headers: _headers,
        body: jsonEncode({'document': gameDoc}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to insert game: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['id'];
    } catch (e) {
      print('GameProxyService insertGame error: $e');
      rethrow;
    }
  }

  Future<void> updateGame(String id, Map<String, dynamic> update) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/db/updateOne/games'),
        headers: _headers,
        body: jsonEncode({
          'filter': {'_id': id},
          'update': {'\$set': update}
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update game: ${response.body}');
      }
    } catch (e) {
      print('GameProxyService updateGame error: $e');
      rethrow;
    }
  }

  Future<void> deleteGame(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/db/deleteOne/games'),
        headers: _headers,
        body: jsonEncode({
          'filter': {'_id': id}
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete game: ${response.body}');
      }
    } catch (e) {
      print('GameProxyService deleteGame error: $e');
      rethrow;
    }
  }

  Future<int> count([Map<String, dynamic>? query]) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/db/count/games'),
        headers: _headers,
        body: jsonEncode({'query': query ?? {}}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get count: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['count'];
    } catch (e) {
      print('GameProxyService count error: $e');
      return 0;
    }
  }

  Future<List<Game>> aggregate(List<Map<String, dynamic>> pipeline) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/db/aggregate/games'),
        headers: _headers,
        body: jsonEncode({'pipeline': pipeline}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to aggregate games: ${response.body}');
      }

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((game) => Game.fromJson(game)).toList();
    } catch (e) {
      print('GameProxyService aggregate error: $e');
      rethrow;
    }
  }
}