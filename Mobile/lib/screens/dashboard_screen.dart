import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  
  Map<String, dynamic>? _stats;
  List<dynamic> _calls = [];
  List<dynamic> _chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final statsRes = await ApiService.getDashboardStats();
      final callsRes = await ApiService.getCalls();
      final chartRes = await ApiService.getWeeklyCalls();

      if (statsRes.statusCode == 200) {
        _stats = jsonDecode(statsRes.body);
      }
      if (callsRes.statusCode == 200) {
        _calls = jsonDecode(callsRes.body);
      }
      if (chartRes.statusCode == 200) {
        _chartData = jsonDecode(chartRes.body);
      }
    } catch (e) {
      debugPrint("Dashboard fetch error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/dashboard'),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const Text(
                    "Here's your agent performance overview.",
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),

                  // Stats Grid
                  _buildStatsGrid(),
                  const SizedBox(height: 24),

                  // Analytics Chart Card
                  _buildAnalyticsChartCard(),
                  const SizedBox(height: 24),

                  // Recent Calls Card
                  _buildRecentCallsCard(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatsGrid() {
    final totalCalls = _stats?['totalCalls'] ?? 0;
    final activeAgents = _stats?['activeAgents'] ?? 0;
    final satisfaction = _stats?['satisfaction'] ?? 0.0;
    final avgDuration = _stats?['avgDuration'] ?? "0s";

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _buildStatCard("Total Calls Today", "$totalCalls", Icons.phone, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
        _buildStatCard("Active Agents", "$activeAgents", Icons.smart_toy, const Color(0xFFECFDF5), const Color(0xFF10B981)),
        _buildStatCard("CSAT Rating", "${satisfaction.toStringAsFixed(1)}★", Icons.thumb_up, const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)),
        _buildStatCard("Avg Duration", avgDuration, Icons.timer, const Color(0xFFFFF7ED), const Color(0xFFF97316)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor, Color iconColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: iconColor, size: 18),
                )
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsChartCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Call Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text('Weekly call volume', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.green, size: 10),
                    SizedBox(width: 4),
                    Text('Live', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: _chartData.isEmpty 
                ? const Center(child: Text("No chart data available", style: TextStyle(color: Color(0xFF64748B))))
                : BarChart(
                    BarChartData(
                      barGroups: _generateBarGroups(),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < _chartData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(_chartData[value.toInt()]['day'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 5,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                      ),
                    ),
                  ),
            )
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(_chartData.length, (index) {
      final callsCount = (_chartData[index]['calls'] ?? 0).toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: callsCount == 0 ? 0.3 : callsCount,
            color: const Color(0xFF2563EB),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 15,
              color: const Color(0xFFF1F5F9),
            ),
          )
        ],
      );
    });
  }

  Widget _buildRecentCallsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Calls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            _calls.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text("No calls found", style: TextStyle(color: Color(0xFF64748B)))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _calls.take(5).length, // Show up to 5 calls on dashboard
                  separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final call = _calls[index];
                    final String caller = call['caller'] ?? "Unknown";
                    final String agentName = call['agent'] ?? "N/A";
                    final String duration = call['duration'] ?? "0s";
                    final String status = call['status'] ?? "completed";
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.phone_outlined, color: Color(0xFF64748B), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(caller, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                Text("Agent: $agentName", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(duration, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Text(
                                status.toUpperCase(), 
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold, 
                                  color: status == "completed" ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          )
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
