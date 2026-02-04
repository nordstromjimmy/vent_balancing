enum FlowStatus { unknown, ok, warn, bad }

class FlowEval {
  final double? projected; // l/s
  final double? measured; // l/s
  final double tolerancePct; // ex 10 = ±10%

  const FlowEval({
    required this.projected,
    required this.measured,
    required this.tolerancePct,
  });

  double? get ratio {
    if (projected == null || measured == null) return null;
    if (projected == 0) return null;
    return measured! / projected!;
  }

  double? get percentOfProjected => ratio == null ? null : ratio! * 100;

  double? get deviationPct {
    if (projected == null || measured == null) return null;
    if (projected == 0) return null;
    return ((measured! - projected!) / projected!) * 100;
  }

  FlowStatus get status {
    if (projected == null || measured == null) return FlowStatus.unknown;
    final d = deviationPct;
    if (d == null) return FlowStatus.unknown;
    final abs = d.abs();
    if (abs <= tolerancePct) return FlowStatus.ok;
    if (abs <= tolerancePct * 2) return FlowStatus.warn;
    return FlowStatus.bad;
  }
}
