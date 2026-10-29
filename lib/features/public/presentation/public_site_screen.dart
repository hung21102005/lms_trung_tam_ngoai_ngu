import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../data/public_catalog_repository.dart';

enum PublicPage {
  home,
  programs,
  courses,
  courseDetail,
  classes,
  consultation,
  registration,
  myRegistrations,
}

class PublicSiteScreen extends StatefulWidget {
  const PublicSiteScreen({
    super.key,
    required this.repository,
    required this.page,
    this.slug,
    this.targetCourse,
    this.programSlug,
    this.dashboardRoute,
    this.courseId,
    this.classId,
    this.isStudent = false,
    this.studentName,
  });

  final PublicCatalogRepository repository;
  final PublicPage page;
  final String? slug;
  final String? targetCourse;
  final String? programSlug;
  final String? dashboardRoute;
  final String? courseId;
  final String? classId;
  final bool isStudent;
  final String? studentName;

  @override
  State<PublicSiteScreen> createState() => _PublicSiteScreenState();
}

class _PublicSiteScreenState extends State<PublicSiteScreen> {
  late Future<dynamic> _content;
  int _classPage = 1;
  final TextEditingController _courseSearch = TextEditingController();
  String _courseSort = 'name';
  String? _programFilter;

  @override
  void initState() {
    super.initState();
    _programFilter = widget.programSlug;
    _load();
  }

  @override
  void didUpdateWidget(covariant PublicSiteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programSlug != widget.programSlug) {
      _programFilter = widget.programSlug;
    }
  }

  @override
  void dispose() {
    _courseSearch.dispose();
    super.dispose();
  }

  void _load() {
    _content = switch (widget.page) {
      PublicPage.home => Future.wait([
        widget.repository.programs(),
        widget.repository.classes(),
        widget.repository.courses(),
      ]),
      PublicPage.programs => widget.repository.programs(),
      PublicPage.courses => widget.repository.courses(),
      PublicPage.courseDetail => widget.repository.course(widget.slug ?? ''),
      PublicPage.classes => widget.repository.classes(
        courseId: widget.courseId,
        page: _classPage,
      ),
      PublicPage.consultation => Future.value(null),
      PublicPage.registration => widget.repository.classDetail(
        widget.classId ?? '',
      ),
      PublicPage.myRegistrations => widget.repository.myRegistrations(),
    };
  }

  void _refresh() => setState(_load);

  void _navigate(String path) => context.go(path);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 1000;
        final current = switch (widget.page) {
          PublicPage.home => 0,
          PublicPage.programs => 1,
          PublicPage.courses || PublicPage.courseDetail => 2,
          PublicPage.classes ||
          PublicPage.registration ||
          PublicPage.myRegistrations => 3,
          PublicPage.consultation => 4,
        };
        const routes = [
          RouteNames.publicHome,
          RouteNames.publicPrograms,
          RouteNames.publicCourses,
          RouteNames.publicClasses,
          RouteNames.publicConsultation,
        ];
        const labels = [
          'Trang chủ',
          'Chương trình',
          'Khóa học',
          'Lớp khai giảng',
          'Tư vấn',
        ];
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text(
              'EduLMS',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: mobile
                ? [
                    IconButton(
                      tooltip: widget.dashboardRoute == null
                          ? 'Đăng nhập'
                          : 'Vào LMS',
                      onPressed: () =>
                          _navigate(widget.dashboardRoute ?? RouteNames.login),
                      icon: Icon(
                        widget.dashboardRoute == null
                            ? Icons.login_rounded
                            : Icons.dashboard_outlined,
                      ),
                    ),
                  ]
                : [
                    for (var i = 0; i < routes.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton(
                          onPressed: () => _navigate(routes[i]),
                          child: Text(labels[i]),
                        ),
                      ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () =>
                          _navigate(widget.dashboardRoute ?? RouteNames.login),
                      child: Text(
                        widget.dashboardRoute == null ? 'Đăng nhập' : 'Vào LMS',
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
          ),
          bottomNavigationBar: mobile
              ? NavigationBar(
                  selectedIndex: current,
                  onDestinationSelected: (index) => _navigate(routes[index]),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      label: 'Trang chủ',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_tree_outlined),
                      label: 'Chương trình',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      label: 'Khóa học',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.event_outlined),
                      label: 'Lớp học',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.support_agent_outlined),
                      label: 'Tư vấn',
                    ),
                  ],
                )
              : null,
          body: SafeArea(
            child: widget.page == PublicPage.consultation
                ? _ConsultationForm(
                    repository: widget.repository,
                    targetCourse: widget.targetCourse,
                  )
                : FutureBuilder<dynamic>(
                    future: _content,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _MessageState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Không tải được nội dung',
                          detail: '${snapshot.error}',
                          action: TextButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        );
                      }
                      return switch (widget.page) {
                        PublicPage.home => _home(
                          snapshot.data as List<dynamic>,
                        ),
                        PublicPage.programs => _programs(
                          snapshot.data as List<Map<String, dynamic>>,
                        ),
                        PublicPage.courses => _courses(
                          snapshot.data as List<Map<String, dynamic>>,
                        ),
                        PublicPage.courseDetail => _courseDetail(
                          snapshot.data as Map<String, dynamic>,
                        ),
                        PublicPage.classes => _classes(
                          snapshot.data as Map<String, dynamic>,
                        ),
                        PublicPage.consultation => const SizedBox.shrink(),
                        PublicPage.registration => _RegistrationForm(
                          repository: widget.repository,
                          offering: snapshot.data as Map<String, dynamic>,
                          isStudent: widget.isStudent,
                          studentName: widget.studentName,
                        ),
                        PublicPage.myRegistrations => _myRegistrations(
                          snapshot.data as List<Map<String, dynamic>>,
                        ),
                      };
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _pageScroll(List<Widget> children) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );

  Widget _home(List<dynamic> result) {
    final programs = result[0] as List<Map<String, dynamic>>;
    final classes = result[1] as Map<String, dynamic>;
    final offerings = (classes['items'] as List).cast<Map<String, dynamic>>();
    final courses = result[2] as List<Map<String, dynamic>>;
    return _pageScroll([
      _HeroCard(
        title: 'Học tiếng Anh theo lộ trình của bạn',
        subtitle: 'Khám phá chương trình đào tạo và lớp đang nhận đăng ký tại EduLMS.',
        onExplore: () => _navigate(RouteNames.publicCourses),
        onConsult: () => _navigate(RouteNames.publicConsultation),
      ),
      const SizedBox(height: 32),
      _SectionHeading(
        'Chương trình đào tạo',
        () => _navigate(RouteNames.publicPrograms),
      ),
      const SizedBox(height: 12),
      if (programs.isEmpty)
        const _EmptyCard('Chương trình đang được chuẩn bị công bố.')
      else
        _responsiveCards(
          programs
              .take(3)
              .map(
                (item) => _InfoCard(
                  icon: Icons.school_outlined,
                  title: _string(item['nameVi']),
                  subtitle: _string(item['description']),
                  footnote: _string(item['targetAudience']),
                  onTap: () => _navigate(
                    '${RouteNames.publicCourses}?chuong-trinh=${Uri.encodeQueryComponent(_string(item['slug']))}',
                  ),
                ),
              )
              .toList(),
        ),
      const SizedBox(height: 32),
      _SectionHeading(
        'Khóa học đã công bố',
        () => _navigate(RouteNames.publicCourses),
      ),
      const SizedBox(height: 12),
      if (courses.isEmpty)
        const _EmptyCard('Khóa học đang được chuẩn bị công bố.')
      else
        _responsiveCards(
          courses.take(3).map((course) {
            final program = course['program'] as Map?;
            return _InfoCard(
              icon: Icons.menu_book_rounded,
              title: _string(course['title']),
              subtitle: _string(course['publicDescription']),
              footnote: _string(program?['nameVi']),
              actionLabel: 'Xem khóa học',
              onTap: () => _navigate(
                '/khoa-hoc-cong-khai/${Uri.encodeComponent(_string(course['slug']))}',
              ),
            );
          }).toList(),
        ),
      const SizedBox(height: 32),
      _SectionHeading(
        'Lớp sắp khai giảng',
        () => _navigate(RouteNames.publicClasses),
      ),
      const SizedBox(height: 12),
      if (offerings.isEmpty)
        const _EmptyCard('Hiện chưa có lớp mở đăng ký.')
      else
        _responsiveCards(offerings.take(3).map(_offeringCard).toList()),
    ]);
  }

  Widget _programs(List<Map<String, dynamic>> programs) => _pageScroll([
    const _PageHeading(
      'Chương trình đào tạo',
      'Khám phá các nhóm chương trình đã được công bố.',
    ),
    const SizedBox(height: 24),
    if (programs.isEmpty)
      const _EmptyCard('Chưa có chương trình được công bố.')
    else
      _responsiveCards(
        programs
            .map(
              (program) => _InfoCard(
                icon: Icons.account_tree_outlined,
                title: _string(program['nameVi']),
                subtitle: _string(program['description']),
                footnote: _string(program['targetAudience']),
                actionLabel: 'Xem khóa học',
                onTap: () => _navigate(
                  '${RouteNames.publicCourses}?chuong-trinh=${Uri.encodeQueryComponent(_string(program['slug']))}',
                ),
              ),
            )
            .toList(),
      ),
  ]);

  Widget _courses(List<Map<String, dynamic>> courses) {
    final programsBySlug = <String, String>{};
    for (final course in courses) {
      final program = course['program'] as Map?;
      final slug = _string(program?['slug']);
      if (slug.isNotEmpty) {
        programsBySlug[slug] = _string(program?['nameVi']);
      }
    }
    final programSlugs = programsBySlug.keys.toList()
      ..sort((a, b) => programsBySlug[a]!.compareTo(programsBySlug[b]!));
    final inProgram = courses
        .where(
          (course) =>
              _programFilter == null ||
              (course['program'] as Map?)?['slug'] == _programFilter,
        )
        .toList();
    final query = _courseSearch.text.trim().toLowerCase();
    final visible = inProgram.where((course) {
      if (query.isEmpty) return true;
      final program = course['program'] as Map?;
      return [
        course['title'],
        course['code'],
        program?['nameVi'],
      ].any((value) => _string(value).toLowerCase().contains(query));
    }).toList();
    visible.sort((a, b) {
      final result = _string(a['title'])
          .toLowerCase()
          .compareTo(_string(b['title']).toLowerCase());
      return _courseSort == 'name_desc' ? -result : result;
    });
    return _pageScroll([
      const _PageHeading(
        'Khóa học',
        'Chọn lộ trình phù hợp với mục tiêu học tập của bạn.',
      ),
      const SizedBox(height: 24),
      if (courses.isNotEmpty) ...[
        LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: _courseSearch,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Tìm khóa học',
                hintText: 'Tên, mã hoặc chương trình',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            );
            final sort = DropdownButtonFormField<String>(
              initialValue: _courseSort,
              decoration: const InputDecoration(
                labelText: 'Sắp xếp',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Tên A–Z')),
                DropdownMenuItem(value: 'name_desc', child: Text('Tên Z–A')),
              ],
              onChanged: (value) =>
                  setState(() => _courseSort = value ?? 'name'),
            );
            final programFilter = DropdownButtonFormField<String>(
              key: ValueKey(_programFilter),
              isExpanded: true,
              initialValue: _programFilter,
              decoration: const InputDecoration(
                labelText: 'Chương trình',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('Tất cả chương trình'),
                ),
                if (_programFilter != null &&
                    !programsBySlug.containsKey(_programFilter))
                  DropdownMenuItem<String>(
                    value: _programFilter,
                    child: Text('Chương trình: $_programFilter'),
                  ),
                for (final slug in programSlugs)
                  DropdownMenuItem<String>(
                    value: slug,
                    child: Text(programsBySlug[slug]!),
                  ),
              ],
              onChanged: (value) => setState(
                () => _programFilter = value == null || value.isEmpty
                    ? null
                    : value,
              ),
            );
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  search,
                  const SizedBox(height: 12),
                  programFilter,
                  const SizedBox(height: 12),
                  sort,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                SizedBox(width: 240, child: programFilter),
                const SizedBox(width: 12),
                SizedBox(width: 180, child: sort),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],
      if (courses.isEmpty)
        const _EmptyCard(
          'Chưa có khóa học được công bố. Vui lòng quay lại sau.',
        )
      else if (inProgram.isEmpty)
        const _EmptyCard('Chương trình này chưa có khóa học được công bố.')
      else if (visible.isEmpty)
        const _EmptyCard('Không tìm thấy khóa học phù hợp.')
      else
        _responsiveCards(
          visible.map((course) {
            final program = course['program'] as Map?;
            final levels = course['levels'] as List? ?? [];
            return _InfoCard(
              icon: Icons.menu_book_rounded,
              title: _string(course['title']),
              subtitle: _string(course['publicDescription']),
              footnote:
                  '${_string(program?['nameVi'])} · ${levels.length} cấp độ',
              onTap: () => _navigate(
                '/khoa-hoc-cong-khai/${Uri.encodeComponent(_string(course['slug']))}',
              ),
            );
          }).toList(),
        ),
    ]);
  }

  Widget _courseDetail(Map<String, dynamic> course) {
    final levels = course['levels'] as List? ?? [];
    return _pageScroll([
      TextButton.icon(
        onPressed: () => _navigate(RouteNames.publicCourses),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Tất cả khóa học'),
      ),
      const SizedBox(height: 8),
      _PageHeading(
        _string(course['title']),
        _string(course['publicDescription']),
      ),
      const SizedBox(height: 16),
      Text('Đối tượng: ${_string(course['targetAudience'])}'),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: () => _navigate(
              '${RouteNames.publicConsultation}?khoa-hoc=${Uri.encodeQueryComponent(_string(course['title']))}',
            ),
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('Nhận tư vấn khóa học'),
          ),
          if (_string(course['id']).isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _navigate(
                '${RouteNames.publicClasses}?khoa-hoc=${Uri.encodeQueryComponent(_string(course['id']))}',
              ),
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Xem lớp đang mở'),
            ),
        ],
      ),
      const SizedBox(height: 32),
      const Text(
        'Các cấp độ',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      if (levels.isEmpty)
        const _EmptyCard('Thông tin cấp độ đang được cập nhật.')
      else
        Column(
          children: [
            for (final raw in levels)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PublicLevelCard(
                  level: Map<String, dynamic>.from(raw as Map),
                ),
              ),
          ],
        ),
    ]);
  }

  Widget _classes(Map<String, dynamic> data) {
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    final totalPages = (data['totalPages'] as num?)?.toInt() ?? 0;
    return _pageScroll([
      _PageHeading(
        widget.courseId == null ? 'Lớp sắp khai giảng' : 'Lớp mở cho khóa học',
        'Lịch học, học phí và chỗ còn lại được cập nhật từ hệ thống.',
      ),
      const SizedBox(height: 24),
      if (items.isEmpty)
        const _EmptyCard('Hiện chưa có lớp đủ điều kiện mở đăng ký.')
      else
        _responsiveCards(items.map(_offeringCard).toList()),
      if (totalPages > 1) ...[
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Trang trước',
              onPressed: _classPage > 1
                  ? () {
                      setState(() {
                        _classPage--;
                        _load();
                      });
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Trang $_classPage / $totalPages'),
            IconButton(
              tooltip: 'Trang sau',
              onPressed: _classPage < totalPages
                  ? () {
                      setState(() {
                        _classPage++;
                        _load();
                      });
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    ]);
  }

  Widget _myRegistrations(List<Map<String, dynamic>> requests) => _pageScroll([
    const _PageHeading(
      'Đơn đăng ký của tôi',
      'Theo dõi trạng thái yêu cầu nhập học của bạn.',
    ),
    const SizedBox(height: 20),
    if (requests.isEmpty)
      const _EmptyCard('Bạn chưa gửi yêu cầu đăng ký lớp nào.')
    else
      for (final item in requests)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InfoCard(
            icon: Icons.assignment_turned_in_outlined,
            title: _string((item['class'] as Map?)?['name']),
            subtitle: _string(
              ((item['class'] as Map?)?['course'] as Map?)?['title'],
            ),
            footnote: switch (_string(item['status'])) {
              'PENDING' => 'Chờ học vụ xử lý',
              'CONTACTED' => 'Học vụ đã liên hệ',
              'APPROVED' => 'Đã xác nhận nhập học',
              'REJECTED' => 'Đã từ chối',
              _ => _string(item['status']),
            },
          ),
        ),
  ]);

  Widget _offeringCard(Map<String, dynamic> item) {
    final course = item['course'] as Map?;
    final branch = item['branch'] as Map?;
    final price = num.tryParse('${item['tuitionFee']}');
    final start = DateTime.tryParse('${item['startDate']}');
    return _InfoCard(
      icon: Icons.event_available_rounded,
      title: _string(item['name']),
      subtitle:
          '${_string(course?['title'])}\n${_string(branch?['name'])} · ${_string(item['startTime'])}–${_string(item['endTime'])}',
      footnote:
          '${start == null ? '' : '${start.day}/${start.month}/${start.year} · '}${item['remainingSeats']} chỗ còn · ${price == null ? 'Liên hệ học phí' : '${price.toStringAsFixed(0)} đ'}',
      onTap: () =>
          _navigate('/dang-ky-lop/${Uri.encodeComponent(_string(item['id']))}'),
      actionLabel: 'Đăng ký lớp',
    );
  }

  Widget _responsiveCards(List<Widget> cards) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 600
          ? 2
          : 1;
      if (columns == 1) {
        return Column(
          children: [
            for (final card in cards)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: card),
          ],
        );
      }
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final card in cards)
            SizedBox(
              width: (constraints.maxWidth - 16 * (columns - 1)) / columns,
              child: card,
            ),
        ],
      );
    },
  );
}

String _string(dynamic value) => value == null ? '' : '$value';

class _PublicLevelCard extends StatelessWidget {
  const _PublicLevelCard({required this.level});

  final Map<String, dynamic> level;

  @override
  Widget build(BuildContext context) {
    final modules = level['modules'] as List? ?? const [];
    final details = [
      _string(level['cefrLevel']),
      if (level['recommendedHours'] != null)
        '${level['recommendedHours']} giờ tham khảo',
    ].where((part) => part.isNotEmpty).join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(
          Icons.stacked_bar_chart_rounded,
          color: AppColors.primary,
        ),
        title: Text(
          _string(level['name']),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: details.isEmpty ? null : Text(details),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_string(level['description']).isNotEmpty)
            Text(_string(level['description'])),
          for (final entry in <(String, String)>[
            ('Đầu vào', _string(level['entryRequirements'])),
            ('Kết quả học tập', _string(level['expectedOutcomes'])),
            ('Đánh giá', _string(level['assessmentScheme'])),
            ('Hoàn thành', _string(level['completionCriteria'])),
          ])
            if (entry.$2.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                entry.$1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(entry.$2),
            ],
          if (modules.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Học phần',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final raw in modules) ...[
              const SizedBox(height: 10),
              Text(
                _string((raw as Map)['title']),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (_string(raw['description']).isNotEmpty)
                Text(_string(raw['description'])),
              for (final lesson in raw['lessons'] as List? ?? const [])
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text('• ${_string((lesson as Map)['title'])}'),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading(this.title, this.subtitle);
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondaryLight,
        ),
      ),
    ],
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.onExplore,
    required this.onConsult,
  });
  final String title;
  final String subtitle;
  final VoidCallback onExplore;
  final VoidCallback onConsult;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 600;
      final introduction = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              mobile ? 'EDULMS · TIẾNG ANH' : 'HỌC TIẾNG ANH CÙNG EDULMS',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: mobile ? 18 : 28),
          Text(
            title,
            style: TextStyle(
              fontSize: mobile ? (constraints.maxWidth < 360 ? 27 : 30) : 42,
              height: 1.14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          if (mobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: onExplore,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Khám phá khóa học'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onConsult,
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('Nhận tư vấn chọn lộ trình'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                ),
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onExplore,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Khám phá khóa học'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onConsult,
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('Nhận tư vấn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      );
      return Container(
        padding: EdgeInsets.all(mobile ? 24 : 40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(mobile ? 28 : 32),
        ),
        child: mobile
            ? introduction
            : Row(
                children: [
                  Expanded(flex: 3, child: introduction),
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 38,
                            color: Colors.white,
                          ),
                          SizedBox(height: 24),
                          _HeroStep('01', 'Khám phá chương trình'),
                          _HeroStep('02', 'Chọn khóa và lớp phù hợp'),
                          _HeroStep('03', 'Đăng ký hoặc nhận tư vấn'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class _HeroStep extends StatelessWidget {
  const _HeroStep(this.number, this.label);
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, this.onTap);
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      TextButton(onPressed: onTap, child: const Text('Xem tất cả')),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.footnote,
    this.onTap,
    this.actionLabel,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String footnote;
  final VoidCallback? onTap;
  final String? actionLabel;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.borderLight),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.neutral100,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
            if (footnote.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                footnote,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              Text(
                actionLabel!,
                style: const TextStyle(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 40,
            color: AppColors.textMutedLight,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
  });
  final IconData icon;
  final String title;
  final String detail;
  final Widget action;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondaryLight),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          action,
        ],
      ),
    ),
  );
}

class _ConsultationForm extends StatefulWidget {
  const _ConsultationForm({required this.repository, this.targetCourse});
  final PublicCatalogRepository repository;
  final String? targetCourse;
  @override
  State<_ConsultationForm> createState() => _ConsultationFormState();
}

class _ConsultationFormState extends State<_ConsultationForm> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  late final TextEditingController _target = TextEditingController(
    text: widget.targetCourse ?? '',
  );
  bool _saving = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.sendConsultation(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        targetCourse: _target.text.trim(),
        notes: _notes.text.trim(),
      );
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: _sent
            ? _MessageState(
                icon: Icons.check_circle_outline,
                title: 'Đã gửi yêu cầu tư vấn',
                detail: 'EduLMS đã tiếp nhận thông tin của bạn và sẽ liên hệ theo số điện thoại đã cung cấp.',
                action: TextButton(
                  onPressed: () => context.go(RouteNames.publicHome),
                  child: const Text('Về trang chủ'),
                ),
              )
            : Form(
                key: _key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PageHeading(
                      'Đăng ký tư vấn',
                      'Để lại thông tin, đội ngũ tuyển sinh sẽ liên hệ với bạn.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          RegExp(r'^[0-9+(). -]{9,18}$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Số điện thoại không hợp lệ',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email (tùy chọn)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null ||
                              value.trim().isEmpty ||
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(value.trim())
                          ? null
                          : 'Email không hợp lệ',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _target,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Khóa học quan tâm',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Nhu cầu học tập',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        _saving ? 'Đang gửi...' : 'Gửi yêu cầu tư vấn',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}

class _RegistrationForm extends StatefulWidget {
  const _RegistrationForm({
    required this.repository,
    required this.offering,
    required this.isStudent,
    this.studentName,
  });
  final PublicCatalogRepository repository;
  final Map<String, dynamic> offering;
  final bool isStudent;
  final String? studentName;

  @override
  State<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<_RegistrationForm> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if ((!widget.isStudent && !_key.currentState!.validate()) || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isStudent) {
        await widget.repository.registerStudent(
          classId: _string(widget.offering['id']),
          notes: _notes.text.trim(),
        );
      } else {
        await widget.repository.registerGuest(
          classId: _string(widget.offering['id']),
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          notes: _notes.text.trim(),
        );
      }
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.offering['course'] as Map?;
    final branch = widget.offering['branch'] as Map?;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _sent
              ? _MessageState(
                  icon: Icons.mark_email_read_outlined,
                  title: 'Đã tiếp nhận đăng ký',
                  detail: 'Yêu cầu của bạn đang chờ học vụ xác nhận. Việc gửi yêu cầu chưa phải là ghi danh chính thức.',
                  action: TextButton(
                    onPressed: () => context.go(
                      widget.isStudent
                          ? RouteNames.myRegistrations
                          : RouteNames.publicClasses,
                    ),
                    child: Text(
                      widget.isStudent
                          ? 'Theo dõi đơn của tôi'
                          : 'Xem các lớp khác',
                    ),
                  ),
                )
              : Form(
                  key: _key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _PageHeading(
                        'Đăng ký lớp học',
                        'Điền thông tin để học vụ liên hệ và xác nhận nhập học.',
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _string(widget.offering['name']),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(_string(course?['title'])),
                              const SizedBox(height: 4),
                              Text(
                                '${_string(branch?['name'])} · ${widget.offering['remainingSeats']} chỗ còn',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (widget.isStudent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Đăng ký bằng tài khoản học viên: ${widget.studentName ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                      else ...[
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Vui lòng nhập họ tên'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              RegExp(r'^(?:\+?84|0)[0-9 .()-]{8,15}$')
                                  .hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Số điện thoại không hợp lệ',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email (tùy chọn)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null ||
                                  value.trim().isEmpty ||
                                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(value.trim())
                              ? null
                              : 'Email không hợp lệ',
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Nhu cầu hoặc câu hỏi thêm',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _saving ? 'Đang gửi...' : 'Gửi đăng ký lớp',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Học vụ sẽ kiểm tra chỗ trống và liên hệ xác nhận. Chưa phát sinh học phí khi gửi yêu cầu.',
                        style: TextStyle(color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
