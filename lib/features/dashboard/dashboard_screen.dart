import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_inventory/core/widgets/app_drawer.dart';
import 'package:pos_inventory/features/dashboard/logic/dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _primaryBlue = Color(0xFF1D61E7);

  final DashboardController _controller = DashboardController();
  final NumberFormat _money = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _controller.loadDashboard();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _controller.loadDashboard();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Dashboard POS'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat dashboard: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final todayTrend = _trend(
            data.today.salesAmount,
            data.yesterday.salesAmount,
          );
          final yesterdayTrend = _trend(
            data.yesterday.salesAmount,
            data.today.salesAmount,
          );

          return RefreshIndicator(
            onRefresh: _reload,
            color: _primaryBlue,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HeroCard(
                        title: 'Hari Ini',
                        value: _money.format(data.today.salesAmount),
                        trendLabel: _trendLabel(
                          todayTrend,
                          comparisonPeriod: 'hari kemarin',
                        ),
                        trendUp: todayTrend >= 0,
                        subtitle:
                            '${data.today.transactions} trx • ${data.today.soldItems} item',
                        compact: true,
                        icon: Icons.today_rounded,
                        gradientColors: const [
                          Color(0xFF4E8DFF),
                          Color(0xFF1D61E7),
                          Color(0xFF164CB7),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroCard(
                        title: 'Kemarin',
                        value: _money.format(data.yesterday.salesAmount),
                        trendLabel: _trendLabel(
                          yesterdayTrend,
                          comparisonPeriod: 'hari ini',
                        ),
                        trendUp: yesterdayTrend >= 0,
                        subtitle:
                            '${data.yesterday.transactions} trx • ${data.yesterday.soldItems} item',
                        compact: true,
                        icon: Icons.history_toggle_off_rounded,
                        gradientColors: const [
                          Color(0xFF13B9B0),
                          Color(0xFF0E8D96),
                          Color(0xFF0C6674),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SimpleMetricCard(
                  title: 'Penjualan Bulan Ini',
                  value: _money.format(data.month.salesAmount),
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 12),
                _SimpleMetricCard(
                  title: 'Total Nilai Inventory',
                  value: _money.format(data.inventoryValue),
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '5 Produk Terlaris',
                  icon: Icons.local_fire_department_outlined,
                  child: data.topProducts.isEmpty
                      ? const _EmptyText(text: 'Belum ada data penjualan')
                      : Column(
                          children: data.topProducts.asMap().entries.map((
                            entry,
                          ) {
                            final i = entry.key;
                            final p = entry.value;
                            return _ListRow(
                              leading: '#${i + 1}',
                              title: p.name,
                              subtitle: '${p.soldQty} item',
                              trailing: _money.format(p.soldTotal),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '10 Barang Stok Kritis',
                  icon: Icons.warning_amber_rounded,
                  child: data.criticalStocks.isEmpty
                      ? const _EmptyText(text: 'Belum ada data produk')
                      : Column(
                          children: data.criticalStocks.asMap().entries.map((
                            entry,
                          ) {
                            final p = entry.value;
                            return _ListRow(
                              leading: '${entry.key + 1}',
                              title: p.name,
                              subtitle: '${p.category} • Stok ${p.stock}',
                              trailing: _money.format(p.stock * p.price),
                              highlight: p.stock <= 10,
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _trend(double current, double previous) {
    if (previous == 0) {
      return current > 0 ? 100 : 0;
    }
    return ((current - previous) / previous) * 100;
  }

  String _trendLabel(double trend, {required String comparisonPeriod}) {
    final sign = trend > 0 ? '+' : '';
    return '$sign${trend.toStringAsFixed(1)}%  vs $comparisonPeriod';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.value,
    required this.trendLabel,
    required this.trendUp,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.compact = false,
  });

  final String title;
  final String value;
  final String trendLabel;
  final bool trendUp;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color trendColor = trendUp
        ? const Color(0xFF86EFAC)
        : const Color(0xFFFCA5A5);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _DashboardScreenState._primaryBlue.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
              Container(
                width: compact ? 28 : 32,
                height: compact ? 28 : 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: compact ? 16 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 22 : 28,
                height: 1.05,
              ),
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Row(
            children: [
              Icon(
                trendUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: trendColor,
                size: compact ? 15 : 17,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trendLabel,
                  style: TextStyle(
                    color: trendColor,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 5 : 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white70,
              fontSize: compact ? 11 : 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleMetricCard extends StatelessWidget {
  const _SimpleMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1D61E7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1D61E7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1D61E7), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.highlight = false,
  });

  final String leading;
  final String title;
  final String subtitle;
  final String trailing;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? const Color(0xFFFECACA) : const Color(0xFFE2E8F7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1D61E7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              leading,
              style: const TextStyle(
                color: Color(0xFF1D61E7),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            style: TextStyle(
              color: highlight
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFF1D61E7),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(text, style: const TextStyle(color: Color(0xFF64748B))),
      ),
    );
  }
}
