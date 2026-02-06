import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/metric_chip.dart';
import '../../../core/widgets/ratio_badge.dart';
import '../application/projects_controller.dart';
import '../domain/flow_eval.dart';
import '../domain/measurement_point.dart';
import 'project_editor_page.dart';

enum FlowMode { base, boost }

enum SummaryMode { base, boost }

class SystemSummary {
  // Base totals
  final double projectedBaseSupply;
  final double projectedBaseExhaust;
  final double measuredBaseSupply;
  final double measuredBaseExhaust;

  // Boost totals
  final double projectedBoostSupply;
  final double projectedBoostExhaust;
  final double measuredBoostSupply;
  final double measuredBoostExhaust;

  final int measuredBaseCount;
  final int measuredBoostCount;
  final int totalCount;

  const SystemSummary({
    required this.projectedBaseSupply,
    required this.projectedBaseExhaust,
    required this.measuredBaseSupply,
    required this.measuredBaseExhaust,
    required this.projectedBoostSupply,
    required this.projectedBoostExhaust,
    required this.measuredBoostSupply,
    required this.measuredBoostExhaust,
    required this.measuredBaseCount,
    required this.measuredBoostCount,
    required this.totalCount,
  });

  double? _balancePct(double a, double b) {
    if (a <= 0 || b <= 0) return null;
    final ratio = (a < b) ? (a / b) : (b / a);
    return ratio * 100.0;
  }

  // Base balance
  double? get baseProjectedBalancePct =>
      _balancePct(projectedBaseSupply, projectedBaseExhaust);
  double? get baseMeasuredBalancePct =>
      _balancePct(measuredBaseSupply, measuredBaseExhaust);

  // Boost balance
  double? get boostProjectedBalancePct =>
      _balancePct(projectedBoostSupply, projectedBoostExhaust);
  double? get boostMeasuredBalancePct =>
      _balancePct(measuredBoostSupply, measuredBoostExhaust);

  // Base measured-vs-projected %
  double? get baseSupplyOfProjectedPct => projectedBaseSupply <= 0
      ? null
      : (measuredBaseSupply / projectedBaseSupply) * 100.0;
  double? get baseExhaustOfProjectedPct => projectedBaseExhaust <= 0
      ? null
      : (measuredBaseExhaust / projectedBaseExhaust) * 100.0;

  // Boost measured-vs-projected %
  double? get boostSupplyOfProjectedPct => projectedBoostSupply <= 0
      ? null
      : (measuredBoostSupply / projectedBoostSupply) * 100.0;
  double? get boostExhaustOfProjectedPct => projectedBoostExhaust <= 0
      ? null
      : (measuredBoostExhaust / projectedBoostExhaust) * 100.0;

  // Delta (supply - exhaust)
  double get baseDeltaMeasured => measuredBaseSupply - measuredBaseExhaust;
  double get boostDeltaMeasured => measuredBoostSupply - measuredBoostExhaust;
}

SystemSummary buildSystemSummary(List<MeasurementPoint> points) {
  double pbs = 0, pbe = 0, mbs = 0, mbe = 0; // base totals
  double pfs = 0, pfe = 0, mfs = 0, mfe = 0; // boost totals

  int measuredBaseCount = 0;
  int measuredBoostCount = 0;

  for (final p in points) {
    final isSupply = p.airType == AirType.supply;

    // ---- Projected base (nullable) ----
    final projBase = p.projectedBaseLs;
    if (projBase != null && projBase > 0) {
      if (isSupply) {
        pbs += projBase;
      } else {
        pbe += projBase;
      }
    }

    // ---- Projected boost (nullable) ----
    final projBoost = p.projectedBoostLs;
    if (projBoost != null && projBoost > 0) {
      if (isSupply) {
        pfs += projBoost;
      } else {
        pfe += projBoost;
      }
    }

    // ---- Measured base (nullable) ----
    final measBase = p.measuredBaseLs;
    if (measBase != null) {
      measuredBaseCount++;
      if (isSupply) {
        mbs += measBase;
      } else {
        mbe += measBase;
      }
    }

    // ---- Measured boost (nullable) ----
    final measBoost = p.measuredBoostLs;
    if (measBoost != null) {
      measuredBoostCount++;
      if (isSupply) {
        mfs += measBoost;
      } else {
        mfe += measBoost;
      }
    }
  }

  return SystemSummary(
    projectedBaseSupply: pbs,
    projectedBaseExhaust: pbe,
    measuredBaseSupply: mbs,
    measuredBaseExhaust: mbe,

    projectedBoostSupply: pfs,
    projectedBoostExhaust: pfe,
    measuredBoostSupply: mfs,
    measuredBoostExhaust: mfe,

    measuredBaseCount: measuredBaseCount,
    measuredBoostCount: measuredBoostCount,
    totalCount: points.length,
  );
}

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({
    super.key,
    required this.projectId,
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final String projectId;
  final OverviewFilter filter;
  final OverviewSort sort;
  final ValueChanged<OverviewFilter> onFilterChanged;
  final ValueChanged<OverviewSort> onSortChanged;

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  bool _summaryExpanded = false;

  SummaryMode _summaryMode = SummaryMode.base;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsControllerProvider);

    ({double projected, double? measured, bool usedBoost}) pickEvalValues(
      MeasurementPoint pt,
    ) {
      final hasBase = (pt.projectedBaseLs != null && pt.projectedBaseLs! > 0);
      final hasBoost =
          (pt.projectedBoostLs != null && pt.projectedBoostLs! > 0);

      // Prefer base if it exists, otherwise fall back to boost
      if (hasBase) {
        return (
          projected: pt.projectedBaseLs!,
          measured: pt.measuredBaseLs,
          usedBoost: false,
        );
      }
      if (hasBoost) {
        return (
          projected: pt.projectedBoostLs!,
          measured: pt.measuredBoostLs,
          usedBoost: true,
        );
      }

      // No projected at all -> eval will be "unknown"
      return (projected: 0, measured: null, usedBoost: false);
    }

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (projects) {
        final p = projects.firstWhere((x) => x.id == widget.projectId);

        final items = p.points.map((pt) {
          final picked = pickEvalValues(pt);

          final eval = FlowEval(
            projected: picked.projected,
            measured: picked.measured,
            tolerancePct: pt.tolerancePct,
          );

          return (pt: pt, eval: eval, usedBoost: picked.usedBoost);
        }).toList();

        final summary = buildSystemSummary(p.points);

        bool include(
          ({MeasurementPoint pt, FlowEval eval, bool usedBoost}) item,
        ) {
          final status = item.eval.status;
          return switch (widget.filter) {
            OverviewFilter.all => true,
            OverviewFilter.needsWork =>
              status == FlowStatus.warn ||
                  status == FlowStatus.bad ||
                  status == FlowStatus.unknown,
            OverviewFilter.badOnly => status == FlowStatus.bad,
          };
        }

        double deviationAbsOrZero(FlowEval e) => (e.deviationPct?.abs() ?? 0);

        final filtered = items.where(include).toList();

        if (widget.sort == OverviewSort.label) {
          filtered.sort(
            (a, b) =>
                a.pt.label.toLowerCase().compareTo(b.pt.label.toLowerCase()),
          );
        } else {
          filtered.sort(
            (a, b) => deviationAbsOrZero(
              b.eval,
            ).compareTo(deviationAbsOrZero(a.eval)),
          );
        }

        final total = p.points.length;
        final okCount = items
            .where((x) => x.eval.status == FlowStatus.ok)
            .length;
        final warnCount = items
            .where((x) => x.eval.status == FlowStatus.warn)
            .length;
        final badCount = items
            .where((x) => x.eval.status == FlowStatus.bad)
            .length;

        return Column(
          children: [
            // Header: chips + filter/sort
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      MetricChip(label: 'Totalt', value: '$total'),
                      MetricChip(label: 'OK', value: '$okCount'),
                      MetricChip(label: 'Varningar', value: '$warnCount'),
                      MetricChip(label: 'Dåliga', value: '$badCount'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<OverviewFilter>(
                          initialValue: widget.filter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Filter',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: OverviewFilter.needsWork,
                              child: Text(
                                'Behöver justeras',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: OverviewFilter.all,
                              child: Text(
                                'Alla',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: OverviewFilter.badOnly,
                              child: Text(
                                'Endast dåliga',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) widget.onFilterChanged(v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<OverviewSort>(
                          initialValue: widget.sort,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sortera',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: OverviewSort.worstDeviation,
                              child: Text(
                                'Sämst',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: OverviewSort.label,
                              child: Text(
                                'Etikett',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) widget.onSortChanged(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Collapsible summary card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                child: ExpansionTile(
                  initiallyExpanded: _summaryExpanded,
                  onExpansionChanged: (v) =>
                      setState(() => _summaryExpanded = v),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  title: const Text(
                    'Systemöversikt',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${summary.measuredBaseCount}/${summary.totalCount} mätta • '
                    'Proj balans: ${summary.baseProjectedBalancePct == null ? '—' : '${summary.baseProjectedBalancePct!.toStringAsFixed(0)}%'} • '
                    'Mätt balans: ${summary.baseMeasuredBalancePct == null ? '—' : '${summary.baseMeasuredBalancePct!.toStringAsFixed(0)}%'}',
                  ),
                  children: [
                    // Toggle between base/boost
                    SegmentedButton<SummaryMode>(
                      segments: const [
                        ButtonSegment(
                          value: SummaryMode.base,
                          label: Text('Grund'),
                        ),
                        ButtonSegment(
                          value: SummaryMode.boost,
                          label: Text('Forcerat'),
                        ),
                      ],
                      selected: {_summaryMode},
                      onSelectionChanged: (s) =>
                          setState(() => _summaryMode = s.first),
                    ),
                    const SizedBox(height: 12),
                    SystemSummaryCardContent(
                      summary: summary,
                      mode: _summaryMode,
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // List takes remaining space
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Inget att visa för det här filtret.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        String fmtLs(double? v) =>
                            v == null ? '—' : v.toStringAsFixed(1);
                        final pt = filtered[i].pt;
                        final eval = filtered[i].eval;

                        final usedBoost = filtered[i].usedBoost;

                        final hasBase =
                            (pt.projectedBaseLs != null &&
                                pt.projectedBaseLs! > 0) ||
                            (pt.measuredBaseLs != null);

                        final hasBoost =
                            (pt.projectedBoostLs != null &&
                                pt.projectedBoostLs! > 0) ||
                            (pt.measuredBoostLs != null);

                        final deviation = eval.deviationPct;
                        final deviationText = deviation == null
                            ? '—'
                            : '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(0)}%';

                        final meta = <String>[];
                        if (pt.pressurePa != null) {
                          meta.add('Pa ${pt.pressurePa!.toStringAsFixed(0)}');
                        }
                        if (pt.kFactor != null) {
                          meta.add('K ${pt.kFactor!.toStringAsFixed(2)}');
                        }
                        if (pt.setting != null && pt.setting!.isNotEmpty) {
                          meta.add('Inst ${pt.setting!}');
                        }

                        final metaText = meta.isEmpty ? null : meta.join(' • ');

                        return Card(
                          child: ListTile(
                            isThreeLine:
                                (hasBase && hasBoost) || metaText != null,
                            title: Text(
                              pt.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasBase)
                                  Text(
                                    'Grund: ${fmtLs(pt.measuredBaseLs)} / ${fmtLs(pt.projectedBaseLs)} l/s'
                                    '${usedBoost ? '' : ' • $deviationText'}',
                                  ),
                                if (hasBoost)
                                  Text(
                                    'Forc: ${fmtLs(pt.measuredBoostLs)} / ${fmtLs(pt.projectedBoostLs)} l/s'
                                    '${usedBoost ? ' • $deviationText' : ''}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                if (!hasBase && !hasBoost)
                                  Text(
                                    'Inga flöden angivna.',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                if (metaText != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    metaText,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            trailing: RatioBadge(eval: eval),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
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
            MetricChip(label: 'Proj Tilluft', value: fmtLs(projSupply)),
            MetricChip(label: 'Proj Frånluft', value: fmtLs(projExhaust)),
            MetricChip(label: 'Mätt Tilluft', value: fmtLs(measSupply)),
            MetricChip(label: 'Mätt Frånluft', value: fmtLs(measExhaust)),
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
