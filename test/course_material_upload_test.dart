import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/datasources/courses_remote_datasource.dart';

class _Api extends Fake implements ApiClient {
  FormData? uploadData;
  Map<String, dynamic>? materialData;

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path == '/upload') {
      uploadData = data as FormData;
      return {
        'data': {'url': 'https://storage.example/lesson.pdf'},
      };
    }
    if (path == '/lessons/lesson-1/materials') {
      materialData = Map<String, dynamic>.from(data as Map);
      return {
        'data': {'id': 'material-1', 'lessonId': 'lesson-1', ...materialData!},
      };
    }
    throw StateError(path);
  }
}

void main() {
  test('upload tệp thật trước khi lưu tài liệu vào bài học', () async {
    final api = _Api();
    final source = CoursesRemoteDataSourceImpl(apiClient: api);
    final material = await source.uploadLessonMaterial(
      'lesson-1',
      title: 'Bài đọc PDF',
      fileName: 'bai-doc.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(api.uploadData!.files.single.value.filename, 'bai-doc.pdf');
    expect(api.uploadData!.fields.single.value, 'materials');
    expect(api.materialData, {
      'title': 'Bài đọc PDF',
      'fileUrl': 'https://storage.example/lesson.pdf',
      'fileType': 'PDF',
      'fileSizeBytes': 3,
    });
    expect(material.fileType, 'PDF');
  });
}
