import 'package:flutter/material.dart';

/// Controller scope for synchronizing shimmer animations across multiple skeleton widgets.
class ShimmerScope extends InheritedWidget {
  final Animation<double> animation;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerScope({
    super.key,
    required this.animation,
    required this.baseColor,
    required this.highlightColor,
    required super.child,
  });

  static ShimmerScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShimmerScope>();
  }

  @override
  bool updateShouldNotify(ShimmerScope oldWidget) {
    return animation != oldWidget.animation ||
        baseColor != oldWidget.baseColor ||
        highlightColor != oldWidget.highlightColor;
  }
}

/// A lightweight, smooth shimmer widget that drives a single synchronized
/// animation across all nested skeleton elements to avoid duplicate loops and memory leaks.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBase = widget.baseColor ??
        (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final effectiveHighlight = widget.highlightColor ??
        (isDark ? const Color(0xFF475569) : const Color(0xFFF8FAFC));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShimmerScope(
          animation: _controller,
          baseColor: effectiveBase,
          highlightColor: effectiveHighlight,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

/// Mask widget that applies the shimmer gradient sweep over its child's opaque pixels.
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scope = ShimmerScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = scope?.baseColor ??
        (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final highlightColor = scope?.highlightColor ??
        (isDark ? const Color(0xFF475569) : const Color(0xFFF8FAFC));
    final animValue = scope?.animation.value ?? 0.0;

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.1, 0.35, 0.6],
          transform: _SlidingGradientTransform(slidePercent: animValue),
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2.5 - 1.0),
      0.0,
      0.0,
    );
  }
}

/// A single skeleton placeholder box with rounded corners and consistent dimensions.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton placeholder for the 8 Summary KPI / Count cards on the Dashboard.
class SummaryCardsSkeleton extends StatelessWidget {
  const SummaryCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;
          final double childAspectRatio =
              constraints.maxWidth < 600 ? 1.5 : 2.2;

          if (constraints.maxWidth >= 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth >= 800) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth >= 600) {
            crossAxisCount = 2;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) => _buildSkeletonCard(context),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLarge = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ShimmerLoading(
        child: Row(
          children: [
            // Icon skeleton
            ShimmerBox(
              width: isLarge ? 44 : 36,
              height: isLarge ? 44 : 36,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 16),
            // Title & Value skeletons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerBox(
                    width: isLarge ? 85 : 70,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 10),
                  ShimmerBox(
                    width: isLarge ? 110 : 85,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
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

/// Simulated chart graphic placeholder (bars or lines) used inside chart containers.
enum ChartSkeletonType { line, bar }

class ChartGraphicSkeleton extends StatelessWidget {
  final ChartSkeletonType type;

  const ChartGraphicSkeleton({
    super.key,
    this.type = ChartSkeletonType.bar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated chart area with horizontal grid lines and vertical bars / line elements
          Expanded(
            child: Stack(
              children: [
                // Horizontal grid lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (_) => Container(
                      height: 1,
                      color: dividerColor,
                    ),
                  ),
                ),
                // Chart graphic elements
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: type == ChartSkeletonType.bar
                        ? _buildBarSkeleton()
                        : _buildLineSkeleton(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Simulated bottom horizontal axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              6,
              (_) => ShimmerBox(
                width: 28,
                height: 10,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarSkeleton() {
    final barFractions = [0.45, 0.72, 0.52, 0.88, 0.60, 0.78, 0.65];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: barFractions.map((fraction) {
        return FractionallySizedBox(
          heightFactor: fraction,
          child: ShimmerBox(
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        return CustomPaint(
          size: Size(width, height),
          painter: _LineChartPlaceholderPainter(),
        );
      },
    );
  }
}

class _LineChartPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final p0 = Offset(0, size.height * 0.75);
    final p1 = Offset(size.width * 0.2, size.height * 0.55);
    final p2 = Offset(size.width * 0.4, size.height * 0.65);
    final p3 = Offset(size.width * 0.6, size.height * 0.30);
    final p4 = Offset(size.width * 0.8, size.height * 0.40);
    final p5 = Offset(size.width, size.height * 0.15);

    path.moveTo(p0.dx, p0.dy);
    path.quadraticBezierTo(p1.dx, p1.dy, (p0.dx + p2.dx) / 2, (p0.dy + p2.dy) / 2);
    path.quadraticBezierTo(p2.dx, p2.dy, (p2.dx + p3.dx) / 2, (p2.dy + p3.dy) / 2);
    path.quadraticBezierTo(p3.dx, p3.dy, (p3.dx + p4.dx) / 2, (p3.dy + p4.dy) / 2);
    path.quadraticBezierTo(p4.dx, p4.dy, p5.dx, p5.dy);

    canvas.drawPath(path, paint);

    // Subtle area fill underneath the curve
    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A standalone skeleton container matching the chart containers in `DashboardCharts`.
class ChartCardSkeleton extends StatelessWidget {
  final ChartSkeletonType type;
  final double height;

  const ChartCardSkeleton({
    super.key,
    this.type = ChartSkeletonType.bar,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title placeholder + trailing badge placeholder
          ShimmerLoading(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(
                  width: 140,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                ShimmerBox(
                  width: 70,
                  height: 14,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Body: Simulated chart graphic
          Expanded(
            child: ChartGraphicSkeleton(type: type),
          ),
        ],
      ),
    );
  }
}

/// Full skeleton layout for the Dashboard Charts (Sales Trend, Monthly Sales vs Purchase,
/// and Top Selling Products) matching the desktop/mobile layout breakpoints.
class DashboardChartsSkeleton extends StatelessWidget {
  const DashboardChartsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 1000;

          return Column(
            children: [
              if (isDesktop)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ChartCardSkeleton(type: ChartSkeletonType.line),
                    ),
                    SizedBox(width: 24),
                  ],
                )
              else ...[
                const ChartCardSkeleton(type: ChartSkeletonType.line),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 24),
              if (isDesktop)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: ChartCardSkeleton(type: ChartSkeletonType.bar),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: ChartCardSkeleton(type: ChartSkeletonType.bar),
                    ),
                  ],
                )
              else ...[
                const ChartCardSkeleton(type: ChartSkeletonType.bar),
                const SizedBox(height: 24),
                const ChartCardSkeleton(type: ChartSkeletonType.bar),
              ],
            ],
          );
        },
      ),
    );
  }
}
