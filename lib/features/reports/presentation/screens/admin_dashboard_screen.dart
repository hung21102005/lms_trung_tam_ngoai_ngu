import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/reports_bloc.dart';
import '../widgets/revenue_line_chart.dart';
import '../widgets/student_distribution_pie_chart.dart';
import '../../data/models/report_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  final bool showAppBar;
  const AdminDashboardScreen({super.key, this.showAppBar = true});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(const FetchDashboardOverviewEvent());
  }

  void _onRefresh() {
    context.read<ReportsBloc>().add(
      const FetchDashboardOverviewEvent(forceRefresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Báo Cáo & Dashboard Quản Trị'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Làm mới dữ liệu',
                  onPressed: _onRefresh,
                ),
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  tooltip: 'Báo cáo chi tiết',
                  onPressed: () => context.push(RouteNames.reportsOverview),
                ),
              ],
            )
          : null,
      body: BlocConsumer<ReportsBloc, ReportsState>(
        listener: (context, state) {
          if (state is ReportsErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${state.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReportsLoadingState) {
            return const LoadingWidget(
              message: 'Đang tải báo cáo tổng quan...',
            );
          }

          if (state is DashboardOverviewLoadedState) {
            final data = state.data;
            if (AdaptiveBreakpoints.fromWidth(
                  MediaQuery.sizeOf(context).width,
                ) ==
                AdaptiveSize.mobile) {
              return _buildMobileDashboard(data);
            }
            return RefreshIndicator(
              onRefresh: () async => _onRefresh(),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // KPI Metric Cards Grid
                  _buildKpiGrid(data),
                  const SizedBox(height: 16),

                  // Revenue Chart
                  RevenueLineChart(trend: data.revenueTrend),
                  const SizedBox(height: 16),

                  // Student Distribution Pie Chart
                  StudentDistributionPieChart(
                    distribution: data.courseDistribution,
                  ),
                  const SizedBox(height: 16),

                  // Upcoming Classes Table / List
                  _buildUpcomingClassesCard(data.upcomingClasses),
                  const SizedBox(height: 16),

                  // Top Debtors Card
                  _buildTopDebtorsCard(data.topDebtors),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.dashboard_outlined,
                  size: 48,
                  color: AppColors.neutral400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có dữ liệu thống kê',
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _onRefresh,
                  child: const Text('Tải dữ liệu'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileDashboard(DashboardOverviewModel data) => RefreshIndicator(
    onRefresh: () async => _onRefresh(),
    child: ListView(
      key: const ValueKey('admin-dashboard-mobile'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        Text(
          'Tổng quan trung tâm',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(MobileTokens.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Học viên đang học',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                '${data.totalStudents}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${data.newStudentsThisMonth} học viên mới tháng này',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _mobileMetric(
                'Lớp hoạt động',
                '${data.totalActiveClasses}',
                Icons.meeting_room_outlined,
              ),
              _mobileMetric(
                'Doanh thu tháng',
                _currencyFormat.format(data.monthlyRevenue),
                Icons.payments_outlined,
              ),
              _mobileMetric(
                'Công nợ',
                _currencyFormat.format(data.totalDebts),
                Icons.receipt_long_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Lớp sắp khai giảng',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (data.upcomingClasses.isEmpty)
          const MobileSectionCard(child: Text('Chưa có lớp sắp khai giảng.')),
        for (final item in data.upcomingClasses)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MobileSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.enrolledCount}/${item.maxStudents} học viên · ${DateFormat('dd/MM/yyyy').format(item.startDate)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.teacherName,
                    style: const TextStyle(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Học phí cần theo dõi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (data.topDebtors.isEmpty)
          const MobileSectionCard(
            child: Text('Không có công nợ cần theo dõi.'),
          ),
        for (final item in data.topDebtors)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MobileSectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.className,
                          style: const TextStyle(color: AppColors.neutral600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(item.balance),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _mobileMetric(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: SizedBox(
      width: 160,
      child: MobileSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildKpiGrid(DashboardOverviewModel data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Học viên Active',
                value: data.totalStudents.toString(),
                subText: '+${data.newStudentsThisMonth} học viên mới tháng này',
                icon: Icons.people_alt_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Lớp Hoạt Động',
                value: data.totalActiveClasses.toString(),
                subText: 'Đang vận hành',
                icon: Icons.meeting_room_outlined,
                color: const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Doanh thu tháng',
                value: _currencyFormat.format(data.monthlyRevenue),
                subText: data.monthlyRevenueGrowth >= 0
                    ? '▲ +${data.monthlyRevenueGrowth}% so với tháng trước'
                    : '▼ ${data.monthlyRevenueGrowth}% so với tháng trước',
                subTextColor: data.monthlyRevenueGrowth >= 0
                    ? AppColors.success
                    : AppColors.error,
                icon: Icons.monetization_on_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Công nợ tồn đọng',
                value: _currencyFormat.format(data.totalDebts),
                subText: 'Học phí chưa thu',
                subTextColor: AppColors.error,
                icon: Icons.pending_actions_outlined,
                color: AppColors.error,
                onTap: () => context.push(RouteNames.debtsReport),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subText,
    Color? subTextColor,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h4(context)
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: subTextColor ?? AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingClassesCard(List<UpcomingClassItem> classes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lớp học sắp khai giảng',
                style: AppTextStyles.h4(context)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.schedule, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Không có lớp nào sắp khai giảng',
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
            )
          else
            ...classes.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${c.courseName} • GV: ${c.teacherName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(c.startDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${c.enrolledCount}/${c.maxStudents} HV',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopDebtorsCard(List<TopDebtorItem> debtors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top công nợ cần đôn đốc',
                style: AppTextStyles.h4(context)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => context.push(RouteNames.debtsReport),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (debtors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Không có công nợ tồn đọng',
                style: TextStyle(color: AppColors.success),
              ),
            )
          else
            ...debtors.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${d.invoiceCode} • ${d.className}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _currencyFormat.format(d.balance),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
