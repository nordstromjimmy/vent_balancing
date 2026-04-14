import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/dialogs.dart';
import '../../../../core/widgets/metric_chip.dart';
import '../../../../core/widgets/ratio_badge.dart';
import '../../application/projects_controller.dart';
import '../../domain/flow_eval.dart';
import '../../domain/measurement_point.dart';
import '../edit_measurement_point_dialog.dart';
import 'measured_inputs.dart';

class MeasureTab extends ConsumerWidget {
  const MeasureTab({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsControllerProvider);
    String fmtLs(double? v) => v == null ? '—' : '${v.toStringAsFixed(0)} l/s';

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (projects) {
        final p = projects.firstWhere((x) => x.id == projectId);

        if (p.points.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Inga flöden ännu.\nTryck på "Nytt flöde" för att börja.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: p.points.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final pt = p.points[i];

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

            final hasBase = pt.projectedBaseLs != null;
            final hasBoost = pt.projectedBoostLs != null;

            // Build one eval per active mode — shown as separate badges.
            final baseEval = hasBase
                ? FlowEval(
                    projected: pt.projectedBaseLs!,
                    measured: pt.measuredBaseLs,
                    tolerancePct: pt.tolerancePct,
                  )
                : null;

            final boostEval = hasBoost
                ? FlowEval(
                    projected: pt.projectedBoostLs!,
                    measured: pt.measuredBoostLs,
                    tolerancePct: pt.tolerancePct,
                  )
                : null;

            return Dismissible(
              key: ValueKey(pt.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.red.withValues(alpha: 0.15),
                child: const Icon(Icons.delete_outline),
              ),
              confirmDismiss: (_) async {
                return await showConfirmDialog(
                  context: context,
                  title: 'Radera mätningar?',
                  message: '"${pt.label}" kommer tas bort.',
                  confirmText: 'Radera',
                );
              },
              onDismissed: (_) async {
                await ref
                    .read(projectsControllerProvider.notifier)
                    .deletePoint(projectId, pt.id);
              },
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final updated = await showDialog<MeasurementPoint>(
                    context: context,
                    builder: (_) => EditMeasurementPointDialog(point: pt),
                  );
                  if (updated != null) {
                    await ref
                        .read(projectsControllerProvider.notifier)
                        .updatePoint(projectId, updated);
                  }
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pt.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // One badge per active mode; labelled when both present.
                            _EvalBadges(
                              baseEval: baseEval,
                              boostEval: boostEval,
                            ),
                            const SizedBox(width: 10),

                            Text(
                              pt.airType == AirType.supply
                                  ? 'Tilluft'
                                  : 'Frånluft',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            MetricChip(
                              label: 'Grund proj',
                              value: fmtLs(pt.projectedBaseLs),
                            ),
                            MetricChip(
                              label: 'Grund mätt',
                              value: fmtLs(pt.measuredBaseLs),
                            ),
                            if (pt.projectedBoostLs != null ||
                                pt.measuredBoostLs != null) ...[
                              MetricChip(
                                label: 'Forc proj',
                                value: fmtLs(pt.projectedBoostLs),
                              ),
                              MetricChip(
                                label: 'Forc mätt',
                                value: fmtLs(pt.measuredBoostLs),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        MeasuredInputs(
                          hasBase: hasBase,
                          hasBoost: hasBoost,
                          baseInitialValue: pt.measuredBaseLs,
                          boostInitialValue: pt.measuredBoostLs,
                          onBaseChanged: (val) {
                            ref
                                .read(projectsControllerProvider.notifier)
                                .updateMeasuredBase(projectId, pt.id, val);
                          },
                          onBoostChanged: (val) {
                            ref
                                .read(projectsControllerProvider.notifier)
                                .updateMeasuredBoost(projectId, pt.id, val);
                          },
                        ),
                        if (metaText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            metaText,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Renders one or two [RatioBadge] widgets depending on which flow modes exist.
/// When both are present, each badge is labelled "G" (grund) or "F" (forc)
/// so the technician can tell them apart at a glance.
class _EvalBadges extends StatelessWidget {
  const _EvalBadges({required this.baseEval, required this.boostEval});

  final FlowEval? baseEval;
  final FlowEval? boostEval;

  @override
  Widget build(BuildContext context) {
    final both = baseEval != null && boostEval != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (baseEval != null) ...[
          if (both)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'G',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          RatioBadge(eval: baseEval!),
        ],
        if (both) const SizedBox(width: 6),
        if (boostEval != null) ...[
          if (both)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'F',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          RatioBadge(eval: boostEval!),
        ],
      ],
    );
  }
}
