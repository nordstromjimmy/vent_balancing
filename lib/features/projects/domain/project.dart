import 'package:freezed_annotation/freezed_annotation.dart';
import 'measurement_point.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
@JsonSerializable(explicitToJson: true)
class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    @Default('') String address,
    @Default([]) List<MeasurementPoint> points,
    @Default(10.0) double defaultTolerancePct,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
