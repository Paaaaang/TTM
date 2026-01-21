/// 친구 추가 화면
import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';

/// 사용자 검색 결과 모델
class SearchUser {
  final String id;
  final String username;
  final String name;
  final String profileImage;
  final int level;
  final bool isFriend;

  SearchUser({
    required this.id,
    required this.username,
    required this.name,
    required this.profileImage,
    required this.level,
    this.isFriend = false,
  });
}

/// 친구 추가 화면 위젯
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({Key? key}) : super(key: key);

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<SearchUser> _searchResults = [];

  // 더미 데이터
  final List<SearchUser> _dummyUsers = [
    SearchUser(
      id: '4',
      username: 'healthy_life',
      name: '최건강',
      profileImage: '',
      level: 20,
    ),
    SearchUser(
      id: '5',
      username: 'workout_king',
      name: '정운동',
      profileImage: '',
      level: 18,
    ),
    SearchUser(
      id: '6',
      username: 'diet_queen',
      name: '강다이어트',
      profileImage: '',
      level: 16,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    setState(() {
      _isSearching = true;
    });

    // TODO: 실제 검색 API 호출
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchResults = _dummyUsers
              .where(
                (user) =>
                    user.username.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ) ||
                    user.name.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ),
              )
              .toList();
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('친구 추가'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색 입력
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '사용자 이름 또는 아이디',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _handleSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('검색'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 검색 결과
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '사용자 이름 또는 아이디로\n친구를 검색해보세요',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(SearchUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(
              user.name[0],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Lv.${user.level}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 추가 버튼
          user.isFriend
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '친구',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: () => _handleAddFriend(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('추가'),
                ),
        ],
      ),
    );
  }

  void _handleAddFriend(SearchUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 추가'),
        content: Text('${user.name}님을 친구로 추가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 친구 추가 API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.name}님에게 친구 요청을 보냈습니다')),
              );
              setState(() {
                user.isFriend;
              });
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}
