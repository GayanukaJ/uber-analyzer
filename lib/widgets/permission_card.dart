import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PermissionCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final bool granted;
  final String buttonLabel;
  final VoidCallback onTap;

  const PermissionCard({
    super.key,
    required this.step,
    required this.title,
    required this.description,
    required this.granted,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted ? const Color(0xFF1A4A1A) : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: granted ? const Color(0xFF0D2A0D) : const Color(0xFF272750),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  step,
                  style: TextStyle(
                    color: granted ? AppTheme.green : AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              if (granted)
                const Icon(Icons.check_circle, color: AppTheme.green, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          if (!granted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  side: const BorderSide(color: AppTheme.accent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
