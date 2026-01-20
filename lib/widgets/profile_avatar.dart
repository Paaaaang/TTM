import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';

class ProfileAvatar extends StatelessWidget {
  final XFile? profileImage;
  final String? profileImageUrl;
  final String? nickname;
  final double size;
  final bool showBorder;
  final Color borderColor;

  const ProfileAvatar({
    super.key,
    this.profileImage,
    this.profileImageUrl,
    this.nickname,
    this.size = 40,
    this.showBorder = true,
    this.borderColor = const Color(0xFF1DB954),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor,
                width: 2,
              )
            : null,
      ),
      child: ClipOval(
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    // 선택된 이미지가 있으면 우선 표시
    if (profileImage != null) {
      return FutureBuilder<Uint8List>(
        future: profileImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
          }
          return _buildDefaultAvatar();
        },
      );
    }

    // URL 이미지가 있으면 표시
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      final rawUrl = profileImageUrl!.trim();
      final isHttp = rawUrl.startsWith('http://') || rawUrl.startsWith('https://');
      final isRelative = rawUrl.startsWith('/');
      if (isHttp || isRelative) {
        String fullUrl = rawUrl;
        if (isRelative) {
          fullUrl = '${ApiConstants.baseUrl}$rawUrl';
        }

        return Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildDefaultAvatar();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      }
    }

    // 기본 아바타
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    if (nickname != null && nickname!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getAvatarColor(nickname!),
        ),
        alignment: Alignment.center,
        child: Text(
          nickname!.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }

  Color _getAvatarColor(String text) {
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
    return colors[text.hashCode.abs() % colors.length];
  }
}
