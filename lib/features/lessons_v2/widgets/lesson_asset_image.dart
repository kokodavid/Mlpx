import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LessonAssetImage extends StatelessWidget {
  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const LessonAssetImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    if (_isSvg(source)) {
      return _buildSvgImage();
    }

    return _buildRasterImage();
  }

  Widget _buildSvgImage() {
    return _isRemote(source)
        ? SvgPicture.network(
            source,
            width: width,
            height: height,
            fit: fit,
            placeholderBuilder: (_) => placeholder ?? const SizedBox.shrink(),
          )
        : SvgPicture.file(
            File(_filePath(source)),
            width: width,
            height: height,
            fit: fit,
            placeholderBuilder: (_) => placeholder ?? const SizedBox.shrink(),
          );
  }

  Widget _buildRasterImage() {
    return _isRemote(source)
        ? Image.network(
            source,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) =>
                placeholder ?? const SizedBox.shrink(),
          )
        : Image.file(
            File(_filePath(source)),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) =>
                placeholder ?? const SizedBox.shrink(),
          );
  }

  bool _isRemote(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool _isSvg(String value) {
    final path = Uri.tryParse(value)?.path ?? value;
    return path.toLowerCase().endsWith('.svg');
  }

  String _filePath(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      return uri.toFilePath();
    }
    return value;
  }
}
