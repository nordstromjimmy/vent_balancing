import 'package:flutter/material.dart';
import '../../features/projects/domain/flow_eval.dart';

class RatioBadge extends StatelessWidget {
  const RatioBadge({super.key, required this.eval});
  final FlowEval eval;

  @override
  Widget build(BuildContext context) {
    final pct = eval.percentOfProjected;
    final text = pct == null ? '—' : '${pct.toStringAsFixed(0)}%';

    final color = switch (eval.status) {
      FlowStatus.unknown => Colors.grey,
      FlowStatus.ok => Colors.green,
      FlowStatus.warn => Colors.orange,
      FlowStatus.bad => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
