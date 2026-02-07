import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/projects_controller.dart';
import '../../domain/flow_eval.dart';
import '../../domain/measurement_point.dart';
import '../project_editor/overview_types.dart';
import 'flow_eval_picker.dart';
import 'overview_header.dart';
import 'overview_list.dart';
import 'system_summary.dart';
import 'system_summary_card.dart';

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
            OverviewHeader(
              total: total,
              okCount: okCount,
              warnCount: warnCount,
              badCount: badCount,
              filter: widget.filter,
              sort: widget.sort,
              onFilterChanged: widget.onFilterChanged,
              onSortChanged: widget.onSortChanged,
            ),

            SystemSummaryCard(
              summary: summary,
              expanded: _summaryExpanded,
              onExpandedChanged: (v) => setState(() => _summaryExpanded = v),
              mode: _summaryMode,
              onModeChanged: (m) =>
                  setState(() => _summaryMode = m as SummaryMode),
            ),

            const Divider(height: 1),

            Expanded(child: OverviewList(items: filtered)),
          ],
        );
      },
    );
  }
}
