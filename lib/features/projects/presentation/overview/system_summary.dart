import 'package:flutter/material.dart';

import '../../../../core/widgets/metric_chip.dart';
import 'system_summary_card.dart';

class SystemSummaryCard extends StatelessWidget {
  const SystemSummaryCard({
    super.key,
    required this.summary,
    required this.expanded,
    required this.onExpandedChanged,
    required this.mode,
    required this.onModeChanged,
  });

  final SystemSummary summary;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  final SummaryMode mode;
  final ValueChanged<SummaryMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final subtitle = mode == SummaryMode.base
        ? '${summary.measuredBaseCount}/${summary.totalCount} mätta • '
              'Proj balans: ${summary.baseProjectedBalancePct == null ? '—' : '${summary.baseProjectedBalancePct!.toStringAsFixed(0)}%'} • '
              'Mätt balans: ${summary.baseMeasuredBalancePct == null ? '—' : '${summary.baseMeasuredBalancePct!.toStringAsFixed(0)}%'}'
        : '${summary.measuredBoostCount}/${summary.totalCount} mätta • '
              'Proj balans: ${summary.boostProjectedBalancePct == null ? '—' : '${summary.boostProjectedBalancePct!.toStringAsFixed(0)}%'} • '
              'Mätt balans: ${summary.boostMeasuredBalancePct == null ? '—' : '${summary.boostMeasuredBalancePct!.toStringAsFixed(0)}%'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: onExpandedChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: const Text(
            'Systemöversikt',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subtitle),
          children: [
            SegmentedButton<SummaryMode>(
              segments: const [
                ButtonSegment(value: SummaryMode.base, label: Text('Grund')),
                ButtonSegment(
                  value: SummaryMode.boost,
                  label: Text('Forcerat'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) => onModeChanged(s.first),
            ),
            const SizedBox(height: 12),
            SystemSummaryCardContent(summary: summary, mode: mode),
          ],
        ),
      ),
    );
  }
}

class SystemSummaryCardContent extends StatelessWidget {
  const SystemSummaryCardContent({
    super.key,
    required this.summary,
    required this.mode,
  });

  final SystemSummary summary;
  final SummaryMode mode;

  @override
  Widget build(BuildContext context) {
    String fmtPct(double? v) => v == null ? '—' : '${v.toStringAsFixed(0)}%';
    String fmtLs(double v) => '${v.toStringAsFixed(1)} l/s';

    final isBase = mode == SummaryMode.base;

    final projSupply = isBase
        ? summary.projectedBaseSupply
        : summary.projectedBoostSupply;
    final projExhaust = isBase
        ? summary.projectedBaseExhaust
        : summary.projectedBoostExhaust;
    final measSupply = isBase
        ? summary.measuredBaseSupply
        : summary.measuredBoostSupply;
    final measExhaust = isBase
        ? summary.measuredBaseExhaust
        : summary.measuredBoostExhaust;

    final projBal = isBase
        ? summary.baseProjectedBalancePct
        : summary.boostProjectedBalancePct;
    final measBal = isBase
        ? summary.baseMeasuredBalancePct
        : summary.boostMeasuredBalancePct;

    final supplyVsProj = isBase
        ? summary.baseSupplyOfProjectedPct
        : summary.boostSupplyOfProjectedPct;
    final exhaustVsProj = isBase
        ? summary.baseExhaustOfProjectedPct
        : summary.boostExhaustOfProjectedPct;

    final delta = isBase
        ? summary.baseDeltaMeasured
        : summary.boostDeltaMeasured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MetricChip(label: 'Proj TL', value: fmtLs(projSupply)),
            MetricChip(label: 'Proj FL', value: fmtLs(projExhaust)),
            MetricChip(label: 'Mätt TL', value: fmtLs(measSupply)),
            MetricChip(label: 'Mätt FL', value: fmtLs(measExhaust)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MetricChip(label: 'Proj balans', value: fmtPct(projBal)),
            MetricChip(label: 'Mätt balans', value: fmtPct(measBal)),
            MetricChip(label: 'TL av proj', value: fmtPct(supplyVsProj)),
            MetricChip(label: 'FL av proj', value: fmtPct(exhaustVsProj)),
            MetricChip(
              label: 'Δ TL–FL (mätt)',
              value: '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} l/s',
            ),
          ],
        ),
      ],
    );
  }
}
