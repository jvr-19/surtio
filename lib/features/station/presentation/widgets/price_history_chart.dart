import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/fuel_price_history_point.dart';

class PriceHistoryChart extends StatefulWidget {
  const PriceHistoryChart({super.key, required this.points});

  final List<FuelPriceHistoryPoint> points;

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(PriceHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _selectedIndex = null;
    }
  }

  void _selectNearest(double dx, double width) {
    if (widget.points.isEmpty || width <= 0) {
      return;
    }
    final geometry = _ChartGeometry(widget.points, Size(width, 132));
    var nearest = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < geometry.positions.length; index++) {
      final distance = (geometry.positions[index].dx - dx).abs();
      if (distance < nearestDistance) {
        nearest = index;
        nearestDistance = distance;
      }
    }
    if (_selectedIndex != nearest) {
      setState(() => _selectedIndex = nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 132,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _selectNearest(
                  details.localPosition.dx,
                  constraints.maxWidth,
                ),
                onHorizontalDragStart: (details) => _selectNearest(
                  details.localPosition.dx,
                  constraints.maxWidth,
                ),
                onHorizontalDragUpdate: (details) => _selectNearest(
                  details.localPosition.dx,
                  constraints.maxWidth,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PriceChartPainter(
                          points: widget.points,
                          selectedIndex: _selectedIndex,
                        ),
                      ),
                    ),
                    if (_selectedIndex case final index?)
                      Positioned(
                        top: 0,
                        left: 8,
                        child: _SelectedPointLabel(point: widget.points[index]),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _ChartDateLabels(points: widget.points),
      ],
    );
  }
}

class _SelectedPointLabel extends StatelessWidget {
  const _SelectedPointLabel({required this.point});

  final FuelPriceHistoryPoint point;

  @override
  Widget build(BuildContext context) {
    final date = point.date;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF163743),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          '${point.price.toStringAsFixed(3).replaceAll('.', ',')} €/L  ·  '
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ChartDateLabels extends StatelessWidget {
  const _ChartDateLabels({required this.points});

  final List<FuelPriceHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final middle = points[points.length ~/ 2];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _DateLabel(date: points.first.date),
        _DateLabel(date: middle.date),
        _DateLabel(date: points.last.date),
      ],
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${date.day}/${date.month}',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  const _PriceChartPainter({required this.points, required this.selectedIndex});

  final List<FuelPriceHistoryPoint> points;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final geometry = _ChartGeometry(points, size);
    final positions = geometry.positions;
    _drawGrid(canvas, size);

    final linePath = Path()..moveTo(positions.first.dx, positions.first.dy);
    for (var index = 1; index < positions.length; index++) {
      linePath.lineTo(positions[index].dx, positions[index].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(positions.last.dx, size.height)
      ..lineTo(positions.first.dx, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x3327E0A3), Color(0x0027E0A3)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    final pointPaint = Paint()..color = AppColors.primary;
    final borderPaint = Paint()..color = AppColors.surface;
    for (final position in positions) {
      canvas.drawCircle(position, 4.5, borderPaint);
      canvas.drawCircle(position, 2.5, pointPaint);
    }

    if (selectedIndex case final index?) {
      final selected = positions[index];
      canvas.drawLine(
        Offset(selected.dx, 0),
        Offset(selected.dx, size.height),
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(selected, 7, borderPaint);
      canvas.drawCircle(selected, 4.5, pointPaint);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var index = 1; index <= 3; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.selectedIndex != selectedIndex;
}

class _ChartGeometry {
  _ChartGeometry(this.points, this.size) : positions = _positions(points, size);

  final List<FuelPriceHistoryPoint> points;
  final Size size;
  final List<Offset> positions;

  static List<Offset> _positions(
    List<FuelPriceHistoryPoint> points,
    Size size,
  ) {
    final prices = points.map((point) => point.price).toList();
    var minPrice = prices.reduce(math.min);
    var maxPrice = prices.reduce(math.max);
    if ((maxPrice - minPrice).abs() < 0.001) {
      minPrice -= 0.01;
      maxPrice += 0.01;
    } else {
      final padding = (maxPrice - minPrice) * 0.18;
      minPrice -= padding;
      maxPrice += padding;
    }

    const horizontalPadding = 3.0;
    final chartWidth = size.width - horizontalPadding * 2;
    final firstDate = points.first.date;
    final totalDays = math.max(
      1,
      points.last.date.difference(firstDate).inDays,
    );
    return points.map((point) {
      final elapsedDays = point.date.difference(firstDate).inDays;
      final x = horizontalPadding + chartWidth * elapsedDays / totalDays;
      final normalized = (point.price - minPrice) / (maxPrice - minPrice);
      return Offset(x, size.height - normalized * size.height);
    }).toList();
  }
}
