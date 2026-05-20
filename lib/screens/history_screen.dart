import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_model.dart';
import '../theme/app_theme.dart';
import '../widgets/trip_card.dart';

// ──────────────────────────────────────────────
// HISTORY SCREEN
// ──────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TripData> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final lines = prefs.getStringList('trip_history') ?? [];
    setState(() {
      _trips = lines.map(TripData.fromHistoryLine).toList();
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear History', style: TextStyle(color: Colors.white)),
        content: const Text('Delete all trip history?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('trip_history');
      setState(() => _trips = []);
    }
  }

  // Stats
  double get avgPerKm {
    final valid = _trips.where((t) => t.perKm > 0).toList();
    if (valid.isEmpty) return 0;
    return valid.fold(0.0, (s, t) => s + t.perKm) / valid.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Trip History'),
        actions: [
          if (_trips.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.red), onPressed: _clearHistory),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? const Center(child: Text('No trips recorded yet.', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary stats
                    if (_trips.isNotEmpty) ...[
                      _buildStats(),
                      const SizedBox(height: 20),
                    ],
                    ..._trips.map((trip) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TripCard(trip: trip, showTime: true),
                        )),
                  ],
                ),
    );
  }

  Widget _buildStats() {
    final good = _trips.where((t) => t.rateCategory == RateCategory.good).length;
    final avg = _trips.where((t) => t.rateCategory == RateCategory.average).length;
    final low = _trips.where((t) => t.rateCategory == RateCategory.low).length;

    return Row(
      children: [
        _statBox('${_trips.length}', 'Total', AppTheme.textSecondary),
        const SizedBox(width: 8),
        _statBox('Rs.${avgPerKm.toStringAsFixed(0)}/km', 'Avg Rate', AppTheme.accent),
        const SizedBox(width: 8),
        _statBox('$good', 'Good', AppTheme.green),
        const SizedBox(width: 8),
        _statBox('$low', 'Low', AppTheme.red),
      ],
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SETTINGS SCREEN
// ──────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _goodThreshold = 80;
  double _avgThreshold = 50;
  String _uberPackage = 'com.ubercab.driver';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goodThreshold = prefs.getDouble('threshold_good') ?? 80;
      _avgThreshold = prefs.getDouble('threshold_avg') ?? 50;
      _uberPackage = prefs.getString('uber_package') ?? 'com.ubercab.driver';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('threshold_good', _goodThreshold);
    await prefs.setDouble('threshold_avg', _avgThreshold);
    await prefs.setString('uber_package', _uberPackage);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved'), backgroundColor: AppTheme.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Settings'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppTheme.accent))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Rate thresholds
          _sectionTitle('Rate Thresholds (Rs/km)'),
          const SizedBox(height: 8),
          _thresholdRow('Good rate ≥', _goodThreshold, AppTheme.green, (v) => setState(() => _goodThreshold = v)),
          const SizedBox(height: 8),
          _thresholdRow('Average rate ≥', _avgThreshold, AppTheme.yellow, (v) => setState(() => _avgThreshold = v)),
          const SizedBox(height: 24),

          // Uber package name
          _sectionTitle('Uber App Package Name'),
          const SizedBox(height: 8),
          const Text(
            'Find the exact package name using the "Package Name Viewer" app from Play Store.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _uberPackage,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              hintText: 'com.ubercab.driver',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
            ),
            onChanged: (v) => _uberPackage = v,
          ),
          const SizedBox(height: 8),
          const Text('Common packages:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          _packageChip('com.ubercab.driver', 'Uber Driver'),
          _packageChip('com.ubercab', 'Uber (rider)'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1),
      );

  Widget _thresholdRow(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text('Rs. ${value.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: value,
            min: 20,
            max: 200,
            divisions: 36,
            activeColor: color,
            inactiveColor: AppTheme.divider,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _packageChip(String pkg, String label) {
    return GestureDetector(
      onTap: () => setState(() => _uberPackage = pkg),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              _uberPackage == pkg ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: AppTheme.accent, size: 16,
            ),
            const SizedBox(width: 8),
            Text('$label — ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text(pkg, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}
