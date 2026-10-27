import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/class_model.dart';
import '../../domain/repositories/classes_repository.dart';

class TeacherMyClassesScreen extends StatefulWidget {
  const TeacherMyClassesScreen({super.key, this.initialSearch = ''});

  final String initialSearch;

  @override
  State<TeacherMyClassesScreen> createState() => _TeacherMyClassesScreenState();
}

class _TeacherMyClassesScreenState extends State<TeacherMyClassesScreen> {
  late Future<List<ClassModel>> _classes;
  late final TextEditingController _search;
  String _status = 'ALL';

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialSearch);
    _reload();
  }

  void _reload() => _classes = getIt<ClassesRepository>().getMyClasses();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: FutureBuilder<List<ClassModel>>(
      future: _classes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Không tải được lớp học được phân công.'),
                TextButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final query = _search.text.trim().toLowerCase();
        final classes = (snapshot.data ?? const <ClassModel>[]).where((item) {
          return (_status == 'ALL' || item.status == _status) &&
              (query.isEmpty ||
                  item.name.toLowerCase().contains(query) ||
                  item.code.toLowerCase().contains(query));
        }).toList();
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _classes;
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lớp học của tôi',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    onPressed: () => setState(_reload),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Tìm theo tên hoặc mã lớp',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                        DropdownMenuItem(
                          value: 'IN_PROGRESS',
                          child: Text('Đang học'),
                        ),
                        DropdownMenuItem(
                          value: 'OPEN_FOR_ENROLLMENT',
                          child: Text('Đang tuyển sinh'),
                        ),
                        DropdownMenuItem(
                          value: 'COMPLETED',
                          child: Text('Đã kết thúc'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _status = value ?? 'ALL'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (classes.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Không có lớp học phù hợp.'),
                  ),
                ),
              ...classes.map(
                (item) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.code} • ${item.courseTitle ?? 'Khóa học'} • ${item.levelName ?? 'Cấp độ'}',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.studentsCount} học viên • ${item.sessionsCount}/${item.totalSessions} buổi • ${item.status}',
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.push(
                                RouteNames.classDetail.replaceFirst(
                                  ':id',
                                  item.id,
                                ),
                              ),
                              child: const Text('Xem lớp'),
                            ),
                            OutlinedButton(
                              onPressed: () => context.push(
                                RouteNames.classAssignments.replaceFirst(
                                  ':classId',
                                  item.id,
                                ),
                                extra: true,
                              ),
                              child: const Text('Bài tập'),
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
      },
    ),
  );
}
