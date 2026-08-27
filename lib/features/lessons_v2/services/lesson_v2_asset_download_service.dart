import 'dart:io';

import 'package:dio/dio.dart';

const _connectTimeout = Duration(seconds: 20);
const _receiveTimeout = Duration(seconds: 60);

class LessonV2AssetDownloadService {
  LessonV2AssetDownloadService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: _connectTimeout,
                receiveTimeout: _receiveTimeout,
              ),
            );

  final Dio _dio;

  Future<String> downloadUrl({
    required String url,
    required Directory directory,
    required String fileName,
  }) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final localFile = File('${directory.path}/$fileName');
    await _dio.download(url, localFile.path);
    return localFile.path;
  }
}
