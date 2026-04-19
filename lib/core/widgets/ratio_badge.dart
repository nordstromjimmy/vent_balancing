import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../features/projects/domain/flow_eval.dart';

class RatioBadge extends StatelessWidget {
  const RatioBadge({super.key, required this.eval});
  final FlowEval eval;

  @override
  Widget build(BuildContext context) {
    final pct = eval.percentOfProjected;
    final text = pct == null ? '—' : '${pct.toStringAsFixed(0)}%';

    final color = switch (eval.status) {
      FlowStatus.unknown => AppColors.unknown,
      FlowStatus.ok => AppColors.ok,
      FlowStatus.warn => AppColors.warn,
      FlowStatus.bad => AppColors.bad,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
