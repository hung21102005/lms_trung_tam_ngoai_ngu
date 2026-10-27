import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_client.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/utils/attachment_url.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/datasources/assignments_remote_datasource.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/bloc/assignments_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/presentation/screens/create_assignment_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/app_text_field.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/linkified_text.dart';

class _ApiClient implements ApiClient {
  String? path;
  FormData? form;

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.path = path;
    form = data as FormData;
    return {
      'data': {
        'url': '/uploads/assignments/rubric.pdf',
        'originalName': 'rubric.pdf',
        'mimetype': 'application/pdf',
        'size': 3,
      },
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AssignmentsRepository implements AssignmentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('tải tài liệu qua multipart và lưu URL trả về từ API', () async {
    final client = _ApiClient();
    final source = AssignmentsRemoteDataSourceImpl(apiClient: client);

    final attachment = await source.uploadAttachment(
      'rubric.pdf',
      Uint8List.fromList([1, 2, 3]),
    );

    expect(client.path, '/upload');
    expect(client.form!.fields.single.key, 'folder');
    expect(client.form!.fields.single.value, 'assignments');
    expect(client.form!.files.single.key, 'file');
    expect(client.form!.files.single.value.filename, 'rubric.pdf');
    expect(
      client.form!.files.single.value.contentType.toString(),
      'application/pdf',
    );
    expect(attachment.url, '/uploads/assignments/rubric.pdf');
    expect(
      resolveAttachmentUrl(attachment.url)?.path,
      '/uploads/assignments/rubric.pdf',
    );
  });

  testWidgets('URL trong mô tả có màu xanh và có thể bấm', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LinkifiedText(
            text: 'Xem đề tại https://example.com/rubric.pdf.',
          ),
        ),
      ),
    );

    final text = tester.widget<SelectableText>(find.byType(SelectableText));
    final spans = text.textSpan!.children!;
    final link = spans.whereType<TextSpan>().firstWhere(
      (span) => span.text == 'https://example.com/rubric.pdf',
    );
    expect(link.style?.color, isNotNull);
    expect(link.recognizer, isA<TapGestureRecognizer>());
    expect((spans.last as TextSpan).text, '.');
  });

  testWidgets('form giao bài tập dùng nút chọn tệp và xem trước URL', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = AssignmentsBloc(repository: _AssignmentsRepository());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
          home: CreateAssignmentScreen(classId: 'class-1'),
        ),
      ),
    );

    expect(find.text('Chọn tệp từ máy'), findsOneWidget);
    expect(find.text('Tên file đính kèm'), findsNothing);
    expect(find.text('Đường dẫn file (URL)'), findsNothing);

    await tester.enterText(
      find.descendant(
        of: find.widgetWithText(AppTextField, 'Yêu cầu & Hướng dẫn làm bài'),
        matching: find.byType(TextFormField),
      ),
      'Xem https://example.com/rubric.pdf',
    );
    await tester.pump();
    expect(find.byType(LinkifiedText), findsOneWidget);
  });
}
