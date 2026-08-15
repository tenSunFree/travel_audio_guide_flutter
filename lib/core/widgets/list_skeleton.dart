import 'package:flutter/material.dart';

/// General list skeleton screen
/// [itemHeight] The height of each skeleton item
/// [itemCount] The number of skeleton items to display
/// [hasLeadingBox] Whether there is a square image on the left (used by AttractionTile)
class ListSkeleton extends StatefulWidget {
  const ListSkeleton({
    super.key,
    this.itemCount = 8,
    this.itemHeight = 80,
    this.hasLeadingBox = false,
  });

  final int itemCount;
  final double itemHeight;
  final bool hasLeadingBox;

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final color = baseColor.withValues(alpha: _animation.value);
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, _) => _SkeletonItem(
            height: widget.itemHeight,
            color: color,
            hasLeadingBox: widget.hasLeadingBox,
          ),
        );
      },
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem({
    required this.height,
    required this.color,
    required this.hasLeadingBox,
  });

  final double height;
  final Color color;
  final bool hasLeadingBox;

  Widget _box(double w, double h, {double radius = 6}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Left-side image placeholder (used by AttractionTile)
            if (hasLeadingBox) ...[
              _box(72, 72, radius: 10),
              const SizedBox(width: 12),
            ],
            // Text on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _box(double.infinity, 16),
                  const SizedBox(height: 8),
                  _box(160, 12),
                  const SizedBox(height: 6),
                  _box(120, 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
