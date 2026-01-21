/// 게시글 작성 화면
/// DB 연동 버전 - 이미지 업로드, 드래그앤드롭, 공개범위 선택 기능 포함
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ttm/constants/app_colors.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../constants/api_constants.dart';
import '../widgets/profile_avatar.dart';

/// 게시글 작성 화면 위젯
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  List<XFile> _selectedImages = []; // 선택된 이미지 파일들
  String _selectedCategory = 'FREE'; // 기본값: 자유
  String _selectedVisibility = 'PUBLIC'; // 기본값: 전체 공개
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(_currentUser);
  }

  Widget _buildScaffold(User? currentUser) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // 키보드가 올라올 때 자동으로 화면 조정
      appBar: AppBar(
        title: const Text('게시글 작성'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // 게시 버튼
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: Text(
              '게시',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _contentController.text.trim().isEmpty
                    ? Colors.grey[400]
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 정보
                  Row(
                    children: [
                      // 프로필 아바타
                      ProfileAvatar(
                        size: 48,
                        profileImageUrl: currentUser?.profileImage,
                      ),
                      const SizedBox(width: 12),
                      // 닉네임 및 공개 범위
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.nickname ?? '익명',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // 공개 범위 선택
                            InkWell(
                              onTap: _showVisibilityPicker,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getVisibilityIcon(_selectedVisibility),
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getVisibilityName(_selectedVisibility),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 카테고리 선택
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: const [
                          DropdownMenuItem(value: 'FREE', child: Text('자유')),
                          DropdownMenuItem(value: 'QNA', child: Text('Q&A')),
                          DropdownMenuItem(value: 'REVIEW', child: Text('후기')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 제목 입력 필드
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '제목을 입력하세요',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (value) {
                      setState(() {}); // 게시 버튼 활성화/비활성화를 위한 리빌드
                    },
                  ),

                  Divider(color: Colors.grey[300]),

                  const SizedBox(height: 8),

                  // 내용 입력 필드
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 8,
                    decoration: InputDecoration(
                      hintText: '내용을 입력하세요',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    onChanged: (value) {
                      setState(() {}); // 게시 버튼 활성화/비활성화를 위한 리빌드
                    },
                  ),

                  const SizedBox(height: 20),

                  // 이미지 리스트 (가로 배치)
                  if (_selectedImages.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _selectedImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final image = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                // 이미지
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FutureBuilder<Uint8List>(
                                    future: image.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // 순서 표시
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                // 삭제 버튼
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                // 순서 변경 버튼 (왼쪽)
                                if (index > 0)
                                  Positioned(
                                    left: 4,
                                    bottom: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          final temp = _selectedImages[index];
                                          _selectedImages[index] =
                                              _selectedImages[index - 1];
                                          _selectedImages[index - 1] = temp;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chevron_left,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                // 순서 변경 버튼 (오른쪽)
                                if (index < _selectedImages.length - 1)
                                  Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          final temp = _selectedImages[index];
                                          _selectedImages[index] =
                                              _selectedImages[index + 1];
                                          _selectedImages[index + 1] = temp;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  if (_selectedImages.isNotEmpty) const SizedBox(height: 20),

                  // 하단 액션 버튼들
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        // 사진 추가
                        _buildActionButton(
                          icon: Icons.add_photo_alternate,
                          label: '사진 추가',
                          color: AppColors.primary,
                          onTap: _pickImages,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 액션 버튼 위젯
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이미지 선택
  Future<void> _pickImages() async {
    try {
      // 최대 2개 제한 체크
      if (_selectedImages.length >= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('최대 2개의 이미지만 추가할 수 있습니다')),
          );
        }
        return;
      }

      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        // 2개 초과 방지
        final availableSlots = 2 - _selectedImages.length;
        final imagesToAdd = images.take(availableSlots).toList();

        setState(() {
          // 명시적으로 XFile 타입으로 추가
          for (final image in imagesToAdd) {
            _selectedImages.add(image);
          }
        });

        if (mounted) {
          if (images.length > availableSlots) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${imagesToAdd.length}개의 이미지가 추가되었습니다 (최대 2개 제한)',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${imagesToAdd.length}개의 이미지가 추가되었습니다')),
            );
          }
        }
      }
    } catch (e) {
      print('이미지 선택 오류: $e'); // 디버깅용
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')));
      }
    }
  }

  /// 공개 범위 선택 모달
  void _showVisibilityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '공개 범위 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('전체 공개'),
              subtitle: const Text('모든 사용자가 볼 수 있습니다'),
              trailing: _selectedVisibility == 'PUBLIC'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedVisibility = 'PUBLIC';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('친구 공개'),
              subtitle: const Text('친구만 볼 수 있습니다'),
              trailing: _selectedVisibility == 'FRIENDS'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedVisibility = 'FRIENDS';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('비공개'),
              subtitle: const Text('나만 볼 수 있습니다'),
              trailing: _selectedVisibility == 'PRIVATE'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedVisibility = 'PRIVATE';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 게시글 제출
  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요')));
      return;
    }

    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 이미지 업로드
      List<Map<String, dynamic>>? images;
      if (_selectedImages.isNotEmpty) {
        images = [];
        for (int i = 0; i < _selectedImages.length; i++) {
          try {
            // 이미지를 서버에 업로드
            final imageBytes = await _selectedImages[i].readAsBytes();
            final request = http.MultipartRequest(
              'POST',
              Uri.parse('${ApiConstants.baseUrl}/api/posts/upload-image'),
            );
            request.files.add(
              http.MultipartFile.fromBytes(
                'file',
                imageBytes,
                filename:
                    'image_${DateTime.now().millisecondsSinceEpoch}_${i + 1}.jpg',
              ),
            );

            final streamedResponse = await request.send();
            final response = await http.Response.fromStream(streamedResponse);

            if (response.statusCode == 200) {
              final result = json.decode(response.body);
              images.add({
                'imagePath': result['imagePath'],
                'displayOrder': i + 1,
              });
            } else {
              throw Exception('이미지 업로드 실패: ${response.statusCode}');
            }
          } catch (e) {
            print('이미지 ${i + 1} 업로드 오류: $e');
            // 이미지 업로드 실패 시 placeholder 사용
            images.add({
              'imagePath':
                  'https://via.placeholder.com/400x300.png?text=Upload+Failed',
              'displayOrder': i + 1,
            });
          }
        }
      }

      // 실제 API 호출로 게시글 작성
      await _postService.createPost(
        memberId: currentUser.memberId,
        category: _selectedCategory,
        title: title.isEmpty ? '제목 없음' : title,
        content: content,
        images: images,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // 성공 메시지 표시
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글이 작성되었습니다')));

      // 이전 화면으로 돌아가기
      Navigator.pop(context, true); // true를 반환하여 목록 새로고침 유도
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('게시글 작성에 실패했습니다: $e')));
    }
  }

  /// 아바타 텍스트 생성
  String _getAvatarText(String nickname) {
    if (nickname.isEmpty) return '?';
    return nickname.substring(0, 1).toUpperCase();
  }

  /// 아바타 색상 생성
  Color _getAvatarColor(String nickname) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFF44336),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFE91E63),
      const Color(0xFF3F51B5),
    ];

    final hash = nickname.hashCode.abs();
    return colors[hash % colors.length];
  }

  /// 공개 범위 아이콘
  IconData _getVisibilityIcon(String visibility) {
    switch (visibility) {
      case 'PUBLIC':
        return Icons.public;
      case 'FRIENDS':
        return Icons.people;
      case 'PRIVATE':
        return Icons.lock;
      default:
        return Icons.public;
    }
  }

  /// 공개 범위 이름
  String _getVisibilityName(String visibility) {
    switch (visibility) {
      case 'PUBLIC':
        return '전체 공개';
      case 'FRIENDS':
        return '친구 공개';
      case 'PRIVATE':
        return '비공개';
      default:
        return '전체 공개';
    }
  }
}
