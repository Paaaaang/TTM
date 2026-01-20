// 친구 그룹 생성 팝업
import 'package:flutter/material.dart';
import 'package:ttm/models/user.dart';
import 'package:ttm/models/friend_group.dart';
import 'package:ttm/services/friend_group_service.dart';

class CreateGroupDialog extends StatefulWidget {
  final List<User> friends;
  final List<FriendGroup> existingGroups;
  final int? currentUserId;
  final VoidCallback? onGroupsChanged;

  const CreateGroupDialog({
    Key? key,
    required this.friends,
    this.existingGroups = const [],
    this.currentUserId,
    this.onGroupsChanged,
  }) : super(key: key);

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _customGroupNameController = TextEditingController();
  final Set<int> _selectedFriendIds = {};
  final FriendGroupService _friendGroupService = FriendGroupService();
  bool _isCreating = false;
  bool _isLoadingExcluded = false;
  Set<int> _excludedFriendIds = {};
  late List<FriendGroup> _mutableGroups;
  
  // 선택된 그룹 이름
  String _selectedGroupName = '기본 그룹';
  
  // 드롭다운 옵션들
  late List<String> _groupOptions;
  
  // 직접 입력 모드 여부
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _mutableGroups = List<FriendGroup>.from(widget.existingGroups);
    _groupOptions = _buildGroupOptions();
    _selectedGroupName = _groupOptions.first;
    _showCustomInput = _selectedGroupName == '직접 입력';
    if (!_showCustomInput) {
      _loadExcludedForSelectedGroup();
    }
  }

  @override
  void dispose() {
    _customGroupNameController.dispose();
    super.dispose();
  }

  List<String> _buildGroupOptions() {
    final names = _mutableGroups
        .map((g) => g.groupName)
        .toSet()
        .toList();
    names.sort();
    if (names.isEmpty) {
      return ['기본 그룹', '직접 입력'];
    }
    return [...names, '직접 입력'];
  }

  FriendGroup? _findGroupByName(String name) {
    try {
      return _mutableGroups.firstWhere((g) => g.groupName == name);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showGroupManageDialog() async {
    if (_mutableGroups.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제할 그룹이 없습니다')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '그룹 관리',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ..._mutableGroups.map((group) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(group.groupName),
                    subtitle: Text('멤버 ${group.memberCount}명'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final currentUserId = widget.currentUserId;
                        if (currentUserId == null) return;
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('그룹 삭제'),
                            content: Text('${group.groupName} 그룹을 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;

                        final success = await _friendGroupService.deleteGroup(
                          group.groupId,
                          currentUserId,
                        );
                        if (!mounted) return;
                        if (success) {
                          setState(() {
                            _mutableGroups.removeWhere((g) => g.groupId == group.groupId);
                            _groupOptions = _buildGroupOptions();
                            if (!_groupOptions.contains(_selectedGroupName)) {
                              _selectedGroupName = _groupOptions.first;
                              _showCustomInput = _selectedGroupName == '직접 입력';
                            }
                          });
                          _loadExcludedForSelectedGroup();
                          widget.onGroupsChanged?.call();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('그룹이 삭제되었습니다')),
                            );
                          }
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('그룹 삭제에 실패했습니다')),
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadExcludedForSelectedGroup() async {
    final group = _findGroupByName(_selectedGroupName);
    if (group == null) {
      setState(() {
        _excludedFriendIds = {};
        _isLoadingExcluded = false;
      });
      return;
    }

    setState(() {
      _isLoadingExcluded = true;
    });

    final members = await _friendGroupService.getGroupMembers(group.groupId);
    if (!mounted) return;
    setState(() {
      _excludedFriendIds = members.map((m) => m.memberId).toSet();
      _isLoadingExcluded = false;
      _selectedFriendIds.removeWhere((id) => _excludedFriendIds.contains(id));
    });
  }

  void _toggleFriendSelection(int friendId) {
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  bool get _canCreate {
    final groupName = _showCustomInput
        ? _customGroupNameController.text.trim()
        : _selectedGroupName;
    return groupName.isNotEmpty &&
        _selectedFriendIds.isNotEmpty &&
        !_isCreating;
  }
  
  String get _finalGroupName {
    return _showCustomInput
        ? _customGroupNameController.text.trim()
        : _selectedGroupName;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '새 그룹 만들기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 그룹 이름 (고정)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '그룹 이름',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _showGroupManageDialog,
                        icon: const Icon(Icons.settings, size: 20),
                        color: Colors.grey[700],
                        tooltip: '그룹 관리',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 드롭다운과 커스텀 입력
                  if (!_showCustomInput)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGroupName,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          borderRadius: BorderRadius.circular(12),
                          items: _groupOptions.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == '직접 입력') {
                              setState(() {
                                _showCustomInput = true;
                                _customGroupNameController.clear();
                                _excludedFriendIds = {};
                              });
                            } else {
                              setState(() {
                                _selectedGroupName = value!;
                                _showCustomInput = false;
                              });
                              _loadExcludedForSelectedGroup();
                            }
                          },
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customGroupNameController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '새 그룹 이름을 입력하세요',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1DB954),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showCustomInput = false;
                              _selectedGroupName = _groupOptions.first;
                              _customGroupNameController.clear();
                            });
                            _loadExcludedForSelectedGroup();
                          },
                          icon: const Icon(Icons.cancel_outlined),
                          color: Colors.grey[600],
                          tooltip: '취소',
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // 친구 선택 레이블 (고정)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '친구 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (_isLoadingExcluded)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            // 친구 목록 (스크롤 가능)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // 친구 목록이 없을 때
                    if (widget.friends.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '친구가 없습니다',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    // 친구 목록
                    else ...[
                      ...widget.friends
                          .where((friend) =>
                              friend.memberId != widget.currentUserId &&
                              !_excludedFriendIds.contains(friend.memberId))
                          .map((friend) {
                        final isSelected = _selectedFriendIds.contains(friend.memberId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1DB954).withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1DB954)
                                  : Colors.grey[200]!,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _toggleFriendSelection(friend.memberId),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // 프로필 이미지
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF1DB954).withOpacity(0.1),
                                    child: Text(
                                      friend.nickname[0],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1DB954),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 닉네임
                                  Expanded(
                                    child: Text(
                                      friend.nickname,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // 체크 아이콘
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF1DB954),
                                      size: 20,
                                    )
                                  else
                                    Icon(
                                      Icons.circle_outlined,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                        if (widget.friends.isNotEmpty &&
                          widget.friends
                            .where((f) => f.memberId != widget.currentUserId)
                            .every((f) => _excludedFriendIds.contains(f.memberId)))
                        Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          child: Text(
                            '선택한 그룹에 이미 속한 친구입니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canCreate
                          ? () {
                              Navigator.pop(context, {
                                'groupName': _finalGroupName,
                                'selectedFriendIds': _selectedFriendIds.toList(),
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _selectedFriendIds.isEmpty
                                  ? '생성하기'
                                  : '생성하기 (${_selectedFriendIds.length}명)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
