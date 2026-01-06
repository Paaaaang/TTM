import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/post.dart';

class PostService {
  static const String _cacheKeyPrefix = 'posts_cache_';
  static const Duration _cacheDuration = Duration(hours: 1);

  // GET /api/posts/list - 게시�?목록 조회
  Future<List<PostListItem>> getPostsList({
    int page = 1,
    int limit = 10,
    String? category,
    int? memberId,
  }) async {
    try {
      // 캐시 ???�성
      final cacheKey =
          '${_cacheKeyPrefix}list_p${page}_l${limit}_c${category ?? 'all'}_m${memberId ?? 'all'}';

      // 캐시 ?�인
      final cachedData = await _getCachedData(cacheKey);
      if (cachedData != null) {
        return (cachedData as List)
            .map((item) => PostListItem.fromJson(item))
            .toList();
      }

      // API ?�출
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (category != null && category != '?�체') {
        queryParams['category'] = category;
      }
      if (memberId != null) {
        queryParams['member_id'] = memberId.toString();
      }

      final uri =
          Uri.parse('${ApiConstants.baseUrl}/api/posts/list').replace(
        queryParameters: queryParams,
      );

      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        final posts =
            jsonList.map((item) => PostListItem.fromJson(item)).toList();

        // 캐시 ?�??
        await _saveCacheData(cacheKey, jsonList);

        return posts;
      } else {
        // API ?�류 ??캐시 반환 (만료?�었?�도)
        final expiredCache = await _getCachedData(cacheKey, ignoreExpiry: true);
        if (expiredCache != null) {
          return (expiredCache as List)
              .map((item) => PostListItem.fromJson(item))
              .toList();
        }
        throw Exception('게시�?목록 조회 ?�패: ${response.statusCode}');
      }
    } catch (e) {
      // ?�트?�크 ?�류 ??캐시 반환
      final cacheKey =
          '${_cacheKeyPrefix}list_p${page}_l${limit}_c${category ?? 'all'}_m${memberId ?? 'all'}';
      final cachedData = await _getCachedData(cacheKey, ignoreExpiry: true);
      if (cachedData != null) {
        return (cachedData as List)
            .map((item) => PostListItem.fromJson(item))
            .toList();
      }
      throw Exception('게시�?목록 조회 ?�패: $e');
    }
  }

  // GET /api/posts/{post_id} - 게시�??�세 조회
  Future<Post> getPost(int postId) async {
    try {
      // 캐시 ??
      final cacheKey = '${_cacheKeyPrefix}detail_$postId';

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/posts/$postId');

      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        final post = Post.fromJson(jsonData);

        // 캐시 ?�??
        await _saveCacheData(cacheKey, jsonData);

        return post;
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 ???�습?�다');
      } else {
        throw Exception('게시�?조회 ?�패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('게시�?조회 ?�패: $e');
    }
  }

  // POST /api/posts/ - 게시�??�성
  Future<Post> createPost({
    required int memberId,
    required String category,
    required String title,
    required String content,
    List<Map<String, dynamic>>? images,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/posts/');

      final body = {
        'memberId': memberId,
        'category': category,
        'title': title,
        'content': content,
      };

      if (images != null && images.isNotEmpty) {
        body['images'] = images;
      }

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        final post = Post.fromJson(jsonData);

        // 목록 캐시 무효??
        await _invalidateListCache();

        return post;
      } else {
        throw Exception('게시�??�성 ?�패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('게시�??�성 ?�패: $e');
    }
  }

  // PUT /api/posts/{post_id} - 게시�??�정
  Future<Post> updatePost({
    required int postId,
    String? category,
    String? title,
    String? content,
    List<Map<String, dynamic>>? images,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/posts/$postId');

      final body = <String, dynamic>{};
      if (category != null) body['category'] = category;
      if (title != null) body['title'] = title;
      if (content != null) body['content'] = content;
      if (images != null) body['images'] = images;

      final response = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        final post = Post.fromJson(jsonData);

        // ?�세/목록 캐시 무효??
        await _invalidatePostCache(postId);
        await _invalidateListCache();

        return post;
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 ???�습?�다');
      } else {
        throw Exception('게시�??�정 ?�패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('게시�??�정 ?�패: $e');
    }
  }

  // DELETE /api/posts/{post_id} - 게시�???��
  Future<void> deletePost(int postId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/posts/$postId');

      final response = await http
          .delete(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        // ?�세/목록 캐시 무효??
        await _invalidatePostCache(postId);
        await _invalidateListCache();
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 ???�습?�다');
      } else {
        throw Exception('게시�???�� ?�패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('게시�???�� ?�패: $e');
    }
  }

  // GET /api/posts/search - 게시�?검??
  Future<List<PostListItem>> searchPosts({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // 검?��? 캐시?��? ?�음 (?�시간성 중요)
      final queryParams = {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri =
          Uri.parse('${ApiConstants.baseUrl}/api/posts/search').replace(
        queryParameters: queryParams,
      );

      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        return jsonList.map((item) => PostListItem.fromJson(item)).toList();
      } else {
        throw Exception('게시�?검???�패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('게시�?검???�패: $e');
    }
  }

  // POST /api/posts/{post_id}/like - 좋아??추�?
  Future<void> likePost(int postId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/posts/$postId/like');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        // ?�세/목록 캐시 무효??
        await _invalidatePostCache(postId);
        await _invalidateListCache();
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 ???�습?�다');
      } else {
        throw Exception('좋아??추�? ?�패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('좋아??추�? ?�패: $e');
    }
  }

  // DELETE /api/posts/{post_id}/like - 좋아??취소
  Future<void> unlikePost(int postId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/posts/$postId/like');

      final response = await http
          .delete(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        // ?�세/목록 캐시 무효??
        await _invalidatePostCache(postId);
        await _invalidateListCache();
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 ???�습?�다');
      } else {
        throw Exception('좋아??취소 ?�패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('좋아??취소 ?�패: $e');
    }
  }

  // 캐시 관???�퍼 메서??
  Future<dynamic> _getCachedData(String key,
      {bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(key);
      if (cachedJson == null) return null;

      final cachedData = json.decode(cachedJson);
      final timestamp = DateTime.parse(cachedData['timestamp']);

      if (!ignoreExpiry &&
          DateTime.now().difference(timestamp) > _cacheDuration) {
        return null;
      }

      return cachedData['data'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveCacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      await prefs.setString(key, json.encode(cacheData));
    } catch (e) {
      // 캐시 ?�???�패??무시
    }
  }

  Future<void> _invalidatePostCache(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKeyPrefix}detail_$postId';
      await prefs.remove(cacheKey);
    } catch (e) {
      // 무시
    }
  }

  Future<void> _invalidateListCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('${_cacheKeyPrefix}list_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // 무시
    }
  }
}

