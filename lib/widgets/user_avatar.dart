import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/app_user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.imageBytes,
    this.onTap,
  });

  final AppUser user;
  final double radius;
  final Uint8List? imageBytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? imageProvider = imageBytes != null
        ? MemoryImage(imageBytes!)
        : user.profileImageUrl.isNotEmpty
            ? NetworkImage(user.profileImageUrl)
            : null;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: radius * 0.78,
              ),
            )
          : null,
    );

    if (onTap == null) return avatar;

    return InkWell(
      borderRadius: BorderRadius.circular(radius * 2),
      onTap: onTap,
      child: avatar,
    );
  }
}
