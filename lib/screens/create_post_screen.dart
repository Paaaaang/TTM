/// 게시글 작성 화면
/// CreatePostScreen.tsx를 Flutter로 변환
import 'package:flutter/material.dart';

/// 게시글 작성 화면 위젯
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<String> _selectedImages = []; // 선택된 이미지 경로들
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    : const Color(0xFF66BB6A),
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
                      // 아바타
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '😊',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 이름
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '나',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '전체 공개',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 내용 입력 필드
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 8,
                    decoration: const InputDecoration(
                      hintText: '무슨 생각을 하고 계신가요?',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                    onChanged: (value) {
                      setState(() {}); // 게시 버튼 활성화/비활성화를 위한 리빌드
                    },
                  ),

                  const SizedBox(height: 20),

                  // 이미지 그리드 (선택된 이미지가 있을 경우)
                  if (_selectedImages.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            // 이미지 (더미로 컨테이너)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.image, size: 40, color: Colors.grey),
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
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  if (_selectedImages.isNotEmpty) const SizedBox(height: 20),

                  // 하단 액션 버튼들
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 사진 추가
                        _buildActionButton(
                          icon: Icons.image,
                          label: '사진',
                          color: const Color(0xFF66BB6A),
                          onTap: _pickImages,
                        ),
                        const SizedBox(width: 16),
                        // 태그
                        _buildActionButton(
                          icon: Icons.local_offer,
                          label: '태그',
                          color: const Color(0xFF42A5F5),
                          onTap: () {
                            // TODO: 태그 추가 기능
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('태그 기능 준비 중입니다')),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // 위치
                        _buildActionButton(
                          icon: Icons.location_on,
                          label: '위치',
                          color: const Color(0xFFF44336),
                          onTap: () {
                            // TODO: 위치 추가 기능
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('위치 기능 준비 중입니다')),
                            );
                          },
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
  void _pickImages() {
    // TODO: image_picker를 사용하여 실제 이미지 선택 구현
    setState(() {
      _selectedImages.add('dummy_image_${_selectedImages.length + 1}');
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지가 추가되었습니다')),
    );
  }

  /// 게시글 제출
  void _submitPost() async {
    final content = _contentController.text.trim();
    
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: 실제 API 호출로 게시글 작성
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('게시글이 작성되었습니다')),
    );

    // 이전 화면으로 돌아가기
    Navigator.pop(context);
  }
}
