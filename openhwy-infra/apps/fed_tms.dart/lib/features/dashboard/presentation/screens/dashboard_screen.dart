import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fed_tms/core/widgets/app_drawer.dart';
import 'package:fed_tms/features/dashboard/presentation/widgets/app_stat_card.dart';
import 'package:fed_tms/features/drivers/providers/driver_provider.dart';
import 'package:fed_tms/features/loads/providers/load_provider.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadStats = ref.watch(loadStatsProvider);
    final driverStats = ref.watch(driverStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('TMS Dashboard'),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => GoRouter.of(context).go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loadStatsProvider);
          ref.invalidate(driverStatsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // Statistics Cards
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              loadStats.when(
                data: (stats) => _buildLoadStats(stats),
                loading: () => _buildLoadingStats(),
                error: (error, stack) => _buildErrorState(error.toString()),
              ),

              const SizedBox(height: 16),

              driverStats.when(
                data: (stats) => _buildDriverStats(stats),
                loading: () => _buildLoadingStats(),
                error: (error, stack) => _buildErrorState(error.toString()),
              ),

              const SizedBox(height: 24),

              // Revenue Chart
              loadStats.when(
                data: (stats) => _buildRevenueChart(stats),
                loading: () => const SizedBox(),
                error: (error, stack) => const SizedBox(),
              ),

              const SizedBox(height: 24),

              // Recent Activity
              _buildRecentActivity(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/loads/create'),
        backgroundColor: const Color(0xFF1976D2),
        icon: const Icon(Icons.add),
        label: const Text('New Load'),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'TMS Operations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(now),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_shipping,
            size: 60,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_circle_outline,
            label: 'New Load',
            color: const Color(0xFF1976D2),
            onTap: () => context.push('/loads/create'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.view_list,
            label: 'Load Board',
            color: const Color(0xFF0288D1),
            onTap: () => context.push('/loadboard'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.people_outline,
            label: 'Drivers',
            color: const Color(0xFF0277BD),
            onTap: () => context.push('/drivers'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.calendar_today,
            label: 'Calendar',
            color: const Color(0xFF01579B),
            onTap: () => context.push('/calendar'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadStats(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: AppStatCard(
            title: 'Total Loads',
            value: stats['totalLoads'].toString(),
            icon: Icons.local_shipping,
            color: const Color(0xFF1976D2),
            trend: '+12%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatCard(
            title: 'Active',
            value: stats['activeLoads'].toString(),
            icon: Icons.trending_up,
            color: const Color(0xFF43A047),
            subtitle: 'In Progress',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatCard(
            title: 'Pending',
            value: stats['pendingLoads'].toString(),
            icon: Icons.pending_actions,
            color: const Color(0xFFFFA726),
            subtitle: 'Awaiting',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatCard(
            title: 'Delivered',
            value: stats['deliveredLoads'].toString(),
            icon: Icons.check_circle,
            color: const Color(0xFF66BB6A),
            subtitle: 'Complete',
          ),
        ),
      ],
    );
  }

  Widget _buildDriverStats(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: AppStatCard(
            title: 'Total Drivers',
            value: stats['totalDrivers'].toString(),
            icon: Icons.people,
            color: const Color(0xFF5E35B1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatCard(
            title: 'Available',
            value: stats['availableDrivers'].toString(),
            icon: Icons.check_circle_outline,
            color: const Color(0xFF43A047),
            subtitle: 'Ready',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatCard(
            title: 'On Load',
            value: stats['onLoadDrivers'].toString(),
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF1976D2),
            subtitle: 'Active',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatCard(
            title: 'Avg Rating',
            value: stats['avgRating'].toStringAsFixed(1),
            icon: Icons.star,
            color: const Color(0xFFFFA726),
            subtitle: 'Stars',
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'This Month',
                  style: TextStyle(
                    color: Color(0xFF43A047),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: \$${NumberFormat('#,##0.00').format(stats['totalRevenue'])}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF43A047),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1000,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(0)}K',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 5000,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 1200),
                      const FlSpot(1, 1800),
                      const FlSpot(2, 1400),
                      const FlSpot(3, 2200),
                      const FlSpot(4, 1900),
                      const FlSpot(5, 2800),
                      const FlSpot(6, 2400),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF43A047)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1976D2).withOpacity(0.3),
                          const Color(0xFF43A047).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildRecentActivity(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/loads'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.check_circle,
            title: 'Load LD-2024-004 delivered',
            time: '2 hours ago',
            color: const Color(0xFF43A047),
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildActivityItem(
            icon: Icons.local_shipping,
            title: 'Load LD-2024-002 in transit',
            time: '4 hours ago',
            color: const Color(0xFF1976D2),
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildActivityItem(
            icon: Icons.assignment_turned_in,
            title: 'Load LD-2024-001 assigned to John Smith',
            time: '1 day ago',
            color: const Color(0xFFFFA726),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF161B33),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error loading stats: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
