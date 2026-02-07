import '../../domain/measurement_point.dart';

typedef EvalPick = ({double projected, double? measured, bool usedBoost});

EvalPick pickEvalValues(MeasurementPoint pt) {
  final hasBase = (pt.projectedBaseLs != null && pt.projectedBaseLs! > 0);
  final hasBoost = (pt.projectedBoostLs != null && pt.projectedBoostLs! > 0);

  if (hasBase) {
    return (
      projected: pt.projectedBaseLs!,
      measured: pt.measuredBaseLs,
      usedBoost: false,
    );
  }

  if (hasBoost) {
    return (
      projected: pt.projectedBoostLs!,
      measured: pt.measuredBoostLs,
      usedBoost: true,
    );
  }

  return (projected: 0, measured: null, usedBoost: false);
}
