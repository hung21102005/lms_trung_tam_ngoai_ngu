import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/models/course_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/domain/repositories/courses_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/screens/course_detail_screen.dart';

class _Repository extends Fake implements CoursesRepository {
  _Repository({this.empty = false, this.fail = false});

  final bool empty;
  final bool fail;

  @override
  Future<CourseModel> getCourseDetail(String id) async {
    if (fail) throw StateError('Không tải được chi tiết');
    return CourseModel(
      id: id,
      code: 'IELTS-F-01',
      title: 'IELTS Foundation: chương trình luyện thi với tên rất dài trên màn hình nhỏ',
      description: 'Mô tả chương trình đào tạo dài để kiểm tra xuống dòng trên thiết bị nhỏ.',
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
}
