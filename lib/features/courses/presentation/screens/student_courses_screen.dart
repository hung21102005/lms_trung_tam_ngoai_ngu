import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
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

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _curriculum.clear();
    _expandedClasses.clear();
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
