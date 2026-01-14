import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:milpress/features/course/course_models/lesson_model.dart';
import 'package:milpress/utils/app_colors.dart';

class EnhancedLessonCard extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onTap;
  final bool showPlayButton;

  const EnhancedLessonCard({
    Key? key,
    required this.lesson,
    required this.onTap,
    this.showPlayButton = true,
  }) : super(key: key);

  String? _getFormattedThumbnailUrl() {
    if (lesson.thumbnailUrl == null || lesson.thumbnailUrl!.isEmpty) {
      return null;
    }
    
    // Fix double slash issue in the URL
    String cleanUrl = lesson.thumbnailUrl!;
    // Replace multiple consecutive slashes with single slash, but preserve http:// and https://
    cleanUrl = cleanUrl.replaceAll(RegExp(r'(?<!:)\/\/+'), '/');
    
    print('Original URL: ${lesson.thumbnailUrl}');
    print('Cleaned URL: $cleanUrl');
    
    return cleanUrl;
  }



  Widget _buildFallbackImage(String url) {
    final uri = Uri.tryParse(url);
    final isRemote = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isRemote) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 48,
                color: AppColors.primaryColor,
              ),
            ),
          );
        },
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Image.network error: $error');
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 48,
              color: AppColors.primaryColor,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _getFormattedThumbnailUrl() != null
                        ? Builder(
                            builder: (context) {
                              final thumbnailUrl = _getFormattedThumbnailUrl();
                              print('CachedNetworkImage - Loading URL: $thumbnailUrl');
                              
                              return _buildFallbackImage(thumbnailUrl!);
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 48,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                  ),
                ),
                // Duration badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      lesson.formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Play button overlay
                if (showPlayButton)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Content section - compact
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and level badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          lesson.displayCategory,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          lesson.displayLevel,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF232B3A),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
