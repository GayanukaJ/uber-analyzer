import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../theme/app_theme.dart';

class TripCard extends StatelessWidget {
  final TripData trip;
  final bool showTime;

  const TripCard({super.key, required this.trip, this.showTime = false});

  @override
  Widget build(BuildContext context) {
    final rateColor = Color(trip.rateCategory.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trip.title,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (showTime)
                Text(
                  _formatTime(trip.timestamp),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrics row
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _metric('FARE', trip.price > 0 ? 'Rs. ${trip.price.toStringAsFixed(0)}' : '—')),
                const VerticalDivider(color: AppTheme.divider, width: 1),
                Expanded(child: _metric('DISTANCE', trip.distanceKm > 0 ? '${trip.distanceKm.toStringAsFixed(1)} km' : '—')),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Per-km highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1A0D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A3A1A)),
            ),
            child: Column(
              children: [
                const Text('RATE PER KM', style: TextStyle(color: Color(0xFFBBBBCC), fontSize: 10, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(
                  trip.perKm > 0 ? 'Rs. ${trip.perKm.toStringAsFixed(1)} / km' : '—',
                  style: TextStyle(color: rateColor, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                if (trip.perKm > 0) ...[
                  const SizedBox(height: 2),
                  Text(trip.rateCategory.label, style: TextStyle(color: rateColor, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
