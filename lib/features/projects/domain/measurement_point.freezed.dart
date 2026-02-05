// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'measurement_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MeasurementPoint _$MeasurementPointFromJson(Map<String, dynamic> json) {
  return _MeasurementPoint.fromJson(json);
}

/// @nodoc
mixin _$MeasurementPoint {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  AirType get airType => throw _privateConstructorUsedError; // Projected
  double get projectedBaseLs => throw _privateConstructorUsedError;
  double? get projectedBoostLs =>
      throw _privateConstructorUsedError; // Measured
  double? get measuredBaseLs => throw _privateConstructorUsedError;
  double? get measuredBoostLs => throw _privateConstructorUsedError;
  double get tolerancePct => throw _privateConstructorUsedError;
  String? get notes =>
      throw _privateConstructorUsedError; // Optional “edit-only” extra fields
  double? get pressurePa => throw _privateConstructorUsedError;
  double? get kFactor => throw _privateConstructorUsedError;
  String? get setting => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MeasurementPointCopyWith<MeasurementPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeasurementPointCopyWith<$Res> {
  factory $MeasurementPointCopyWith(
          MeasurementPoint value, $Res Function(MeasurementPoint) then) =
      _$MeasurementPointCopyWithImpl<$Res, MeasurementPoint>;
  @useResult
  $Res call(
      {String id,
      String label,
      AirType airType,
      double projectedBaseLs,
      double? projectedBoostLs,
      double? measuredBaseLs,
      double? measuredBoostLs,
      double tolerancePct,
      String? notes,
      double? pressurePa,
      double? kFactor,
      String? setting});
}

/// @nodoc
class _$MeasurementPointCopyWithImpl<$Res, $Val extends MeasurementPoint>
    implements $MeasurementPointCopyWith<$Res> {
  _$MeasurementPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? airType = null,
    Object? projectedBaseLs = null,
    Object? projectedBoostLs = freezed,
    Object? measuredBaseLs = freezed,
    Object? measuredBoostLs = freezed,
    Object? tolerancePct = null,
    Object? notes = freezed,
    Object? pressurePa = freezed,
    Object? kFactor = freezed,
    Object? setting = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      airType: null == airType
          ? _value.airType
          : airType // ignore: cast_nullable_to_non_nullable
              as AirType,
      projectedBaseLs: null == projectedBaseLs
          ? _value.projectedBaseLs
          : projectedBaseLs // ignore: cast_nullable_to_non_nullable
              as double,
      projectedBoostLs: freezed == projectedBoostLs
          ? _value.projectedBoostLs
          : projectedBoostLs // ignore: cast_nullable_to_non_nullable
              as double?,
      measuredBaseLs: freezed == measuredBaseLs
          ? _value.measuredBaseLs
          : measuredBaseLs // ignore: cast_nullable_to_non_nullable
              as double?,
      measuredBoostLs: freezed == measuredBoostLs
          ? _value.measuredBoostLs
          : measuredBoostLs // ignore: cast_nullable_to_non_nullable
              as double?,
      tolerancePct: null == tolerancePct
          ? _value.tolerancePct
          : tolerancePct // ignore: cast_nullable_to_non_nullable
              as double,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      pressurePa: freezed == pressurePa
          ? _value.pressurePa
          : pressurePa // ignore: cast_nullable_to_non_nullable
              as double?,
      kFactor: freezed == kFactor
          ? _value.kFactor
          : kFactor // ignore: cast_nullable_to_non_nullable
              as double?,
      setting: freezed == setting
          ? _value.setting
          : setting // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MeasurementPointImplCopyWith<$Res>
    implements $MeasurementPointCopyWith<$Res> {
  factory _$$MeasurementPointImplCopyWith(_$MeasurementPointImpl value,
          $Res Function(_$MeasurementPointImpl) then) =
      __$$MeasurementPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      AirType airType,
      double projectedBaseLs,
      double? projectedBoostLs,
      double? measuredBaseLs,
      double? measuredBoostLs,
      double tolerancePct,
      String? notes,
      double? pressurePa,
      double? kFactor,
      String? setting});
}

/// @nodoc
class __$$MeasurementPointImplCopyWithImpl<$Res>
    extends _$MeasurementPointCopyWithImpl<$Res, _$MeasurementPointImpl>
    implements _$$MeasurementPointImplCopyWith<$Res> {
  __$$MeasurementPointImplCopyWithImpl(_$MeasurementPointImpl _value,
      $Res Function(_$MeasurementPointImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? airType = null,
    Object? projectedBaseLs = null,
    Object? projectedBoostLs = freezed,
    Object? measuredBaseLs = freezed,
    Object? measuredBoostLs = freezed,
    Object? tolerancePct = null,
    Object? notes = freezed,
    Object? pressurePa = freezed,
    Object? kFactor = freezed,
    Object? setting = freezed,
  }) {
    return _then(_$MeasurementPointImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      airType: null == airType
          ? _value.airType
          : airType // ignore: cast_nullable_to_non_nullable
              as AirType,
      projectedBaseLs: null == projectedBaseLs
          ? _value.projectedBaseLs
          : projectedBaseLs // ignore: cast_nullable_to_non_nullable
              as double,
      projectedBoostLs: freezed == projectedBoostLs
          ? _value.projectedBoostLs
          : projectedBoostLs // ignore: cast_nullable_to_non_nullable
              as double?,
      measuredBaseLs: freezed == measuredBaseLs
          ? _value.measuredBaseLs
          : measuredBaseLs // ignore: cast_nullable_to_non_nullable
              as double?,
      measuredBoostLs: freezed == measuredBoostLs
          ? _value.measuredBoostLs
          : measuredBoostLs // ignore: cast_nullable_to_non_nullable
              as double?,
      tolerancePct: null == tolerancePct
          ? _value.tolerancePct
          : tolerancePct // ignore: cast_nullable_to_non_nullable
              as double,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      pressurePa: freezed == pressurePa
          ? _value.pressurePa
          : pressurePa // ignore: cast_nullable_to_non_nullable
              as double?,
      kFactor: freezed == kFactor
          ? _value.kFactor
          : kFactor // ignore: cast_nullable_to_non_nullable
              as double?,
      setting: freezed == setting
          ? _value.setting
          : setting // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MeasurementPointImpl implements _MeasurementPoint {
  const _$MeasurementPointImpl(
      {required this.id,
      required this.label,
      required this.airType,
      required this.projectedBaseLs,
      this.projectedBoostLs,
      this.measuredBaseLs,
      this.measuredBoostLs,
      this.tolerancePct = 10.0,
      this.notes,
      this.pressurePa,
      this.kFactor,
      this.setting});

  factory _$MeasurementPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$MeasurementPointImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final AirType airType;
// Projected
  @override
  final double projectedBaseLs;
  @override
  final double? projectedBoostLs;
// Measured
  @override
  final double? measuredBaseLs;
  @override
  final double? measuredBoostLs;
  @override
  @JsonKey()
  final double tolerancePct;
  @override
  final String? notes;
// Optional “edit-only” extra fields
  @override
  final double? pressurePa;
  @override
  final double? kFactor;
  @override
  final String? setting;

  @override
  String toString() {
    return 'MeasurementPoint(id: $id, label: $label, airType: $airType, projectedBaseLs: $projectedBaseLs, projectedBoostLs: $projectedBoostLs, measuredBaseLs: $measuredBaseLs, measuredBoostLs: $measuredBoostLs, tolerancePct: $tolerancePct, notes: $notes, pressurePa: $pressurePa, kFactor: $kFactor, setting: $setting)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeasurementPointImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.airType, airType) || other.airType == airType) &&
            (identical(other.projectedBaseLs, projectedBaseLs) ||
                other.projectedBaseLs == projectedBaseLs) &&
            (identical(other.projectedBoostLs, projectedBoostLs) ||
                other.projectedBoostLs == projectedBoostLs) &&
            (identical(other.measuredBaseLs, measuredBaseLs) ||
                other.measuredBaseLs == measuredBaseLs) &&
            (identical(other.measuredBoostLs, measuredBoostLs) ||
                other.measuredBoostLs == measuredBoostLs) &&
            (identical(other.tolerancePct, tolerancePct) ||
                other.tolerancePct == tolerancePct) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.pressurePa, pressurePa) ||
                other.pressurePa == pressurePa) &&
            (identical(other.kFactor, kFactor) || other.kFactor == kFactor) &&
            (identical(other.setting, setting) || other.setting == setting));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      label,
      airType,
      projectedBaseLs,
      projectedBoostLs,
      measuredBaseLs,
      measuredBoostLs,
      tolerancePct,
      notes,
      pressurePa,
      kFactor,
      setting);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MeasurementPointImplCopyWith<_$MeasurementPointImpl> get copyWith =>
      __$$MeasurementPointImplCopyWithImpl<_$MeasurementPointImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MeasurementPointImplToJson(
      this,
    );
  }
}

abstract class _MeasurementPoint implements MeasurementPoint {
  const factory _MeasurementPoint(
      {required final String id,
      required final String label,
      required final AirType airType,
      required final double projectedBaseLs,
      final double? projectedBoostLs,
      final double? measuredBaseLs,
      final double? measuredBoostLs,
      final double tolerancePct,
      final String? notes,
      final double? pressurePa,
      final double? kFactor,
      final String? setting}) = _$MeasurementPointImpl;

  factory _MeasurementPoint.fromJson(Map<String, dynamic> json) =
      _$MeasurementPointImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  AirType get airType;
  @override // Projected
  double get projectedBaseLs;
  @override
  double? get projectedBoostLs;
  @override // Measured
  double? get measuredBaseLs;
  @override
  double? get measuredBoostLs;
  @override
  double get tolerancePct;
  @override
  String? get notes;
  @override // Optional “edit-only” extra fields
  double? get pressurePa;
  @override
  double? get kFactor;
  @override
  String? get setting;
  @override
  @JsonKey(ignore: true)
  _$$MeasurementPointImplCopyWith<_$MeasurementPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
