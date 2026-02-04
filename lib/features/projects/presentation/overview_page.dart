import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/metric_chip.dart';
import '../../../core/widgets/ratio_badge.dart';
import '../application/projects_controller.dart';
import '../domain/flow_eval.dart';
import '../domain/measurement_point.dart';
import 'project_editor_page.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsControllerProvider);

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (projects) {
        final p = projects.firstWhere((x) => x.id == projectId);

        final items = p.points.map((pt) {
          final eval = FlowEval(
            projected: pt.projectedLs,
            measured: pt.measuredLs,
            tolerancePct: pt.tolerancePct,
          );
          return (pt: pt, eval: eval); // named record
        }).toList();

        bool include(({MeasurementPoint pt, FlowEval eval}) item) {
          final status = item.eval.status;
          return switch (filter) {
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

        if (sort == OverviewSort.label) {
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
                          initialValue: filter,
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
                            if (v != null) onFilterChanged(v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<OverviewSort>(
                          initialValue: sort,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sort',
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
                            if (v != null) onSortChanged(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final pt = filtered[i].pt;
                        final eval = filtered[i].eval;

                        final proj = pt.projectedLs;
                        final meas = pt.measuredLs;

                        final deviation = eval.deviationPct;
                        final deviationText = deviation == null
                            ? '—'
                            : '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(0)}%';

                        return Card(
                          child: ListTile(
                            title: Text(
                              pt.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              'Uppmätt ${meas?.toStringAsFixed(1) ?? '—'} / ${proj.toStringAsFixed(1)} l/s • $deviationText',
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
