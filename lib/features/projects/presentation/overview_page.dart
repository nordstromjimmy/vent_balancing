import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/metric_chip.dart';
import '../../../core/widgets/ratio_badge.dart';
import '../application/projects_controller.dart';
import '../domain/flow_eval.dart';
import '../domain/measurement_point.dart';
import 'project_editor_page.dart';

enum FlowMode { base, boost }

class SystemSummary {
  final double projectedSupply;
  final double projectedExhaust;
  final double measuredSupply;
  final double measuredExhaust;
  final int measuredCount;
  final int totalCount;

  const SystemSummary({
    required this.projectedSupply,
    required this.projectedExhaust,
    required this.measuredSupply,
    required this.measuredExhaust,
    required this.measuredCount,
    required this.totalCount,
  });

  double? _balancePct(double a, double b) {
    if (a <= 0 || b <= 0) return null;
    final ratio = (a < b) ? (a / b) : (b / a);
    return ratio * 100.0;
  }

  /// Balanced between supply and exhaust (DESIGN)
  double? get projectedBalancePct =>
      _balancePct(projectedSupply, projectedExhaust);

  /// Balanced between supply and exhaust (MEASURED)
  double? get measuredBalancePct =>
      _balancePct(measuredSupply, measuredExhaust);

  /// Measured supply as % of projected supply
  double? get supplyOfProjectedPct {
    if (projectedSupply <= 0) return null;
    return (measuredSupply / projectedSupply) * 100.0;
  }

  /// Measured exhaust as % of projected exhaust
  double? get exhaustOfProjectedPct {
    if (projectedExhaust <= 0) return null;
    return (measuredExhaust / projectedExhaust) * 100.0;
  }

  /// Signed difference (supply - exhaust), measured totals
  double get deltaMeasured => measuredSupply - measuredExhaust;
}

SystemSummary buildSystemSummary(List<MeasurementPoint> points) {
  double ps = 0, pe = 0, ms = 0, me = 0;
  int measuredCount = 0;

  for (final p in points) {
    if (p.airType == AirType.supply) {
      ps += p.projectedBaseLs;
      ms += (p.measuredBaseLs ?? 0);
    } else {
      pe += p.projectedBaseLs;
      me += (p.measuredBaseLs ?? 0);
    }
    if (p.measuredBaseLs != null) measuredCount++;
  }

  return SystemSummary(
    projectedSupply: ps,
    projectedExhaust: pe,
    measuredSupply: ms,
    measuredExhaust: me,
    measuredCount: measuredCount,
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

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsControllerProvider);

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (projects) {
        final p = projects.firstWhere((x) => x.id == widget.projectId);

        final items = p.points.map((pt) {
          final eval = FlowEval(
            projected: pt.projectedBaseLs,
            measured: pt.measuredBaseLs,
            tolerancePct: pt.tolerancePct,
          );
          return (pt: pt, eval: eval);
        }).toList();

        final summary = buildSystemSummary(p.points);

        bool include(({MeasurementPoint pt, FlowEval eval}) item) {
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
                    '${summary.measuredCount}/${summary.totalCount} mätta • '
                    'Proj balans: ${summary.projectedBalancePct == null ? '—' : '${summary.projectedBalancePct!.toStringAsFixed(0)}%'} • '
                    'Mätt balans: ${summary.measuredBalancePct == null ? '—' : '${summary.measuredBalancePct!.toStringAsFixed(0)}%'}',
                  ),
                  children: [SystemSummaryCardContent(summary: summary)],
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
                        final pt = filtered[i].pt;
                        final eval = filtered[i].eval;

                        final proj = pt.projectedBaseLs;
                        final meas = pt.measuredBaseLs;

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
                            isThreeLine: metaText != null,
                            title: Text(
                              pt.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Uppmätt ${meas?.toStringAsFixed(1) ?? '—'} / ${proj.toStringAsFixed(1)} l/s • $deviationText',
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
  const SystemSummaryCardContent({super.key, required this.summary});
  final SystemSummary summary;

  @override
  Widget build(BuildContext context) {
    final projBal = summary.projectedBalancePct;
    final measBal = summary.measuredBalancePct;

    final supplyVsProj = summary.supplyOfProjectedPct;
    final exhaustVsProj = summary.exhaustOfProjectedPct;

    String fmtPct(double? v) => v == null ? '—' : '${v.toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MetricChip(label: 'Proj. Balans', value: fmtPct(projBal)),
            MetricChip(label: 'Mätt Balans', value: fmtPct(measBal)),
            MetricChip(label: 'TL av proj', value: fmtPct(supplyVsProj)),
            MetricChip(label: 'FL av proj', value: fmtPct(exhaustVsProj)),
          ],
        ),
        const SizedBox(height: 10),

        // Optional: keep delta chip, it's very useful
        MetricChip(
          label: 'Över/undertryck',
          value:
              '${summary.deltaMeasured >= 0 ? '+' : ''}${summary.deltaMeasured.toStringAsFixed(1)} l/s',
        ),
        const SizedBox(height: 12),
        if (supplyVsProj != null) ...[
          Text(
            'Till (mätt vs proj): ${fmtPct(supplyVsProj)}',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (supplyVsProj / 100.0).clamp(0.0, 1.5),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (exhaustVsProj != null) ...[
          Text(
            'Från (mätt vs proj): ${fmtPct(exhaustVsProj)}',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (exhaustVsProj / 100.0).clamp(0.0, 1.5),
              minHeight: 10,
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}
