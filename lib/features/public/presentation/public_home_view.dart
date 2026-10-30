import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/router/route_names.dart';

/// The public landing page uses the same API records as the catalog screens.
/// Only its presentation differs from the other public routes.
class PublicHomeView extends StatelessWidget {
  const PublicHomeView({
    super.key,
    required this.programs,
    required this.courses,
    required this.offerings,
    required this.navigate,
    this.dashboardRoute,
  });

  final List<Map<String, dynamic>> programs;
  final List<Map<String, dynamic>> courses;
  final List<Map<String, dynamic>> offerings;
  final void Function(String route) navigate;
  final String? dashboardRoute;

  static const navy = Color(0xFF142A65);
  static const ink = Color(0xFF17213C);
  static const muted = Color(0xFF68758E);
  static const blue = Color(0xFF285AE4);
  static const lime = Color(0xFFD7F86F);
  static const canvas = Color(0xFFF7FAFF);
  static const border = Color(0xFFDDE6F4);

  String _value(dynamic value) => value == null ? '' : '$value';

  void _program(Map<String, dynamic> item) {
    final slug = _value(item['slug']);
    navigate(
      slug.isEmpty
          ? RouteNames.publicPrograms
          : '${RouteNames.publicCourses}?chuong-trinh=${Uri.encodeQueryComponent(slug)}',
    );
  }

  void _course(Map<String, dynamic> item) {
    final slug = _value(item['slug']);
    if (slug.isNotEmpty) {
      navigate('/khoa-hoc-cong-khai/${Uri.encodeComponent(slug)}');
    }
  }

  void _class(Map<String, dynamic> item) {
    final id = _value(item['id']);
    if (id.isNotEmpty) navigate('/dang-ky-lop/${Uri.encodeComponent(id)}');
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 768;
      final tablet = constraints.maxWidth < 1200;
      final side = mobile
          ? 16.0
          : tablet
          ? 28.0
          : 40.0;
      return ColoredBox(
        color: canvas,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(constraints.maxWidth < 1100),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1296),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: side),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: mobile ? 16 : 30),
                        mobile ? _mobileHero() : _desktopHero(),
                        SizedBox(height: mobile ? 16 : 24),
                        mobile ? _mobileFinder() : _desktopFinder(),
                        SizedBox(height: mobile ? 30 : 44),
                        _programSection(mobile),
                        SizedBox(height: mobile ? 30 : 44),
                        _courseSection(mobile),
                        SizedBox(height: mobile ? 30 : 44),
                        _classSection(mobile),
                        SizedBox(height: mobile ? 30 : 34),
                        _steps(mobile),
                        SizedBox(height: mobile ? 24 : 34),
                        _consultationBanner(mobile),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
              _footer(mobile),
            ],
          ),
        ),
      );
    },
  );

  Widget _header(bool mobile) => ColoredBox(
    color: Colors.white,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1296),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 18 : 40,
            vertical: mobile ? 18 : 17,
          ),
          child: Row(
            children: [
              Container(
                width: mobile ? 40 : 46,
                height: mobile ? 40 : 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EduLMS',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: mobile ? 20 : 23,
                      ),
                    ),
                    Text(
                      mobile
                          ? 'English Learning Center'
                          : 'Trung tâm đào tạo tiếng Anh',
                      maxLines: 1,
                      style: const TextStyle(color: muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (mobile)
                PopupMenuButton<String>(
                  tooltip: 'Mở menu',
                  onSelected: navigate,
                  icon: const Icon(Icons.menu_rounded, color: navy),
                  itemBuilder: (context) => [
                    _menu('Chương trình', RouteNames.publicPrograms),
                    _menu('Khóa học', RouteNames.publicCourses),
                    _menu('Lớp khai giảng', RouteNames.publicClasses),
                    _menu('Tư vấn', RouteNames.publicConsultation),
                    _menu(
                      dashboardRoute == null ? 'Đăng nhập' : 'Vào LMS',
                      dashboardRoute ?? RouteNames.login,
                    ),
                  ],
                )
              else ...[
                _nav('Chương trình', RouteNames.publicPrograms),
                _nav('Khóa học', RouteNames.publicCourses),
                _nav('Lớp khai giảng', RouteNames.publicClasses),
                _nav('Tư vấn', RouteNames.publicConsultation),
                const SizedBox(width: 16),
                _action(
                  dashboardRoute == null ? 'Đăng nhập ↗' : 'Vào LMS ↗',
                  () => navigate(dashboardRoute ?? RouteNames.login),
                  dark: true,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  PopupMenuItem<String> _menu(String label, String route) =>
      PopupMenuItem(value: route, child: Text(label));

  Widget _nav(String label, String route) => TextButton(
    onPressed: () => navigate(route),
    child: Text(
      label,
      style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
    ),
  );

  Widget _action(
    String label,
    VoidCallback onTap, {
    bool dark = false,
    bool pale = false,
    bool stretch = false,
  }) => SizedBox(
    width: stretch ? double.infinity : null,
    height: 48,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: dark
            ? ink
            : pale
            ? Colors.white
            : lime,
        foregroundColor: dark
            ? Colors.white
            : pale
            ? blue
            : ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );

  Widget _desktopHero() => Container(
    padding: const EdgeInsets.all(50),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(30),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 940;
        final copy = _heroCopy(false);
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [copy, const SizedBox(height: 28), _journey(false)],
              )
            : Row(
                children: [
                  Expanded(flex: 6, child: copy),
                  const SizedBox(width: 36),
                  Expanded(flex: 5, child: _journey(false)),
                ],
              );
      },
    ),
  );

  Widget _mobileHero() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_heroCopy(true), const SizedBox(height: 18), _journey(true)],
    ),
  );

  Widget _heroCopy(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _pill(
        mobile
            ? 'CHINH PHỤC MỤC TIÊU TIẾNG ANH'
            : 'HỌC ĐÚNG LỘ TRÌNH · CHINH PHỤC MỤC TIÊU',
        const Color(0xFF2E4786),
        Colors.white,
      ),
      SizedBox(height: mobile ? 18 : 20),
      Text(
        mobile
            ? 'Học tiếng Anh.\nMở tương lai.'
            : 'Tiếng Anh vững vàng.\nTương lai rộng mở.',
        style: TextStyle(
          color: Colors.white,
          fontSize: mobile ? 33 : 46,
          height: 1.16,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        mobile
            ? 'Chọn đúng lộ trình, tìm lớp phù hợp và bắt đầu hành trình của bạn.'
            : 'Chọn lộ trình phù hợp với trình độ, lịch học và mục tiêu của bạn.',
        style: TextStyle(
          color: const Color(0xFFD3DEFA),
          fontSize: mobile ? 15 : 17,
          height: 1.55,
        ),
      ),
      SizedBox(height: mobile ? 20 : 26),
      if (mobile)
        Column(
          children: [
            _action(
              'Khám phá khóa học ↗',
              () => navigate(RouteNames.publicCourses),
              stretch: true,
            ),
            const SizedBox(height: 12),
            _action(
              'Nhận tư vấn miễn phí',
              () => navigate(RouteNames.publicConsultation),
              pale: true,
              stretch: true,
            ),
          ],
        )
      else
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _action(
              'Khám phá khóa học ↗',
              () => navigate(RouteNames.publicCourses),
            ),
            _action(
              'Nhận tư vấn miễn phí',
              () => navigate(RouteNames.publicConsultation),
              pale: true,
            ),
          ],
        ),
      if (!mobile) ...[
        const SizedBox(height: 20),
        const Text(
          '● Lộ trình rõ ràng     ● Lịch học linh hoạt     ● Theo dõi tiến độ',
          style: TextStyle(color: Color(0xFFD6E2FB), fontSize: 12),
        ),
      ],
    ],
  );

  Widget _journey(bool mobile) => Container(
    padding: EdgeInsets.all(mobile ? 17 : 25),
    decoration: BoxDecoration(
      color: const Color(0xFF25458E),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'BẮT ĐẦU HÀNH TRÌNH',
          style: TextStyle(
            color: const Color(0xFFC9D8FF),
            fontSize: mobile ? 11 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            for (final (index, label) in [
              'Khám phá',
              'Chọn lớp',
              'Đăng ký',
            ].indexed) ...[
              if (index > 0) const SizedBox(width: 7),
              Expanded(
                child: Container(
                  height: mobile ? 54 : 75,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == 2 ? lime : const Color(0xFF5575B9),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index == 2 ? ink : Colors.white,
                      fontSize: mobile ? 11 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 13),
        const Text(
          'Tìm lộ trình phù hợp với mục tiêu của bạn →',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _mobileFinder() => _surface(
    padding: 18,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Bạn đang tìm khóa học gì?',
          style: TextStyle(
            color: ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => navigate(RouteNames.publicCourses),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: muted, size: 19),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tìm IELTS, TOEIC, giao tiếp...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _desktopFinder() => _surface(
    padding: 24,
    child: Wrap(
      spacing: 14,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const SizedBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn muốn học gì?',
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Chọn mục tiêu để bắt đầu',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        for (final item in programs.take(3))
          ActionChip(
            label: Text(
              _value(item['nameVi']),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
            ),
            onPressed: () => _program(item),
            backgroundColor: const Color(0xFFEAF0FC),
            side: BorderSide.none,
          ),
        _action('Tìm lớp học ↗', () => navigate(RouteNames.publicClasses)),
      ],
    ),
  );

  Widget _sectionTitle(
    String title,
    String subtitle,
    String link,
    VoidCallback onTap, {
    required bool mobile,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (mobile) ...[
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: muted, fontSize: 13)),
        ],
      ] else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: muted, fontSize: 14),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onTap, child: Text(link)),
          ],
        ),
    ],
  );

  Widget _programSection(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionTitle(
        mobile ? 'Khám phá theo mục tiêu' : 'Bắt đầu từ mục tiêu của bạn',
        mobile ? '' : 'Chọn chương trình phù hợp, sau đó khám phá khóa học và lớp đang tuyển sinh.',
        'Xem tất cả',
        () => navigate(RouteNames.publicPrograms),
        mobile: mobile,
      ),
      const SizedBox(height: 17),
      if (programs.isEmpty)
        _empty('Chương trình đang được chuẩn bị công bố.')
      else
        _grid(
          programs.take(4).toList(),
          mobile ? 2 : 4,
          (item, index) => _programCard(item, index, mobile),
        ),
      if (mobile)
        _textLink(
          'Xem tất cả chương trình →',
          () => navigate(RouteNames.publicPrograms),
        ),
    ],
  );

  Widget _programCard(Map<String, dynamic> item, int index, bool mobile) =>
      _tapCard(
        () => _program(item),
        color: [
          const Color(0xFFEAF1FF),
          const Color(0xFFF3EDFF),
          const Color(0xFFFFF1E8),
          const Color(0xFFECF8EA),
        ][index % 4],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mobile ? '↗' : '${index + 1}'.padLeft(2, '0'),
              style: const TextStyle(color: blue, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              _value(item['nameVi']),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: mobile ? 17 : 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _value(item['description']).isEmpty
                  ? _value(item['targetAudience'])
                  : _value(item['description']),
              maxLines: mobile ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, fontSize: 12, height: 1.4),
            ),
            if (!mobile) ...[
              const SizedBox(height: 18),
              const Text(
                'Khám phá →',
                style: TextStyle(color: blue, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      );

  Widget _courseSection(bool mobile) => _surface(
    padding: mobile ? 20 : 32,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Khóa học nổi bật',
          'Xem lộ trình trước khi chọn lớp.',
          'Tất cả khóa học',
          () => navigate(RouteNames.publicCourses),
          mobile: mobile,
        ),
        const SizedBox(height: 20),
        if (courses.isEmpty)
          _empty('Khóa học đang được chuẩn bị công bố.')
        else
          _grid(
            courses.take(3).toList(),
            mobile ? 1 : 3,
            (item, index) => _courseCard(item, index, mobile),
          ),
        if (mobile)
          _textLink(
            'Xem tất cả khóa học →',
            () => navigate(RouteNames.publicCourses),
          ),
      ],
    ),
  );

  Widget _courseCard(Map<String, dynamic> item, int index, bool mobile) {
    final program = item['program'] as Map?;
    final cover = [
      const Color(0xFFDFEBFF),
      const Color(0xFFEAE3FF),
      const Color(0xFFDDF3F1),
    ][index % 3];
    return _tapCard(
      () => _course(item),
      padding: 0,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: mobile ? 90 : 126,
            padding: EdgeInsets.all(mobile ? 17 : 24),
            decoration: BoxDecoration(
              color: cover,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _value(item['title']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w800,
                  fontSize: mobile ? 21 : 25,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(mobile ? 17 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_value(program?['nameVi']).isNotEmpty) ...[
                  _pill(
                    _value(program?['nameVi']),
                    const Color(0xFFEAF0FC),
                    blue,
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  _value(item['title']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: mobile ? 17 : 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _value(item['publicDescription']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  mobile ? 'Xem khóa học ↗' : 'Xem lộ trình khóa học ↗',
                  style: const TextStyle(
                    color: blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _classSection(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionTitle(
        'Lớp đang mở đăng ký',
        'Chọn ca học phù hợp và gửi đăng ký trực tuyến.',
        'Xem lịch khai giảng',
        () => navigate(RouteNames.publicClasses),
        mobile: mobile,
      ),
      const SizedBox(height: 20),
      if (offerings.isEmpty)
        _empty('Hiện chưa có lớp mở đăng ký.')
      else
        _grid(
          offerings.take(mobile ? 1 : 2).toList(),
          mobile ? 1 : 2,
          (item, _) => _classCard(item, mobile),
        ),
      if (!mobile) ...[const SizedBox(height: 16), _adviceCard(false)],
      if (mobile)
        _textLink(
          'Xem tất cả lớp khai giảng →',
          () => navigate(RouteNames.publicClasses),
        ),
    ],
  );

  Widget _classCard(Map<String, dynamic> item, bool mobile) {
    final course = item['course'] as Map?;
    final branch = item['branch'] as Map?;
    final remaining = _value(item['remainingSeats']);
    final fee = num.tryParse(_value(item['tuitionFee']));
    final start = DateTime.tryParse(_value(item['startDate']));
    final time = '${_value(item['startTime'])}–${_value(item['endTime'])}';
    return _surface(
      padding: mobile ? 19 : 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pill(
            'ĐANG TUYỂN SINH',
            const Color(0xFFE0F5E7),
            const Color(0xFF16804C),
          ),
          const SizedBox(height: 16),
          Text(
            _value(item['name']),
            style: TextStyle(
              color: ink,
              fontSize: mobile ? 19 : 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _value(course?['title']),
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (start != null)
            Text(
              'Khai giảng ${start.day}/${start.month}/${start.year} · $time',
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          if (_value(branch?['name']).isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              _value(branch?['name']),
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '$remaining chỗ còn · ${fee == null ? 'Liên hệ học phí' : '${NumberFormat.decimalPattern('vi_VN').format(fee)} đ'}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _action('Đăng ký lớp', () => _class(item), stretch: mobile),
        ],
      ),
    );
  }

  Widget _adviceCard(bool mobile) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pill('TƯ VẤN XẾP LỚP', const Color(0xFF2E4786), Colors.white),
        const SizedBox(height: 17),
        const Text(
          'Chưa biết lớp nào phù hợp?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Cho chúng tôi biết trình độ, mục tiêu và lịch rảnh. Bộ phận tuyển sinh sẽ hỗ trợ chọn lớp phù hợp.',
          style: TextStyle(color: Color(0xFFD3DEFA), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 17),
        _action('Nhận tư vấn ↗', () => navigate(RouteNames.publicConsultation)),
      ],
    ),
  );

  Widget _steps(bool mobile) => _surface(
    padding: mobile ? 20 : 34,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mobile ? 'Bắt đầu chỉ trong 3 bước' : 'Ba bước bắt đầu hành trình',
          style: TextStyle(
            color: ink,
            fontSize: mobile ? 21 : 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        _grid(
          const [
            ('01', 'Khám phá chương trình', 'Chọn lộ trình đúng với mục tiêu.'),
            (
              '02',
              'Chọn khóa và lớp',
              'Xem thời khóa biểu, học phí, chỗ trống.',
            ),
            ('03', 'Gửi đăng ký', 'Học vụ tiếp nhận và xác nhận.'),
          ],
          mobile ? 1 : 3,
          (item, _) => Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: mobile
                ? Row(
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: blue,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _stepCopy(item)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: blue,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _stepCopy(item),
                    ],
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _stepCopy((String, String, String) item) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        item.$2,
        style: const TextStyle(
          color: ink,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(item.$3, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );

  Widget _consultationBanner(bool mobile) => Container(
    padding: EdgeInsets.all(mobile ? 23 : 35),
    decoration: BoxDecoration(
      color: lime,
      borderRadius: BorderRadius.circular(20),
    ),
    child: mobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chưa biết nên bắt đầu từ đâu?',
                style: TextStyle(
                  color: ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Đăng ký tư vấn để chọn khóa và ca học phù hợp với bạn.',
                style: TextStyle(color: ink, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _action(
                'Nhận tư vấn miễn phí ↗',
                () => navigate(RouteNames.publicConsultation),
                dark: true,
                stretch: true,
              ),
            ],
          )
        : Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn đã sẵn sàng bắt đầu?',
                      style: TextStyle(
                        color: ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'EduLMS sẽ hỗ trợ chọn lộ trình học phù hợp.',
                      style: TextStyle(color: ink, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _action(
                'Đăng ký tư vấn ↗',
                () => navigate(RouteNames.publicConsultation),
                dark: true,
              ),
            ],
          ),
  );

  Widget _footer(bool mobile) => ColoredBox(
    color: const Color(0xFF0F1D42),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1296),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 22 : 40,
            vertical: mobile ? 28 : 46,
          ),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _footerBrand(),
                    const SizedBox(height: 18),
                    _footerLinks(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 2, child: _FooterBrand()),
                    Expanded(child: _footerLinks()),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _footerBrand() => const _FooterBrand();

  Widget _footerLinks() => Wrap(
    spacing: 20,
    runSpacing: 8,
    children: [
      _footerLink('Chương trình đào tạo', RouteNames.publicPrograms),
      _footerLink('Khóa học công bố', RouteNames.publicCourses),
      _footerLink('Lớp khai giảng', RouteNames.publicClasses),
      _footerLink('Đăng ký tư vấn', RouteNames.publicConsultation),
      _footerLink('Đăng nhập', dashboardRoute ?? RouteNames.login),
    ],
  );

  Widget _footerLink(String title, String route) => TextButton(
    onPressed: () => navigate(route),
    child: Text(
      title,
      style: const TextStyle(color: Color(0xFFD6E2FB), fontSize: 12),
    ),
  );

  Widget _pill(String label, Color background, Color foreground) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label,
      maxLines: 2,
      style: TextStyle(
        color: foreground,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _surface({required Widget child, double padding = 20}) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget _tapCard(
    VoidCallback onTap, {
    required Widget child,
    required Color color,
    double padding = 22,
  }) => Material(
    color: color,
    borderRadius: BorderRadius.circular(17),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 115),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(17),
        ),
        child: child,
      ),
    ),
  );

  Widget _empty(String message) => _surface(
    child: Text(message, style: const TextStyle(color: muted, fontSize: 14)),
  );

  Widget _textLink(String label, VoidCallback onTap) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(onPressed: onTap, child: Text(label)),
  );

  Widget _grid<T>(
    List<T> items,
    int columns,
    Widget Function(T item, int index) builder,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth < 600
          ? (columns == 1 ? 1 : columns)
          : columns;
      const gap = 14.0;
      final width = (constraints.maxWidth - gap * (count - 1)) / count;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(width: width, child: builder(items[i], i)),
        ],
      );
    },
  );
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'EduLMS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Hệ thống đào tạo ngoại ngữ\nKhám phá khóa học, đăng ký lớp và học tập thuận tiện.',
        style: TextStyle(color: Color(0xFFD6E2FB), fontSize: 12, height: 1.5),
      ),
    ],
  );
}
