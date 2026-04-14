import 'package:flutter/material.dart';
import '../../../../core/utils/formatting.dart'; // ← shared helpers
import '../../../../core/widgets/ratio_badge.dart';
import '../../domain/measurement_point.dart';
import '../../domain/flow_eval.dart';

typedef OverviewItem = ({MeasurementPoint pt, FlowEval eval, bool usedBoost});

class OverviewList extends StatelessWidget {
  const OverviewList({super.key, required this.items});

  final List<OverviewItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Inget att visa för det här filtret.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final pt = items[i].pt;
        final eval = items[i].eval;
        final usedBoost = items[i].usedBoost;

        final hasBase =
            (pt.projectedBaseLs != null && pt.projectedBaseLs! > 0) ||
            (pt.measuredBaseLs != null);

        final hasBoost =
            (pt.projectedBoostLs != null && pt.projectedBoostLs! > 0) ||
            (pt.measuredBoostLs != null);

        final deviationText = fmtDeviationPct(eval.deviationPct);

        final meta = <String>[];
        if (pt.pressurePa != null) {
          meta.add('Pa ${pt.pressurePa!.toStringAsFixed(0)}');
        }
        if (pt.kFactor != null) meta.add('K ${pt.kFactor!.toStringAsFixed(2)}');
        if (pt.setting != null && pt.setting!.isNotEmpty) {
          meta.add('Inst ${pt.setting!}');
        }
        final metaText = meta.isEmpty ? null : meta.join(' • ');

        return Card(
          child: ListTile(
            isThreeLine: (hasBase && hasBoost) || metaText != null,
            title: Text(
              pt.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBase)
                  Text(
                    'Grund: ${fmtLsRaw(pt.measuredBaseLs)} / ${fmtLsRaw(pt.projectedBaseLs)} l/s'
                    '${usedBoost ? '' : ' • $deviationText'}',
                  ),
                if (hasBoost)
                  Text(
                    'Forc: ${fmtLsRaw(pt.measuredBoostLs)} / ${fmtLsRaw(pt.projectedBoostLs)} l/s'
                    '${usedBoost ? ' • $deviationText' : ''}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                if (!hasBase && !hasBoost)
                  Text(
                    'Inga flöden angivna.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
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
            trailing: RatioBadge(eval: eval),
          ),
        );
      },
    );
  }
}
