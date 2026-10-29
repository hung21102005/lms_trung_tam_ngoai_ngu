import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../data/repositories/program_catalog_repository.dart';

Future<bool?> openCourseManagementEditor(
  BuildContext context, {
  required ProgramCatalogRepository repository,
  String? courseId,
}) async {
  final programs = await repository.getPrograms();
  final course = courseId == null ? null : await repository.getCourse(courseId);
  if (!context.mounted) return null;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => CourseEditor(
      course: course,
      programs: programs,
      initialProgramId: course?.programId,
      onSave: (values, isActive) => repository.saveCourse(
        id: course?.id,
        programId: values['programId']!,
        code: values['code']!,
        title: values['title']!,
        slug: values['slug']!,
        description: values['description']!,
        publicDescription: values['publicDescription']!,
        targetAudience: values['targetAudience']!,
        language: values['language']!,
        thumbnailUrl: values['thumbnailUrl']!,
        isActive: isActive,
      ),
    ),
  );
}

class ProgramCatalogScreen extends StatefulWidget {
  final ProgramCatalogRepository repository;
  final bool canManage;

  const ProgramCatalogScreen({
    super.key,
    required this.repository,
    this.canManage = true,
  });

  @override
  State<ProgramCatalogScreen> createState() => _ProgramCatalogScreenState();
}

class _ProgramCatalogScreenState extends State<ProgramCatalogScreen> {
  late Future<List<TrainingProgramRecord>> _programs;

  @override
  void initState() {
    super.initState();
    _programs = widget.repository.getPrograms();
  }

  void _reload() {
    setState(() {
      _programs = widget.repository.getPrograms();
    });
  }

  Future<void> _openEditor([TrainingProgramRecord? program]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ProgramEditor(
        program: program,
        onSave: (values) async {
          await widget.repository.saveProgram(
            id: program?.id,
            code: values['code']!,
            slug: values['slug']!,
            nameVi: values['nameVi']!,
            nameEn: values['nameEn']!,
            category: values['category']!,
            description: values['description']!,
            targetAudience: values['targetAudience']!,
          );
        },
      ),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _openDetails(TrainingProgramRecord program) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ProgramDetails(
        repository: widget.repository,
        programId: program.id,
        onChanged: _reload,
        canManage: widget.canManage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Chương trình đào tạo')),
      floatingActionButton: mobile && widget.canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm chương trình'),
            )
          : null,
      body: FutureBuilder<List<TrainingProgramRecord>>(
        future: _programs,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 38),
                  const SizedBox(height: 12),
                  Text('Không tải được chương trình: ${snapshot.error}'),
                  TextButton(onPressed: _reload, child: const Text('Thử lại')),
                ],
              ),
            );
          }
          final programs = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _programs;
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 32,
                16,
                mobile ? 16 : 32,
                100,
              ),
              children: [
                if (!mobile && widget.canManage)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _openEditor(),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm chương trình'),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  '${programs.length} chương trình',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chỉ nội dung đã duyệt và bật hiển thị mới xuất hiện trên website công khai.',
                ),
                const SizedBox(height: 16),
                if (programs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Chưa có chương trình đào tạo.'),
                    ),
                  ),
                for (final program in programs) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openDetails(program),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    program.nameVi,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${program.code} · ${program.nameEn}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(label: Text(_statusLabel(program.status))),
                                Chip(
                                  label: Text(
                                    '${program.courseCount} khóa học',
                                  ),
                                ),
                                if (program.isPublic)
                                  const Chip(
                                    label: Text('Đang hiển thị công khai'),
                                  ),
                              ],
                            ),
                            if (program.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                program.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
  'DRAFT' => 'Bản nháp',
  'IN_REVIEW' => 'Chờ duyệt',
  'PUBLISHED' => 'Đã duyệt',
  'ARCHIVED' => 'Đã lưu trữ',
  _ => status,
};

class _ProgramDetails extends StatefulWidget {
  final ProgramCatalogRepository repository;
  final String programId;
  final VoidCallback onChanged;
  final bool canManage;

  const _ProgramDetails({
    required this.repository,
    required this.programId,
    required this.onChanged,
    required this.canManage,
  });

  @override
  State<_ProgramDetails> createState() => _ProgramDetailsState();
}

class _ProgramDetailsState extends State<_ProgramDetails> {
  late Future<TrainingProgramRecord> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getProgram(widget.programId);
  }

  void _refresh() {
    setState(() {
      _future = widget.repository.getProgram(widget.programId);
    });
  }

  Future<void> _change(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      widget.onChanged();
      if (mounted) {
        _refresh();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không cập nhật được: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openCourseEditor(
    TrainingProgramRecord program, [
    ProgramCourseRecord? course,
  ]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CourseEditor(
        course: course,
        programs: [program],
        initialProgramId: program.id,
        onSave: (values, isActive) => widget.repository.saveCourse(
          id: course?.id,
          programId: values['programId']!,
          code: values['code']!,
          title: values['title']!,
          slug: values['slug']!,
          description: values['description']!,
          publicDescription: values['publicDescription']!,
          targetAudience: values['targetAudience']!,
          language: values['language']!,
          thumbnailUrl: values['thumbnailUrl']!,
          isActive: isActive,
        ),
      ),
    );
    if (saved == true && mounted) {
      widget.onChanged();
      _refresh();
    }
  }

  Future<void> _openAttachCourse(String programId) async {
    final attached = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _AttachCourseSheet(
        repository: widget.repository,
        programId: programId,
      ),
    );
    if (attached == true && mounted) {
      widget.onChanged();
      _refresh();
    }
  }

  Future<void> _showCoursePublicationCheck(ProgramCourseRecord course) async {
    try {
      final result = await widget.repository.validateCoursePublication(
        course.id,
      );
      if (!mounted) return;
      final blockers = (result['blockers'] as List? ?? const [])
          .map((item) => item.toString())
          .toList();
      final canConfirmReview = result['canConfirmReview'] == true;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Kiểm tra công bố: ${course.title}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['canPublish'] == true
                        ? 'Khóa học đã đủ điều kiện công bố.'
                        : 'Cần xử lý các mục sau trước khi công bố:',
                  ),
                  for (final blocker in blockers)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('• $blocker'),
                    ),
                  if (canConfirmReview) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Chỉ xác nhận sau khi đã đọc mô tả, cấp độ và toàn bộ lộ trình. Nội dung thay đổi sẽ yêu cầu rà soát lại.',
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
            if (canConfirmReview)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _change(
                    () => widget.repository.confirmCourseAcademicReview(
                      course.id,
                    ),
                  );
                },
                child: const Text('Xác nhận đã rà soát'),
              ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không kiểm tra được khóa học: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .9,
    child: FutureBuilder<TrainingProgramRecord>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _refresh,
              child: Text('Không tải được. Thử lại: ${snapshot.error}'),
            ),
          );
        }
        final program = snapshot.data!;
        final next = switch (program.status) {
          'DRAFT' => 'IN_REVIEW',
          'IN_REVIEW' => 'PUBLISHED',
          'PUBLISHED' => 'ARCHIVED',
          _ => null,
        };
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              program.nameVi,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('${program.code} · ${_statusLabel(program.status)}'),
            const SizedBox(height: 12),
            Text(
              program.description.isEmpty
                  ? 'Chưa có mô tả'
                  : program.description,
            ),
            const SizedBox(height: 12),
            if (widget.canManage && program.status != 'ARCHIVED')
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final saved = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          showDragHandle: true,
                          builder: (_) => _ProgramEditor(
                            program: program,
                            onSave: (values) => widget.repository.saveProgram(
                              id: program.id,
                              code: values['code']!,
                              slug: values['slug']!,
                              nameVi: values['nameVi']!,
                              nameEn: values['nameEn']!,
                              category: values['category']!,
                              description: values['description']!,
                              targetAudience: values['targetAudience']!,
                            ),
                          ),
                        );
                        if (saved == true) {
                          widget.onChanged();
                          _refresh();
                        }
                      },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Sửa chương trình'),
              ),
            if (widget.canManage && next != null)
              FilledButton(
                onPressed: _saving
                    ? null
                    : () => _change(
                        () => widget.repository.changeStatus(program.id, next),
                      ),
                child: Text(
                  next == 'IN_REVIEW'
                      ? 'Gửi duyệt'
                      : next == 'PUBLISHED'
                      ? 'Duyệt chương trình'
                      : 'Lưu trữ chương trình',
                ),
              ),
            if (widget.canManage && program.status == 'IN_REVIEW')
              TextButton(
                onPressed: _saving
                    ? null
                    : () => _change(
                        () =>
                            widget.repository.changeStatus(program.id, 'DRAFT'),
                      ),
                child: const Text('Trả về bản nháp'),
              ),
            if (widget.canManage && program.status == 'PUBLISHED')
              SwitchListTile.adaptive(
                title: const Text('Hiển thị trên website công khai'),
                value: program.isPublic,
                onChanged: _saving
                    ? null
                    : (value) => _change(
                        () =>
                            widget.repository.setVisibility(program.id, value),
                      ),
              ),
            const Divider(height: 32),
            Text(
              'Khóa học (${program.courses.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (widget.canManage && program.status != 'ARCHIVED') ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _openAttachCourse(program.id),
                    icon: const Icon(Icons.link),
                    label: const Text('Gắn khóa đã có'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _openCourseEditor(program),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo khóa trong chương trình'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (program.courses.isEmpty)
              const Text('Chưa có khóa học trong chương trình.'),
            for (final course in program.courses)
              Card(
                child: ListTile(
                  title: Text(course.title),
                  subtitle: Text(
                    '${course.code} · ${_statusLabel(course.status)} · '
                    '${course.isActive ? 'Đang hoạt động' : 'Tạm ngưng'}',
                  ),
                  trailing: widget.canManage && course.status != 'ARCHIVED'
                      ? PopupMenuButton<String>(
                          tooltip: 'Thao tác khóa học',
                          onSelected: (action) {
                            if (action == 'edit') {
                              _openCourseEditor(program, course);
                            } else if (action == 'validate') {
                              _showCoursePublicationCheck(course);
                            } else {
                              _change(
                                () => widget.repository.changeCourseStatus(
                                  course.id,
                                  action,
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'validate',
                              child: Text('Kiểm tra công bố'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Sửa khóa học'),
                            ),
                            if (course.status == 'DRAFT')
                              const PopupMenuItem(
                                value: 'IN_REVIEW',
                                child: Text('Gửi duyệt khóa'),
                              ),
                            if (course.status == 'IN_REVIEW') ...[
                              const PopupMenuItem(
                                value: 'DRAFT',
                                child: Text('Trả về nháp'),
                              ),
                              const PopupMenuItem(
                                value: 'PUBLISHED',
                                child: Text('Duyệt công bố khóa'),
                              ),
                            ],
                            if (course.status == 'PUBLISHED') ...[
                              const PopupMenuItem(
                                value: 'DRAFT',
                                child: Text('Ngừng công bố'),
                              ),
                              const PopupMenuItem(
                                value: 'ARCHIVED',
                                child: Text('Lưu trữ khóa'),
                              ),
                            ],
                          ],
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    final router = GoRouter.of(context);
                    Navigator.pop(context);
                    router.push(
                      RouteNames.courseDetail.replaceFirst(':id', course.id),
                    );
                  },
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ProgramEditor extends StatefulWidget {
  final TrainingProgramRecord? program;
  final Future<void> Function(Map<String, String>) onSave;

  const _ProgramEditor({this.program, required this.onSave});

  @override
  State<_ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends State<_ProgramEditor> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _fields = {
      'code': TextEditingController(text: p?.code ?? ''),
      'slug': TextEditingController(text: p?.slug ?? ''),
      'nameVi': TextEditingController(text: p?.nameVi ?? ''),
      'nameEn': TextEditingController(text: p?.nameEn ?? ''),
      'category': TextEditingController(text: p?.category ?? ''),
      'description': TextEditingController(text: p?.description ?? ''),
      'targetAudience': TextEditingController(text: p?.targetAudience ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _fields.map((key, value) => MapEntry(key, value.text.trim())),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không lưu được: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(
      String key,
      String label, {
      bool required = true,
      int lines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fields[key],
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            required && (value == null || value.trim().isEmpty)
            ? 'Vui lòng nhập $label'
            : null,
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.program == null
                        ? 'Thêm chương trình'
                        : 'Sửa chương trình',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  field('code', 'Mã chương trình'),
                  field('slug', 'Đường dẫn công khai'),
                  field('nameVi', 'Tên tiếng Việt'),
                  field('nameEn', 'Tên tiếng Anh'),
                  field('category', 'Danh mục'),
                  field('description', 'Mô tả', required: false, lines: 3),
                  field('targetAudience', 'Đối tượng học', required: false),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Đang lưu...' : 'Lưu chương trình'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CourseEditor extends StatefulWidget {
  final ProgramCourseRecord? course;
  final List<TrainingProgramRecord> programs;
  final String? initialProgramId;
  final Future<void> Function(Map<String, String>, bool) onSave;

  const CourseEditor({
    super.key,
    this.course,
    required this.programs,
    this.initialProgramId,
    required this.onSave,
  });

  @override
  State<CourseEditor> createState() => _CourseEditorState();
}

class _CourseEditorState extends State<CourseEditor> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late bool _isActive;
  late String? _programId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _isActive = course?.isActive ?? false;
    _programId = course?.programId ?? widget.initialProgramId;
    _fields = {
      'code': TextEditingController(text: course?.code ?? ''),
      'title': TextEditingController(text: course?.title ?? ''),
      'slug': TextEditingController(text: course?.slug ?? ''),
      'description': TextEditingController(text: course?.description ?? ''),
      'publicDescription': TextEditingController(
        text: course?.publicDescription ?? '',
      ),
      'targetAudience': TextEditingController(
        text: course?.targetAudience ?? '',
      ),
      'language': TextEditingController(text: course?.language ?? 'English'),
      'thumbnailUrl': TextEditingController(text: course?.thumbnailUrl ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate() || _programId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave({
        ..._fields.map((key, value) => MapEntry(key, value.text.trim())),
        'programId': _programId!,
      }, _isActive);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được khóa học: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label, {int lines = 1}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fields[key],
        enabled:
            widget.course == null ||
            widget.course!.status == 'DRAFT' ||
            widget.course!.status == 'IN_REVIEW' ||
            key == 'thumbnailUrl',
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if ((key == 'code' ||
                  key == 'title' ||
                  key == 'slug' ||
                  key == 'language') &&
              (value == null || value.trim().isEmpty)) {
            return 'Vui lòng nhập $label';
          }
          if (key == 'code' &&
              !RegExp(r'^[A-Z0-9_-]+$').hasMatch(value!.trim())) {
            return 'Mã chỉ gồm chữ hoa, số, gạch dưới và gạch nối';
          }
          if (key == 'slug' &&
              !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$')
                  .hasMatch(value?.trim() ?? '')) {
            return 'Đường dẫn chỉ gồm chữ thường, số và dấu gạch nối';
          }
          final imageUri = key == 'thumbnailUrl' && value != null
              ? Uri.tryParse(value.trim())
              : null;
          if (key == 'thumbnailUrl' &&
              value != null &&
              value.trim().isNotEmpty &&
              (imageUri == null ||
                  !imageUri.hasAuthority ||
                  !['http', 'https'].contains(imageUri.scheme))) {
            return 'Vui lòng nhập URL ảnh hợp lệ';
          }
          return null;
        },
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.course == null
                        ? 'Tạo khóa học nháp'
                        : 'Sửa thông tin khóa học',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Khóa mới ở trạng thái nháp. Cần nội dung học thuật và duyệt trước khi công bố.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _programId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chương trình đào tạo',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.programs
                        .where((program) => program.status != 'ARCHIVED')
                        .map(
                          (program) => DropdownMenuItem(
                            value: program.id,
                            child: Text(program.nameVi),
                          ),
                        )
                        .toList(),
                    onChanged:
                        widget.course == null ||
                            widget.course!.status == 'DRAFT'
                        ? (value) => setState(() => _programId = value)
                        : null,
                    validator: (value) => value == null
                        ? 'Vui lòng chọn chương trình đào tạo'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  field('code', 'Mã khóa học'),
                  field('title', 'Tên khóa học'),
                  field('slug', 'Đường dẫn công khai'),
                  field('description', 'Mô tả nội bộ', lines: 3),
                  field('publicDescription', 'Mô tả công khai', lines: 3),
                  field('targetAudience', 'Đối tượng học', lines: 2),
                  field('language', 'Ngôn ngữ giảng dạy'),
                  field('thumbnailUrl', 'URL ảnh đại diện'),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Khóa đang hoạt động'),
                    subtitle: const Text(
                      'Chỉ bật sau khi đã rà soát nội dung.',
                    ),
                    value: _isActive,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _isActive = value),
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Đang lưu...' : 'Lưu khóa học'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachCourseSheet extends StatefulWidget {
  final ProgramCatalogRepository repository;
  final String programId;

  const _AttachCourseSheet({required this.repository, required this.programId});

  @override
  State<_AttachCourseSheet> createState() => _AttachCourseSheetState();
}

class _AttachCourseSheetState extends State<_AttachCourseSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  late Future<List<ProgramCourseRecord>> _results;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _results = widget.repository.searchUnassignedCourses('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _results = widget.repository.searchUnassignedCourses(value.trim());
        });
      }
    });
  }

  Future<void> _attach(ProgramCourseRecord course) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.repository.attachCourse(course.id, widget.programId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không gắn được khóa học: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: FractionallySizedBox(
        heightFactor: .8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gắn khóa học đã có',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    autofocus: true,
                    onChanged: _searchChanged,
                    decoration: const InputDecoration(
                      labelText: 'Tìm tên hoặc mã khóa học',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ProgramCourseRecord>>(
                future: _results,
                builder: (context, snapshot) {
                  if (!snapshot.hasData && !snapshot.hasError) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Không tìm được khóa học: ${snapshot.error}'),
                    );
                  }
                  final courses = snapshot.data!;
                  if (courses.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có khóa chưa gắn chương trình phù hợp.',
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return ListTile(
                        title: Text(course.title),
                        subtitle: Text(course.code),
                        trailing: _saving ? null : const Icon(Icons.add_link),
                        onTap: _saving ? null : () => _attach(course),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
