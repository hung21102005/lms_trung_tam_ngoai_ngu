import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/models/course_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/domain/repositories/courses_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/screens/course_detail_screen.dart';

class _Repository extends Fake implements CoursesRepository {
  _Repository({this.empty = false, this.fail = false, this.archived = false});

  final bool empty;
  final bool fail;
  final bool archived;
  String? createdLevelCode;
  Map<String, dynamic>? updatedLevelChanges;
  Map<String, dynamic>? updatedModuleChanges;
  Map<String, dynamic>? updatedLessonChanges;
  String? createdModuleTitle;
  String? createdLessonTitle;

  @override
  Future<ModuleModel> createModule(
    String levelId, {
    required String title,
    int order = 1,
    String? description,
  }) async {
    createdModuleTitle = title;
    return ModuleModel(id: 'new-module', levelId: levelId, title: title);
  }

  @override
  Future<LessonModel> createLesson(
    String moduleId, {
    required String title,
    int order = 1,
    String? content,
    int durationMinutes = 90,
  }) async {
    createdLessonTitle = title;
    return LessonModel(id: 'new-lesson', moduleId: moduleId, title: title);
  }

  @override
  Future<ModuleModel> updateModule(
    String id,
    Map<String, dynamic> changes,
  ) async {
    updatedModuleChanges = changes;
    return ModuleModel(
      id: id,
      levelId: 'level-1',
      title: changes['title'] as String,
    );
  }

  @override
  Future<LessonModel> updateLesson(
    String id,
    Map<String, dynamic> changes,
  ) async {
    updatedLessonChanges = changes;
    return LessonModel(
      id: id,
      moduleId: 'module-1',
      title: changes['title'] as String,
    );
  }

  @override
  Future<CourseLevelModel> updateLevel(
    String levelId,
    Map<String, dynamic> changes,
  ) async {
    updatedLevelChanges = changes;
    return CourseLevelModel(
      id: levelId,
      courseId: 'course-1',
      code: changes['code'] as String,
      name: changes['name'] as String,
    );
  }

  @override
  Future<CourseLevelModel> createLevel(
    String courseId, {
    required String code,
    required String name,
    String? description,
    int order = 1,
    int estimatedSessions = 24,
    double tuitionFee = 0,
  }) async {
    createdLevelCode = code;
    return CourseLevelModel(
      id: 'new-level',
      courseId: courseId,
      code: code,
      name: name,
    );
  }

  @override
  Future<CourseModel> getCourseDetail(String id) async {
    if (fail) throw StateError('Không tải được chi tiết');
    return CourseModel(
      id: id,
      code: 'IELTS-F-01',
      title: 'IELTS Foundation: chương trình luyện thi với tên rất dài trên màn hình nhỏ',
      description: 'Mô tả chương trình đào tạo dài để kiểm tra xuống dòng trên thiết bị nhỏ.',
      publicationStatus: archived ? 'ARCHIVED' : 'DRAFT',
      levelsCount: empty ? 0 : 1,
      levels: empty
          ? const []
          : const [
              CourseLevelModel(
                id: 'level-1',
                courseId: 'course-1',
                code: 'FOUNDATION-01',
                name: 'Nền tảng nghe nói đọc viết cho người mới bắt đầu',
                estimatedSessions: 24,
                modules: [
                  ModuleModel(
                    id: 'module-1',
                    levelId: 'level-1',
                    title:
                        'Học phần phát triển toàn diện bốn kỹ năng tiếng Anh',
                    lessons: [
                      LessonModel(
                        id: 'lesson-1',
                        moduleId: 'module-1',
                        title: 'Bài học đầu tiên',
                        durationMinutes: 90,
                      ),
                    ],
                  ),
                ],
              ),
            ],
    );
  }
}

Widget _app(_Repository repository) => MaterialApp(
  home: BlocProvider(
    create: (_) => CoursesBloc(repository: repository),
    child: const CourseDetailScreen(courseId: 'course-1'),
  ),
);

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('chi tiết khóa học ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(_Repository()));
      await tester.pumpAndSettle();
      expect(find.textContaining('IELTS Foundation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mobile hiện học phần và bài học khi mở rộng', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_Repository()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Học phần phát triển'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Học phần phát triển'));
    await tester.pumpAndSettle();
    expect(find.text('Bài học đầu tiên'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile có trạng thái trống và lỗi', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_Repository(empty: true)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có cấp độ đào tạo nào'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_app(_Repository(fail: true)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tải được chi tiết'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile thêm cấp độ qua bottom sheet và Bloc', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final repository = _Repository(empty: true);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm cấp độ'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu cấp độ'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập mã cấp độ'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mã cấp độ *'),
      'a1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên cấp độ *'),
      'Nền tảng A1',
    );
    await tester.ensureVisible(find.text('Lưu cấp độ'));
    await tester.tap(find.text('Lưu cấp độ'));
    await tester.pumpAndSettle();
    expect(repository.createdLevelCode, 'A1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile sửa chuẩn đầu ra cấp độ và lưu qua repository', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final repository = _Repository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sửa cấp độ'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa cấp độ'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'CEFR (nếu áp dụng)'),
      'B1',
    );
    await tester.ensureVisible(find.text('Lưu cấp độ'));
    await tester.tap(find.text('Lưu cấp độ'));
    await tester.pumpAndSettle();
    expect(repository.updatedLevelChanges?['cefrLevel'], 'B1');
    expect(repository.updatedLevelChanges?['code'], 'FOUNDATION-01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile sửa học phần và bài học qua Bloc', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Học phần phát triển'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa học phần'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mô tả học phần'),
      'Mục tiêu nghe nói',
    );
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(
      repository.updatedModuleChanges?['description'],
      'Mục tiêu nghe nói',
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sửa bài học').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nội dung bài học'),
      'Bài tập tự luyện',
    );
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(repository.updatedLessonChanges?['content'], 'Bài tập tự luyện');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile tạo học phần và bài học qua Bloc', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm học phần'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tiêu đề *'),
      'Kỹ năng giao tiếp',
    );
    await tester.tap(find.text('Tạo học phần'));
    await tester.pumpAndSettle();
    expect(repository.createdModuleTitle, 'Kỹ năng giao tiếp');

    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Học phần phát triển'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm bài học'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tiêu đề *'),
      'Luyện phát âm',
    );
    await tester.tap(find.text('Tạo bài học'));
    await tester.pumpAndSettle();
    expect(repository.createdLessonTitle, 'Luyện phát âm');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khóa lưu trữ không hiện thao tác biên tập', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_Repository(archived: true)));
    await tester.pumpAndSettle();
    expect(find.text('Sửa cấp độ'), findsNothing);
    expect(find.text('Thêm học phần'), findsNothing);
    expect(find.byTooltip('Sửa bài học'), findsNothing);
  });
}
