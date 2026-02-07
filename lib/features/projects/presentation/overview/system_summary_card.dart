import '../../domain/measurement_point.dart';

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

    final projBase = p.projectedBaseLs;
    if (projBase != null && projBase > 0) {
      if (isSupply) {
        pbs += projBase;
      } else {
        pbe += projBase;
      }
    }

    final projBoost = p.projectedBoostLs;
    if (projBoost != null && projBoost > 0) {
      if (isSupply) {
        pfs += projBoost;
      } else {
        pfe += projBoost;
      }
    }

    final measBase = p.measuredBaseLs;
    if (measBase != null) {
      measuredBaseCount++;
      if (isSupply) {
        mbs += measBase;
      } else {
        mbe += measBase;
      }
    }

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
