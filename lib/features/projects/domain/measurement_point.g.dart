// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

const _$AirTypeEnumMap = {AirType.supply: 'supply', AirType.exhaust: 'exhaust'};

_$MeasurementPointImpl _$$MeasurementPointImplFromJson(
  Map<String, dynamic> json,
) => _$MeasurementPointImpl(
  id: json['id'] as String,
  label: json['label'] as String,
  airType: $enumDecode(_$AirTypeEnumMap, json['airType']),
  projectedLs: (json['projectedLs'] as num).toDouble(),
  measuredLs: (json['measuredLs'] as num?)?.toDouble(),
  tolerancePct: (json['tolerancePct'] as num?)?.toDouble() ?? 10.0,
  notes: json['notes'] as String?,
  pressurePa: (json['pressurePa'] as num?)?.toDouble(),
  kFactor: (json['kFactor'] as num?)?.toDouble(),
  setting: json['setting'] as String?,
);

Map<String, dynamic> _$$MeasurementPointImplToJson(
  _$MeasurementPointImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'airType': _$AirTypeEnumMap[instance.airType]!,
  'projectedLs': instance.projectedLs,
  'measuredLs': instance.measuredLs,
  'tolerancePct': instance.tolerancePct,
  'notes': instance.notes,
  'pressurePa': instance.pressurePa,
  'kFactor': instance.kFactor,
  'setting': instance.setting,
};
