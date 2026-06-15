import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart' as shimmer;

class Shimmer extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const Shimmer({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
  });

  factory Shimmer.list() {
    return const Shimmer(itemCount: 8);
  }

  factory Shimmer.card() {
    return const Shimmer(itemCount: 1);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: _ShimmerCard(),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    final imageSize = size.width * 0.18;
    final titleWidth = size.width * 0.55;
    final subWidth = size.width * 0.35;

    return shimmer.Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE BLOCK
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),

            const SizedBox(width: 12),

            /// TEXT BLOCK (SAFE - NO OVERFLOW)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(width: titleWidth, height: 14),
                  const SizedBox(height: 10),

                  _line(width: subWidth, height: 12),
                  const SizedBox(height: 6),

                  _line(width: subWidth * 0.8, height: 12),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _line(
                        width: size.width * 0.18,
                        height: 26,
                        radius: 30,
                      ),
                      const SizedBox(width: 10),
                      _line(
                        width: size.width * 0.22,
                        height: 26,
                        radius: 30,
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

  Widget _line({
    required double width,
    required double height,
    double radius = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}