import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostService {
  static const String _cacheKeyPrefix = 'posts_cache_';
  static const Duration _cacheDuration = Duration(hours: 1);

  // GET /api/posts/list - 게시글 목록 조회
  Future<List<PostListItem>> getPostsList({
    int page = 1,
    int limit = 10,
    String? category,
    int? memberId,
    int? currentMemberId,
    bool likedOnly = false,
    bool forceRefresh = false,
  }) async {
    if (likedOnly && currentMemberId == null) {
      throw Exception('likedOnly를 사용하려면 currentMemberId가 필요합니다');
    }

    final effectiveLimit = limit > 50 ? 50 : limit;
    final useCache =
        !forceRefresh && memberId == null && currentMemberId == null && !likedOnly;
    final cacheKey = useCache
        ? '${_cacheKeyPrefix}list_p${page}_l${effectiveLimit}_c${category ?? 'all'}_m${memberId ?? 'all'}_cm${currentMemberId ?? 'none'}_liked${likedOnly ? 1 : 0}'
        : null;

    try {
      if (useCache && cacheKey != null) {
        final cachedData = await _getCachedData(cacheKey);
        if (cachedData != null) {
          return (cachedData as List)
              .map((item) => PostListItem.fromJson(item))
              .toList();
        }
      }

      // API 호출
      final queryParams = {
        'page': page.toString(),
        'limit': effectiveLimit.toString(),
      };
      if (category != null && category != '전체') {
        queryParams['category'] = category;
      }
      if (memberId != null) {
        queryParams['member_id'] = memberId.toString();
      }
      if (currentMemberId != null) {
        queryParams['current_member_id'] = currentMemberId.toString();
      }
      if (likedOnly) {
        queryParams['liked_only'] = 'true';
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/posts/list',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final posts = jsonList
            .map((item) => PostListItem.fromJson(item))
            .toList();

        if (useCache && cacheKey != null) {
          await _saveCacheData(cacheKey, jsonList);
        }

        return posts;
      } else {
        // API 오류 시 캐시 반환 (만료되었어도)
        if (useCache && cacheKey != null) {
          final expiredCache = await _getCachedData(cacheKey, ignoreExpiry: true);
          if (expiredCache != null) {
            return (expiredCache as List)
                .map((item) => PostListItem.fromJson(item))
                .toList();
          }
        }
        throw Exception('게시글 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 네트워크 오류 시 캐시 반환
      if (useCache && cacheKey != null) {
        final cachedData = await _getCachedData(cacheKey, ignoreExpiry: true);
        if (cachedData != null) {
          return (cachedData as List)
              .map((item) => PostListItem.fromJson(item))
              .toList();
        }
      }
      throw Exception('게시글 목록 조회 실패: $e');
    }
  }

  // GET /api/posts/{post_id} - 게시글 상세 조회
  Future<Post> getPost(int postId, {int? currentMemberId}) async {
    try {
      // 캐시 키
      final cacheKey = '${_cacheKeyPrefix}detail_$postId';

      final queryParams = <String, String>{};
      if (currentMemberId != null) {
        queryParams['current_member_id'] = currentMemberId.toString();
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/posts/$postId',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        final post = Post.fromJson(jsonData);

        // 캐시 저장
        await _saveCacheData(cacheKey, jsonData);

        return post;
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 수 없습니다');
      } else {
        throw Exception('게시글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('게시글 조회 실패: $e');
    }
  }

  // POST /api/posts/ - 게시글 작성
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

      print('게시글 작성 요청: ${json.encode(body)}'); // 디버깅용

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(ApiConstants.timeout);

      print('게시글 작성 응답: ${response.statusCode}'); // 디버깅용
      print('응답 본문: ${response.body}'); // 디버깅용

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        final post = Post.fromJson(jsonData);

        // 목록 캐시 무효화
        await _invalidateListCache();

        return post;
      } else {
        throw Exception('게시글 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('게시글 작성 오류: $e'); // 디버깅용
      throw Exception('게시글 작성 실패: $e');
    }
  }

  // PUT /api/posts/{post_id} - 게시글 수정
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

        // 상세/목록 캐시 무효화
        await _invalidatePostCache(postId);
        await _invalidateListCache();

        return post;
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 수 없습니다');
      } else {
        throw Exception('게시글 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('게시글 수정 실패: $e');
    }
  }

  // DELETE /api/posts/{post_id} - 게시글 삭제
  Future<void> deletePost(int postId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/posts/$postId');

      final response = await http
          .delete(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        // 상세/목록 캐시 무효화
        await _invalidatePostCache(postId);
        await _invalidateListCache();
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 수 없습니다');
      } else {
        throw Exception('게시글 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('게시글 삭제 실패: $e');
    }
  }

  // GET /api/posts/search - 게시글 검색
  Future<List<PostListItem>> searchPosts({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // 검색은 캐시하지 않음 (실시간성 중요)
      final queryParams = {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/posts/search',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((item) => PostListItem.fromJson(item)).toList();
      } else {
        throw Exception('게시글 검색 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('게시글 검색 실패: $e');
    }
  }

  // POST /api/posts/{post_id}/like - 좋아요 추가
  Future<void> likePost(int postId, int memberId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/posts/$postId/like',
      ).replace(queryParameters: {'member_id': memberId.toString()});

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        // 상세/목록 캐시 무효화
        await _invalidatePostCache(postId);
        await _invalidateListCache();
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 수 없습니다');
      } else {
        throw Exception('좋아요 추가 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('좋아요 추가 실패: $e');
    }
  }

  // DELETE /api/posts/{post_id}/like - 좋아요 취소
  Future<void> unlikePost(int postId, int memberId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/posts/$postId/like',
      ).replace(queryParameters: {'member_id': memberId.toString()});

      final response = await http
          .delete(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        // 상세/목록 캐시 무효화
        await _invalidatePostCache(postId);
        await _invalidateListCache();
      } else if (response.statusCode == 404) {
        throw Exception('게시물을 찾을 수 없습니다');
      } else {
        throw Exception('좋아요 취소 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('좋아요 취소 실패: $e');
    }
  }

  // 캐시 관리 헬퍼 메서드
  Future<dynamic> _getCachedData(
    String key, {
    bool ignoreExpiry = false,
  }) async {
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
      // 캐시 저장 실패는 무시
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

  // GET /api/posts/list?member_id={member_id} - 내 게시글 조회
  Future<List<PostListItem>> getMyPosts(int memberId) async {
    try {
      return await getPostsList(
        memberId: memberId,
        currentMemberId: memberId,
        limit: 50,
        forceRefresh: true,
      );
    } catch (e) {
      throw Exception('내 게시글 조회 실패: $e');
    }
  }

  // GET /api/posts/list?current_member_id={member_id} - 좋아요한 게시글 조회
  Future<List<PostListItem>> getLikedPosts(int memberId) async {
    try {
      return await getPostsList(
        limit: 50,
        currentMemberId: memberId,
        likedOnly: true,
        forceRefresh: true,
      );
    } catch (e) {
      throw Exception('좋아요한 게시글 조회 실패: $e');
    }
  }

  // --- 댓글 관련 메서드 ---

  // GET /api/posts/{postId}/comments - 댓글 목록 조회
  Future<List<Comment>> getComments(int postId, {int? currentMemberId}) async {
    try {
      final queryParams = <String, String>{};
      if (currentMemberId != null) {
        queryParams['current_member_id'] = currentMemberId.toString();
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/posts/$postId/comments')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        return jsonData.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('댓글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('댓글 조회 중 오류 발생: $e');
    }
  }

  // POST /api/posts/{postId}/comments - 댓글 작성
  Future<Comment> createComment({
    required int postId,
    required int memberId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/posts/$postId/comments');
      
      final body = {
        'memberId': memberId,
        'content': content,
        'parentCommentId': parentCommentId,
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return Comment.fromJson(jsonData);
      } else {
        throw Exception('댓글 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('댓글 작성 중 오류 발생: $e');
    }
  }

  // POST /api/comments/{commentId}/like - 댓글 좋아요 토글
  Future<Map<String, dynamic>> toggleCommentLike(int commentId, int memberId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/comments/$commentId/like');
      
      final body = {'memberId': memberId};

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('댓글 좋아요 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('댓글 좋아요 오류: $e');
    }
  }

  // DELETE /api/comments/{commentId} - 댓글 삭제
  Future<void> deleteComment(int commentId, int memberId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/comments/$commentId?memberId=$memberId');

      final response = await http
          .delete(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode != 200) {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['detail'] ?? '댓글 삭제 실패');
      }
    } catch (e) {
      throw Exception('댓글 삭제 중 오류 발생: $e');
    }
  }
}
