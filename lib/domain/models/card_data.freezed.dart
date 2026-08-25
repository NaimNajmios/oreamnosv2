// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatItem {

 String get label; String get value; String get context;
/// Create a copy of StatItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatItemCopyWith<StatItem> get copyWith => _$StatItemCopyWithImpl<StatItem>(this as StatItem, _$identity);

  /// Serializes this StatItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatItem&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.context, context) || other.context == context));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value,context);

@override
String toString() {
  return 'StatItem(label: $label, value: $value, context: $context)';
}


}

/// @nodoc
abstract mixin class $StatItemCopyWith<$Res>  {
  factory $StatItemCopyWith(StatItem value, $Res Function(StatItem) _then) = _$StatItemCopyWithImpl;
@useResult
$Res call({
 String label, String value, String context
});




}
/// @nodoc
class _$StatItemCopyWithImpl<$Res>
    implements $StatItemCopyWith<$Res> {
  _$StatItemCopyWithImpl(this._self, this._then);

  final StatItem _self;
  final $Res Function(StatItem) _then;

/// Create a copy of StatItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,Object? context = null,}) {
  return _then(StatItem(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StatItem].
extension StatItemPatterns on StatItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatItem value)  $default,){
final _that = this;
switch (_that) {
case _StatItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatItem value)?  $default,){
final _that = this;
switch (_that) {
case _StatItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String value,  String context)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatItem() when $default != null:
return $default(_that.label,_that.value,_that.context);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String value,  String context)  $default,) {final _that = this;
switch (_that) {
case _StatItem():
return $default(_that.label,_that.value,_that.context);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String value,  String context)?  $default,) {final _that = this;
switch (_that) {
case _StatItem() when $default != null:
return $default(_that.label,_that.value,_that.context);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatItem implements StatItem {
  const _StatItem({required this.label, required this.value, this.context = 'N/A'});
  factory _StatItem.fromJson(Map<String, dynamic> json) => _$StatItemFromJson(json);

@override final  String label;
@override final  String value;
@override@JsonKey() final  String context;

/// Create a copy of StatItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatItemCopyWith<_StatItem> get copyWith => __$StatItemCopyWithImpl<_StatItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatItem&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.context, context) || other.context == context));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value,context);

@override
String toString() {
  return 'StatItem(label: $label, value: $value, context: $context)';
}


}

/// @nodoc
abstract mixin class _$StatItemCopyWith<$Res> implements $StatItemCopyWith<$Res> {
  factory _$StatItemCopyWith(_StatItem value, $Res Function(_StatItem) _then) = __$StatItemCopyWithImpl;
@override @useResult
$Res call({
 String label, String value, String context
});




}
/// @nodoc
class __$StatItemCopyWithImpl<$Res>
    implements _$StatItemCopyWith<$Res> {
  __$StatItemCopyWithImpl(this._self, this._then);

  final _StatItem _self;
  final $Res Function(_StatItem) _then;

/// Create a copy of StatItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,Object? context = null,}) {
  return _then(_StatItem(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ComparisonStat {

 String get label; String get homeValue; String get awayValue;
/// Create a copy of ComparisonStat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComparisonStatCopyWith<ComparisonStat> get copyWith => _$ComparisonStatCopyWithImpl<ComparisonStat>(this as ComparisonStat, _$identity);

  /// Serializes this ComparisonStat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComparisonStat&&(identical(other.label, label) || other.label == label)&&(identical(other.homeValue, homeValue) || other.homeValue == homeValue)&&(identical(other.awayValue, awayValue) || other.awayValue == awayValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,homeValue,awayValue);

@override
String toString() {
  return 'ComparisonStat(label: $label, homeValue: $homeValue, awayValue: $awayValue)';
}


}

/// @nodoc
abstract mixin class $ComparisonStatCopyWith<$Res>  {
  factory $ComparisonStatCopyWith(ComparisonStat value, $Res Function(ComparisonStat) _then) = _$ComparisonStatCopyWithImpl;
@useResult
$Res call({
 String label, String homeValue, String awayValue
});




}
/// @nodoc
class _$ComparisonStatCopyWithImpl<$Res>
    implements $ComparisonStatCopyWith<$Res> {
  _$ComparisonStatCopyWithImpl(this._self, this._then);

  final ComparisonStat _self;
  final $Res Function(ComparisonStat) _then;

/// Create a copy of ComparisonStat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? homeValue = null,Object? awayValue = null,}) {
  return _then(ComparisonStat(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,homeValue: null == homeValue ? _self.homeValue : homeValue // ignore: cast_nullable_to_non_nullable
as String,awayValue: null == awayValue ? _self.awayValue : awayValue // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ComparisonStat].
extension ComparisonStatPatterns on ComparisonStat {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComparisonStat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComparisonStat() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComparisonStat value)  $default,){
final _that = this;
switch (_that) {
case _ComparisonStat():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComparisonStat value)?  $default,){
final _that = this;
switch (_that) {
case _ComparisonStat() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String homeValue,  String awayValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComparisonStat() when $default != null:
return $default(_that.label,_that.homeValue,_that.awayValue);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String homeValue,  String awayValue)  $default,) {final _that = this;
switch (_that) {
case _ComparisonStat():
return $default(_that.label,_that.homeValue,_that.awayValue);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String homeValue,  String awayValue)?  $default,) {final _that = this;
switch (_that) {
case _ComparisonStat() when $default != null:
return $default(_that.label,_that.homeValue,_that.awayValue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComparisonStat implements ComparisonStat {
  const _ComparisonStat({required this.label, required this.homeValue, required this.awayValue});
  factory _ComparisonStat.fromJson(Map<String, dynamic> json) => _$ComparisonStatFromJson(json);

@override final  String label;
@override final  String homeValue;
@override final  String awayValue;

/// Create a copy of ComparisonStat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComparisonStatCopyWith<_ComparisonStat> get copyWith => __$ComparisonStatCopyWithImpl<_ComparisonStat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComparisonStatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComparisonStat&&(identical(other.label, label) || other.label == label)&&(identical(other.homeValue, homeValue) || other.homeValue == homeValue)&&(identical(other.awayValue, awayValue) || other.awayValue == awayValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,homeValue,awayValue);

@override
String toString() {
  return 'ComparisonStat(label: $label, homeValue: $homeValue, awayValue: $awayValue)';
}


}

/// @nodoc
abstract mixin class _$ComparisonStatCopyWith<$Res> implements $ComparisonStatCopyWith<$Res> {
  factory _$ComparisonStatCopyWith(_ComparisonStat value, $Res Function(_ComparisonStat) _then) = __$ComparisonStatCopyWithImpl;
@override @useResult
$Res call({
 String label, String homeValue, String awayValue
});




}
/// @nodoc
class __$ComparisonStatCopyWithImpl<$Res>
    implements _$ComparisonStatCopyWith<$Res> {
  __$ComparisonStatCopyWithImpl(this._self, this._then);

  final _ComparisonStat _self;
  final $Res Function(_ComparisonStat) _then;

/// Create a copy of ComparisonStat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? homeValue = null,Object? awayValue = null,}) {
  return _then(_ComparisonStat(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,homeValue: null == homeValue ? _self.homeValue : homeValue // ignore: cast_nullable_to_non_nullable
as String,awayValue: null == awayValue ? _self.awayValue : awayValue // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LineupPlayer {

 String get number; String get name;
/// Create a copy of LineupPlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineupPlayerCopyWith<LineupPlayer> get copyWith => _$LineupPlayerCopyWithImpl<LineupPlayer>(this as LineupPlayer, _$identity);

  /// Serializes this LineupPlayer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineupPlayer&&(identical(other.number, number) || other.number == number)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,name);

@override
String toString() {
  return 'LineupPlayer(number: $number, name: $name)';
}


}

/// @nodoc
abstract mixin class $LineupPlayerCopyWith<$Res>  {
  factory $LineupPlayerCopyWith(LineupPlayer value, $Res Function(LineupPlayer) _then) = _$LineupPlayerCopyWithImpl;
@useResult
$Res call({
 String number, String name
});




}
/// @nodoc
class _$LineupPlayerCopyWithImpl<$Res>
    implements $LineupPlayerCopyWith<$Res> {
  _$LineupPlayerCopyWithImpl(this._self, this._then);

  final LineupPlayer _self;
  final $Res Function(LineupPlayer) _then;

/// Create a copy of LineupPlayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? name = null,}) {
  return _then(LineupPlayer(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LineupPlayer].
extension LineupPlayerPatterns on LineupPlayer {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LineupPlayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LineupPlayer() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LineupPlayer value)  $default,){
final _that = this;
switch (_that) {
case _LineupPlayer():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LineupPlayer value)?  $default,){
final _that = this;
switch (_that) {
case _LineupPlayer() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String number,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LineupPlayer() when $default != null:
return $default(_that.number,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String number,  String name)  $default,) {final _that = this;
switch (_that) {
case _LineupPlayer():
return $default(_that.number,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String number,  String name)?  $default,) {final _that = this;
switch (_that) {
case _LineupPlayer() when $default != null:
return $default(_that.number,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LineupPlayer implements LineupPlayer {
  const _LineupPlayer({required this.number, required this.name});
  factory _LineupPlayer.fromJson(Map<String, dynamic> json) => _$LineupPlayerFromJson(json);

@override final  String number;
@override final  String name;

/// Create a copy of LineupPlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LineupPlayerCopyWith<_LineupPlayer> get copyWith => __$LineupPlayerCopyWithImpl<_LineupPlayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LineupPlayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LineupPlayer&&(identical(other.number, number) || other.number == number)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,name);

@override
String toString() {
  return 'LineupPlayer(number: $number, name: $name)';
}


}

/// @nodoc
abstract mixin class _$LineupPlayerCopyWith<$Res> implements $LineupPlayerCopyWith<$Res> {
  factory _$LineupPlayerCopyWith(_LineupPlayer value, $Res Function(_LineupPlayer) _then) = __$LineupPlayerCopyWithImpl;
@override @useResult
$Res call({
 String number, String name
});




}
/// @nodoc
class __$LineupPlayerCopyWithImpl<$Res>
    implements _$LineupPlayerCopyWith<$Res> {
  __$LineupPlayerCopyWithImpl(this._self, this._then);

  final _LineupPlayer _self;
  final $Res Function(_LineupPlayer) _then;

/// Create a copy of LineupPlayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? name = null,}) {
  return _then(_LineupPlayer(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TableRow {

 int get position; String get teamName; int get played; int get won; int get drawn; int get lost; int get points; String get form;
/// Create a copy of TableRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableRowCopyWith<TableRow> get copyWith => _$TableRowCopyWithImpl<TableRow>(this as TableRow, _$identity);

  /// Serializes this TableRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TableRow&&(identical(other.position, position) || other.position == position)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.played, played) || other.played == played)&&(identical(other.won, won) || other.won == won)&&(identical(other.drawn, drawn) || other.drawn == drawn)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.points, points) || other.points == points)&&(identical(other.form, form) || other.form == form));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,teamName,played,won,drawn,lost,points,form);

@override
String toString() {
  return 'TableRow(position: $position, teamName: $teamName, played: $played, won: $won, drawn: $drawn, lost: $lost, points: $points, form: $form)';
}


}

/// @nodoc
abstract mixin class $TableRowCopyWith<$Res>  {
  factory $TableRowCopyWith(TableRow value, $Res Function(TableRow) _then) = _$TableRowCopyWithImpl;
@useResult
$Res call({
 int position, String teamName, int played, int won, int drawn, int lost, int points, String form
});




}
/// @nodoc
class _$TableRowCopyWithImpl<$Res>
    implements $TableRowCopyWith<$Res> {
  _$TableRowCopyWithImpl(this._self, this._then);

  final TableRow _self;
  final $Res Function(TableRow) _then;

/// Create a copy of TableRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? teamName = null,Object? played = null,Object? won = null,Object? drawn = null,Object? lost = null,Object? points = null,Object? form = null,}) {
  return _then(TableRow(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as int,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as int,drawn: null == drawn ? _self.drawn : drawn // ignore: cast_nullable_to_non_nullable
as int,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TableRow].
extension TableRowPatterns on TableRow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TableRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TableRow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TableRow value)  $default,){
final _that = this;
switch (_that) {
case _TableRow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TableRow value)?  $default,){
final _that = this;
switch (_that) {
case _TableRow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int position,  String teamName,  int played,  int won,  int drawn,  int lost,  int points,  String form)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TableRow() when $default != null:
return $default(_that.position,_that.teamName,_that.played,_that.won,_that.drawn,_that.lost,_that.points,_that.form);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int position,  String teamName,  int played,  int won,  int drawn,  int lost,  int points,  String form)  $default,) {final _that = this;
switch (_that) {
case _TableRow():
return $default(_that.position,_that.teamName,_that.played,_that.won,_that.drawn,_that.lost,_that.points,_that.form);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int position,  String teamName,  int played,  int won,  int drawn,  int lost,  int points,  String form)?  $default,) {final _that = this;
switch (_that) {
case _TableRow() when $default != null:
return $default(_that.position,_that.teamName,_that.played,_that.won,_that.drawn,_that.lost,_that.points,_that.form);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TableRow implements TableRow {
  const _TableRow({required this.position, required this.teamName, required this.played, required this.won, required this.drawn, required this.lost, required this.points, this.form = 'N/A'});
  factory _TableRow.fromJson(Map<String, dynamic> json) => _$TableRowFromJson(json);

@override final  int position;
@override final  String teamName;
@override final  int played;
@override final  int won;
@override final  int drawn;
@override final  int lost;
@override final  int points;
@override@JsonKey() final  String form;

/// Create a copy of TableRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TableRowCopyWith<_TableRow> get copyWith => __$TableRowCopyWithImpl<_TableRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TableRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TableRow&&(identical(other.position, position) || other.position == position)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.played, played) || other.played == played)&&(identical(other.won, won) || other.won == won)&&(identical(other.drawn, drawn) || other.drawn == drawn)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.points, points) || other.points == points)&&(identical(other.form, form) || other.form == form));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,teamName,played,won,drawn,lost,points,form);

@override
String toString() {
  return 'TableRow(position: $position, teamName: $teamName, played: $played, won: $won, drawn: $drawn, lost: $lost, points: $points, form: $form)';
}


}

/// @nodoc
abstract mixin class _$TableRowCopyWith<$Res> implements $TableRowCopyWith<$Res> {
  factory _$TableRowCopyWith(_TableRow value, $Res Function(_TableRow) _then) = __$TableRowCopyWithImpl;
@override @useResult
$Res call({
 int position, String teamName, int played, int won, int drawn, int lost, int points, String form
});




}
/// @nodoc
class __$TableRowCopyWithImpl<$Res>
    implements _$TableRowCopyWith<$Res> {
  __$TableRowCopyWithImpl(this._self, this._then);

  final _TableRow _self;
  final $Res Function(_TableRow) _then;

/// Create a copy of TableRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? teamName = null,Object? played = null,Object? won = null,Object? drawn = null,Object? lost = null,Object? points = null,Object? form = null,}) {
  return _then(_TableRow(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as int,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as int,drawn: null == drawn ? _self.drawn : drawn // ignore: cast_nullable_to_non_nullable
as int,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InjuryItem {

 String get playerName; String get injury; String get status; String get position; String get recoveryPercentage; bool get isLongTerm; bool get surgeryRequired;
/// Create a copy of InjuryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InjuryItemCopyWith<InjuryItem> get copyWith => _$InjuryItemCopyWithImpl<InjuryItem>(this as InjuryItem, _$identity);

  /// Serializes this InjuryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InjuryItem&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.injury, injury) || other.injury == injury)&&(identical(other.status, status) || other.status == status)&&(identical(other.position, position) || other.position == position)&&(identical(other.recoveryPercentage, recoveryPercentage) || other.recoveryPercentage == recoveryPercentage)&&(identical(other.isLongTerm, isLongTerm) || other.isLongTerm == isLongTerm)&&(identical(other.surgeryRequired, surgeryRequired) || other.surgeryRequired == surgeryRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerName,injury,status,position,recoveryPercentage,isLongTerm,surgeryRequired);

@override
String toString() {
  return 'InjuryItem(playerName: $playerName, injury: $injury, status: $status, position: $position, recoveryPercentage: $recoveryPercentage, isLongTerm: $isLongTerm, surgeryRequired: $surgeryRequired)';
}


}

/// @nodoc
abstract mixin class $InjuryItemCopyWith<$Res>  {
  factory $InjuryItemCopyWith(InjuryItem value, $Res Function(InjuryItem) _then) = _$InjuryItemCopyWithImpl;
@useResult
$Res call({
 String playerName, String injury, String status, String position, String recoveryPercentage, bool isLongTerm, bool surgeryRequired
});




}
/// @nodoc
class _$InjuryItemCopyWithImpl<$Res>
    implements $InjuryItemCopyWith<$Res> {
  _$InjuryItemCopyWithImpl(this._self, this._then);

  final InjuryItem _self;
  final $Res Function(InjuryItem) _then;

/// Create a copy of InjuryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerName = null,Object? injury = null,Object? status = null,Object? position = null,Object? recoveryPercentage = null,Object? isLongTerm = null,Object? surgeryRequired = null,}) {
  return _then(InjuryItem(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,injury: null == injury ? _self.injury : injury // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String,recoveryPercentage: null == recoveryPercentage ? _self.recoveryPercentage : recoveryPercentage // ignore: cast_nullable_to_non_nullable
as String,isLongTerm: null == isLongTerm ? _self.isLongTerm : isLongTerm // ignore: cast_nullable_to_non_nullable
as bool,surgeryRequired: null == surgeryRequired ? _self.surgeryRequired : surgeryRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InjuryItem].
extension InjuryItemPatterns on InjuryItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InjuryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InjuryItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InjuryItem value)  $default,){
final _that = this;
switch (_that) {
case _InjuryItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InjuryItem value)?  $default,){
final _that = this;
switch (_that) {
case _InjuryItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerName,  String injury,  String status,  String position,  String recoveryPercentage,  bool isLongTerm,  bool surgeryRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InjuryItem() when $default != null:
return $default(_that.playerName,_that.injury,_that.status,_that.position,_that.recoveryPercentage,_that.isLongTerm,_that.surgeryRequired);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerName,  String injury,  String status,  String position,  String recoveryPercentage,  bool isLongTerm,  bool surgeryRequired)  $default,) {final _that = this;
switch (_that) {
case _InjuryItem():
return $default(_that.playerName,_that.injury,_that.status,_that.position,_that.recoveryPercentage,_that.isLongTerm,_that.surgeryRequired);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerName,  String injury,  String status,  String position,  String recoveryPercentage,  bool isLongTerm,  bool surgeryRequired)?  $default,) {final _that = this;
switch (_that) {
case _InjuryItem() when $default != null:
return $default(_that.playerName,_that.injury,_that.status,_that.position,_that.recoveryPercentage,_that.isLongTerm,_that.surgeryRequired);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InjuryItem implements InjuryItem {
  const _InjuryItem({required this.playerName, required this.injury, required this.status, this.position = 'N/A', this.recoveryPercentage = 'N/A', this.isLongTerm = false, this.surgeryRequired = false});
  factory _InjuryItem.fromJson(Map<String, dynamic> json) => _$InjuryItemFromJson(json);

@override final  String playerName;
@override final  String injury;
@override final  String status;
@override@JsonKey() final  String position;
@override@JsonKey() final  String recoveryPercentage;
@override@JsonKey() final  bool isLongTerm;
@override@JsonKey() final  bool surgeryRequired;

/// Create a copy of InjuryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InjuryItemCopyWith<_InjuryItem> get copyWith => __$InjuryItemCopyWithImpl<_InjuryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InjuryItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InjuryItem&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.injury, injury) || other.injury == injury)&&(identical(other.status, status) || other.status == status)&&(identical(other.position, position) || other.position == position)&&(identical(other.recoveryPercentage, recoveryPercentage) || other.recoveryPercentage == recoveryPercentage)&&(identical(other.isLongTerm, isLongTerm) || other.isLongTerm == isLongTerm)&&(identical(other.surgeryRequired, surgeryRequired) || other.surgeryRequired == surgeryRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerName,injury,status,position,recoveryPercentage,isLongTerm,surgeryRequired);

@override
String toString() {
  return 'InjuryItem(playerName: $playerName, injury: $injury, status: $status, position: $position, recoveryPercentage: $recoveryPercentage, isLongTerm: $isLongTerm, surgeryRequired: $surgeryRequired)';
}


}

/// @nodoc
abstract mixin class _$InjuryItemCopyWith<$Res> implements $InjuryItemCopyWith<$Res> {
  factory _$InjuryItemCopyWith(_InjuryItem value, $Res Function(_InjuryItem) _then) = __$InjuryItemCopyWithImpl;
@override @useResult
$Res call({
 String playerName, String injury, String status, String position, String recoveryPercentage, bool isLongTerm, bool surgeryRequired
});




}
/// @nodoc
class __$InjuryItemCopyWithImpl<$Res>
    implements _$InjuryItemCopyWith<$Res> {
  __$InjuryItemCopyWithImpl(this._self, this._then);

  final _InjuryItem _self;
  final $Res Function(_InjuryItem) _then;

/// Create a copy of InjuryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerName = null,Object? injury = null,Object? status = null,Object? position = null,Object? recoveryPercentage = null,Object? isLongTerm = null,Object? surgeryRequired = null,}) {
  return _then(_InjuryItem(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,injury: null == injury ? _self.injury : injury // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String,recoveryPercentage: null == recoveryPercentage ? _self.recoveryPercentage : recoveryPercentage // ignore: cast_nullable_to_non_nullable
as String,isLongTerm: null == isLongTerm ? _self.isLongTerm : isLongTerm // ignore: cast_nullable_to_non_nullable
as bool,surgeryRequired: null == surgeryRequired ? _self.surgeryRequired : surgeryRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ContractPlayer {

 String get playerName; String get position; String get expiresIn; String get marketValue; String get status; String get wage; String get askingPrice; String get interestLevel; String get negotiationProgress; String get previousClub;
/// Create a copy of ContractPlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractPlayerCopyWith<ContractPlayer> get copyWith => _$ContractPlayerCopyWithImpl<ContractPlayer>(this as ContractPlayer, _$identity);

  /// Serializes this ContractPlayer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractPlayer&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.position, position) || other.position == position)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.status, status) || other.status == status)&&(identical(other.wage, wage) || other.wage == wage)&&(identical(other.askingPrice, askingPrice) || other.askingPrice == askingPrice)&&(identical(other.interestLevel, interestLevel) || other.interestLevel == interestLevel)&&(identical(other.negotiationProgress, negotiationProgress) || other.negotiationProgress == negotiationProgress)&&(identical(other.previousClub, previousClub) || other.previousClub == previousClub));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerName,position,expiresIn,marketValue,status,wage,askingPrice,interestLevel,negotiationProgress,previousClub);

@override
String toString() {
  return 'ContractPlayer(playerName: $playerName, position: $position, expiresIn: $expiresIn, marketValue: $marketValue, status: $status, wage: $wage, askingPrice: $askingPrice, interestLevel: $interestLevel, negotiationProgress: $negotiationProgress, previousClub: $previousClub)';
}


}

/// @nodoc
abstract mixin class $ContractPlayerCopyWith<$Res>  {
  factory $ContractPlayerCopyWith(ContractPlayer value, $Res Function(ContractPlayer) _then) = _$ContractPlayerCopyWithImpl;
@useResult
$Res call({
 String playerName, String position, String expiresIn, String marketValue, String status, String wage, String askingPrice, String interestLevel, String negotiationProgress, String previousClub
});




}
/// @nodoc
class _$ContractPlayerCopyWithImpl<$Res>
    implements $ContractPlayerCopyWith<$Res> {
  _$ContractPlayerCopyWithImpl(this._self, this._then);

  final ContractPlayer _self;
  final $Res Function(ContractPlayer) _then;

/// Create a copy of ContractPlayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerName = null,Object? position = null,Object? expiresIn = null,Object? marketValue = null,Object? status = null,Object? wage = null,Object? askingPrice = null,Object? interestLevel = null,Object? negotiationProgress = null,Object? previousClub = null,}) {
  return _then(ContractPlayer(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,wage: null == wage ? _self.wage : wage // ignore: cast_nullable_to_non_nullable
as String,askingPrice: null == askingPrice ? _self.askingPrice : askingPrice // ignore: cast_nullable_to_non_nullable
as String,interestLevel: null == interestLevel ? _self.interestLevel : interestLevel // ignore: cast_nullable_to_non_nullable
as String,negotiationProgress: null == negotiationProgress ? _self.negotiationProgress : negotiationProgress // ignore: cast_nullable_to_non_nullable
as String,previousClub: null == previousClub ? _self.previousClub : previousClub // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ContractPlayer].
extension ContractPlayerPatterns on ContractPlayer {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContractPlayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContractPlayer() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContractPlayer value)  $default,){
final _that = this;
switch (_that) {
case _ContractPlayer():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContractPlayer value)?  $default,){
final _that = this;
switch (_that) {
case _ContractPlayer() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerName,  String position,  String expiresIn,  String marketValue,  String status,  String wage,  String askingPrice,  String interestLevel,  String negotiationProgress,  String previousClub)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContractPlayer() when $default != null:
return $default(_that.playerName,_that.position,_that.expiresIn,_that.marketValue,_that.status,_that.wage,_that.askingPrice,_that.interestLevel,_that.negotiationProgress,_that.previousClub);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerName,  String position,  String expiresIn,  String marketValue,  String status,  String wage,  String askingPrice,  String interestLevel,  String negotiationProgress,  String previousClub)  $default,) {final _that = this;
switch (_that) {
case _ContractPlayer():
return $default(_that.playerName,_that.position,_that.expiresIn,_that.marketValue,_that.status,_that.wage,_that.askingPrice,_that.interestLevel,_that.negotiationProgress,_that.previousClub);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerName,  String position,  String expiresIn,  String marketValue,  String status,  String wage,  String askingPrice,  String interestLevel,  String negotiationProgress,  String previousClub)?  $default,) {final _that = this;
switch (_that) {
case _ContractPlayer() when $default != null:
return $default(_that.playerName,_that.position,_that.expiresIn,_that.marketValue,_that.status,_that.wage,_that.askingPrice,_that.interestLevel,_that.negotiationProgress,_that.previousClub);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContractPlayer implements ContractPlayer {
  const _ContractPlayer({required this.playerName, required this.position, required this.expiresIn, this.marketValue = 'N/A', this.status = 'N/A', this.wage = 'N/A', this.askingPrice = 'N/A', this.interestLevel = 'N/A', this.negotiationProgress = 'N/A', this.previousClub = 'N/A'});
  factory _ContractPlayer.fromJson(Map<String, dynamic> json) => _$ContractPlayerFromJson(json);

@override final  String playerName;
@override final  String position;
@override final  String expiresIn;
@override@JsonKey() final  String marketValue;
@override@JsonKey() final  String status;
@override@JsonKey() final  String wage;
@override@JsonKey() final  String askingPrice;
@override@JsonKey() final  String interestLevel;
@override@JsonKey() final  String negotiationProgress;
@override@JsonKey() final  String previousClub;

/// Create a copy of ContractPlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractPlayerCopyWith<_ContractPlayer> get copyWith => __$ContractPlayerCopyWithImpl<_ContractPlayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractPlayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractPlayer&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.position, position) || other.position == position)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.status, status) || other.status == status)&&(identical(other.wage, wage) || other.wage == wage)&&(identical(other.askingPrice, askingPrice) || other.askingPrice == askingPrice)&&(identical(other.interestLevel, interestLevel) || other.interestLevel == interestLevel)&&(identical(other.negotiationProgress, negotiationProgress) || other.negotiationProgress == negotiationProgress)&&(identical(other.previousClub, previousClub) || other.previousClub == previousClub));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerName,position,expiresIn,marketValue,status,wage,askingPrice,interestLevel,negotiationProgress,previousClub);

@override
String toString() {
  return 'ContractPlayer(playerName: $playerName, position: $position, expiresIn: $expiresIn, marketValue: $marketValue, status: $status, wage: $wage, askingPrice: $askingPrice, interestLevel: $interestLevel, negotiationProgress: $negotiationProgress, previousClub: $previousClub)';
}


}

/// @nodoc
abstract mixin class _$ContractPlayerCopyWith<$Res> implements $ContractPlayerCopyWith<$Res> {
  factory _$ContractPlayerCopyWith(_ContractPlayer value, $Res Function(_ContractPlayer) _then) = __$ContractPlayerCopyWithImpl;
@override @useResult
$Res call({
 String playerName, String position, String expiresIn, String marketValue, String status, String wage, String askingPrice, String interestLevel, String negotiationProgress, String previousClub
});




}
/// @nodoc
class __$ContractPlayerCopyWithImpl<$Res>
    implements _$ContractPlayerCopyWith<$Res> {
  __$ContractPlayerCopyWithImpl(this._self, this._then);

  final _ContractPlayer _self;
  final $Res Function(_ContractPlayer) _then;

/// Create a copy of ContractPlayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerName = null,Object? position = null,Object? expiresIn = null,Object? marketValue = null,Object? status = null,Object? wage = null,Object? askingPrice = null,Object? interestLevel = null,Object? negotiationProgress = null,Object? previousClub = null,}) {
  return _then(_ContractPlayer(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,wage: null == wage ? _self.wage : wage // ignore: cast_nullable_to_non_nullable
as String,askingPrice: null == askingPrice ? _self.askingPrice : askingPrice // ignore: cast_nullable_to_non_nullable
as String,interestLevel: null == interestLevel ? _self.interestLevel : interestLevel // ignore: cast_nullable_to_non_nullable
as String,negotiationProgress: null == negotiationProgress ? _self.negotiationProgress : negotiationProgress // ignore: cast_nullable_to_non_nullable
as String,previousClub: null == previousClub ? _self.previousClub : previousClub // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NomineeItem {

 String get playerName; String get club; String get achievement; String get odds; bool get isFavorite; bool get previousWinner; String get votes;
/// Create a copy of NomineeItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NomineeItemCopyWith<NomineeItem> get copyWith => _$NomineeItemCopyWithImpl<NomineeItem>(this as NomineeItem, _$identity);

  /// Serializes this NomineeItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NomineeItem&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.club, club) || other.club == club)&&(identical(other.achievement, achievement) || other.achievement == achievement)&&(identical(other.odds, odds) || other.odds == odds)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.previousWinner, previousWinner) || other.previousWinner == previousWinner)&&(identical(other.votes, votes) || other.votes == votes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerName,club,achievement,odds,isFavorite,previousWinner,votes);

@override
String toString() {
  return 'NomineeItem(playerName: $playerName, club: $club, achievement: $achievement, odds: $odds, isFavorite: $isFavorite, previousWinner: $previousWinner, votes: $votes)';
}


}

/// @nodoc
abstract mixin class $NomineeItemCopyWith<$Res>  {
  factory $NomineeItemCopyWith(NomineeItem value, $Res Function(NomineeItem) _then) = _$NomineeItemCopyWithImpl;
@useResult
$Res call({
 String playerName, String club, String achievement, String odds, bool isFavorite, bool previousWinner, String votes
});




}
/// @nodoc
class _$NomineeItemCopyWithImpl<$Res>
    implements $NomineeItemCopyWith<$Res> {
  _$NomineeItemCopyWithImpl(this._self, this._then);

  final NomineeItem _self;
  final $Res Function(NomineeItem) _then;

/// Create a copy of NomineeItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerName = null,Object? club = null,Object? achievement = null,Object? odds = null,Object? isFavorite = null,Object? previousWinner = null,Object? votes = null,}) {
  return _then(NomineeItem(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,club: null == club ? _self.club : club // ignore: cast_nullable_to_non_nullable
as String,achievement: null == achievement ? _self.achievement : achievement // ignore: cast_nullable_to_non_nullable
as String,odds: null == odds ? _self.odds : odds // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,previousWinner: null == previousWinner ? _self.previousWinner : previousWinner // ignore: cast_nullable_to_non_nullable
as bool,votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NomineeItem].
extension NomineeItemPatterns on NomineeItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NomineeItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NomineeItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NomineeItem value)  $default,){
final _that = this;
switch (_that) {
case _NomineeItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NomineeItem value)?  $default,){
final _that = this;
switch (_that) {
case _NomineeItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerName,  String club,  String achievement,  String odds,  bool isFavorite,  bool previousWinner,  String votes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NomineeItem() when $default != null:
return $default(_that.playerName,_that.club,_that.achievement,_that.odds,_that.isFavorite,_that.previousWinner,_that.votes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerName,  String club,  String achievement,  String odds,  bool isFavorite,  bool previousWinner,  String votes)  $default,) {final _that = this;
switch (_that) {
case _NomineeItem():
return $default(_that.playerName,_that.club,_that.achievement,_that.odds,_that.isFavorite,_that.previousWinner,_that.votes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerName,  String club,  String achievement,  String odds,  bool isFavorite,  bool previousWinner,  String votes)?  $default,) {final _that = this;
switch (_that) {
case _NomineeItem() when $default != null:
return $default(_that.playerName,_that.club,_that.achievement,_that.odds,_that.isFavorite,_that.previousWinner,_that.votes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NomineeItem implements NomineeItem {
  const _NomineeItem({required this.playerName, required this.club, required this.achievement, this.odds = 'N/A', this.isFavorite = false, this.previousWinner = false, this.votes = 'N/A'});
  factory _NomineeItem.fromJson(Map<String, dynamic> json) => _$NomineeItemFromJson(json);

@override final  String playerName;
@override final  String club;
@override final  String achievement;
@override@JsonKey() final  String odds;
@override@JsonKey() final  bool isFavorite;
@override@JsonKey() final  bool previousWinner;
@override@JsonKey() final  String votes;

/// Create a copy of NomineeItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NomineeItemCopyWith<_NomineeItem> get copyWith => __$NomineeItemCopyWithImpl<_NomineeItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NomineeItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NomineeItem&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.club, club) || other.club == club)&&(identical(other.achievement, achievement) || other.achievement == achievement)&&(identical(other.odds, odds) || other.odds == odds)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.previousWinner, previousWinner) || other.previousWinner == previousWinner)&&(identical(other.votes, votes) || other.votes == votes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerName,club,achievement,odds,isFavorite,previousWinner,votes);

@override
String toString() {
  return 'NomineeItem(playerName: $playerName, club: $club, achievement: $achievement, odds: $odds, isFavorite: $isFavorite, previousWinner: $previousWinner, votes: $votes)';
}


}

/// @nodoc
abstract mixin class _$NomineeItemCopyWith<$Res> implements $NomineeItemCopyWith<$Res> {
  factory _$NomineeItemCopyWith(_NomineeItem value, $Res Function(_NomineeItem) _then) = __$NomineeItemCopyWithImpl;
@override @useResult
$Res call({
 String playerName, String club, String achievement, String odds, bool isFavorite, bool previousWinner, String votes
});




}
/// @nodoc
class __$NomineeItemCopyWithImpl<$Res>
    implements _$NomineeItemCopyWith<$Res> {
  __$NomineeItemCopyWithImpl(this._self, this._then);

  final _NomineeItem _self;
  final $Res Function(_NomineeItem) _then;

/// Create a copy of NomineeItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerName = null,Object? club = null,Object? achievement = null,Object? odds = null,Object? isFavorite = null,Object? previousWinner = null,Object? votes = null,}) {
  return _then(_NomineeItem(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,club: null == club ? _self.club : club // ignore: cast_nullable_to_non_nullable
as String,achievement: null == achievement ? _self.achievement : achievement // ignore: cast_nullable_to_non_nullable
as String,odds: null == odds ? _self.odds : odds // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,previousWinner: null == previousWinner ? _self.previousWinner : previousWinner // ignore: cast_nullable_to_non_nullable
as bool,votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

CardData _$CardDataFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'playerSpotlight':
          return PlayerSpotlight.fromJson(
            json
          );
                case 'headlineQuote':
          return HeadlineQuote.fromJson(
            json
          );
                case 'topStats':
          return TopStats.fromJson(
            json
          );
                case 'transferNews':
          return TransferNews.fromJson(
            json
          );
                case 'breakingNews':
          return BreakingNews.fromJson(
            json
          );
                case 'matchPreview':
          return MatchPreview.fromJson(
            json
          );
                case 'detailedScoreboard':
          return DetailedScoreboard.fromJson(
            json
          );
                case 'onThisDay':
          return OnThisDay.fromJson(
            json
          );
                case 'startingXI':
          return StartingXI.fromJson(
            json
          );
                case 'matchStatsComparison':
          return MatchStatsComparison.fromJson(
            json
          );
                case 'socialPost':
          return SocialPost.fromJson(
            json
          );
                case 'rivalry':
          return Rivalry.fromJson(
            json
          );
                case 'tableStandings':
          return TableStandings.fromJson(
            json
          );
                case 'injuryReport':
          return InjuryReport.fromJson(
            json
          );
                case 'contractExpiry':
          return ContractExpiry.fromJson(
            json
          );
                case 'awardNominee':
          return AwardNominee.fromJson(
            json
          );
                case 'sparse':
          return SparseCard.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'CardData',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$CardData {

 CardTemplate? get suggestedTemplate;
/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardDataCopyWith<CardData> get copyWith => _$CardDataCopyWithImpl<CardData>(this as CardData, _$identity);

  /// Serializes this CardData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardData&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,suggestedTemplate);

@override
String toString() {
  return 'CardData(suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $CardDataCopyWith<$Res>  {
  factory $CardDataCopyWith(CardData value, $Res Function(CardData) _then) = _$CardDataCopyWithImpl;
@useResult
$Res call({
 CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$CardDataCopyWithImpl<$Res>
    implements $CardDataCopyWith<$Res> {
  _$CardDataCopyWithImpl(this._self, this._then);

  final CardData _self;
  final $Res Function(CardData) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? suggestedTemplate = freezed,}) {
  return _then(_self.copyWith(
suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}

}


/// Adds pattern-matching-related methods to [CardData].
extension CardDataPatterns on CardData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlayerSpotlight value)?  playerSpotlight,TResult Function( HeadlineQuote value)?  headlineQuote,TResult Function( TopStats value)?  topStats,TResult Function( TransferNews value)?  transferNews,TResult Function( BreakingNews value)?  breakingNews,TResult Function( MatchPreview value)?  matchPreview,TResult Function( DetailedScoreboard value)?  detailedScoreboard,TResult Function( OnThisDay value)?  onThisDay,TResult Function( StartingXI value)?  startingXI,TResult Function( MatchStatsComparison value)?  matchStatsComparison,TResult Function( SocialPost value)?  socialPost,TResult Function( Rivalry value)?  rivalry,TResult Function( TableStandings value)?  tableStandings,TResult Function( InjuryReport value)?  injuryReport,TResult Function( ContractExpiry value)?  contractExpiry,TResult Function( AwardNominee value)?  awardNominee,TResult Function( SparseCard value)?  sparse,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlayerSpotlight() when playerSpotlight != null:
return playerSpotlight(_that);case HeadlineQuote() when headlineQuote != null:
return headlineQuote(_that);case TopStats() when topStats != null:
return topStats(_that);case TransferNews() when transferNews != null:
return transferNews(_that);case BreakingNews() when breakingNews != null:
return breakingNews(_that);case MatchPreview() when matchPreview != null:
return matchPreview(_that);case DetailedScoreboard() when detailedScoreboard != null:
return detailedScoreboard(_that);case OnThisDay() when onThisDay != null:
return onThisDay(_that);case StartingXI() when startingXI != null:
return startingXI(_that);case MatchStatsComparison() when matchStatsComparison != null:
return matchStatsComparison(_that);case SocialPost() when socialPost != null:
return socialPost(_that);case Rivalry() when rivalry != null:
return rivalry(_that);case TableStandings() when tableStandings != null:
return tableStandings(_that);case InjuryReport() when injuryReport != null:
return injuryReport(_that);case ContractExpiry() when contractExpiry != null:
return contractExpiry(_that);case AwardNominee() when awardNominee != null:
return awardNominee(_that);case SparseCard() when sparse != null:
return sparse(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlayerSpotlight value)  playerSpotlight,required TResult Function( HeadlineQuote value)  headlineQuote,required TResult Function( TopStats value)  topStats,required TResult Function( TransferNews value)  transferNews,required TResult Function( BreakingNews value)  breakingNews,required TResult Function( MatchPreview value)  matchPreview,required TResult Function( DetailedScoreboard value)  detailedScoreboard,required TResult Function( OnThisDay value)  onThisDay,required TResult Function( StartingXI value)  startingXI,required TResult Function( MatchStatsComparison value)  matchStatsComparison,required TResult Function( SocialPost value)  socialPost,required TResult Function( Rivalry value)  rivalry,required TResult Function( TableStandings value)  tableStandings,required TResult Function( InjuryReport value)  injuryReport,required TResult Function( ContractExpiry value)  contractExpiry,required TResult Function( AwardNominee value)  awardNominee,required TResult Function( SparseCard value)  sparse,}){
final _that = this;
switch (_that) {
case PlayerSpotlight():
return playerSpotlight(_that);case HeadlineQuote():
return headlineQuote(_that);case TopStats():
return topStats(_that);case TransferNews():
return transferNews(_that);case BreakingNews():
return breakingNews(_that);case MatchPreview():
return matchPreview(_that);case DetailedScoreboard():
return detailedScoreboard(_that);case OnThisDay():
return onThisDay(_that);case StartingXI():
return startingXI(_that);case MatchStatsComparison():
return matchStatsComparison(_that);case SocialPost():
return socialPost(_that);case Rivalry():
return rivalry(_that);case TableStandings():
return tableStandings(_that);case InjuryReport():
return injuryReport(_that);case ContractExpiry():
return contractExpiry(_that);case AwardNominee():
return awardNominee(_that);case SparseCard():
return sparse(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlayerSpotlight value)?  playerSpotlight,TResult? Function( HeadlineQuote value)?  headlineQuote,TResult? Function( TopStats value)?  topStats,TResult? Function( TransferNews value)?  transferNews,TResult? Function( BreakingNews value)?  breakingNews,TResult? Function( MatchPreview value)?  matchPreview,TResult? Function( DetailedScoreboard value)?  detailedScoreboard,TResult? Function( OnThisDay value)?  onThisDay,TResult? Function( StartingXI value)?  startingXI,TResult? Function( MatchStatsComparison value)?  matchStatsComparison,TResult? Function( SocialPost value)?  socialPost,TResult? Function( Rivalry value)?  rivalry,TResult? Function( TableStandings value)?  tableStandings,TResult? Function( InjuryReport value)?  injuryReport,TResult? Function( ContractExpiry value)?  contractExpiry,TResult? Function( AwardNominee value)?  awardNominee,TResult? Function( SparseCard value)?  sparse,}){
final _that = this;
switch (_that) {
case PlayerSpotlight() when playerSpotlight != null:
return playerSpotlight(_that);case HeadlineQuote() when headlineQuote != null:
return headlineQuote(_that);case TopStats() when topStats != null:
return topStats(_that);case TransferNews() when transferNews != null:
return transferNews(_that);case BreakingNews() when breakingNews != null:
return breakingNews(_that);case MatchPreview() when matchPreview != null:
return matchPreview(_that);case DetailedScoreboard() when detailedScoreboard != null:
return detailedScoreboard(_that);case OnThisDay() when onThisDay != null:
return onThisDay(_that);case StartingXI() when startingXI != null:
return startingXI(_that);case MatchStatsComparison() when matchStatsComparison != null:
return matchStatsComparison(_that);case SocialPost() when socialPost != null:
return socialPost(_that);case Rivalry() when rivalry != null:
return rivalry(_that);case TableStandings() when tableStandings != null:
return tableStandings(_that);case InjuryReport() when injuryReport != null:
return injuryReport(_that);case ContractExpiry() when contractExpiry != null:
return contractExpiry(_that);case AwardNominee() when awardNominee != null:
return awardNominee(_that);case SparseCard() when sparse != null:
return sparse(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String playerName,  String club,  String position,  double rating,  int goals,  int assists,  int minutesPlayed,  String keyAction,  String keyQuote,  String nationality,  int appearances,  int cleanSheets,  int passes,  int tackles,  CardTemplate? suggestedTemplate)?  playerSpotlight,TResult Function( String headline,  String subtext,  String quoteAuthor,  String authorTitle,  String category,  String relatedTeams,  CardTemplate? suggestedTemplate)?  headlineQuote,TResult Function( String matchContext,  List<StatItem> stats,  CardTemplate? suggestedTemplate)?  topStats,TResult Function( String playerName,  String action,  String fromTeam,  String toTeam,  String fee,  String contractLength,  String transferType,  String quote,  String feeCategory,  bool medicalCompleted,  bool workPermit,  String agentName,  CardTemplate? suggestedTemplate)?  transferNews,TResult Function( String label,  String headline,  String subtext,  int impactRating,  String relatedTeams,  CardTemplate? suggestedTemplate)?  breakingNews,TResult Function( String competition,  String homeTeam,  String awayTeam,  String homeForm,  String awayForm,  String matchTime,  String stadium,  String referee,  String tvChannel,  String kickoffTime,  String weather,  String capacity,  CardTemplate? suggestedTemplate)?  matchPreview,TResult Function( String homeTeam,  String awayTeam,  int homeScore,  int awayScore,  String homeScorers,  String awayScorers,  String possession,  String shotsOnTarget,  String competition,  String matchStatus,  String corners,  String fouls,  String yellowCards,  String redCards,  String attendance,  String referee,  String penaltyShootout,  String assistProviders,  CardTemplate? suggestedTemplate)?  detailedScoreboard,TResult Function( String dateLabel,  int yearsAgo,  String competition,  String headline,  List<StatItem> keyStats,  String venue,  String attendance,  String result,  String significance,  CardTemplate? suggestedTemplate)?  onThisDay,TResult Function( String teamName,  String formation,  List<LineupPlayer> starters,  List<LineupPlayer> subs,  String manager,  String averageAge,  String keyAbsences,  String captain,  String viceCaptain,  String tactics,  String injuredPlayers,  String suspendedPlayers,  CardTemplate? suggestedTemplate)?  startingXI,TResult Function( String homeTeam,  String awayTeam,  List<ComparisonStat> stats,  CardTemplate? suggestedTemplate)?  matchStatsComparison,TResult Function( String handle,  String name,  String content,  String timestamp,  String metrics,  bool verified,  String followers,  String shares,  String bookmarks,  String mediaType,  bool isEdited,  CardTemplate? suggestedTemplate)?  socialPost,TResult Function( String player1Name,  String player2Name,  String matchContext,  List<StatItem> player1Stats,  List<StatItem> player2Stats,  String headToHead,  String verdict,  String compareType,  String totalMatches,  String draws,  String player1Trophies,  String player2Trophies,  String predictionConfidence,  CardTemplate? suggestedTemplate)?  rivalry,TResult Function( String leagueName,  String matchday,  List<TableRow> standings,  String highlightedTeam,  int promotionZone,  int relegationZone,  String gamesInHand,  String pointsBehindLeader,  String topScorer,  String topAssists,  CardTemplate? suggestedTemplate)?  tableStandings,TResult Function( String teamName,  String reportDate,  List<InjuryItem> injuries,  List<InjuryItem> doubtfits,  List<InjuryItem> returns,  String nextMatch,  String recoveryPercentage,  CardTemplate? suggestedTemplate)?  injuryReport,TResult Function( String teamName,  String seasonYear,  List<ContractPlayer> expiringPlayers,  List<ContractPlayer> renewals,  String wage,  String askingPrice,  String interestLevel,  CardTemplate? suggestedTemplate)?  contractExpiry,TResult Function( String awardName,  String category,  List<NomineeItem> nominees,  String ceremonyDate,  String currentFavorite,  String votingDeadline,  String votingMethod,  int totalNominees,  String venue,  String host,  CardTemplate? suggestedTemplate)?  awardNominee,TResult Function( String headline,  String subtext,  String? microStat,  CardTemplate? suggestedTemplate)?  sparse,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlayerSpotlight() when playerSpotlight != null:
return playerSpotlight(_that.playerName,_that.club,_that.position,_that.rating,_that.goals,_that.assists,_that.minutesPlayed,_that.keyAction,_that.keyQuote,_that.nationality,_that.appearances,_that.cleanSheets,_that.passes,_that.tackles,_that.suggestedTemplate);case HeadlineQuote() when headlineQuote != null:
return headlineQuote(_that.headline,_that.subtext,_that.quoteAuthor,_that.authorTitle,_that.category,_that.relatedTeams,_that.suggestedTemplate);case TopStats() when topStats != null:
return topStats(_that.matchContext,_that.stats,_that.suggestedTemplate);case TransferNews() when transferNews != null:
return transferNews(_that.playerName,_that.action,_that.fromTeam,_that.toTeam,_that.fee,_that.contractLength,_that.transferType,_that.quote,_that.feeCategory,_that.medicalCompleted,_that.workPermit,_that.agentName,_that.suggestedTemplate);case BreakingNews() when breakingNews != null:
return breakingNews(_that.label,_that.headline,_that.subtext,_that.impactRating,_that.relatedTeams,_that.suggestedTemplate);case MatchPreview() when matchPreview != null:
return matchPreview(_that.competition,_that.homeTeam,_that.awayTeam,_that.homeForm,_that.awayForm,_that.matchTime,_that.stadium,_that.referee,_that.tvChannel,_that.kickoffTime,_that.weather,_that.capacity,_that.suggestedTemplate);case DetailedScoreboard() when detailedScoreboard != null:
return detailedScoreboard(_that.homeTeam,_that.awayTeam,_that.homeScore,_that.awayScore,_that.homeScorers,_that.awayScorers,_that.possession,_that.shotsOnTarget,_that.competition,_that.matchStatus,_that.corners,_that.fouls,_that.yellowCards,_that.redCards,_that.attendance,_that.referee,_that.penaltyShootout,_that.assistProviders,_that.suggestedTemplate);case OnThisDay() when onThisDay != null:
return onThisDay(_that.dateLabel,_that.yearsAgo,_that.competition,_that.headline,_that.keyStats,_that.venue,_that.attendance,_that.result,_that.significance,_that.suggestedTemplate);case StartingXI() when startingXI != null:
return startingXI(_that.teamName,_that.formation,_that.starters,_that.subs,_that.manager,_that.averageAge,_that.keyAbsences,_that.captain,_that.viceCaptain,_that.tactics,_that.injuredPlayers,_that.suspendedPlayers,_that.suggestedTemplate);case MatchStatsComparison() when matchStatsComparison != null:
return matchStatsComparison(_that.homeTeam,_that.awayTeam,_that.stats,_that.suggestedTemplate);case SocialPost() when socialPost != null:
return socialPost(_that.handle,_that.name,_that.content,_that.timestamp,_that.metrics,_that.verified,_that.followers,_that.shares,_that.bookmarks,_that.mediaType,_that.isEdited,_that.suggestedTemplate);case Rivalry() when rivalry != null:
return rivalry(_that.player1Name,_that.player2Name,_that.matchContext,_that.player1Stats,_that.player2Stats,_that.headToHead,_that.verdict,_that.compareType,_that.totalMatches,_that.draws,_that.player1Trophies,_that.player2Trophies,_that.predictionConfidence,_that.suggestedTemplate);case TableStandings() when tableStandings != null:
return tableStandings(_that.leagueName,_that.matchday,_that.standings,_that.highlightedTeam,_that.promotionZone,_that.relegationZone,_that.gamesInHand,_that.pointsBehindLeader,_that.topScorer,_that.topAssists,_that.suggestedTemplate);case InjuryReport() when injuryReport != null:
return injuryReport(_that.teamName,_that.reportDate,_that.injuries,_that.doubtfits,_that.returns,_that.nextMatch,_that.recoveryPercentage,_that.suggestedTemplate);case ContractExpiry() when contractExpiry != null:
return contractExpiry(_that.teamName,_that.seasonYear,_that.expiringPlayers,_that.renewals,_that.wage,_that.askingPrice,_that.interestLevel,_that.suggestedTemplate);case AwardNominee() when awardNominee != null:
return awardNominee(_that.awardName,_that.category,_that.nominees,_that.ceremonyDate,_that.currentFavorite,_that.votingDeadline,_that.votingMethod,_that.totalNominees,_that.venue,_that.host,_that.suggestedTemplate);case SparseCard() when sparse != null:
return sparse(_that.headline,_that.subtext,_that.microStat,_that.suggestedTemplate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String playerName,  String club,  String position,  double rating,  int goals,  int assists,  int minutesPlayed,  String keyAction,  String keyQuote,  String nationality,  int appearances,  int cleanSheets,  int passes,  int tackles,  CardTemplate? suggestedTemplate)  playerSpotlight,required TResult Function( String headline,  String subtext,  String quoteAuthor,  String authorTitle,  String category,  String relatedTeams,  CardTemplate? suggestedTemplate)  headlineQuote,required TResult Function( String matchContext,  List<StatItem> stats,  CardTemplate? suggestedTemplate)  topStats,required TResult Function( String playerName,  String action,  String fromTeam,  String toTeam,  String fee,  String contractLength,  String transferType,  String quote,  String feeCategory,  bool medicalCompleted,  bool workPermit,  String agentName,  CardTemplate? suggestedTemplate)  transferNews,required TResult Function( String label,  String headline,  String subtext,  int impactRating,  String relatedTeams,  CardTemplate? suggestedTemplate)  breakingNews,required TResult Function( String competition,  String homeTeam,  String awayTeam,  String homeForm,  String awayForm,  String matchTime,  String stadium,  String referee,  String tvChannel,  String kickoffTime,  String weather,  String capacity,  CardTemplate? suggestedTemplate)  matchPreview,required TResult Function( String homeTeam,  String awayTeam,  int homeScore,  int awayScore,  String homeScorers,  String awayScorers,  String possession,  String shotsOnTarget,  String competition,  String matchStatus,  String corners,  String fouls,  String yellowCards,  String redCards,  String attendance,  String referee,  String penaltyShootout,  String assistProviders,  CardTemplate? suggestedTemplate)  detailedScoreboard,required TResult Function( String dateLabel,  int yearsAgo,  String competition,  String headline,  List<StatItem> keyStats,  String venue,  String attendance,  String result,  String significance,  CardTemplate? suggestedTemplate)  onThisDay,required TResult Function( String teamName,  String formation,  List<LineupPlayer> starters,  List<LineupPlayer> subs,  String manager,  String averageAge,  String keyAbsences,  String captain,  String viceCaptain,  String tactics,  String injuredPlayers,  String suspendedPlayers,  CardTemplate? suggestedTemplate)  startingXI,required TResult Function( String homeTeam,  String awayTeam,  List<ComparisonStat> stats,  CardTemplate? suggestedTemplate)  matchStatsComparison,required TResult Function( String handle,  String name,  String content,  String timestamp,  String metrics,  bool verified,  String followers,  String shares,  String bookmarks,  String mediaType,  bool isEdited,  CardTemplate? suggestedTemplate)  socialPost,required TResult Function( String player1Name,  String player2Name,  String matchContext,  List<StatItem> player1Stats,  List<StatItem> player2Stats,  String headToHead,  String verdict,  String compareType,  String totalMatches,  String draws,  String player1Trophies,  String player2Trophies,  String predictionConfidence,  CardTemplate? suggestedTemplate)  rivalry,required TResult Function( String leagueName,  String matchday,  List<TableRow> standings,  String highlightedTeam,  int promotionZone,  int relegationZone,  String gamesInHand,  String pointsBehindLeader,  String topScorer,  String topAssists,  CardTemplate? suggestedTemplate)  tableStandings,required TResult Function( String teamName,  String reportDate,  List<InjuryItem> injuries,  List<InjuryItem> doubtfits,  List<InjuryItem> returns,  String nextMatch,  String recoveryPercentage,  CardTemplate? suggestedTemplate)  injuryReport,required TResult Function( String teamName,  String seasonYear,  List<ContractPlayer> expiringPlayers,  List<ContractPlayer> renewals,  String wage,  String askingPrice,  String interestLevel,  CardTemplate? suggestedTemplate)  contractExpiry,required TResult Function( String awardName,  String category,  List<NomineeItem> nominees,  String ceremonyDate,  String currentFavorite,  String votingDeadline,  String votingMethod,  int totalNominees,  String venue,  String host,  CardTemplate? suggestedTemplate)  awardNominee,required TResult Function( String headline,  String subtext,  String? microStat,  CardTemplate? suggestedTemplate)  sparse,}) {final _that = this;
switch (_that) {
case PlayerSpotlight():
return playerSpotlight(_that.playerName,_that.club,_that.position,_that.rating,_that.goals,_that.assists,_that.minutesPlayed,_that.keyAction,_that.keyQuote,_that.nationality,_that.appearances,_that.cleanSheets,_that.passes,_that.tackles,_that.suggestedTemplate);case HeadlineQuote():
return headlineQuote(_that.headline,_that.subtext,_that.quoteAuthor,_that.authorTitle,_that.category,_that.relatedTeams,_that.suggestedTemplate);case TopStats():
return topStats(_that.matchContext,_that.stats,_that.suggestedTemplate);case TransferNews():
return transferNews(_that.playerName,_that.action,_that.fromTeam,_that.toTeam,_that.fee,_that.contractLength,_that.transferType,_that.quote,_that.feeCategory,_that.medicalCompleted,_that.workPermit,_that.agentName,_that.suggestedTemplate);case BreakingNews():
return breakingNews(_that.label,_that.headline,_that.subtext,_that.impactRating,_that.relatedTeams,_that.suggestedTemplate);case MatchPreview():
return matchPreview(_that.competition,_that.homeTeam,_that.awayTeam,_that.homeForm,_that.awayForm,_that.matchTime,_that.stadium,_that.referee,_that.tvChannel,_that.kickoffTime,_that.weather,_that.capacity,_that.suggestedTemplate);case DetailedScoreboard():
return detailedScoreboard(_that.homeTeam,_that.awayTeam,_that.homeScore,_that.awayScore,_that.homeScorers,_that.awayScorers,_that.possession,_that.shotsOnTarget,_that.competition,_that.matchStatus,_that.corners,_that.fouls,_that.yellowCards,_that.redCards,_that.attendance,_that.referee,_that.penaltyShootout,_that.assistProviders,_that.suggestedTemplate);case OnThisDay():
return onThisDay(_that.dateLabel,_that.yearsAgo,_that.competition,_that.headline,_that.keyStats,_that.venue,_that.attendance,_that.result,_that.significance,_that.suggestedTemplate);case StartingXI():
return startingXI(_that.teamName,_that.formation,_that.starters,_that.subs,_that.manager,_that.averageAge,_that.keyAbsences,_that.captain,_that.viceCaptain,_that.tactics,_that.injuredPlayers,_that.suspendedPlayers,_that.suggestedTemplate);case MatchStatsComparison():
return matchStatsComparison(_that.homeTeam,_that.awayTeam,_that.stats,_that.suggestedTemplate);case SocialPost():
return socialPost(_that.handle,_that.name,_that.content,_that.timestamp,_that.metrics,_that.verified,_that.followers,_that.shares,_that.bookmarks,_that.mediaType,_that.isEdited,_that.suggestedTemplate);case Rivalry():
return rivalry(_that.player1Name,_that.player2Name,_that.matchContext,_that.player1Stats,_that.player2Stats,_that.headToHead,_that.verdict,_that.compareType,_that.totalMatches,_that.draws,_that.player1Trophies,_that.player2Trophies,_that.predictionConfidence,_that.suggestedTemplate);case TableStandings():
return tableStandings(_that.leagueName,_that.matchday,_that.standings,_that.highlightedTeam,_that.promotionZone,_that.relegationZone,_that.gamesInHand,_that.pointsBehindLeader,_that.topScorer,_that.topAssists,_that.suggestedTemplate);case InjuryReport():
return injuryReport(_that.teamName,_that.reportDate,_that.injuries,_that.doubtfits,_that.returns,_that.nextMatch,_that.recoveryPercentage,_that.suggestedTemplate);case ContractExpiry():
return contractExpiry(_that.teamName,_that.seasonYear,_that.expiringPlayers,_that.renewals,_that.wage,_that.askingPrice,_that.interestLevel,_that.suggestedTemplate);case AwardNominee():
return awardNominee(_that.awardName,_that.category,_that.nominees,_that.ceremonyDate,_that.currentFavorite,_that.votingDeadline,_that.votingMethod,_that.totalNominees,_that.venue,_that.host,_that.suggestedTemplate);case SparseCard():
return sparse(_that.headline,_that.subtext,_that.microStat,_that.suggestedTemplate);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String playerName,  String club,  String position,  double rating,  int goals,  int assists,  int minutesPlayed,  String keyAction,  String keyQuote,  String nationality,  int appearances,  int cleanSheets,  int passes,  int tackles,  CardTemplate? suggestedTemplate)?  playerSpotlight,TResult? Function( String headline,  String subtext,  String quoteAuthor,  String authorTitle,  String category,  String relatedTeams,  CardTemplate? suggestedTemplate)?  headlineQuote,TResult? Function( String matchContext,  List<StatItem> stats,  CardTemplate? suggestedTemplate)?  topStats,TResult? Function( String playerName,  String action,  String fromTeam,  String toTeam,  String fee,  String contractLength,  String transferType,  String quote,  String feeCategory,  bool medicalCompleted,  bool workPermit,  String agentName,  CardTemplate? suggestedTemplate)?  transferNews,TResult? Function( String label,  String headline,  String subtext,  int impactRating,  String relatedTeams,  CardTemplate? suggestedTemplate)?  breakingNews,TResult? Function( String competition,  String homeTeam,  String awayTeam,  String homeForm,  String awayForm,  String matchTime,  String stadium,  String referee,  String tvChannel,  String kickoffTime,  String weather,  String capacity,  CardTemplate? suggestedTemplate)?  matchPreview,TResult? Function( String homeTeam,  String awayTeam,  int homeScore,  int awayScore,  String homeScorers,  String awayScorers,  String possession,  String shotsOnTarget,  String competition,  String matchStatus,  String corners,  String fouls,  String yellowCards,  String redCards,  String attendance,  String referee,  String penaltyShootout,  String assistProviders,  CardTemplate? suggestedTemplate)?  detailedScoreboard,TResult? Function( String dateLabel,  int yearsAgo,  String competition,  String headline,  List<StatItem> keyStats,  String venue,  String attendance,  String result,  String significance,  CardTemplate? suggestedTemplate)?  onThisDay,TResult? Function( String teamName,  String formation,  List<LineupPlayer> starters,  List<LineupPlayer> subs,  String manager,  String averageAge,  String keyAbsences,  String captain,  String viceCaptain,  String tactics,  String injuredPlayers,  String suspendedPlayers,  CardTemplate? suggestedTemplate)?  startingXI,TResult? Function( String homeTeam,  String awayTeam,  List<ComparisonStat> stats,  CardTemplate? suggestedTemplate)?  matchStatsComparison,TResult? Function( String handle,  String name,  String content,  String timestamp,  String metrics,  bool verified,  String followers,  String shares,  String bookmarks,  String mediaType,  bool isEdited,  CardTemplate? suggestedTemplate)?  socialPost,TResult? Function( String player1Name,  String player2Name,  String matchContext,  List<StatItem> player1Stats,  List<StatItem> player2Stats,  String headToHead,  String verdict,  String compareType,  String totalMatches,  String draws,  String player1Trophies,  String player2Trophies,  String predictionConfidence,  CardTemplate? suggestedTemplate)?  rivalry,TResult? Function( String leagueName,  String matchday,  List<TableRow> standings,  String highlightedTeam,  int promotionZone,  int relegationZone,  String gamesInHand,  String pointsBehindLeader,  String topScorer,  String topAssists,  CardTemplate? suggestedTemplate)?  tableStandings,TResult? Function( String teamName,  String reportDate,  List<InjuryItem> injuries,  List<InjuryItem> doubtfits,  List<InjuryItem> returns,  String nextMatch,  String recoveryPercentage,  CardTemplate? suggestedTemplate)?  injuryReport,TResult? Function( String teamName,  String seasonYear,  List<ContractPlayer> expiringPlayers,  List<ContractPlayer> renewals,  String wage,  String askingPrice,  String interestLevel,  CardTemplate? suggestedTemplate)?  contractExpiry,TResult? Function( String awardName,  String category,  List<NomineeItem> nominees,  String ceremonyDate,  String currentFavorite,  String votingDeadline,  String votingMethod,  int totalNominees,  String venue,  String host,  CardTemplate? suggestedTemplate)?  awardNominee,TResult? Function( String headline,  String subtext,  String? microStat,  CardTemplate? suggestedTemplate)?  sparse,}) {final _that = this;
switch (_that) {
case PlayerSpotlight() when playerSpotlight != null:
return playerSpotlight(_that.playerName,_that.club,_that.position,_that.rating,_that.goals,_that.assists,_that.minutesPlayed,_that.keyAction,_that.keyQuote,_that.nationality,_that.appearances,_that.cleanSheets,_that.passes,_that.tackles,_that.suggestedTemplate);case HeadlineQuote() when headlineQuote != null:
return headlineQuote(_that.headline,_that.subtext,_that.quoteAuthor,_that.authorTitle,_that.category,_that.relatedTeams,_that.suggestedTemplate);case TopStats() when topStats != null:
return topStats(_that.matchContext,_that.stats,_that.suggestedTemplate);case TransferNews() when transferNews != null:
return transferNews(_that.playerName,_that.action,_that.fromTeam,_that.toTeam,_that.fee,_that.contractLength,_that.transferType,_that.quote,_that.feeCategory,_that.medicalCompleted,_that.workPermit,_that.agentName,_that.suggestedTemplate);case BreakingNews() when breakingNews != null:
return breakingNews(_that.label,_that.headline,_that.subtext,_that.impactRating,_that.relatedTeams,_that.suggestedTemplate);case MatchPreview() when matchPreview != null:
return matchPreview(_that.competition,_that.homeTeam,_that.awayTeam,_that.homeForm,_that.awayForm,_that.matchTime,_that.stadium,_that.referee,_that.tvChannel,_that.kickoffTime,_that.weather,_that.capacity,_that.suggestedTemplate);case DetailedScoreboard() when detailedScoreboard != null:
return detailedScoreboard(_that.homeTeam,_that.awayTeam,_that.homeScore,_that.awayScore,_that.homeScorers,_that.awayScorers,_that.possession,_that.shotsOnTarget,_that.competition,_that.matchStatus,_that.corners,_that.fouls,_that.yellowCards,_that.redCards,_that.attendance,_that.referee,_that.penaltyShootout,_that.assistProviders,_that.suggestedTemplate);case OnThisDay() when onThisDay != null:
return onThisDay(_that.dateLabel,_that.yearsAgo,_that.competition,_that.headline,_that.keyStats,_that.venue,_that.attendance,_that.result,_that.significance,_that.suggestedTemplate);case StartingXI() when startingXI != null:
return startingXI(_that.teamName,_that.formation,_that.starters,_that.subs,_that.manager,_that.averageAge,_that.keyAbsences,_that.captain,_that.viceCaptain,_that.tactics,_that.injuredPlayers,_that.suspendedPlayers,_that.suggestedTemplate);case MatchStatsComparison() when matchStatsComparison != null:
return matchStatsComparison(_that.homeTeam,_that.awayTeam,_that.stats,_that.suggestedTemplate);case SocialPost() when socialPost != null:
return socialPost(_that.handle,_that.name,_that.content,_that.timestamp,_that.metrics,_that.verified,_that.followers,_that.shares,_that.bookmarks,_that.mediaType,_that.isEdited,_that.suggestedTemplate);case Rivalry() when rivalry != null:
return rivalry(_that.player1Name,_that.player2Name,_that.matchContext,_that.player1Stats,_that.player2Stats,_that.headToHead,_that.verdict,_that.compareType,_that.totalMatches,_that.draws,_that.player1Trophies,_that.player2Trophies,_that.predictionConfidence,_that.suggestedTemplate);case TableStandings() when tableStandings != null:
return tableStandings(_that.leagueName,_that.matchday,_that.standings,_that.highlightedTeam,_that.promotionZone,_that.relegationZone,_that.gamesInHand,_that.pointsBehindLeader,_that.topScorer,_that.topAssists,_that.suggestedTemplate);case InjuryReport() when injuryReport != null:
return injuryReport(_that.teamName,_that.reportDate,_that.injuries,_that.doubtfits,_that.returns,_that.nextMatch,_that.recoveryPercentage,_that.suggestedTemplate);case ContractExpiry() when contractExpiry != null:
return contractExpiry(_that.teamName,_that.seasonYear,_that.expiringPlayers,_that.renewals,_that.wage,_that.askingPrice,_that.interestLevel,_that.suggestedTemplate);case AwardNominee() when awardNominee != null:
return awardNominee(_that.awardName,_that.category,_that.nominees,_that.ceremonyDate,_that.currentFavorite,_that.votingDeadline,_that.votingMethod,_that.totalNominees,_that.venue,_that.host,_that.suggestedTemplate);case SparseCard() when sparse != null:
return sparse(_that.headline,_that.subtext,_that.microStat,_that.suggestedTemplate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class PlayerSpotlight extends CardData {
  const PlayerSpotlight({required this.playerName, this.club = 'N/A', this.position = 'N/A', this.rating = 0.0, this.goals = 0, this.assists = 0, this.minutesPlayed = 0, this.keyAction = 'N/A', this.keyQuote = 'N/A', this.nationality = 'N/A', this.appearances = 0, this.cleanSheets = 0, this.passes = 0, this.tackles = 0, this.suggestedTemplate,  String? $type}): $type = $type ?? 'playerSpotlight',super._();
  factory PlayerSpotlight.fromJson(Map<String, dynamic> json) => _$PlayerSpotlightFromJson(json);

 final  String playerName;
@JsonKey() final  String club;
@JsonKey() final  String position;
@JsonKey() final  double rating;
@JsonKey() final  int goals;
@JsonKey() final  int assists;
@JsonKey() final  int minutesPlayed;
@JsonKey() final  String keyAction;
@JsonKey() final  String keyQuote;
@JsonKey() final  String nationality;
@JsonKey() final  int appearances;
@JsonKey() final  int cleanSheets;
@JsonKey() final  int passes;
@JsonKey() final  int tackles;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerSpotlightCopyWith<PlayerSpotlight> get copyWith => _$PlayerSpotlightCopyWithImpl<PlayerSpotlight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerSpotlightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerSpotlight&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.club, club) || other.club == club)&&(identical(other.position, position) || other.position == position)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.goals, goals) || other.goals == goals)&&(identical(other.assists, assists) || other.assists == assists)&&(identical(other.minutesPlayed, minutesPlayed) || other.minutesPlayed == minutesPlayed)&&(identical(other.keyAction, keyAction) || other.keyAction == keyAction)&&(identical(other.keyQuote, keyQuote) || other.keyQuote == keyQuote)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.appearances, appearances) || other.appearances == appearances)&&(identical(other.cleanSheets, cleanSheets) || other.cleanSheets == cleanSheets)&&(identical(other.passes, passes) || other.passes == passes)&&(identical(other.tackles, tackles) || other.tackles == tackles)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerName,club,position,rating,goals,assists,minutesPlayed,keyAction,keyQuote,nationality,appearances,cleanSheets,passes,tackles,suggestedTemplate);

@override
String toString() {
  return 'CardData.playerSpotlight(playerName: $playerName, club: $club, position: $position, rating: $rating, goals: $goals, assists: $assists, minutesPlayed: $minutesPlayed, keyAction: $keyAction, keyQuote: $keyQuote, nationality: $nationality, appearances: $appearances, cleanSheets: $cleanSheets, passes: $passes, tackles: $tackles, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $PlayerSpotlightCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $PlayerSpotlightCopyWith(PlayerSpotlight value, $Res Function(PlayerSpotlight) _then) = _$PlayerSpotlightCopyWithImpl;
@override @useResult
$Res call({
 String playerName, String club, String position, double rating, int goals, int assists, int minutesPlayed, String keyAction, String keyQuote, String nationality, int appearances, int cleanSheets, int passes, int tackles, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$PlayerSpotlightCopyWithImpl<$Res>
    implements $PlayerSpotlightCopyWith<$Res> {
  _$PlayerSpotlightCopyWithImpl(this._self, this._then);

  final PlayerSpotlight _self;
  final $Res Function(PlayerSpotlight) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerName = null,Object? club = null,Object? position = null,Object? rating = null,Object? goals = null,Object? assists = null,Object? minutesPlayed = null,Object? keyAction = null,Object? keyQuote = null,Object? nationality = null,Object? appearances = null,Object? cleanSheets = null,Object? passes = null,Object? tackles = null,Object? suggestedTemplate = freezed,}) {
  return _then(PlayerSpotlight(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,club: null == club ? _self.club : club // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,goals: null == goals ? _self.goals : goals // ignore: cast_nullable_to_non_nullable
as int,assists: null == assists ? _self.assists : assists // ignore: cast_nullable_to_non_nullable
as int,minutesPlayed: null == minutesPlayed ? _self.minutesPlayed : minutesPlayed // ignore: cast_nullable_to_non_nullable
as int,keyAction: null == keyAction ? _self.keyAction : keyAction // ignore: cast_nullable_to_non_nullable
as String,keyQuote: null == keyQuote ? _self.keyQuote : keyQuote // ignore: cast_nullable_to_non_nullable
as String,nationality: null == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String,appearances: null == appearances ? _self.appearances : appearances // ignore: cast_nullable_to_non_nullable
as int,cleanSheets: null == cleanSheets ? _self.cleanSheets : cleanSheets // ignore: cast_nullable_to_non_nullable
as int,passes: null == passes ? _self.passes : passes // ignore: cast_nullable_to_non_nullable
as int,tackles: null == tackles ? _self.tackles : tackles // ignore: cast_nullable_to_non_nullable
as int,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class HeadlineQuote extends CardData {
  const HeadlineQuote({required this.headline, required this.subtext, this.quoteAuthor = 'N/A', this.authorTitle = 'N/A', this.category = 'N/A', this.relatedTeams = 'N/A', this.suggestedTemplate,  String? $type}): $type = $type ?? 'headlineQuote',super._();
  factory HeadlineQuote.fromJson(Map<String, dynamic> json) => _$HeadlineQuoteFromJson(json);

 final  String headline;
 final  String subtext;
@JsonKey() final  String quoteAuthor;
@JsonKey() final  String authorTitle;
@JsonKey() final  String category;
@JsonKey() final  String relatedTeams;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeadlineQuoteCopyWith<HeadlineQuote> get copyWith => _$HeadlineQuoteCopyWithImpl<HeadlineQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HeadlineQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeadlineQuote&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.subtext, subtext) || other.subtext == subtext)&&(identical(other.quoteAuthor, quoteAuthor) || other.quoteAuthor == quoteAuthor)&&(identical(other.authorTitle, authorTitle) || other.authorTitle == authorTitle)&&(identical(other.category, category) || other.category == category)&&(identical(other.relatedTeams, relatedTeams) || other.relatedTeams == relatedTeams)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,headline,subtext,quoteAuthor,authorTitle,category,relatedTeams,suggestedTemplate);

@override
String toString() {
  return 'CardData.headlineQuote(headline: $headline, subtext: $subtext, quoteAuthor: $quoteAuthor, authorTitle: $authorTitle, category: $category, relatedTeams: $relatedTeams, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $HeadlineQuoteCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $HeadlineQuoteCopyWith(HeadlineQuote value, $Res Function(HeadlineQuote) _then) = _$HeadlineQuoteCopyWithImpl;
@override @useResult
$Res call({
 String headline, String subtext, String quoteAuthor, String authorTitle, String category, String relatedTeams, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$HeadlineQuoteCopyWithImpl<$Res>
    implements $HeadlineQuoteCopyWith<$Res> {
  _$HeadlineQuoteCopyWithImpl(this._self, this._then);

  final HeadlineQuote _self;
  final $Res Function(HeadlineQuote) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? headline = null,Object? subtext = null,Object? quoteAuthor = null,Object? authorTitle = null,Object? category = null,Object? relatedTeams = null,Object? suggestedTemplate = freezed,}) {
  return _then(HeadlineQuote(
headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,subtext: null == subtext ? _self.subtext : subtext // ignore: cast_nullable_to_non_nullable
as String,quoteAuthor: null == quoteAuthor ? _self.quoteAuthor : quoteAuthor // ignore: cast_nullable_to_non_nullable
as String,authorTitle: null == authorTitle ? _self.authorTitle : authorTitle // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,relatedTeams: null == relatedTeams ? _self.relatedTeams : relatedTeams // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class TopStats extends CardData {
  const TopStats({this.matchContext = 'N/A',  List<StatItem> stats = const [], this.suggestedTemplate,  String? $type}): _stats = stats,$type = $type ?? 'topStats',super._();
  factory TopStats.fromJson(Map<String, dynamic> json) => _$TopStatsFromJson(json);

@JsonKey() final  String matchContext;
 final  List<StatItem> _stats;
@JsonKey() List<StatItem> get stats {
  if (_stats is EqualUnmodifiableListView) return _stats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stats);
}

@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopStatsCopyWith<TopStats> get copyWith => _$TopStatsCopyWithImpl<TopStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TopStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopStats&&(identical(other.matchContext, matchContext) || other.matchContext == matchContext)&&const DeepCollectionEquality().equals(other._stats, _stats)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchContext,const DeepCollectionEquality().hash(_stats),suggestedTemplate);

@override
String toString() {
  return 'CardData.topStats(matchContext: $matchContext, stats: $stats, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $TopStatsCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $TopStatsCopyWith(TopStats value, $Res Function(TopStats) _then) = _$TopStatsCopyWithImpl;
@override @useResult
$Res call({
 String matchContext, List<StatItem> stats, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$TopStatsCopyWithImpl<$Res>
    implements $TopStatsCopyWith<$Res> {
  _$TopStatsCopyWithImpl(this._self, this._then);

  final TopStats _self;
  final $Res Function(TopStats) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchContext = null,Object? stats = null,Object? suggestedTemplate = freezed,}) {
  return _then(TopStats(
matchContext: null == matchContext ? _self.matchContext : matchContext // ignore: cast_nullable_to_non_nullable
as String,stats: null == stats ? _self._stats : stats // ignore: cast_nullable_to_non_nullable
as List<StatItem>,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class TransferNews extends CardData {
  const TransferNews({required this.playerName, this.action = 'N/A', this.fromTeam = 'N/A', this.toTeam = 'N/A', this.fee = 'N/A', this.contractLength = 'N/A', this.transferType = 'N/A', this.quote = 'N/A', this.feeCategory = 'N/A', this.medicalCompleted = false, this.workPermit = false, this.agentName = 'N/A', this.suggestedTemplate,  String? $type}): $type = $type ?? 'transferNews',super._();
  factory TransferNews.fromJson(Map<String, dynamic> json) => _$TransferNewsFromJson(json);

 final  String playerName;
@JsonKey() final  String action;
@JsonKey() final  String fromTeam;
@JsonKey() final  String toTeam;
@JsonKey() final  String fee;
@JsonKey() final  String contractLength;
@JsonKey() final  String transferType;
@JsonKey() final  String quote;
@JsonKey() final  String feeCategory;
@JsonKey() final  bool medicalCompleted;
@JsonKey() final  bool workPermit;
@JsonKey() final  String agentName;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferNewsCopyWith<TransferNews> get copyWith => _$TransferNewsCopyWithImpl<TransferNews>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransferNewsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferNews&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.action, action) || other.action == action)&&(identical(other.fromTeam, fromTeam) || other.fromTeam == fromTeam)&&(identical(other.toTeam, toTeam) || other.toTeam == toTeam)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.contractLength, contractLength) || other.contractLength == contractLength)&&(identical(other.transferType, transferType) || other.transferType == transferType)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.feeCategory, feeCategory) || other.feeCategory == feeCategory)&&(identical(other.medicalCompleted, medicalCompleted) || other.medicalCompleted == medicalCompleted)&&(identical(other.workPermit, workPermit) || other.workPermit == workPermit)&&(identical(other.agentName, agentName) || other.agentName == agentName)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerName,action,fromTeam,toTeam,fee,contractLength,transferType,quote,feeCategory,medicalCompleted,workPermit,agentName,suggestedTemplate);

@override
String toString() {
  return 'CardData.transferNews(playerName: $playerName, action: $action, fromTeam: $fromTeam, toTeam: $toTeam, fee: $fee, contractLength: $contractLength, transferType: $transferType, quote: $quote, feeCategory: $feeCategory, medicalCompleted: $medicalCompleted, workPermit: $workPermit, agentName: $agentName, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $TransferNewsCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $TransferNewsCopyWith(TransferNews value, $Res Function(TransferNews) _then) = _$TransferNewsCopyWithImpl;
@override @useResult
$Res call({
 String playerName, String action, String fromTeam, String toTeam, String fee, String contractLength, String transferType, String quote, String feeCategory, bool medicalCompleted, bool workPermit, String agentName, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$TransferNewsCopyWithImpl<$Res>
    implements $TransferNewsCopyWith<$Res> {
  _$TransferNewsCopyWithImpl(this._self, this._then);

  final TransferNews _self;
  final $Res Function(TransferNews) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerName = null,Object? action = null,Object? fromTeam = null,Object? toTeam = null,Object? fee = null,Object? contractLength = null,Object? transferType = null,Object? quote = null,Object? feeCategory = null,Object? medicalCompleted = null,Object? workPermit = null,Object? agentName = null,Object? suggestedTemplate = freezed,}) {
  return _then(TransferNews(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,fromTeam: null == fromTeam ? _self.fromTeam : fromTeam // ignore: cast_nullable_to_non_nullable
as String,toTeam: null == toTeam ? _self.toTeam : toTeam // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as String,contractLength: null == contractLength ? _self.contractLength : contractLength // ignore: cast_nullable_to_non_nullable
as String,transferType: null == transferType ? _self.transferType : transferType // ignore: cast_nullable_to_non_nullable
as String,quote: null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as String,feeCategory: null == feeCategory ? _self.feeCategory : feeCategory // ignore: cast_nullable_to_non_nullable
as String,medicalCompleted: null == medicalCompleted ? _self.medicalCompleted : medicalCompleted // ignore: cast_nullable_to_non_nullable
as bool,workPermit: null == workPermit ? _self.workPermit : workPermit // ignore: cast_nullable_to_non_nullable
as bool,agentName: null == agentName ? _self.agentName : agentName // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BreakingNews extends CardData {
  const BreakingNews({this.label = '🚨 BREAKING', required this.headline, this.subtext = 'N/A', this.impactRating = 3, this.relatedTeams = 'N/A', this.suggestedTemplate,  String? $type}): $type = $type ?? 'breakingNews',super._();
  factory BreakingNews.fromJson(Map<String, dynamic> json) => _$BreakingNewsFromJson(json);

@JsonKey() final  String label;
 final  String headline;
@JsonKey() final  String subtext;
@JsonKey() final  int impactRating;
@JsonKey() final  String relatedTeams;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreakingNewsCopyWith<BreakingNews> get copyWith => _$BreakingNewsCopyWithImpl<BreakingNews>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BreakingNewsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreakingNews&&(identical(other.label, label) || other.label == label)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.subtext, subtext) || other.subtext == subtext)&&(identical(other.impactRating, impactRating) || other.impactRating == impactRating)&&(identical(other.relatedTeams, relatedTeams) || other.relatedTeams == relatedTeams)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,headline,subtext,impactRating,relatedTeams,suggestedTemplate);

@override
String toString() {
  return 'CardData.breakingNews(label: $label, headline: $headline, subtext: $subtext, impactRating: $impactRating, relatedTeams: $relatedTeams, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $BreakingNewsCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $BreakingNewsCopyWith(BreakingNews value, $Res Function(BreakingNews) _then) = _$BreakingNewsCopyWithImpl;
@override @useResult
$Res call({
 String label, String headline, String subtext, int impactRating, String relatedTeams, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$BreakingNewsCopyWithImpl<$Res>
    implements $BreakingNewsCopyWith<$Res> {
  _$BreakingNewsCopyWithImpl(this._self, this._then);

  final BreakingNews _self;
  final $Res Function(BreakingNews) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? headline = null,Object? subtext = null,Object? impactRating = null,Object? relatedTeams = null,Object? suggestedTemplate = freezed,}) {
  return _then(BreakingNews(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,subtext: null == subtext ? _self.subtext : subtext // ignore: cast_nullable_to_non_nullable
as String,impactRating: null == impactRating ? _self.impactRating : impactRating // ignore: cast_nullable_to_non_nullable
as int,relatedTeams: null == relatedTeams ? _self.relatedTeams : relatedTeams // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MatchPreview extends CardData {
  const MatchPreview({this.competition = 'N/A', required this.homeTeam, required this.awayTeam, this.homeForm = 'N/A', this.awayForm = 'N/A', this.matchTime = 'N/A', this.stadium = 'N/A', this.referee = 'N/A', this.tvChannel = 'N/A', this.kickoffTime = 'N/A', this.weather = 'N/A', this.capacity = 'N/A', this.suggestedTemplate,  String? $type}): $type = $type ?? 'matchPreview',super._();
  factory MatchPreview.fromJson(Map<String, dynamic> json) => _$MatchPreviewFromJson(json);

@JsonKey() final  String competition;
 final  String homeTeam;
 final  String awayTeam;
@JsonKey() final  String homeForm;
@JsonKey() final  String awayForm;
@JsonKey() final  String matchTime;
@JsonKey() final  String stadium;
@JsonKey() final  String referee;
@JsonKey() final  String tvChannel;
@JsonKey() final  String kickoffTime;
@JsonKey() final  String weather;
@JsonKey() final  String capacity;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchPreviewCopyWith<MatchPreview> get copyWith => _$MatchPreviewCopyWithImpl<MatchPreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchPreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchPreview&&(identical(other.competition, competition) || other.competition == competition)&&(identical(other.homeTeam, homeTeam) || other.homeTeam == homeTeam)&&(identical(other.awayTeam, awayTeam) || other.awayTeam == awayTeam)&&(identical(other.homeForm, homeForm) || other.homeForm == homeForm)&&(identical(other.awayForm, awayForm) || other.awayForm == awayForm)&&(identical(other.matchTime, matchTime) || other.matchTime == matchTime)&&(identical(other.stadium, stadium) || other.stadium == stadium)&&(identical(other.referee, referee) || other.referee == referee)&&(identical(other.tvChannel, tvChannel) || other.tvChannel == tvChannel)&&(identical(other.kickoffTime, kickoffTime) || other.kickoffTime == kickoffTime)&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competition,homeTeam,awayTeam,homeForm,awayForm,matchTime,stadium,referee,tvChannel,kickoffTime,weather,capacity,suggestedTemplate);

@override
String toString() {
  return 'CardData.matchPreview(competition: $competition, homeTeam: $homeTeam, awayTeam: $awayTeam, homeForm: $homeForm, awayForm: $awayForm, matchTime: $matchTime, stadium: $stadium, referee: $referee, tvChannel: $tvChannel, kickoffTime: $kickoffTime, weather: $weather, capacity: $capacity, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $MatchPreviewCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $MatchPreviewCopyWith(MatchPreview value, $Res Function(MatchPreview) _then) = _$MatchPreviewCopyWithImpl;
@override @useResult
$Res call({
 String competition, String homeTeam, String awayTeam, String homeForm, String awayForm, String matchTime, String stadium, String referee, String tvChannel, String kickoffTime, String weather, String capacity, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$MatchPreviewCopyWithImpl<$Res>
    implements $MatchPreviewCopyWith<$Res> {
  _$MatchPreviewCopyWithImpl(this._self, this._then);

  final MatchPreview _self;
  final $Res Function(MatchPreview) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competition = null,Object? homeTeam = null,Object? awayTeam = null,Object? homeForm = null,Object? awayForm = null,Object? matchTime = null,Object? stadium = null,Object? referee = null,Object? tvChannel = null,Object? kickoffTime = null,Object? weather = null,Object? capacity = null,Object? suggestedTemplate = freezed,}) {
  return _then(MatchPreview(
competition: null == competition ? _self.competition : competition // ignore: cast_nullable_to_non_nullable
as String,homeTeam: null == homeTeam ? _self.homeTeam : homeTeam // ignore: cast_nullable_to_non_nullable
as String,awayTeam: null == awayTeam ? _self.awayTeam : awayTeam // ignore: cast_nullable_to_non_nullable
as String,homeForm: null == homeForm ? _self.homeForm : homeForm // ignore: cast_nullable_to_non_nullable
as String,awayForm: null == awayForm ? _self.awayForm : awayForm // ignore: cast_nullable_to_non_nullable
as String,matchTime: null == matchTime ? _self.matchTime : matchTime // ignore: cast_nullable_to_non_nullable
as String,stadium: null == stadium ? _self.stadium : stadium // ignore: cast_nullable_to_non_nullable
as String,referee: null == referee ? _self.referee : referee // ignore: cast_nullable_to_non_nullable
as String,tvChannel: null == tvChannel ? _self.tvChannel : tvChannel // ignore: cast_nullable_to_non_nullable
as String,kickoffTime: null == kickoffTime ? _self.kickoffTime : kickoffTime // ignore: cast_nullable_to_non_nullable
as String,weather: null == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class DetailedScoreboard extends CardData {
  const DetailedScoreboard({required this.homeTeam, required this.awayTeam, this.homeScore = 0, this.awayScore = 0, this.homeScorers = 'N/A', this.awayScorers = 'N/A', this.possession = 'N/A', this.shotsOnTarget = 'N/A', this.competition = 'N/A', this.matchStatus = 'N/A', this.corners = 'N/A', this.fouls = 'N/A', this.yellowCards = 'N/A', this.redCards = 'N/A', this.attendance = 'N/A', this.referee = 'N/A', this.penaltyShootout = 'N/A', this.assistProviders = 'N/A', this.suggestedTemplate,  String? $type}): $type = $type ?? 'detailedScoreboard',super._();
  factory DetailedScoreboard.fromJson(Map<String, dynamic> json) => _$DetailedScoreboardFromJson(json);

 final  String homeTeam;
 final  String awayTeam;
@JsonKey() final  int homeScore;
@JsonKey() final  int awayScore;
@JsonKey() final  String homeScorers;
@JsonKey() final  String awayScorers;
@JsonKey() final  String possession;
@JsonKey() final  String shotsOnTarget;
@JsonKey() final  String competition;
@JsonKey() final  String matchStatus;
@JsonKey() final  String corners;
@JsonKey() final  String fouls;
@JsonKey() final  String yellowCards;
@JsonKey() final  String redCards;
@JsonKey() final  String attendance;
@JsonKey() final  String referee;
@JsonKey() final  String penaltyShootout;
@JsonKey() final  String assistProviders;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetailedScoreboardCopyWith<DetailedScoreboard> get copyWith => _$DetailedScoreboardCopyWithImpl<DetailedScoreboard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetailedScoreboardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailedScoreboard&&(identical(other.homeTeam, homeTeam) || other.homeTeam == homeTeam)&&(identical(other.awayTeam, awayTeam) || other.awayTeam == awayTeam)&&(identical(other.homeScore, homeScore) || other.homeScore == homeScore)&&(identical(other.awayScore, awayScore) || other.awayScore == awayScore)&&(identical(other.homeScorers, homeScorers) || other.homeScorers == homeScorers)&&(identical(other.awayScorers, awayScorers) || other.awayScorers == awayScorers)&&(identical(other.possession, possession) || other.possession == possession)&&(identical(other.shotsOnTarget, shotsOnTarget) || other.shotsOnTarget == shotsOnTarget)&&(identical(other.competition, competition) || other.competition == competition)&&(identical(other.matchStatus, matchStatus) || other.matchStatus == matchStatus)&&(identical(other.corners, corners) || other.corners == corners)&&(identical(other.fouls, fouls) || other.fouls == fouls)&&(identical(other.yellowCards, yellowCards) || other.yellowCards == yellowCards)&&(identical(other.redCards, redCards) || other.redCards == redCards)&&(identical(other.attendance, attendance) || other.attendance == attendance)&&(identical(other.referee, referee) || other.referee == referee)&&(identical(other.penaltyShootout, penaltyShootout) || other.penaltyShootout == penaltyShootout)&&(identical(other.assistProviders, assistProviders) || other.assistProviders == assistProviders)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,homeTeam,awayTeam,homeScore,awayScore,homeScorers,awayScorers,possession,shotsOnTarget,competition,matchStatus,corners,fouls,yellowCards,redCards,attendance,referee,penaltyShootout,assistProviders,suggestedTemplate]);

@override
String toString() {
  return 'CardData.detailedScoreboard(homeTeam: $homeTeam, awayTeam: $awayTeam, homeScore: $homeScore, awayScore: $awayScore, homeScorers: $homeScorers, awayScorers: $awayScorers, possession: $possession, shotsOnTarget: $shotsOnTarget, competition: $competition, matchStatus: $matchStatus, corners: $corners, fouls: $fouls, yellowCards: $yellowCards, redCards: $redCards, attendance: $attendance, referee: $referee, penaltyShootout: $penaltyShootout, assistProviders: $assistProviders, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $DetailedScoreboardCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $DetailedScoreboardCopyWith(DetailedScoreboard value, $Res Function(DetailedScoreboard) _then) = _$DetailedScoreboardCopyWithImpl;
@override @useResult
$Res call({
 String homeTeam, String awayTeam, int homeScore, int awayScore, String homeScorers, String awayScorers, String possession, String shotsOnTarget, String competition, String matchStatus, String corners, String fouls, String yellowCards, String redCards, String attendance, String referee, String penaltyShootout, String assistProviders, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$DetailedScoreboardCopyWithImpl<$Res>
    implements $DetailedScoreboardCopyWith<$Res> {
  _$DetailedScoreboardCopyWithImpl(this._self, this._then);

  final DetailedScoreboard _self;
  final $Res Function(DetailedScoreboard) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? homeTeam = null,Object? awayTeam = null,Object? homeScore = null,Object? awayScore = null,Object? homeScorers = null,Object? awayScorers = null,Object? possession = null,Object? shotsOnTarget = null,Object? competition = null,Object? matchStatus = null,Object? corners = null,Object? fouls = null,Object? yellowCards = null,Object? redCards = null,Object? attendance = null,Object? referee = null,Object? penaltyShootout = null,Object? assistProviders = null,Object? suggestedTemplate = freezed,}) {
  return _then(DetailedScoreboard(
homeTeam: null == homeTeam ? _self.homeTeam : homeTeam // ignore: cast_nullable_to_non_nullable
as String,awayTeam: null == awayTeam ? _self.awayTeam : awayTeam // ignore: cast_nullable_to_non_nullable
as String,homeScore: null == homeScore ? _self.homeScore : homeScore // ignore: cast_nullable_to_non_nullable
as int,awayScore: null == awayScore ? _self.awayScore : awayScore // ignore: cast_nullable_to_non_nullable
as int,homeScorers: null == homeScorers ? _self.homeScorers : homeScorers // ignore: cast_nullable_to_non_nullable
as String,awayScorers: null == awayScorers ? _self.awayScorers : awayScorers // ignore: cast_nullable_to_non_nullable
as String,possession: null == possession ? _self.possession : possession // ignore: cast_nullable_to_non_nullable
as String,shotsOnTarget: null == shotsOnTarget ? _self.shotsOnTarget : shotsOnTarget // ignore: cast_nullable_to_non_nullable
as String,competition: null == competition ? _self.competition : competition // ignore: cast_nullable_to_non_nullable
as String,matchStatus: null == matchStatus ? _self.matchStatus : matchStatus // ignore: cast_nullable_to_non_nullable
as String,corners: null == corners ? _self.corners : corners // ignore: cast_nullable_to_non_nullable
as String,fouls: null == fouls ? _self.fouls : fouls // ignore: cast_nullable_to_non_nullable
as String,yellowCards: null == yellowCards ? _self.yellowCards : yellowCards // ignore: cast_nullable_to_non_nullable
as String,redCards: null == redCards ? _self.redCards : redCards // ignore: cast_nullable_to_non_nullable
as String,attendance: null == attendance ? _self.attendance : attendance // ignore: cast_nullable_to_non_nullable
as String,referee: null == referee ? _self.referee : referee // ignore: cast_nullable_to_non_nullable
as String,penaltyShootout: null == penaltyShootout ? _self.penaltyShootout : penaltyShootout // ignore: cast_nullable_to_non_nullable
as String,assistProviders: null == assistProviders ? _self.assistProviders : assistProviders // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class OnThisDay extends CardData {
  const OnThisDay({this.dateLabel = 'N/A', this.yearsAgo = 0, this.competition = 'N/A', this.headline = 'N/A',  List<StatItem> keyStats = const [], this.venue = 'N/A', this.attendance = 'N/A', this.result = 'N/A', this.significance = 'N/A', this.suggestedTemplate,  String? $type}): _keyStats = keyStats,$type = $type ?? 'onThisDay',super._();
  factory OnThisDay.fromJson(Map<String, dynamic> json) => _$OnThisDayFromJson(json);

@JsonKey() final  String dateLabel;
@JsonKey() final  int yearsAgo;
@JsonKey() final  String competition;
@JsonKey() final  String headline;
 final  List<StatItem> _keyStats;
@JsonKey() List<StatItem> get keyStats {
  if (_keyStats is EqualUnmodifiableListView) return _keyStats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keyStats);
}

@JsonKey() final  String venue;
@JsonKey() final  String attendance;
@JsonKey() final  String result;
@JsonKey() final  String significance;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnThisDayCopyWith<OnThisDay> get copyWith => _$OnThisDayCopyWithImpl<OnThisDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OnThisDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnThisDay&&(identical(other.dateLabel, dateLabel) || other.dateLabel == dateLabel)&&(identical(other.yearsAgo, yearsAgo) || other.yearsAgo == yearsAgo)&&(identical(other.competition, competition) || other.competition == competition)&&(identical(other.headline, headline) || other.headline == headline)&&const DeepCollectionEquality().equals(other._keyStats, _keyStats)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.attendance, attendance) || other.attendance == attendance)&&(identical(other.result, result) || other.result == result)&&(identical(other.significance, significance) || other.significance == significance)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dateLabel,yearsAgo,competition,headline,const DeepCollectionEquality().hash(_keyStats),venue,attendance,result,significance,suggestedTemplate);

@override
String toString() {
  return 'CardData.onThisDay(dateLabel: $dateLabel, yearsAgo: $yearsAgo, competition: $competition, headline: $headline, keyStats: $keyStats, venue: $venue, attendance: $attendance, result: $result, significance: $significance, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $OnThisDayCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $OnThisDayCopyWith(OnThisDay value, $Res Function(OnThisDay) _then) = _$OnThisDayCopyWithImpl;
@override @useResult
$Res call({
 String dateLabel, int yearsAgo, String competition, String headline, List<StatItem> keyStats, String venue, String attendance, String result, String significance, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$OnThisDayCopyWithImpl<$Res>
    implements $OnThisDayCopyWith<$Res> {
  _$OnThisDayCopyWithImpl(this._self, this._then);

  final OnThisDay _self;
  final $Res Function(OnThisDay) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dateLabel = null,Object? yearsAgo = null,Object? competition = null,Object? headline = null,Object? keyStats = null,Object? venue = null,Object? attendance = null,Object? result = null,Object? significance = null,Object? suggestedTemplate = freezed,}) {
  return _then(OnThisDay(
dateLabel: null == dateLabel ? _self.dateLabel : dateLabel // ignore: cast_nullable_to_non_nullable
as String,yearsAgo: null == yearsAgo ? _self.yearsAgo : yearsAgo // ignore: cast_nullable_to_non_nullable
as int,competition: null == competition ? _self.competition : competition // ignore: cast_nullable_to_non_nullable
as String,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,keyStats: null == keyStats ? _self._keyStats : keyStats // ignore: cast_nullable_to_non_nullable
as List<StatItem>,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String,attendance: null == attendance ? _self.attendance : attendance // ignore: cast_nullable_to_non_nullable
as String,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,significance: null == significance ? _self.significance : significance // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class StartingXI extends CardData {
  const StartingXI({this.teamName = 'N/A', this.formation = 'N/A',  List<LineupPlayer> starters = const [],  List<LineupPlayer> subs = const [], this.manager = 'N/A', this.averageAge = 'N/A', this.keyAbsences = 'N/A', this.captain = 'N/A', this.viceCaptain = 'N/A', this.tactics = 'N/A', this.injuredPlayers = 'N/A', this.suspendedPlayers = 'N/A', this.suggestedTemplate,  String? $type}): _starters = starters,_subs = subs,$type = $type ?? 'startingXI',super._();
  factory StartingXI.fromJson(Map<String, dynamic> json) => _$StartingXIFromJson(json);

@JsonKey() final  String teamName;
@JsonKey() final  String formation;
 final  List<LineupPlayer> _starters;
@JsonKey() List<LineupPlayer> get starters {
  if (_starters is EqualUnmodifiableListView) return _starters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_starters);
}

 final  List<LineupPlayer> _subs;
@JsonKey() List<LineupPlayer> get subs {
  if (_subs is EqualUnmodifiableListView) return _subs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subs);
}

@JsonKey() final  String manager;
@JsonKey() final  String averageAge;
@JsonKey() final  String keyAbsences;
@JsonKey() final  String captain;
@JsonKey() final  String viceCaptain;
@JsonKey() final  String tactics;
@JsonKey() final  String injuredPlayers;
@JsonKey() final  String suspendedPlayers;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartingXICopyWith<StartingXI> get copyWith => _$StartingXICopyWithImpl<StartingXI>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StartingXIToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartingXI&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.formation, formation) || other.formation == formation)&&const DeepCollectionEquality().equals(other._starters, _starters)&&const DeepCollectionEquality().equals(other._subs, _subs)&&(identical(other.manager, manager) || other.manager == manager)&&(identical(other.averageAge, averageAge) || other.averageAge == averageAge)&&(identical(other.keyAbsences, keyAbsences) || other.keyAbsences == keyAbsences)&&(identical(other.captain, captain) || other.captain == captain)&&(identical(other.viceCaptain, viceCaptain) || other.viceCaptain == viceCaptain)&&(identical(other.tactics, tactics) || other.tactics == tactics)&&(identical(other.injuredPlayers, injuredPlayers) || other.injuredPlayers == injuredPlayers)&&(identical(other.suspendedPlayers, suspendedPlayers) || other.suspendedPlayers == suspendedPlayers)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamName,formation,const DeepCollectionEquality().hash(_starters),const DeepCollectionEquality().hash(_subs),manager,averageAge,keyAbsences,captain,viceCaptain,tactics,injuredPlayers,suspendedPlayers,suggestedTemplate);

@override
String toString() {
  return 'CardData.startingXI(teamName: $teamName, formation: $formation, starters: $starters, subs: $subs, manager: $manager, averageAge: $averageAge, keyAbsences: $keyAbsences, captain: $captain, viceCaptain: $viceCaptain, tactics: $tactics, injuredPlayers: $injuredPlayers, suspendedPlayers: $suspendedPlayers, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $StartingXICopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $StartingXICopyWith(StartingXI value, $Res Function(StartingXI) _then) = _$StartingXICopyWithImpl;
@override @useResult
$Res call({
 String teamName, String formation, List<LineupPlayer> starters, List<LineupPlayer> subs, String manager, String averageAge, String keyAbsences, String captain, String viceCaptain, String tactics, String injuredPlayers, String suspendedPlayers, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$StartingXICopyWithImpl<$Res>
    implements $StartingXICopyWith<$Res> {
  _$StartingXICopyWithImpl(this._self, this._then);

  final StartingXI _self;
  final $Res Function(StartingXI) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamName = null,Object? formation = null,Object? starters = null,Object? subs = null,Object? manager = null,Object? averageAge = null,Object? keyAbsences = null,Object? captain = null,Object? viceCaptain = null,Object? tactics = null,Object? injuredPlayers = null,Object? suspendedPlayers = null,Object? suggestedTemplate = freezed,}) {
  return _then(StartingXI(
teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,formation: null == formation ? _self.formation : formation // ignore: cast_nullable_to_non_nullable
as String,starters: null == starters ? _self._starters : starters // ignore: cast_nullable_to_non_nullable
as List<LineupPlayer>,subs: null == subs ? _self._subs : subs // ignore: cast_nullable_to_non_nullable
as List<LineupPlayer>,manager: null == manager ? _self.manager : manager // ignore: cast_nullable_to_non_nullable
as String,averageAge: null == averageAge ? _self.averageAge : averageAge // ignore: cast_nullable_to_non_nullable
as String,keyAbsences: null == keyAbsences ? _self.keyAbsences : keyAbsences // ignore: cast_nullable_to_non_nullable
as String,captain: null == captain ? _self.captain : captain // ignore: cast_nullable_to_non_nullable
as String,viceCaptain: null == viceCaptain ? _self.viceCaptain : viceCaptain // ignore: cast_nullable_to_non_nullable
as String,tactics: null == tactics ? _self.tactics : tactics // ignore: cast_nullable_to_non_nullable
as String,injuredPlayers: null == injuredPlayers ? _self.injuredPlayers : injuredPlayers // ignore: cast_nullable_to_non_nullable
as String,suspendedPlayers: null == suspendedPlayers ? _self.suspendedPlayers : suspendedPlayers // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MatchStatsComparison extends CardData {
  const MatchStatsComparison({this.homeTeam = 'N/A', this.awayTeam = 'N/A',  List<ComparisonStat> stats = const [], this.suggestedTemplate,  String? $type}): _stats = stats,$type = $type ?? 'matchStatsComparison',super._();
  factory MatchStatsComparison.fromJson(Map<String, dynamic> json) => _$MatchStatsComparisonFromJson(json);

@JsonKey() final  String homeTeam;
@JsonKey() final  String awayTeam;
 final  List<ComparisonStat> _stats;
@JsonKey() List<ComparisonStat> get stats {
  if (_stats is EqualUnmodifiableListView) return _stats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stats);
}

@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchStatsComparisonCopyWith<MatchStatsComparison> get copyWith => _$MatchStatsComparisonCopyWithImpl<MatchStatsComparison>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchStatsComparisonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchStatsComparison&&(identical(other.homeTeam, homeTeam) || other.homeTeam == homeTeam)&&(identical(other.awayTeam, awayTeam) || other.awayTeam == awayTeam)&&const DeepCollectionEquality().equals(other._stats, _stats)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,homeTeam,awayTeam,const DeepCollectionEquality().hash(_stats),suggestedTemplate);

@override
String toString() {
  return 'CardData.matchStatsComparison(homeTeam: $homeTeam, awayTeam: $awayTeam, stats: $stats, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $MatchStatsComparisonCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $MatchStatsComparisonCopyWith(MatchStatsComparison value, $Res Function(MatchStatsComparison) _then) = _$MatchStatsComparisonCopyWithImpl;
@override @useResult
$Res call({
 String homeTeam, String awayTeam, List<ComparisonStat> stats, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$MatchStatsComparisonCopyWithImpl<$Res>
    implements $MatchStatsComparisonCopyWith<$Res> {
  _$MatchStatsComparisonCopyWithImpl(this._self, this._then);

  final MatchStatsComparison _self;
  final $Res Function(MatchStatsComparison) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? homeTeam = null,Object? awayTeam = null,Object? stats = null,Object? suggestedTemplate = freezed,}) {
  return _then(MatchStatsComparison(
homeTeam: null == homeTeam ? _self.homeTeam : homeTeam // ignore: cast_nullable_to_non_nullable
as String,awayTeam: null == awayTeam ? _self.awayTeam : awayTeam // ignore: cast_nullable_to_non_nullable
as String,stats: null == stats ? _self._stats : stats // ignore: cast_nullable_to_non_nullable
as List<ComparisonStat>,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SocialPost extends CardData {
  const SocialPost({this.handle = 'N/A', this.name = 'N/A', this.content = 'N/A', this.timestamp = 'N/A', this.metrics = 'N/A', this.verified = false, this.followers = 'N/A', this.shares = 'N/A', this.bookmarks = 'N/A', this.mediaType = 'N/A', this.isEdited = false, this.suggestedTemplate,  String? $type}): $type = $type ?? 'socialPost',super._();
  factory SocialPost.fromJson(Map<String, dynamic> json) => _$SocialPostFromJson(json);

@JsonKey() final  String handle;
@JsonKey() final  String name;
@JsonKey() final  String content;
@JsonKey() final  String timestamp;
@JsonKey() final  String metrics;
@JsonKey() final  bool verified;
@JsonKey() final  String followers;
@JsonKey() final  String shares;
@JsonKey() final  String bookmarks;
@JsonKey() final  String mediaType;
@JsonKey() final  bool isEdited;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialPostCopyWith<SocialPost> get copyWith => _$SocialPostCopyWithImpl<SocialPost>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocialPostToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialPost&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.metrics, metrics) || other.metrics == metrics)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.shares, shares) || other.shares == shares)&&(identical(other.bookmarks, bookmarks) || other.bookmarks == bookmarks)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,handle,name,content,timestamp,metrics,verified,followers,shares,bookmarks,mediaType,isEdited,suggestedTemplate);

@override
String toString() {
  return 'CardData.socialPost(handle: $handle, name: $name, content: $content, timestamp: $timestamp, metrics: $metrics, verified: $verified, followers: $followers, shares: $shares, bookmarks: $bookmarks, mediaType: $mediaType, isEdited: $isEdited, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $SocialPostCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $SocialPostCopyWith(SocialPost value, $Res Function(SocialPost) _then) = _$SocialPostCopyWithImpl;
@override @useResult
$Res call({
 String handle, String name, String content, String timestamp, String metrics, bool verified, String followers, String shares, String bookmarks, String mediaType, bool isEdited, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$SocialPostCopyWithImpl<$Res>
    implements $SocialPostCopyWith<$Res> {
  _$SocialPostCopyWithImpl(this._self, this._then);

  final SocialPost _self;
  final $Res Function(SocialPost) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? handle = null,Object? name = null,Object? content = null,Object? timestamp = null,Object? metrics = null,Object? verified = null,Object? followers = null,Object? shares = null,Object? bookmarks = null,Object? mediaType = null,Object? isEdited = null,Object? suggestedTemplate = freezed,}) {
  return _then(SocialPost(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as String,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as String,bookmarks: null == bookmarks ? _self.bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Rivalry extends CardData {
  const Rivalry({this.player1Name = 'N/A', this.player2Name = 'N/A', this.matchContext = 'N/A',  List<StatItem> player1Stats = const [],  List<StatItem> player2Stats = const [], this.headToHead = 'N/A', this.verdict = 'N/A', this.compareType = 'N/A', this.totalMatches = 'N/A', this.draws = 'N/A', this.player1Trophies = 'N/A', this.player2Trophies = 'N/A', this.predictionConfidence = 'N/A', this.suggestedTemplate,  String? $type}): _player1Stats = player1Stats,_player2Stats = player2Stats,$type = $type ?? 'rivalry',super._();
  factory Rivalry.fromJson(Map<String, dynamic> json) => _$RivalryFromJson(json);

@JsonKey() final  String player1Name;
@JsonKey() final  String player2Name;
@JsonKey() final  String matchContext;
 final  List<StatItem> _player1Stats;
@JsonKey() List<StatItem> get player1Stats {
  if (_player1Stats is EqualUnmodifiableListView) return _player1Stats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_player1Stats);
}

 final  List<StatItem> _player2Stats;
@JsonKey() List<StatItem> get player2Stats {
  if (_player2Stats is EqualUnmodifiableListView) return _player2Stats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_player2Stats);
}

@JsonKey() final  String headToHead;
@JsonKey() final  String verdict;
@JsonKey() final  String compareType;
@JsonKey() final  String totalMatches;
@JsonKey() final  String draws;
@JsonKey() final  String player1Trophies;
@JsonKey() final  String player2Trophies;
@JsonKey() final  String predictionConfidence;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RivalryCopyWith<Rivalry> get copyWith => _$RivalryCopyWithImpl<Rivalry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RivalryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rivalry&&(identical(other.player1Name, player1Name) || other.player1Name == player1Name)&&(identical(other.player2Name, player2Name) || other.player2Name == player2Name)&&(identical(other.matchContext, matchContext) || other.matchContext == matchContext)&&const DeepCollectionEquality().equals(other._player1Stats, _player1Stats)&&const DeepCollectionEquality().equals(other._player2Stats, _player2Stats)&&(identical(other.headToHead, headToHead) || other.headToHead == headToHead)&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.compareType, compareType) || other.compareType == compareType)&&(identical(other.totalMatches, totalMatches) || other.totalMatches == totalMatches)&&(identical(other.draws, draws) || other.draws == draws)&&(identical(other.player1Trophies, player1Trophies) || other.player1Trophies == player1Trophies)&&(identical(other.player2Trophies, player2Trophies) || other.player2Trophies == player2Trophies)&&(identical(other.predictionConfidence, predictionConfidence) || other.predictionConfidence == predictionConfidence)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,player1Name,player2Name,matchContext,const DeepCollectionEquality().hash(_player1Stats),const DeepCollectionEquality().hash(_player2Stats),headToHead,verdict,compareType,totalMatches,draws,player1Trophies,player2Trophies,predictionConfidence,suggestedTemplate);

@override
String toString() {
  return 'CardData.rivalry(player1Name: $player1Name, player2Name: $player2Name, matchContext: $matchContext, player1Stats: $player1Stats, player2Stats: $player2Stats, headToHead: $headToHead, verdict: $verdict, compareType: $compareType, totalMatches: $totalMatches, draws: $draws, player1Trophies: $player1Trophies, player2Trophies: $player2Trophies, predictionConfidence: $predictionConfidence, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $RivalryCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $RivalryCopyWith(Rivalry value, $Res Function(Rivalry) _then) = _$RivalryCopyWithImpl;
@override @useResult
$Res call({
 String player1Name, String player2Name, String matchContext, List<StatItem> player1Stats, List<StatItem> player2Stats, String headToHead, String verdict, String compareType, String totalMatches, String draws, String player1Trophies, String player2Trophies, String predictionConfidence, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$RivalryCopyWithImpl<$Res>
    implements $RivalryCopyWith<$Res> {
  _$RivalryCopyWithImpl(this._self, this._then);

  final Rivalry _self;
  final $Res Function(Rivalry) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? player1Name = null,Object? player2Name = null,Object? matchContext = null,Object? player1Stats = null,Object? player2Stats = null,Object? headToHead = null,Object? verdict = null,Object? compareType = null,Object? totalMatches = null,Object? draws = null,Object? player1Trophies = null,Object? player2Trophies = null,Object? predictionConfidence = null,Object? suggestedTemplate = freezed,}) {
  return _then(Rivalry(
player1Name: null == player1Name ? _self.player1Name : player1Name // ignore: cast_nullable_to_non_nullable
as String,player2Name: null == player2Name ? _self.player2Name : player2Name // ignore: cast_nullable_to_non_nullable
as String,matchContext: null == matchContext ? _self.matchContext : matchContext // ignore: cast_nullable_to_non_nullable
as String,player1Stats: null == player1Stats ? _self._player1Stats : player1Stats // ignore: cast_nullable_to_non_nullable
as List<StatItem>,player2Stats: null == player2Stats ? _self._player2Stats : player2Stats // ignore: cast_nullable_to_non_nullable
as List<StatItem>,headToHead: null == headToHead ? _self.headToHead : headToHead // ignore: cast_nullable_to_non_nullable
as String,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as String,compareType: null == compareType ? _self.compareType : compareType // ignore: cast_nullable_to_non_nullable
as String,totalMatches: null == totalMatches ? _self.totalMatches : totalMatches // ignore: cast_nullable_to_non_nullable
as String,draws: null == draws ? _self.draws : draws // ignore: cast_nullable_to_non_nullable
as String,player1Trophies: null == player1Trophies ? _self.player1Trophies : player1Trophies // ignore: cast_nullable_to_non_nullable
as String,player2Trophies: null == player2Trophies ? _self.player2Trophies : player2Trophies // ignore: cast_nullable_to_non_nullable
as String,predictionConfidence: null == predictionConfidence ? _self.predictionConfidence : predictionConfidence // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class TableStandings extends CardData {
  const TableStandings({this.leagueName = 'N/A', this.matchday = 'N/A',  List<TableRow> standings = const [], this.highlightedTeam = 'N/A', this.promotionZone = 4, this.relegationZone = 18, this.gamesInHand = 'N/A', this.pointsBehindLeader = 'N/A', this.topScorer = 'N/A', this.topAssists = 'N/A', this.suggestedTemplate,  String? $type}): _standings = standings,$type = $type ?? 'tableStandings',super._();
  factory TableStandings.fromJson(Map<String, dynamic> json) => _$TableStandingsFromJson(json);

@JsonKey() final  String leagueName;
@JsonKey() final  String matchday;
 final  List<TableRow> _standings;
@JsonKey() List<TableRow> get standings {
  if (_standings is EqualUnmodifiableListView) return _standings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_standings);
}

@JsonKey() final  String highlightedTeam;
@JsonKey() final  int promotionZone;
@JsonKey() final  int relegationZone;
@JsonKey() final  String gamesInHand;
@JsonKey() final  String pointsBehindLeader;
@JsonKey() final  String topScorer;
@JsonKey() final  String topAssists;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableStandingsCopyWith<TableStandings> get copyWith => _$TableStandingsCopyWithImpl<TableStandings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TableStandingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TableStandings&&(identical(other.leagueName, leagueName) || other.leagueName == leagueName)&&(identical(other.matchday, matchday) || other.matchday == matchday)&&const DeepCollectionEquality().equals(other._standings, _standings)&&(identical(other.highlightedTeam, highlightedTeam) || other.highlightedTeam == highlightedTeam)&&(identical(other.promotionZone, promotionZone) || other.promotionZone == promotionZone)&&(identical(other.relegationZone, relegationZone) || other.relegationZone == relegationZone)&&(identical(other.gamesInHand, gamesInHand) || other.gamesInHand == gamesInHand)&&(identical(other.pointsBehindLeader, pointsBehindLeader) || other.pointsBehindLeader == pointsBehindLeader)&&(identical(other.topScorer, topScorer) || other.topScorer == topScorer)&&(identical(other.topAssists, topAssists) || other.topAssists == topAssists)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,leagueName,matchday,const DeepCollectionEquality().hash(_standings),highlightedTeam,promotionZone,relegationZone,gamesInHand,pointsBehindLeader,topScorer,topAssists,suggestedTemplate);

@override
String toString() {
  return 'CardData.tableStandings(leagueName: $leagueName, matchday: $matchday, standings: $standings, highlightedTeam: $highlightedTeam, promotionZone: $promotionZone, relegationZone: $relegationZone, gamesInHand: $gamesInHand, pointsBehindLeader: $pointsBehindLeader, topScorer: $topScorer, topAssists: $topAssists, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $TableStandingsCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $TableStandingsCopyWith(TableStandings value, $Res Function(TableStandings) _then) = _$TableStandingsCopyWithImpl;
@override @useResult
$Res call({
 String leagueName, String matchday, List<TableRow> standings, String highlightedTeam, int promotionZone, int relegationZone, String gamesInHand, String pointsBehindLeader, String topScorer, String topAssists, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$TableStandingsCopyWithImpl<$Res>
    implements $TableStandingsCopyWith<$Res> {
  _$TableStandingsCopyWithImpl(this._self, this._then);

  final TableStandings _self;
  final $Res Function(TableStandings) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? leagueName = null,Object? matchday = null,Object? standings = null,Object? highlightedTeam = null,Object? promotionZone = null,Object? relegationZone = null,Object? gamesInHand = null,Object? pointsBehindLeader = null,Object? topScorer = null,Object? topAssists = null,Object? suggestedTemplate = freezed,}) {
  return _then(TableStandings(
leagueName: null == leagueName ? _self.leagueName : leagueName // ignore: cast_nullable_to_non_nullable
as String,matchday: null == matchday ? _self.matchday : matchday // ignore: cast_nullable_to_non_nullable
as String,standings: null == standings ? _self._standings : standings // ignore: cast_nullable_to_non_nullable
as List<TableRow>,highlightedTeam: null == highlightedTeam ? _self.highlightedTeam : highlightedTeam // ignore: cast_nullable_to_non_nullable
as String,promotionZone: null == promotionZone ? _self.promotionZone : promotionZone // ignore: cast_nullable_to_non_nullable
as int,relegationZone: null == relegationZone ? _self.relegationZone : relegationZone // ignore: cast_nullable_to_non_nullable
as int,gamesInHand: null == gamesInHand ? _self.gamesInHand : gamesInHand // ignore: cast_nullable_to_non_nullable
as String,pointsBehindLeader: null == pointsBehindLeader ? _self.pointsBehindLeader : pointsBehindLeader // ignore: cast_nullable_to_non_nullable
as String,topScorer: null == topScorer ? _self.topScorer : topScorer // ignore: cast_nullable_to_non_nullable
as String,topAssists: null == topAssists ? _self.topAssists : topAssists // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class InjuryReport extends CardData {
  const InjuryReport({this.teamName = 'N/A', this.reportDate = 'N/A',  List<InjuryItem> injuries = const [],  List<InjuryItem> doubtfits = const [],  List<InjuryItem> returns = const [], this.nextMatch = 'N/A', this.recoveryPercentage = 'N/A', this.suggestedTemplate,  String? $type}): _injuries = injuries,_doubtfits = doubtfits,_returns = returns,$type = $type ?? 'injuryReport',super._();
  factory InjuryReport.fromJson(Map<String, dynamic> json) => _$InjuryReportFromJson(json);

@JsonKey() final  String teamName;
@JsonKey() final  String reportDate;
 final  List<InjuryItem> _injuries;
@JsonKey() List<InjuryItem> get injuries {
  if (_injuries is EqualUnmodifiableListView) return _injuries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_injuries);
}

 final  List<InjuryItem> _doubtfits;
@JsonKey() List<InjuryItem> get doubtfits {
  if (_doubtfits is EqualUnmodifiableListView) return _doubtfits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_doubtfits);
}

 final  List<InjuryItem> _returns;
@JsonKey() List<InjuryItem> get returns {
  if (_returns is EqualUnmodifiableListView) return _returns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_returns);
}

@JsonKey() final  String nextMatch;
@JsonKey() final  String recoveryPercentage;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InjuryReportCopyWith<InjuryReport> get copyWith => _$InjuryReportCopyWithImpl<InjuryReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InjuryReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InjuryReport&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.reportDate, reportDate) || other.reportDate == reportDate)&&const DeepCollectionEquality().equals(other._injuries, _injuries)&&const DeepCollectionEquality().equals(other._doubtfits, _doubtfits)&&const DeepCollectionEquality().equals(other._returns, _returns)&&(identical(other.nextMatch, nextMatch) || other.nextMatch == nextMatch)&&(identical(other.recoveryPercentage, recoveryPercentage) || other.recoveryPercentage == recoveryPercentage)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamName,reportDate,const DeepCollectionEquality().hash(_injuries),const DeepCollectionEquality().hash(_doubtfits),const DeepCollectionEquality().hash(_returns),nextMatch,recoveryPercentage,suggestedTemplate);

@override
String toString() {
  return 'CardData.injuryReport(teamName: $teamName, reportDate: $reportDate, injuries: $injuries, doubtfits: $doubtfits, returns: $returns, nextMatch: $nextMatch, recoveryPercentage: $recoveryPercentage, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $InjuryReportCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $InjuryReportCopyWith(InjuryReport value, $Res Function(InjuryReport) _then) = _$InjuryReportCopyWithImpl;
@override @useResult
$Res call({
 String teamName, String reportDate, List<InjuryItem> injuries, List<InjuryItem> doubtfits, List<InjuryItem> returns, String nextMatch, String recoveryPercentage, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$InjuryReportCopyWithImpl<$Res>
    implements $InjuryReportCopyWith<$Res> {
  _$InjuryReportCopyWithImpl(this._self, this._then);

  final InjuryReport _self;
  final $Res Function(InjuryReport) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamName = null,Object? reportDate = null,Object? injuries = null,Object? doubtfits = null,Object? returns = null,Object? nextMatch = null,Object? recoveryPercentage = null,Object? suggestedTemplate = freezed,}) {
  return _then(InjuryReport(
teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,reportDate: null == reportDate ? _self.reportDate : reportDate // ignore: cast_nullable_to_non_nullable
as String,injuries: null == injuries ? _self._injuries : injuries // ignore: cast_nullable_to_non_nullable
as List<InjuryItem>,doubtfits: null == doubtfits ? _self._doubtfits : doubtfits // ignore: cast_nullable_to_non_nullable
as List<InjuryItem>,returns: null == returns ? _self._returns : returns // ignore: cast_nullable_to_non_nullable
as List<InjuryItem>,nextMatch: null == nextMatch ? _self.nextMatch : nextMatch // ignore: cast_nullable_to_non_nullable
as String,recoveryPercentage: null == recoveryPercentage ? _self.recoveryPercentage : recoveryPercentage // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ContractExpiry extends CardData {
  const ContractExpiry({this.teamName = 'N/A', this.seasonYear = 'N/A',  List<ContractPlayer> expiringPlayers = const [],  List<ContractPlayer> renewals = const [], this.wage = 'N/A', this.askingPrice = 'N/A', this.interestLevel = 'N/A', this.suggestedTemplate,  String? $type}): _expiringPlayers = expiringPlayers,_renewals = renewals,$type = $type ?? 'contractExpiry',super._();
  factory ContractExpiry.fromJson(Map<String, dynamic> json) => _$ContractExpiryFromJson(json);

@JsonKey() final  String teamName;
@JsonKey() final  String seasonYear;
 final  List<ContractPlayer> _expiringPlayers;
@JsonKey() List<ContractPlayer> get expiringPlayers {
  if (_expiringPlayers is EqualUnmodifiableListView) return _expiringPlayers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expiringPlayers);
}

 final  List<ContractPlayer> _renewals;
@JsonKey() List<ContractPlayer> get renewals {
  if (_renewals is EqualUnmodifiableListView) return _renewals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_renewals);
}

@JsonKey() final  String wage;
@JsonKey() final  String askingPrice;
@JsonKey() final  String interestLevel;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractExpiryCopyWith<ContractExpiry> get copyWith => _$ContractExpiryCopyWithImpl<ContractExpiry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractExpiryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractExpiry&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.seasonYear, seasonYear) || other.seasonYear == seasonYear)&&const DeepCollectionEquality().equals(other._expiringPlayers, _expiringPlayers)&&const DeepCollectionEquality().equals(other._renewals, _renewals)&&(identical(other.wage, wage) || other.wage == wage)&&(identical(other.askingPrice, askingPrice) || other.askingPrice == askingPrice)&&(identical(other.interestLevel, interestLevel) || other.interestLevel == interestLevel)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamName,seasonYear,const DeepCollectionEquality().hash(_expiringPlayers),const DeepCollectionEquality().hash(_renewals),wage,askingPrice,interestLevel,suggestedTemplate);

@override
String toString() {
  return 'CardData.contractExpiry(teamName: $teamName, seasonYear: $seasonYear, expiringPlayers: $expiringPlayers, renewals: $renewals, wage: $wage, askingPrice: $askingPrice, interestLevel: $interestLevel, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $ContractExpiryCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $ContractExpiryCopyWith(ContractExpiry value, $Res Function(ContractExpiry) _then) = _$ContractExpiryCopyWithImpl;
@override @useResult
$Res call({
 String teamName, String seasonYear, List<ContractPlayer> expiringPlayers, List<ContractPlayer> renewals, String wage, String askingPrice, String interestLevel, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$ContractExpiryCopyWithImpl<$Res>
    implements $ContractExpiryCopyWith<$Res> {
  _$ContractExpiryCopyWithImpl(this._self, this._then);

  final ContractExpiry _self;
  final $Res Function(ContractExpiry) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamName = null,Object? seasonYear = null,Object? expiringPlayers = null,Object? renewals = null,Object? wage = null,Object? askingPrice = null,Object? interestLevel = null,Object? suggestedTemplate = freezed,}) {
  return _then(ContractExpiry(
teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,seasonYear: null == seasonYear ? _self.seasonYear : seasonYear // ignore: cast_nullable_to_non_nullable
as String,expiringPlayers: null == expiringPlayers ? _self._expiringPlayers : expiringPlayers // ignore: cast_nullable_to_non_nullable
as List<ContractPlayer>,renewals: null == renewals ? _self._renewals : renewals // ignore: cast_nullable_to_non_nullable
as List<ContractPlayer>,wage: null == wage ? _self.wage : wage // ignore: cast_nullable_to_non_nullable
as String,askingPrice: null == askingPrice ? _self.askingPrice : askingPrice // ignore: cast_nullable_to_non_nullable
as String,interestLevel: null == interestLevel ? _self.interestLevel : interestLevel // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class AwardNominee extends CardData {
  const AwardNominee({this.awardName = 'N/A', this.category = 'N/A',  List<NomineeItem> nominees = const [], this.ceremonyDate = 'N/A', this.currentFavorite = 'N/A', this.votingDeadline = 'N/A', this.votingMethod = 'N/A', this.totalNominees = 0, this.venue = 'N/A', this.host = 'N/A', this.suggestedTemplate,  String? $type}): _nominees = nominees,$type = $type ?? 'awardNominee',super._();
  factory AwardNominee.fromJson(Map<String, dynamic> json) => _$AwardNomineeFromJson(json);

@JsonKey() final  String awardName;
@JsonKey() final  String category;
 final  List<NomineeItem> _nominees;
@JsonKey() List<NomineeItem> get nominees {
  if (_nominees is EqualUnmodifiableListView) return _nominees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nominees);
}

@JsonKey() final  String ceremonyDate;
@JsonKey() final  String currentFavorite;
@JsonKey() final  String votingDeadline;
@JsonKey() final  String votingMethod;
@JsonKey() final  int totalNominees;
@JsonKey() final  String venue;
@JsonKey() final  String host;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AwardNomineeCopyWith<AwardNominee> get copyWith => _$AwardNomineeCopyWithImpl<AwardNominee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AwardNomineeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AwardNominee&&(identical(other.awardName, awardName) || other.awardName == awardName)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._nominees, _nominees)&&(identical(other.ceremonyDate, ceremonyDate) || other.ceremonyDate == ceremonyDate)&&(identical(other.currentFavorite, currentFavorite) || other.currentFavorite == currentFavorite)&&(identical(other.votingDeadline, votingDeadline) || other.votingDeadline == votingDeadline)&&(identical(other.votingMethod, votingMethod) || other.votingMethod == votingMethod)&&(identical(other.totalNominees, totalNominees) || other.totalNominees == totalNominees)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.host, host) || other.host == host)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,awardName,category,const DeepCollectionEquality().hash(_nominees),ceremonyDate,currentFavorite,votingDeadline,votingMethod,totalNominees,venue,host,suggestedTemplate);

@override
String toString() {
  return 'CardData.awardNominee(awardName: $awardName, category: $category, nominees: $nominees, ceremonyDate: $ceremonyDate, currentFavorite: $currentFavorite, votingDeadline: $votingDeadline, votingMethod: $votingMethod, totalNominees: $totalNominees, venue: $venue, host: $host, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $AwardNomineeCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $AwardNomineeCopyWith(AwardNominee value, $Res Function(AwardNominee) _then) = _$AwardNomineeCopyWithImpl;
@override @useResult
$Res call({
 String awardName, String category, List<NomineeItem> nominees, String ceremonyDate, String currentFavorite, String votingDeadline, String votingMethod, int totalNominees, String venue, String host, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$AwardNomineeCopyWithImpl<$Res>
    implements $AwardNomineeCopyWith<$Res> {
  _$AwardNomineeCopyWithImpl(this._self, this._then);

  final AwardNominee _self;
  final $Res Function(AwardNominee) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? awardName = null,Object? category = null,Object? nominees = null,Object? ceremonyDate = null,Object? currentFavorite = null,Object? votingDeadline = null,Object? votingMethod = null,Object? totalNominees = null,Object? venue = null,Object? host = null,Object? suggestedTemplate = freezed,}) {
  return _then(AwardNominee(
awardName: null == awardName ? _self.awardName : awardName // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,nominees: null == nominees ? _self._nominees : nominees // ignore: cast_nullable_to_non_nullable
as List<NomineeItem>,ceremonyDate: null == ceremonyDate ? _self.ceremonyDate : ceremonyDate // ignore: cast_nullable_to_non_nullable
as String,currentFavorite: null == currentFavorite ? _self.currentFavorite : currentFavorite // ignore: cast_nullable_to_non_nullable
as String,votingDeadline: null == votingDeadline ? _self.votingDeadline : votingDeadline // ignore: cast_nullable_to_non_nullable
as String,votingMethod: null == votingMethod ? _self.votingMethod : votingMethod // ignore: cast_nullable_to_non_nullable
as String,totalNominees: null == totalNominees ? _self.totalNominees : totalNominees // ignore: cast_nullable_to_non_nullable
as int,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SparseCard extends CardData {
  const SparseCard({this.headline = 'Generated Card', this.subtext = '', this.microStat, this.suggestedTemplate,  String? $type}): $type = $type ?? 'sparse',super._();
  factory SparseCard.fromJson(Map<String, dynamic> json) => _$SparseCardFromJson(json);

@JsonKey() final  String headline;
@JsonKey() final  String subtext;
 final  String? microStat;
@override final  CardTemplate? suggestedTemplate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SparseCardCopyWith<SparseCard> get copyWith => _$SparseCardCopyWithImpl<SparseCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SparseCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SparseCard&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.subtext, subtext) || other.subtext == subtext)&&(identical(other.microStat, microStat) || other.microStat == microStat)&&(identical(other.suggestedTemplate, suggestedTemplate) || other.suggestedTemplate == suggestedTemplate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,headline,subtext,microStat,suggestedTemplate);

@override
String toString() {
  return 'CardData.sparse(headline: $headline, subtext: $subtext, microStat: $microStat, suggestedTemplate: $suggestedTemplate)';
}


}

/// @nodoc
abstract mixin class $SparseCardCopyWith<$Res> implements $CardDataCopyWith<$Res> {
  factory $SparseCardCopyWith(SparseCard value, $Res Function(SparseCard) _then) = _$SparseCardCopyWithImpl;
@override @useResult
$Res call({
 String headline, String subtext, String? microStat, CardTemplate? suggestedTemplate
});




}
/// @nodoc
class _$SparseCardCopyWithImpl<$Res>
    implements $SparseCardCopyWith<$Res> {
  _$SparseCardCopyWithImpl(this._self, this._then);

  final SparseCard _self;
  final $Res Function(SparseCard) _then;

/// Create a copy of CardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? headline = null,Object? subtext = null,Object? microStat = freezed,Object? suggestedTemplate = freezed,}) {
  return _then(SparseCard(
headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,subtext: null == subtext ? _self.subtext : subtext // ignore: cast_nullable_to_non_nullable
as String,microStat: freezed == microStat ? _self.microStat : microStat // ignore: cast_nullable_to_non_nullable
as String?,suggestedTemplate: freezed == suggestedTemplate ? _self.suggestedTemplate : suggestedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate?,
  ));
}


}

// dart format on
