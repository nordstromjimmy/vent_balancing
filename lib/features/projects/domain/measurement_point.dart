import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_point.freezed.dart';
part 'measurement_point.g.dart';

enum AirType { supply, exhaust }

@freezed
@JsonSerializable(explicitToJson: true)
class MeasurementPoint with _$MeasurementPoint {
  const factory MeasurementPoint({
    required String id,
    required String label,
    required AirType airType,
    required double projectedLs,
    double? measuredLs,
    @Default(10.0) double tolerancePct,
    String? notes,

    // New optional fields:
    double? pressurePa, // Tryck (Pa)
    double? kFactor, // K-faktor
    String? setting, // Inställning (often text like "2.5 varv" / "spjäll 35%")
  }) = _MeasurementPoint;

  factory MeasurementPoint.fromJson(Map<String, dynamic> json) =>
      _$MeasurementPointFromJson(json);
}
