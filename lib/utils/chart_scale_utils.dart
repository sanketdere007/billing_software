import 'dart:math';
import 'package:flutter/material.dart';

/// Holds the dynamically calculated Y-axis scale parameters for charts.
class ChartYAxisScale {
  final double maxY;
  final double interval;
  final double reservedSize;

  const ChartYAxisScale({
    required this.maxY,
    required this.interval,
    required this.reservedSize,
  });
}

/// Utility class for formatting chart values and calculating dynamic Y-axis scales.
class ChartScaleUtils {
  ChartScaleUtils._();

  /// Formats currency values into compact Indian units:
  /// - Below ₹1,000: ₹500, ₹999
  /// - Thousands (K): ₹1K, ₹10K, ₹25K, ₹50.5K
  /// - Lakhs (L): ₹1L, ₹2.5L, ₹10L, ₹50L
  /// - Crores (Cr): ₹1Cr, ₹1.5Cr, ₹10Cr, ₹100Cr
  static String formatIndianCompactCurrency(num value) {
    if (value.isNaN || value.isInfinite) return '₹0';
    final double absVal = value.abs().toDouble();
    final String sign = value < 0 ? '-' : '';

    String formatNumber(double numVal) {
      if (numVal == numVal.roundToDouble()) {
        return numVal.toInt().toString();
      }
      String s = numVal.toStringAsFixed(2);
      if (s.contains('.')) {
        s = s.replaceAll(RegExp(r'0+$'), '');
        s = s.replaceAll(RegExp(r'\.$'), '');
      }
      return s;
    }

    // Round slightly to prevent floating-point representation anomalies
    final double rounded = double.parse(absVal.toStringAsFixed(2));

    if (rounded >= 10000000) {
      // 1 Crore = 10,000,000
      return '$sign₹${formatNumber(rounded / 10000000)}Cr';
    } else if (rounded >= 100000) {
      // 1 Lakh = 100,000
      return '$sign₹${formatNumber(rounded / 100000)}L';
    } else if (rounded >= 1000) {
      // 1 Thousand = 1,000
      return '$sign₹${formatNumber(rounded / 1000)}K';
    } else {
      return '$sign₹${formatNumber(rounded)}';
    }
  }

  /// Dynamically calculates a nice, readable Y-axis scale (maxY, interval, and reserved label width)
  /// based on the maximum data value.
  ///
  /// Guarantees:
  /// - Non-overlapping Y-axis labels by picking a suitable interval (typically 4-5 divisions).
  /// - Headroom above [maxValue] so peaks and dots aren't clipped at the chart's top ceiling.
  /// - Sufficient horizontal [reservedSize] calculated dynamically from the actual rendered label text width.
  static ChartYAxisScale calculateYAxisScale(
    double maxValue, {
    double headroomFactor = 1.15,
    int targetDivisions = 4,
    TextStyle labelStyle = const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
    ),
    double minReservedSize = 42.0,
  }) {
    if (maxValue <= 0) {
      return ChartYAxisScale(
        maxY: 100,
        interval: 25,
        reservedSize: minReservedSize,
      );
    }

    // 1. Calculate target max with headroom
    final double targetMax = maxValue * headroomFactor;
    final double roughInterval = targetMax / targetDivisions;

    // 2. Determine order of magnitude
    final double exponent =
        pow(10, (log(roughInterval) / ln10).floor()).toDouble();
    final double fraction = roughInterval / exponent;

    // 3. Choose a round, human-friendly multiplier (1, 2, 2.5, 5, 10)
    double niceFraction;
    if (fraction <= 1.25) {
      niceFraction = 1.0;
    } else if (fraction <= 2.25) {
      niceFraction = 2.0;
    } else if (fraction <= 3.75) {
      niceFraction = 2.5;
    } else if (fraction <= 7.5) {
      niceFraction = 5.0;
    } else {
      niceFraction = 10.0;
    }

    final double interval = max(1.0, niceFraction * exponent);
    double maxY = (targetMax / interval).ceil() * interval;

    // Guarantee that maxY strictly exceeds maxValue so the peak is never clipped
    if (maxY <= maxValue) {
      maxY += interval;
    }

    // 4. Measure exact rendered label widths to dynamically allocate reservedSize
    double maxLabelWidth = 0;
    final int steps = (maxY / interval).round();
    for (int i = 1; i <= steps; i++) {
      final double v = i * interval;
      final text = formatIndianCompactCurrency(v);
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > maxLabelWidth) {
        maxLabelWidth = tp.width;
      }
    }

    // Dynamic reservedSize: label width + space between label and chart (6) + padding (8)
    final double reservedSize = max(minReservedSize, maxLabelWidth + 14.0);

    return ChartYAxisScale(
      maxY: maxY,
      interval: interval,
      reservedSize: reservedSize,
    );
  }
}
