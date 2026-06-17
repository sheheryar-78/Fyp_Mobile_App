import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

// ─── Base Shimmer Box ─────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppTheme.darkCard : const Color(0xFFE2E8F0),
      highlightColor: isDark ? AppTheme.darkBorder : const Color(0xFFF8FAFC),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ─── 2x2 Stats Grid Skeleton ─────────────────────────────────────────────────

class ShimmerStatGrid extends StatelessWidget {
  const ShimmerStatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: List.generate(4, (index) {
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
                    ShimmerBox(width: 72, height: 11),
                    ShimmerBox(width: 32, height: 32, borderRadius: 8),
                  ],
                ),
                ShimmerBox(width: 56, height: 22, borderRadius: 6),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── List Tile Skeleton ───────────────────────────────────────────────────────

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ShimmerBox(width: 44, height: 44, borderRadius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(height: 13),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 120, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ShimmerBox(width: 44, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Card Block Skeleton ──────────────────────────────────────────────────────

class ShimmerCardBlock extends StatelessWidget {
  final double height;

  const ShimmerCardBlock({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
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
                    ShimmerBox(width: 120, height: 15),
                    const SizedBox(height: 6),
                    ShimmerBox(width: 80, height: 11),
                  ],
                ),
                ShimmerBox(width: 56, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 20),
            ShimmerBox(height: height - 80),
          ],
        ),
      ),
    );
  }
}

// ─── Full Screen Shimmer Loading ─────────────────────────────────────────────

class ShimmerListView extends StatelessWidget {
  final int count;

  const ShimmerListView({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (context, index) => const ShimmerListTile(),
    );
  }
}
