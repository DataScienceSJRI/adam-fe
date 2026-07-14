import 'dart:math' as math;
import 'package:adam/data/models/dashboard_model.dart';
import 'package:flutter/material.dart';

class MovingMetabolicEngineCard extends StatefulWidget {
  final DashboardModel dashboard;

  const MovingMetabolicEngineCard({super.key, required this.dashboard});

  @override
  State<MovingMetabolicEngineCard> createState() =>
      _MovingMetabolicEngineCardState();
}

class _MovingMetabolicEngineCardState extends State<MovingMetabolicEngineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getPercentMetFromSummary(String nutrientKey) {
    try {
      final List<dynamic>? summary = widget.dashboard.nutrientSummary;
      if (summary == null) return 0.0;

      final item = summary.firstWhere(
        (e) =>
            e['Nutrient'] != null &&
            e['Nutrient'].toString().startsWith(nutrientKey),
        orElse: () => null,
      );

      if (item != null && item['% Met'] != null) {
        return (item['% Met'] as num).toDouble();
      }
    } catch (_) {}
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final double carbsPercent = _getPercentMetFromSummary('Carbohydrate');
    final double proteinPercent = _getPercentMetFromSummary('Protein');
    final double fibrePercent = _getPercentMetFromSummary('Dietary Fibre');
    final double fatPercent = _getPercentMetFromSummary('Fat');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Nutritional Intake",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                Icons.bubble_chart_rounded,
                size: 16,
                color: const Color(0xFF3B82F6).withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),

          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniWaveCard(
                          shortLabel: "Carbs",
                          percentMet: carbsPercent,
                          baseColor: const Color(0xFF3B82F6),
                          animationValue: _animationController.value,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMiniWaveCard(
                          shortLabel: "Protein",
                          percentMet: proteinPercent,
                          baseColor: const Color(0xFF10B981),
                          animationValue: _animationController.value + 0.25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniWaveCard(
                          shortLabel: "Fibre",
                          percentMet: fibrePercent,
                          baseColor: const Color(0xFFF59E0B),
                          animationValue: _animationController.value + 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMiniWaveCard(
                          shortLabel: "Lipids",
                          percentMet: fatPercent,
                          baseColor: const Color(0xFF8B5CF6),
                          animationValue: _animationController.value + 0.75,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniWaveCard({
    required String shortLabel,
    required double percentMet,
    required Color baseColor,
    required double animationValue,
  }) {
    final double cappedPercent = percentMet.clamp(0.0, 100.0);

    final int displayPercentage = cappedPercent.round();
    final double fraction = cappedPercent / 100.0;

    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MovingFluidPainter(
                  fillFraction: fraction,
                  baseColor: baseColor,
                  animationValue: animationValue,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    shortLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: baseColor.withOpacity(0.9),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$displayPercentage",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: baseColor,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        "Met",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
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

class _MovingFluidPainter extends CustomPainter {
  final double fillFraction;
  final Color baseColor;
  final double animationValue;

  _MovingFluidPainter({
    required this.fillFraction,
    required this.baseColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scaledFraction = fillFraction.clamp(0.12, 0.78);
    final double targetHeight = size.height * (1.0 - scaledFraction);
    final double basePhase = animationValue * math.pi * 2;

    void drawWaveLayer({
      required double phase,
      required double amplitude,
      required double frequencyScale,
      required double heightOffset,
      required Color color,
      bool drawCrest = false,
    }) {
      final Path wavePath = Path();
      final Path crestPath = Path();

      final double frequency = ((2 * math.pi) / size.width) * frequencyScale;
      final double currentHeight = targetHeight + heightOffset;

      wavePath.moveTo(0, size.height);
      wavePath.lineTo(0, currentHeight);

      for (double x = 0; x <= size.width; x++) {
        final double y =
            currentHeight + math.sin((x * frequency) + phase) * amplitude;
        wavePath.lineTo(x, y);
        if (x == 0) {
          crestPath.moveTo(x, y);
        } else {
          crestPath.lineTo(x, y);
        }
      }
      wavePath.lineTo(size.width, size.height);
      wavePath.close();

      canvas.drawPath(wavePath, Paint()..color = color);

      if (drawCrest) {
        canvas.drawPath(
          crestPath,
          Paint()
            ..color = baseColor.withOpacity(0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    drawWaveLayer(
      phase: basePhase,
      amplitude: 7.0,
      frequencyScale: 1.8,
      heightOffset: -4.0,
      color: baseColor.withOpacity(0.02),
    );

    drawWaveLayer(
      phase: -basePhase * 1.3 + 1.0,
      amplitude: 5.5,
      frequencyScale: 2.6,
      heightOffset: -2.0,
      color: baseColor.withOpacity(0.03),
    );

    drawWaveLayer(
      phase: basePhase * 0.8 + 2.0,
      amplitude: 8.5,
      frequencyScale: 1.4,
      heightOffset: 1.0,
      color: baseColor.withOpacity(0.03),
    );

    drawWaveLayer(
      phase: -basePhase * 1.6 + 3.5,
      amplitude: 4.5,
      frequencyScale: 3.2,
      heightOffset: 3.0,
      color: baseColor.withOpacity(0.04),
    );

    drawWaveLayer(
      phase: basePhase + (math.pi / 2),
      amplitude: 6.5,
      frequencyScale: 2.0,
      heightOffset: 0.0,
      color: baseColor.withOpacity(0.06),
      drawCrest: true,
    );
  }

  @override
  bool shouldRepaint(covariant _MovingFluidPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.fillFraction != fillFraction;
  }
}
