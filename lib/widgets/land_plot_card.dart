import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/haptic_engine.dart';
import '../models/land_plot.dart';

class LandPlotCard extends StatelessWidget {
  final LandPlot plot;

  const LandPlotCard({super.key, required this.plot});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: () async {
        await HapticEngine.triggerSelection();
        // Navigate to details
      },
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(tokens.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: tokens.brandPrimary.withValues(alpha: 0.1),
                width: double.infinity,
                child: const Icon(Icons.landscape, size: 48),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.spacingUnit * 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plot.title,
                    style: tokens.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: tokens.spacingUnit * 0.5),
                  Text(
                    plot.location,
                    style: tokens.bodyStyle.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
