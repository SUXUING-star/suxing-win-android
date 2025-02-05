// lib/widgets/profile/profile_header.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final VoidCallback onEditProfile;
  final Future<void> Function() onAvatarTap;

  const ProfileHeader({
    Key? key,
    required this.user,
    required this.onEditProfile,
    required this.onAvatarTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.avatar != null
                      ? NetworkImage(user.avatar!)
                      : null,
                  child: user.avatar == null
                      ? Icon(Icons.person, size: 50)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.black54),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            user.username,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user.email,
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onEditProfile,
            child: Text('编辑资料'),
          ),
        ],
      ),
    );
  }
}