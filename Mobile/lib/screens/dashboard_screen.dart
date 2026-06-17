import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nexcall_app_bar.dart';
import '../widgets/shimmer_loaders.dart';
import '../widgets/error_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _hasError   = false;

  Map<String, dynamic>? _stats;
  List<dynamic> _calls     = [];
  List<dynamic> _chartData = [];
  String _userName         = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      // Load user name for greeting
      final user = await ApiService.getUser();
      _userName = user?['name'] ?? '';

      final results = await Future.wait([
        ApiService.getDashboardStats(),
        ApiService.getCalls(),
        ApiService.getWeeklyCalls(),
      ]);

      final statsRes = results[0];
      final callsRes = results[1];
      final chartRes = results[2];

      if (statsRes.statusCode == 200) _stats     = jsonDecode(statsRes.body);
      if (callsRes.statusCode == 200) _calls     = jsonDecode(callsRes.body);
      if (chartRes.statusCode == 200) _chartData = jsonDecode(chartRes.body);
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NexCallAppBar(title: 'Dashboard'),
      body: _isLoading
          ? _buildSkeleton()
          : _hasError
              ? ErrorStateWidget(
                  message: 'Failed to load dashboard data.',
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(),
                        const SizedBox(height: 20),
                        _buildStatsGrid(),
                        const SizedBox(height: 20),
                        _buildChartCard(),
                        const SizedBox(height: 20),
                        _buildRecentCallsCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 200, height: 20, borderRadius: 6),
          const SizedBox(height: 6),
          ShimmerBox(width: 280, height: 14, borderRadius: 6),
          const SizedBox(height: 20),
          const ShimmerStatGrid(),
          const SizedBox(height: 20),
          const ShimmerCardBlock(height: 260),
          const SizedBox(height: 20),
          const ShimmerCardBlock(height: 200),
        ],
      ),
    );
  }

  // ── Greeting ───────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final displayName = _userName.isNotEmpty ? ', ${_userName.split(' ').first}' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting$displayName 👋',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Here's your AI agent performance overview.",
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ── Stats Grid ─────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    final totalCalls   = _stats?['totalCalls']   ?? 0;
    final activeAgents = _stats?['activeAgents'] ?? 0;
    final satisfaction = (_stats?['satisfaction'] ?? 0.0) is int
        ? (_stats?['satisfaction'] ?? 0.0).toDouble()
        : (_stats?['satisfaction'] ?? 0.0);
    final avgDuration  = _stats?['avgDuration']  ?? '0s';

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _StatCard(
          label: 'Total Calls Today',
          value: '$totalCalls',
          icon: Icons.phone_rounded,
          bgColor: AppTheme.primaryBlueXLight,
          iconColor: AppTheme.primaryBlue,
        ),
        _StatCard(
          label: 'Active Agents',
          value: '$activeAgents',
          icon: Icons.smart_toy_rounded,
          bgColor: AppTheme.successGreenLight,
          iconColor: AppTheme.successGreen,
        ),
        _StatCard(
          label: 'CSAT Rating',
          value: '${satisfaction.toStringAsFixed(1)}★',
          icon: Icons.thumb_up_rounded,
          bgColor: AppTheme.purpleLight,
          iconColor: AppTheme.purple,
        ),
        _StatCard(
          label: 'Avg Duration',
          value: avgDuration,
          icon: Icons.timer_rounded,
          bgColor: AppTheme.orangeLight,
          iconColor: AppTheme.orange,
        ),
      ],
    );
  }

  // ── Analytics Chart ────────────────────────────────────────────────────────

  Widget _buildChartCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Call Analytics',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Text('Weekly call volume',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreenLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: AppTheme.successGreen, size: 8),
                      SizedBox(width: 5),
                      Text('Live',
                          style: TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 180,
              child: _chartData.isEmpty
                  ? const Center(
                      child: Text('No chart data yet',
                          style: TextStyle(color: AppTheme.textSecondary)))
                  : BarChart(
                      BarChartData(
                        barGroups: _generateBarGroups(),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5,
                          getDrawingHorizontalLine: (_) => const FlLine(
                              color: AppTheme.dividerLight, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                    color: AppTheme.textTertiary, fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i >= 0 && i < _chartData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      _chartData[i]['day'] ?? '',
                                      style: const TextStyle(
                                          color: AppTheme.textTertiary,
                                          fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, gi, rod, ri) =>
                                BarTooltipItem(
                              '${rod.toY.toInt()} calls',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(_chartData.length, (i) {
      final count = (_chartData[i]['calls'] ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: count == 0 ? 0.4 : count,
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBlueLight, AppTheme.primaryBlueDark],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 15,
              color: AppTheme.dividerLight,
            ),
          ),
        ],
      );
    });
  }

  // ── Recent Calls ───────────────────────────────────────────────────────────

  Widget _buildRecentCallsCard() {
    final recent = _calls.take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Calls',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (_calls.length > 5)
                  TextButton(
                    onPressed: () {},
                    child: const Text('View all'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No calls yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final call    = recent[i];
                  final caller  = call['caller']   ?? 'Unknown';
                  final agent   = call['agent']    ?? 'N/A';
                  final dur     = call['duration'] ?? '0s';
                  final status  = call['status']   ?? 'completed';
                  final isOk    = status == 'completed';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlueXLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone_rounded,
                              color: AppTheme.primaryBlue, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(caller,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text('Agent: $agent',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(dur,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOk
                                    ? AppTheme.successGreenLight
                                    : AppTheme.errorRedLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isOk
                                      ? AppTheme.successGreenDark
                                      : AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card Widget ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
