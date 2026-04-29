import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Resolves a Firestore-stored photoUrl to an [ImageProvider].
/// Handles both base64 data URIs (e.g. "data:image/jpeg;base64,...")
/// and regular HTTPS network URLs using [CachedNetworkImageProvider].
ImageProvider? resolveProfileImage(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return null;
  if (photoUrl.startsWith('data:image')) {
    try {
      final base64Str = photoUrl.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }
  return CachedNetworkImageProvider(photoUrl);
}

/// A [CircleAvatar] that correctly displays both base64 data URI photos
/// and regular network URL photos stored in Firestore.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;
  final Widget? fallback;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 24,
    this.backgroundColor = Colors.transparent,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = resolveProfileImage(photoUrl);
    
    // For network images, we use CachedNetworkImage directly for better error handling
    if (photoUrl != null && !photoUrl!.startsWith('data:image') && photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: fallback ?? Icon(Icons.person, size: radius, color: Colors.white24),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageProvider,
      child: imageProvider == null ? (fallback ?? Icon(Icons.person, size: radius, color: Colors.white24)) : null,
    );
  }
}

/// Builds a profile image widget that handles data URIs.
/// Use this for non-CircleAvatar contexts (e.g. Image.network replacements).
Widget buildProfileImage({
  required String? photoUrl,
  required double size,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  if (photoUrl == null || photoUrl.isEmpty) {
    return fallback ?? Icon(Icons.person, size: size, color: Colors.white38);
  }

  if (photoUrl.startsWith('data:image')) {
    final imageProvider = resolveProfileImage(photoUrl);
    if (imageProvider == null) {
      return fallback ?? Icon(Icons.person, size: size, color: Colors.white38);
    }
    return Image(image: imageProvider, width: size, height: size, fit: fit);
  }

  return CachedNetworkImage(
    imageUrl: photoUrl,
    width: size,
    height: size,
    fit: fit,
    placeholder: (context, url) => Container(
      width: size,
      height: size,
      color: Colors.white10,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 1)),
    ),
    errorWidget: (context, url, error) => fallback ?? Icon(Icons.person, size: size, color: Colors.white38),
  );
}
