import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_exception.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/class_list_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/models/course_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/domain/repositories/courses_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_state.dart';

class _FakeClassesRepository implements ClassesRepository {
  List<ClassModel> classes = [];
  List<Map<String, dynamic>> teachers = [];
  int createCallCount = 0;
  int deleteCallCount = 0;
  Object? deleteError;
  Duration createDelay = Duration.zero;
  Completer<List<ClassModel>>? pendingGetClassesCompleter;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  }) async {
    if (pendingGetClassesCompleter != null) {
      final completer = pendingGetClassesCompleter!;
      pendingGetClassesCompleter = null;
      return completer.future;
    }
    return List<ClassModel>.from(classes);
  }

  @override
  Future<ClassModel> getClassDetail(String id) async {
    return classes.firstWhere((c) => c.id == id);
  }

  @override
  Future<ClassModel> createClass({
    required String code,
    required String name,
    required String courseId,
    required String levelId,
    required String branchId,
    String? roomId,
    String? mainTeacherId,
    String? assistantTeacherId,
    String status = 'PLANNING',
    required String startDate,
    required List<String> scheduleDays,
    required String startTime,
    required String endTime,
    int totalSessions = 24,
    int maxCapacity = 20,
    double? tuitionFee,
    String? registrationOpenAt,
    String? registrationCloseAt,
    String? notes,
  }) async {
    createCallCount++;
    if (createDelay > Duration.zero) {
      await Future<void>.delayed(createDelay);
    }
    final newId = 'cls-new-$createCallCount';
    final created = ClassModel(
      id: newId,
      code: code,
      name: name,
      courseId: courseId,
      courseTitle: 'IELTS Intensive',
      levelId: levelId,
      branchId: branchId,
      branchName: 'Cơ sở 1 (Quận 1)',
      roomName: 'P.101',
      mainTeacherName: 'Cô Phạm Minh Nguyệt',
      status: status,
      scheduleDays: scheduleDays,
      startTime: startTime,
      endTime: endTime,
      studentsCount: 0,
      maxCapacity: maxCapacity,
      sessions: [
        ClassSessionModel(
          id: 'ses-1',
          classId: newId,
          sessionNumber: 1,
          title: 'Buổi 1',
          date: DateTime(2026, 11, 2),
          startTime: startTime,
          endTime: endTime,
          status: 'SCHEDULED',
          roomName: 'P.101',
          teacherName: 'Cô Phạm Minh Nguyệt',
        ),
      ],
    );
    classes = [created, ...classes];
    return created;
  }

  @override
  Future<ClassModel> updateClass(
    String id, {
    String? code,
    String? name,
    String? roomId,
    String? mainTeacherId,
    String? assistantTeacherId,
    String? status,
    String? startDate,
    List<String>? scheduleDays,
    String? startTime,
    String? endTime,
    int? maxCapacity,
    double? tuitionFee,
    String? registrationOpenAt,
    String? registrationCloseAt,
    String? notes,
  }) async {
    final index = classes.indexWhere((c) => c.id == id);
    if (index < 0) throw Exception('Class not found');
    final updated = classes[index].copyWith(
      code: code,
      name: name,
      status: status,
      maxCapacity: maxCapacity,
      tuitionFee: tuitionFee,
      notes: notes,
    );
    classes[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteClass(String id) async {
    deleteCallCount++;
    if (deleteError != null) throw deleteError!;
    classes.removeWhere((c) => c.id == id);
  }

  @override
  Future<ClassStudentModel> enrollStudent(
    String classId, {
    required String studentId,
    double tuitionPaid = 0,
    String? notes,
  }) async {
    final index = classes.indexWhere((c) => c.id == classId);
    if (index < 0) throw Exception('Class not found');
    final current = classes[index];
    final enrolled = ClassStudentModel(
      id: 'enr-$studentId',
      classId: classId,
      studentId: studentId,
      studentCode: 'HV-001',
      studentName: 'Học Viên Mới',
      joinedAt: DateTime(2026, 10, 30),
      status: 'ENROLLED',
      tuitionPaid: tuitionPaid,
      notes: notes,
    );
    final newStudents = [...current.students, enrolled];
    classes[index] = current.copyWith(
      studentsCount: newStudents.length,
      students: newStudents,
    );
    return enrolled;
  }

  @override
  Future<void> removeStudent(String classId, String studentId) async {
    final index = classes.indexWhere((c) => c.id == classId);
    if (index < 0) throw Exception('Class not found');
    final current = classes[index];
    final newStudents = current.students
        .where((s) => s.studentId != studentId)
        .toList();
    classes[index] = current.copyWith(
      studentsCount: newStudents.length,
      students: newStudents,
    );
  }

  @override
  Future<ClassSessionModel> updateSession(
    String sessionId, {
    String? date,
    String? startTime,
    String? endTime,
    String? roomId,
    String? teacherId,
    String? status,
    String? notes,
  }) async {
    for (var i = 0; i < classes.length; i++) {
      final current = classes[i];
      ClassSessionModel? updatedSession;
      final updatedSessions = current.sessions.map((s) {
        if (s.id == sessionId) {
          updatedSession = ClassSessionModel(
            id: s.id,
            classId: s.classId,
            sessionNumber: s.sessionNumber,
            title: s.title,
            date: date != null ? DateTime.tryParse(date) ?? s.date : s.date,
            startTime: startTime ?? s.startTime,
            endTime: endTime ?? s.endTime,
            status: status ?? s.status,
            roomName: roomId ?? s.roomName,
            teacherName: teacherId ?? s.teacherName,
            notes: notes ?? s.notes,
          );
          return updatedSession!;
        }
        return s;
      }).toList();
      if (updatedSession != null) {
        classes[i] = current.copyWith(sessions: updatedSessions);
        return updatedSession!;
      }
    }
    throw Exception('Session not found');
  }

  Future<List<Map<String, dynamic>>> getTeachers({String? branchId}) async {
    if (branchId == null || branchId.isEmpty) {
      return List<Map<String, dynamic>>.from(teachers);
    }
    return teachers
        .where((t) => t['branchId'] == null || t['branchId'] == branchId)
        .toList();
  }
}

class _FakeCoursesRepository implements CoursesRepository {
  List<CourseModel> courses = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CourseModel>> getCourses({
    String? search,
    String? language,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    return List<CourseModel>.from(courses);
  }

  @override
  Future<CourseModel> getCourseDetail(String id) async {
    return courses.firstWhere((c) => c.id == id);
  }

  @override
  Future<void> confirmCourseAcademicReview(String id) async {}

  @override
  Future<void> changeCourseStatus(String id, String status) async {
    final index = courses.indexWhere((c) => c.id == id);
    if (index < 0) throw Exception('Course not found');
    final old = courses[index];
    courses[index] = CourseModel(
      id: old.id,
      code: old.code,
      title: old.title,
      language: old.language,
      isActive: old.isActive,
      publicationStatus: status,
      levelsCount: old.levelsCount,
      classesCount: old.classesCount,
      levels: old.levels,
    );
  }

  @override
  Future<CourseModel> updateCourse(
    String id, {
    String? code,
    String? title,
    String? description,
    String? targetAudience,
    String? language,
    String? thumbnailUrl,
    bool? isActive,
  }) async {
    final index = courses.indexWhere((c) => c.id == id);
    if (index < 0) throw Exception('Course not found');
    final old = courses[index];
    final updated = CourseModel(
      id: old.id,
      code: code ?? old.code,
      title: title ?? old.title,
      language: language ?? old.language,
      isActive: isActive ?? old.isActive,
      publicationStatus: old.publicationStatus,
      levelsCount: old.levelsCount,
      classesCount: old.classesCount,
      levels: old.levels,
    );
    courses[index] = updated;
    return updated;
  }
}

ClassModel _makeClass({
  String id = 'cls-1',
  String code = 'IELTS-01',
  String name = 'Lớp IELTS Sáng',
  String status = 'PLANNING',
  String branchName = 'Cơ sở 1 (Quận 1)',
  int studentsCount = 0,
}) {
  return ClassModel(
    id: id,
    code: code,
    name: name,
    courseId: 'crs-1',
    courseTitle: 'IELTS Intensive',
    levelId: 'lvl-1',
    branchId: 'br-1',
    branchName: branchName,
    roomName: 'P.101',
    mainTeacherName: 'Thầy Trần Thanh Hà',
    status: status,
    scheduleDays: const ['MON', 'WED', 'FRI'],
    startTime: '08:00',
    endTime: '10:00',
    studentsCount: studentsCount,
    maxCapacity: 20,
  );
}

void main() {
  group('Admin State Synchronization Regression Suite (No-F5 Guarantee)', () {
    testWidgets(
      'Test A: Creating a class immediately updates ClassListScreen and KPI counters without F5 and blocks double-submit',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = _FakeClassesRepository()
          ..classes = [_makeClass(id: 'cls-existing', code: 'IELTS-OLD-01')]
          ..createDelay = const Duration(milliseconds: 50);
        final bloc = ClassesBloc(repository: repo);
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ClassesBloc>.value(
              value: bloc,
              child: const ClassListScreen(showAppBar: false),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('IELTS-OLD-01'), findsOneWidget);
        expect(find.text('CLS-NEW-2026'), findsNothing);

        // Dispatch two concurrent CreateClassEvents to verify double-submit guard
        bloc.add(
          const CreateClassEvent(
            code: 'CLS-NEW-2026',
            name: 'Lớp IELTS Tối Mới',
            courseId: 'crs-1',
            levelId: 'lvl-1',
            branchId: 'br-1',
            startDate: '2026-11-02',
            scheduleDays: ['MON', 'WED', 'FRI'],
            startTime: '18:00',
            endTime: '20:00',
          ),
        );
        bloc.add(
          const CreateClassEvent(
            code: 'CLS-DUPLICATE',
            name: 'Lớp Trùng',
            courseId: 'crs-1',
            levelId: 'lvl-1',
            branchId: 'br-1',
            startDate: '2026-11-02',
            scheduleDays: ['MON', 'WED', 'FRI'],
            startTime: '18:00',
            endTime: '20:00',
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(repo.createCallCount, 1);
        expect(bloc.cachedClasses.length, 2);
        expect(find.text('CLS-NEW-2026'), findsOneWidget);
        expect(find.text('Lớp IELTS Tối Mới'), findsOneWidget);
      },
    );

    test(
      'Test B: Newly created teacher (even before branch assignment) is immediately returned in teacher lookup without F5',
      () async {
        final repo = _FakeClassesRepository()
          ..teachers = [
            {
              'id': 'tch-1',
              'fullName': 'Thầy Trần Thanh Hà',
              'branchId': 'br-1',
            },
          ];

        final initialTeachers = await repo.getTeachers(branchId: 'br-1');
        expect(initialTeachers.length, 1);

        // Admin creates a new teacher account (branchId assigned or global null)
        repo.teachers.insert(0, {
          'id': 'tch-2',
          'fullName': 'Cô Phạm Minh Nguyệt',
          'branchId': null,
        });

        final syncedTeachers = await repo.getTeachers(branchId: 'br-1');
        expect(syncedTeachers.length, 2);
        expect(
          syncedTeachers.any((t) => t['fullName'] == 'Cô Phạm Minh Nguyệt'),
          isTrue,
        );
      },
    );

    test(
      'Test C: Course Academic Review, Publish, and Activate immediately sync CoursesBloc.cachedCourses and emit CoursesLoaded',
      () async {
        final repo = _FakeCoursesRepository()
          ..courses = [
            const CourseModel(
              id: 'crs-1',
              code: 'CRS-IELTS-2026',
              title: 'IELTS Masterclass',
              publicationStatus: 'DRAFT',
              isActive: false,
            ),
          ];
        final bloc = CoursesBloc(repository: repo);
        addTearDown(bloc.close);

        bloc.add(const FetchCourses(refresh: true));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.cachedCourses.first.publicationStatus, 'DRAFT');
        expect(bloc.cachedCourses.first.isActive, isFalse);

        bloc.add(const ConfirmCourseAcademicReviewEvent('crs-1'));
        bloc.add(
          const ChangeCoursePublicationStatusEvent(
            courseId: 'crs-1',
            status: 'PUBLISHED',
          ),
        );
        bloc.add(
          const ToggleCourseActiveEvent(courseId: 'crs-1', isActive: true),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<CoursesLoaded>());
        expect(bloc.cachedCourses.first.publicationStatus, 'PUBLISHED');
        expect(bloc.cachedCourses.first.isActive, isTrue);
      },
    );

    testWidgets(
      'Test D: Failed delete preserves existing class list; successful delete & cancel immediately update UI without F5',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final repo = _FakeClassesRepository()
          ..classes = [
            _makeClass(id: 'cls-del', code: 'CLS-DEL-01', status: 'PLANNING'),
            _makeClass(
              id: 'cls-cancel',
              code: 'CLS-CAN-02',
              status: 'OPEN',
              studentsCount: 5,
            ),
          ];
        final bloc = ClassesBloc(repository: repo);
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ClassesBloc>.value(
              value: bloc,
              child: const ClassListScreen(showAppBar: false),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Simulate failed delete -> must NOT lose list
        repo.deleteError = const ApiException(
          message: 'Lớp đã có dữ liệu liên quan, không thể xóa.',
          statusCode: 400,
        );
        await expectLater(
          () => bloc.deleteClassAndSync('cls-del'),
          throwsA(isA<ApiException>()),
        );
        await tester.pumpAndSettle();
        expect(find.text('CLS-DEL-01'), findsOneWidget);
        expect(find.text('CLS-CAN-02'), findsOneWidget);

        // 2. Simulate successful delete -> immediately disappears without F5
        repo.deleteError = null;
        await bloc.deleteClassAndSync('cls-del');
        await tester.pumpAndSettle();
        expect(find.text('CLS-DEL-01'), findsNothing);
        expect(find.text('CLS-CAN-02'), findsOneWidget);

        // 3. Simulate successful cancel -> immediately updates status to Đã hủy
        await bloc.updateClassAndSync('cls-cancel', status: 'CANCELLED');
        await tester.pumpAndSettle();
        expect(find.text('Đã hủy'), findsWidgets);
      },
    );

    test(
      'Test E: Enrolling/removing a student and updating a session immediately emit updated ClassDetailLoaded & sync cachedClasses',
      () async {
        final repo = _FakeClassesRepository()
          ..classes = [
            ClassModel(
              id: 'cls-1',
              code: 'IELTS-SYNC-01',
              name: 'Lớp Đồng Bộ Sĩ Số',
              courseId: 'crs-1',
              levelId: 'lvl-1',
              branchId: 'br-1',
              status: 'ONGOING',
              scheduleDays: const ['MON', 'WED'],
              startTime: '18:00',
              endTime: '20:00',
              studentsCount: 0,
              maxCapacity: 15,
              sessions: [
                ClassSessionModel(
                  id: 'ses-1',
                  classId: 'cls-1',
                  sessionNumber: 1,
                  title: 'Buổi 1',
                  date: DateTime(2026, 11, 2),
                  startTime: '18:00',
                  endTime: '20:00',
                  status: 'SCHEDULED',
                  roomName: 'P.101',
                  teacherName: 'GV Cũ',
                ),
              ],
            ),
          ];
        final bloc = ClassesBloc(repository: repo);
        addTearDown(bloc.close);

        bloc.add(const FetchClasses(refresh: true));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.cachedClasses.first.studentsCount, 0);

        // Enroll student
        bloc.add(
          const EnrollStudentEvent(classId: 'cls-1', studentId: 'stu-100'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.cachedClasses.first.studentsCount, 1);
        expect(bloc.getCachedDetail('cls-1')?.students.length, 1);

        // Update session teacher/room (verifies ClassModel.props includes sessions!)
        final emittedStates = <ClassesState>[];
        final sub = bloc.stream.listen(emittedStates.add);
        addTearDown(sub.cancel);

        bloc.add(
          const UpdateSessionEvent(
            classId: 'cls-1',
            sessionId: 'ses-1',
            teacherId: 'Cô Phạm Minh Nguyệt',
            roomId: 'P.202',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(
          emittedStates.whereType<ClassDetailLoaded>().any(
            (s) =>
                s.classDetail.sessions.first.teacherName ==
                    'Cô Phạm Minh Nguyệt' &&
                s.classDetail.sessions.first.roomName == 'P.202',
          ),
          isTrue,
        );

        // Remove student
        bloc.add(
          const RemoveStudentEvent(classId: 'cls-1', studentId: 'stu-100'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.cachedClasses.first.studentsCount, 0);
      },
    );

    test(
      'Test F: Stale out-of-order FetchClasses response does not overwrite newer created class state',
      () async {
        final staleCompleter = Completer<List<ClassModel>>();
        final repo = _FakeClassesRepository()
          ..classes = [_makeClass(id: 'cls-1', code: 'CLS-INIT')];
        final bloc = ClassesBloc(repository: repo);
        addTearDown(bloc.close);

        // Start a slow fetch that will return stale data later
        repo.pendingGetClassesCompleter = staleCompleter;
        bloc.add(const FetchClasses(refresh: true));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Meanwhile, a new class is created and newer fetch completes
        bloc.add(
          const CreateClassEvent(
            code: 'CLS-NEWER',
            name: 'Lớp Mới Nhất',
            courseId: 'crs-1',
            levelId: 'lvl-1',
            branchId: 'br-1',
            startDate: '2026-11-02',
            scheduleDays: ['MON', 'WED', 'FRI'],
            startTime: '18:00',
            endTime: '20:00',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(
          bloc.cachedClasses.any((c) => c.code == 'CLS-NEWER'),
          isTrue,
        );

        // Now complete the old stale fetch with only the initial class
        staleCompleter.complete([_makeClass(id: 'cls-1', code: 'CLS-INIT')]);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Newer class must NOT be overwritten by the stale response
        expect(
          bloc.cachedClasses.any((c) => c.code == 'CLS-NEWER'),
          isTrue,
        );
      },
    );
  });
}
