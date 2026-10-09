import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/firestore_service.dart';

const _chartInk = Color(0xFF111827);
const _chartMuted = Color(0xFF758096);
const _chartOrange = Color(0xFFFF922B);

class RevenuePeriodFilter extends StatelessWidget {
  const RevenuePeriodFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RevenuePeriod value;
  final ValueChanged<RevenuePeriod> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<RevenuePeriod>(
    segments: RevenuePeriod.values
        .map(
          (period) => ButtonSegment<RevenuePeriod>(
            value: period,
            label: Text(period.label),
          ),
        )
        .toList(growable: false),
    selected: {value},
    showSelectedIcon: false,
    style: ButtonStyle(
      visualDensity: VisualDensity.compact,
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : _chartInk,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _chartInk
            : Colors.white,
      ),
      side: const WidgetStatePropertyAll(
        BorderSide(color: Color(0xFFE1E6F0)),
      ),
    ),
    onSelectionChanged: (selected) {
      if (selected.isNotEmpty) onChanged(selected.first);
    },
  );
}

class RevenueTrendChart extends StatelessWidget {
  const RevenueTrendChart({super.key, required this.report});

  final RevenueReport report;

  @override
  Widget build(BuildContext context) {
    final maximum = report.trend.fold<int>(
      0,
      (current, point) => current > point.revenue ? current : point.revenue,
    );
    final hasRevenue = maximum > 0;
    final barWidth = report.trend.length > 7 ? 12.0 : 22.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: _chartInk.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: _chartOrange, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Xu hướng ${report.period.label.toLowerCase()}',
                  style: const TextStyle(
                    color: _chartInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${NumberFormat.compact(locale: 'vi_VN').format(report.totalRevenue)} ₫',
                style: const TextStyle(
                  color: _chartInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasRevenue)
            const SizedBox(
              height: 116,
              child: Center(
                child: Text(
                  'Chưa có doanh thu trong kỳ này.',
                  style: TextStyle(color: _chartMuted, fontSize: 11),
                ),
              ),
            )
          else
            SizedBox(
              height: 116,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: report.trend.map((point) {
                  final height = 14 + 66 * point.revenue / maximum;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              width: barWidth,
                              height: height,
                              decoration: BoxDecoration(
                                color: point.revenue == maximum
                                    ? _chartOrange
                                    : const Color(0xFFB9C9E8),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          point.label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            color: _chartMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }
}
