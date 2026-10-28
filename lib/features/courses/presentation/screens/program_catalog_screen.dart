import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../data/repositories/program_catalog_repository.dart';

class ProgramCatalogScreen extends StatefulWidget {
  final ProgramCatalogRepository repository;

  const ProgramCatalogScreen({super.key, required this.repository});

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Chương trình đào tạo')),
      floatingActionButton: mobile
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
                if (!mobile)
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

  const _ProgramDetails({
    required this.repository,
    required this.programId,
    required this.onChanged,
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
            if (program.status != 'ARCHIVED')
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
            if (next != null)
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
            if (program.status == 'IN_REVIEW')
              TextButton(
                onPressed: _saving
                    ? null
                    : () => _change(
                        () =>
                            widget.repository.changeStatus(program.id, 'DRAFT'),
                      ),
                child: const Text('Trả về bản nháp'),
              ),
            if (program.status == 'PUBLISHED')
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
                  trailing: const Icon(Icons.chevron_right),
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
