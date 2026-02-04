// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) =>
    _$ProjectImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      points:
          (json['points'] as List<dynamic>?)
              ?.map((e) => MeasurementPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      defaultTolerancePct:
          (json['defaultTolerancePct'] as num?)?.toDouble() ?? 10.0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'points': instance.points,
      'defaultTolerancePct': instance.defaultTolerancePct,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
