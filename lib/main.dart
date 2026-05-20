import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';

// ─────────────────────────────────────────────
// OVERLAY ENTRY POINT
// When flutter_overlay_window launches the overlay,
// it calls main() with a special overlay flag.
// We must intercept that and show our overlay widget.
// ─────────────────────────────────────────────
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TripOverlayApp());
}

// ─────────────────────────────────────────────
// MAIN APP ENTRY POINT
// ─────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the background service (notification listener)
  await initBackgroundService();

  runApp(const UberAnalyzerApp());
}

// ─────────────────────────────────────────────
// MAIN APP
// ─────────────────────────────────────────────
class UberAnalyzerApp extends StatelessWidget {
  const UberAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// OVERLAY APP (runs in overlay window)
// ─────────────────────────────────────────────
class TripOverlayApp extends StatelessWidget {
  const TripOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWidget(),
    );
  }
}

// ─────────────────────────────────────────────
// OVERLAY WIDGET — the floating popup
// ─────────────────────────────────────────────
class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget>
    with SingleTickerProviderStateMixin {
  double price = 0;
  double distanceKm = 0;
  String tripTitle = 'Trip Request';
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();

    // Listen for data sent from the background service
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          price = (data['price'] as num?)?.toDouble() ?? 0;
          distanceKm = (data['distanceKm'] as num?)?.toDouble() ?? 0;
          tripTitle = data['title'] as String? ?? 'Trip Request';
        });
        // Reset animation on new data
        _animController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get perKm => (price > 0 && distanceKm > 0) ? price / distanceKm : 0;

  Color get rateColor {
    if (perKm >= 80) return const Color(0xFF00C853);
    if (perKm >= 50) return const Color(0xFFFFD600);
    return const Color(0xFFFF5252);
  }

  String get rateLabel {
    if (perKm <= 0) return '';
    if (perKm >= 80) return '✓ Good Rate';
    if (perKm >= 50) return '~ Average Rate';
    return '✗ Low Rate';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          // Dragging is handled by flutter_overlay_window internally
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF333355)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF333355), height: 1),
                const SizedBox(height: 12),
                _buildMetricsRow(),
                const SizedBox(height: 12),
                _buildPerKmBox(),
                const SizedBox(height: 8),
                const Text(
                  'Drag to move  •  Auto-closes in 30s',
                  style: TextStyle(color: Color(0xFF555566), fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'U',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tripTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () => FlutterOverlayWindow.closeOverlay(),
          child: const Icon(Icons.close, color: Color(0xFF888888), size: 22),
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: _buildMetric('FARE', price > 0 ? 'Rs. ${price.toStringAsFixed(0)}' : '—')),
          const VerticalDivider(color: Color(0xFF333355), width: 1),
          Expanded(child: _buildMetric('DISTANCE', distanceKm > 0 ? '${distanceKm.toStringAsFixed(1)} km' : '—')),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF888899), fontSize: 10, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildPerKmBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            perKm > 0 ? 'Rs. ${perKm.toStringAsFixed(1)} / km' : 'Rs. — / km',
            style: TextStyle(color: rateColor, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          if (rateLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(rateLabel, style: TextStyle(color: rateColor, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
