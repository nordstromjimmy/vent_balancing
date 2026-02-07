import 'package:flutter/material.dart';
import '../../../../core/widgets/metric_chip.dart';
import '../project_editor/overview_types.dart';

class OverviewHeader extends StatelessWidget {
  const OverviewHeader({
    super.key,
    required this.total,
    required this.okCount,
    required this.warnCount,
    required this.badCount,
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final int total;
  final int okCount;
  final int warnCount;
  final int badCount;

  final OverviewFilter filter;
  final OverviewSort sort;

  final ValueChanged<OverviewFilter> onFilterChanged;
  final ValueChanged<OverviewSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                      child: Text('Alla', overflow: TextOverflow.ellipsis),
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
                    labelText: 'Sortera',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: OverviewSort.worstDeviation,
                      child: Text('Sämst', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: OverviewSort.label,
                      child: Text('Etikett', overflow: TextOverflow.ellipsis),
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
    );
  }
}
