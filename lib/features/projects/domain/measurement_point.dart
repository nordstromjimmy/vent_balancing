import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_point.freezed.dart';
part 'measurement_point.g.dart';

enum AirType { supply, exhaust }

@freezed
class MeasurementPoint with _$MeasurementPoint {
  const factory MeasurementPoint({
    required String id,
    required String label,
    required AirType airType,

    // ✅ Projected (base can be null for boost-only points)
    double? projectedBaseLs,
    double? projectedBoostLs,

    // ✅ Measured
    double? measuredBaseLs,
    double? measuredBoostLs,

    @Default(10.0) double tolerancePct,
    String? notes,

    // Optional extra fields
    double? pressurePa,
    double? kFactor,
    String? setting,
  }) = _MeasurementPoint;

  factory MeasurementPoint.fromJson(Map<String, dynamic> json) =>
      _$MeasurementPointFromJson(json);
}
