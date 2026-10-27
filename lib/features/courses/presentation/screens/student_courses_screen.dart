import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/domain/repositories/classes_repository.dart';

/// Read-only curriculum for classes in which the current student is enrolled.
class StudentCoursesScreen extends StatefulWidget {
  final bool showAppBar;

  const StudentCoursesScreen({super.key, this.showAppBar = false});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  late Future<List<ClassModel>> _classesFuture;
  final _curriculum = <String, Future<_StudentCurriculum>>{};
  final _expandedClasses = <String>{};
  String? _mobileSelectedClassId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _curriculum.clear();
    _expandedClasses.clear();
    _mobileSelectedClassId = null;
    _classesFuture = getIt<ClassesRepository>().getMyClasses();
  }

  Future<_StudentCurriculum> _loadCurriculum(ClassModel classItem) async {
    final repository = getIt<ClassesRepository>();
    final api = getIt<ApiClient>();
    final results = await Future.wait<dynamic>([
      api.get('/levels/${classItem.levelId}/modules'),
      repository.getClassSessions(classItem.id),
    ]);
    final response = results[0];
    final data = response is Map ? response['data'] ?? response : response;
    final modules = (data is List ? data : const <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return _StudentCurriculum(modules, results[1] as List<ClassSessionModel>);
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<ClassModel>>(
      future: _classesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _message(
            'Không tải được khóa học của bạn.',
            action: TextButton(
              onPressed: () => setState(_refresh),
              child: const Text('Thử lại'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final classes = snapshot.data!;
        if (classes.isEmpty) {
          return _message('Bạn chưa được ghi danh vào lớp học nào.');
        }
        if (AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
            AdaptiveSize.mobile) {
          return _buildMobileCourses(classes);
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Khóa học của tôi',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Làm mới',
                  onPressed: () => setState(_refresh),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${classes.length} lớp đang hoặc đã tham gia'),
            const SizedBox(height: 16),
            ...classes.map(
              (classItem) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: ValueKey(classItem.id),
                    onExpansionChanged: (expanded) => setState(() {
                      if (expanded) {
                        _expandedClasses.add(classItem.id);
                      } else {
                        _expandedClasses.remove(classItem.id);
                      }
                    }),
                    leading: const CircleAvatar(
                      child: Icon(Icons.school_outlined),
                    ),
                    title: Text(classItem.courseTitle ?? classItem.name),
                    subtitle: Text(
                      '${classItem.name} · ${classItem.levelName ?? classItem.code}',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Giảng viên: ${classItem.mainTeacherName ?? 'Chưa phân công'}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_expandedClasses.contains(classItem.id))
                        FutureBuilder<_StudentCurriculum>(
                          future: _curriculum.putIfAbsent(
                            classItem.id,
                            () => _loadCurriculum(classItem),
                          ),
                          builder: (context, curriculumSnapshot) {
                            if (curriculumSnapshot.hasError) {
                              return Row(
                                children: [
                                  const Expanded(
                                    child: Text('Không tải được giáo trình.'),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _curriculum.remove(classItem.id);
                                    }),
                                    child: const Text('Thử lại'),
                                  ),
                                ],
                              );
                            }
                            if (!curriculumSnapshot.hasData) {
                              return const LinearProgressIndicator();
                            }
                            return _buildModules(curriculumSnapshot.data!);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    return widget.showAppBar
        ? Scaffold(
            appBar: AppBar(title: const Text('Khóa học')),
            body: body,
          )
        : body;
  }

  Widget _buildMobileCourses(List<ClassModel> classes) {
    final selected = classes.where((item) => item.id == _mobileSelectedClassId);
    if (selected.isNotEmpty) {
      return _buildMobileCourseDetail(selected.first);
    }
    return RefreshIndicator(
      onRefresh: () async {
        setState(_refresh);
        try {
          await _classesFuture;
        } catch (_) {
          // FutureBuilder displays retry action.
        }
      },
      child: ListView(
        key: const ValueKey('student-courses-mobile-list'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const Text(
            'Khóa học của tôi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${classes.length} lớp bạn đang hoặc đã tham gia',
            style: const TextStyle(color: AppColors.neutral600),
          ),
          const SizedBox(height: MobileTokens.sectionGap),
          for (final classItem in classes)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MobileSectionCard(
                child: InkWell(
                  key: ValueKey('student-mobile-course-${classItem.id}'),
                  onTap: () =>
                      setState(() => _mobileSelectedClassId = classItem.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  classItem.courseTitle ?? classItem.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  classItem.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (classItem.levelName != null)
                            MobileStatusPill(
                              label: classItem.levelName!,
                              color: AppColors.secondary,
                            ),
                          MobileStatusPill(
                            label: classItem.code,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Giảng viên: ${classItem.mainTeacherName ?? 'Chưa phân công'}',
                        style: const TextStyle(color: AppColors.neutral600),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Xem giáo trình và bài học',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileCourseDetail(ClassModel classItem) {
    final future = _curriculum.putIfAbsent(
      classItem.id,
      () => _loadCurriculum(classItem),
    );
    return ListView(
      key: const ValueKey('student-courses-mobile-detail'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _mobileSelectedClassId = null),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Khóa học của tôi'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          classItem.courseTitle ?? classItem.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          classItem.name,
          style: const TextStyle(color: AppColors.neutral600),
        ),
        const SizedBox(height: 14),
        MobileSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lớp học của bạn',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Mã lớp: ${classItem.code}'),
              Text('Trình độ: ${classItem.levelName ?? 'Đang cập nhật'}'),
              Text(
                'Giảng viên: ${classItem.mainTeacherName ?? 'Chưa phân công'}',
              ),
            ],
          ),
        ),
        const SizedBox(height: MobileTokens.sectionGap),
        FutureBuilder<_StudentCurriculum>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return MobileSectionCard(
                child: Column(
                  children: [
                    const Text('Không tải được giáo trình.'),
                    TextButton(
                      onPressed: () =>
                          setState(() => _curriculum.remove(classItem.id)),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildMobileModules(snapshot.data!);
          },
        ),
      ],
    );
  }

  Widget _buildMobileModules(_StudentCurriculum curriculum) {
    final lessons = curriculum.modules
        .expand(
          (module) => (module['lessons'] as List? ?? const []).whereType<Map>(),
        )
        .toList();
    final completed = curriculum.sessions
        .where(
          (session) =>
              session.status == 'COMPLETED' && session.lessonId != null,
        )
        .map((session) => session.lessonId)
        .toSet();
    final completedCount = lessons
        .where((lesson) => completed.contains(lesson['id']?.toString()))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MobileSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tiến độ học tập',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '$completedCount/${lessons.length} bài học đã hoàn thành',
                style: const TextStyle(color: AppColors.neutral600),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: lessons.isEmpty ? 0 : completedCount / lessons.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
        const SizedBox(height: MobileTokens.sectionGap),
        const Text(
          'Giáo trình',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (curriculum.modules.isEmpty)
          const MobileSectionCard(
            child: Text('Giáo trình đang được cập nhật.'),
          ),
        for (final module in curriculum.modules) ...[
          MobileSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                '${module['title'] ?? 'Chương học'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              children: [
                for (final lesson
                    in (module['lessons'] as List? ?? const [])
                        .whereType<Map>()) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      completed.contains(lesson['id']?.toString())
                          ? Icons.check_circle_rounded
                          : Icons.menu_book_outlined,
                      color: completed.contains(lesson['id']?.toString())
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    title: Text('${lesson['title'] ?? 'Bài học'}'),
                    subtitle: Text(
                      completed.contains(lesson['id']?.toString())
                          ? 'Đã học'
                          : 'Chưa hoàn thành',
                    ),
                  ),
                  for (final material
                      in (lesson['materials'] as List? ?? const [])
                          .whereType<Map>())
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 24),
                      leading: const Icon(Icons.attach_file_rounded),
                      title: Text('${material['title'] ?? 'Tài liệu'}'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () =>
                          _openMaterial(material['fileUrl']?.toString()),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildModules(_StudentCurriculum curriculum) {
    final lessons = curriculum.modules
        .expand(
          (module) => (module['lessons'] as List? ?? const []).whereType<Map>(),
        )
        .toList();
    final completed = curriculum.sessions
        .where(
          (session) =>
              session.status == 'COMPLETED' && session.lessonId != null,
        )
        .map((session) => session.lessonId)
        .toSet();
    final completedCount = lessons
        .where((lesson) => completed.contains(lesson['id']?.toString()))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tiến độ: $completedCount/${lessons.length} bài học'),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: lessons.isEmpty ? 0 : completedCount / lessons.length,
        ),
        const SizedBox(height: 12),
        if (curriculum.modules.isEmpty)
          const Text('Giáo trình của lớp đang được cập nhật.'),
        ...curriculum.modules.map(
          (module) => ExpansionTile(
            title: Text('${module['title'] ?? 'Chương học'}'),
            tilePadding: EdgeInsets.zero,
            children: (module['lessons'] as List? ?? const [])
                .whereType<Map>()
                .map((lesson) {
                  final done = completed.contains(lesson['id']?.toString());
                  final materials = (lesson['materials'] as List? ?? const [])
                      .whereType<Map>();
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          done ? Icons.check_circle : Icons.menu_book_outlined,
                          color: done ? Colors.green : null,
                        ),
                        title: Text('${lesson['title'] ?? 'Bài học'}'),
                        subtitle: Text(done ? 'Đã học' : 'Chưa hoàn thành'),
                      ),
                      ...materials.map(
                        (material) => ListTile(
                          contentPadding: const EdgeInsets.only(left: 40),
                          leading: const Icon(Icons.attach_file),
                          title: Text('${material['title'] ?? 'Tài liệu'}'),
                          trailing: const Icon(Icons.open_in_new, size: 18),
                          onTap: () =>
                              _openMaterial(material['fileUrl']?.toString()),
                        ),
                      ),
                    ],
                  );
                })
                .toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _openMaterial(String? url) async {
    final uri = Uri.tryParse(url ?? '');
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được tài liệu này.')),
      );
    }
  }

  Widget _message(String message, {Widget? action}) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );
}

class _StudentCurriculum {
  final List<Map<String, dynamic>> modules;
  final List<ClassSessionModel> sessions;

  const _StudentCurriculum(this.modules, this.sessions);
}
