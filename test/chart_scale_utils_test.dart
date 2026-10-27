import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/utils/chart_scale_utils.dart';

void main() {
  group('ChartScaleUtils.formatIndianCompactCurrency', () {
    test('formats zero correctly', () {
      expect(ChartScaleUtils.formatIndianCompactCurrency(0), '₹0');
      expect(ChartScaleUtils.formatIndianCompactCurrency(0.0), '₹0');
    });

    test('formats values under ₹1,000 without unit suffix', () {
      expect(ChartScaleUtils.formatIndianCompactCurrency(50), '₹50');
      expect(ChartScaleUtils.formatIndianCompactCurrency(500), '₹500');
      expect(ChartScaleUtils.formatIndianCompactCurrency(999), '₹999');
    });

    test('formats thousands using K', () {
      expect(ChartScaleUtils.formatIndianCompactCurrency(1000), '₹1K');
      expect(ChartScaleUtils.formatIndianCompactCurrency(1500), '₹1.5K');
      expect(ChartScaleUtils.formatIndianCompactCurrency(10000), '₹10K');
      expect(ChartScaleUtils.formatIndianCompactCurrency(25000), '₹25K');
      expect(ChartScaleUtils.formatIndianCompactCurrency(75000), '₹75K');
    });

    test('formats lakhs using L', () {
      expect(ChartScaleUtils.formatIndianCompactCurrency(100000), '₹1L');
      expect(ChartScaleUtils.formatIndianCompactCurrency(150000), '₹1.5L');
      expect(ChartScaleUtils.formatIndianCompactCurrency(200000), '₹2L');
      expect(ChartScaleUtils.formatIndianCompactCurrency(500000), '₹5L');
      expect(ChartScaleUtils.formatIndianCompactCurrency(1000000), '₹10L');
      expect(ChartScaleUtils.formatIndianCompactCurrency(2500000), '₹25L');
      expect(ChartScaleUtils.formatIndianCompactCurrency(5000000), '₹50L');
    });

    test('formats crores using Cr', () {
      expect(ChartScaleUtils.formatIndianCompactCurrency(10000000), '₹1Cr');
      expect(ChartScaleUtils.formatIndianCompactCurrency(15000000), '₹1.5Cr');
      expect(ChartScaleUtils.formatIndianCompactCurrency(20000000), '₹2Cr');
      expect(ChartScaleUtils.formatIndianCompactCurrency(100000000), '₹10Cr');
      expect(ChartScaleUtils.formatIndianCompactCurrency(250000000), '₹25Cr');
    });

    test('handles negative and edge values cleanly', () {
      expect(ChartScaleUtils.formatIndianCompactCurrency(-5000), '-₹5K');
      expect(ChartScaleUtils.formatIndianCompactCurrency(-200000), '-₹2L');
      expect(ChartScaleUtils.formatIndianCompactCurrency(double.nan), '₹0');
      expect(ChartScaleUtils.formatIndianCompactCurrency(double.infinity), '₹0');
    });
  });

  group('ChartScaleUtils.calculateYAxisScale', () {
    test('handles zero or negative maximum sales gracefully', () {
      final scale = ChartScaleUtils.calculateYAxisScale(0);
      expect(scale.maxY, 100);
      expect(scale.interval, 25);
      expect(scale.reservedSize, 42.0);
    });

    test('calculates clean intervals and scales for small sales amounts', () {
      final scale = ChartScaleUtils.calculateYAxisScale(800);
      expect(scale.maxY, greaterThan(800));
      expect(scale.interval, greaterThan(0));
      expect(scale.maxY % scale.interval, 0);
      final steps = scale.maxY / scale.interval;
      expect(steps, inInclusiveRange(3, 6));
    });

    test('calculates clean intervals and scales for thousands (e.g. ₹15,000 - ₹85,000)', () {
      for (final maxSales in [15000.0, 45000.0, 85000.0]) {
        final scale = ChartScaleUtils.calculateYAxisScale(maxSales);
        expect(scale.maxY, greaterThan(maxSales));
        expect(scale.interval, greaterThan(0));
        expect(scale.maxY % scale.interval, 0);
        final steps = scale.maxY / scale.interval;
        expect(steps, inInclusiveRange(3, 6));
      }
    });

    test('calculates clean intervals and scales for lakhs (e.g. ₹1.5L - ₹50L)', () {
      for (final maxSales in [150000.0, 350000.0, 1200000.0, 5000000.0]) {
        final scale = ChartScaleUtils.calculateYAxisScale(maxSales);
        expect(scale.maxY, greaterThan(maxSales));
        expect(scale.interval, greaterThan(0));
        expect(scale.maxY % scale.interval, 0);
        final steps = scale.maxY / scale.interval;
        expect(steps, inInclusiveRange(3, 6));
      }
    });

    test('calculates clean intervals and scales for crores (e.g. ₹1.2Cr - ₹25Cr)', () {
      for (final maxSales in [12000000.0, 50000000.0, 250000000.0]) {
        final scale = ChartScaleUtils.calculateYAxisScale(maxSales);
        expect(scale.maxY, greaterThan(maxSales));
        expect(scale.interval, greaterThan(0));
        expect(scale.maxY % scale.interval, 0);
        final steps = scale.maxY / scale.interval;
        expect(steps, inInclusiveRange(3, 6));
      }
    });

    test('dynamically expands reservedSize when amounts are large to prevent clipping', () {
      final smallScale = ChartScaleUtils.calculateYAxisScale(1000); // ₹1K
      final lakhScale = ChartScaleUtils.calculateYAxisScale(1500000); // ₹15L
      final croreScale = ChartScaleUtils.calculateYAxisScale(150000000); // ₹15Cr

      // Reserved size must not be hardcoded: larger amounts require more width
      expect(lakhScale.reservedSize, greaterThanOrEqualTo(smallScale.reservedSize));
      expect(croreScale.reservedSize, greaterThanOrEqualTo(lakhScale.reservedSize));
      expect(croreScale.reservedSize, greaterThan(42.0));
    });
  });
}
