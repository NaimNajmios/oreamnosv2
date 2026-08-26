// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tavily_search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TavilySearchResponse {

 String get query; List<TavilySearchResult> get results; String get answer;
/// Create a copy of TavilySearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TavilySearchResponseCopyWith<TavilySearchResponse> get copyWith => _$TavilySearchResponseCopyWithImpl<TavilySearchResponse>(this as TavilySearchResponse, _$identity);

  /// Serializes this TavilySearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TavilySearchResponse&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.answer, answer) || other.answer == answer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(results),answer);

@override
String toString() {
  return 'TavilySearchResponse(query: $query, results: $results, answer: $answer)';
}


}

/// @nodoc
abstract mixin class $TavilySearchResponseCopyWith<$Res>  {
  factory $TavilySearchResponseCopyWith(TavilySearchResponse value, $Res Function(TavilySearchResponse) _then) = _$TavilySearchResponseCopyWithImpl;
@useResult
$Res call({
 String query, List<TavilySearchResult> results, String answer
});




}
/// @nodoc
class _$TavilySearchResponseCopyWithImpl<$Res>
    implements $TavilySearchResponseCopyWith<$Res> {
  _$TavilySearchResponseCopyWithImpl(this._self, this._then);

  final TavilySearchResponse _self;
  final $Res Function(TavilySearchResponse) _then;

/// Create a copy of TavilySearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? results = null,Object? answer = null,}) {
  return _then(TavilySearchResponse(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<TavilySearchResult>,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TavilySearchResponse].
extension TavilySearchResponsePatterns on TavilySearchResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TavilySearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TavilySearchResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TavilySearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _TavilySearchResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TavilySearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TavilySearchResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  List<TavilySearchResult> results,  String answer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TavilySearchResponse() when $default != null:
return $default(_that.query,_that.results,_that.answer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  List<TavilySearchResult> results,  String answer)  $default,) {final _that = this;
switch (_that) {
case _TavilySearchResponse():
return $default(_that.query,_that.results,_that.answer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  List<TavilySearchResult> results,  String answer)?  $default,) {final _that = this;
switch (_that) {
case _TavilySearchResponse() when $default != null:
return $default(_that.query,_that.results,_that.answer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TavilySearchResponse implements TavilySearchResponse {
  const _TavilySearchResponse({required this.query, required  List<TavilySearchResult> results, this.answer = ''}): _results = results;
  factory _TavilySearchResponse.fromJson(Map<String, dynamic> json) => _$TavilySearchResponseFromJson(json);

@override final  String query;
 final  List<TavilySearchResult> _results;
@override List<TavilySearchResult> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override@JsonKey() final  String answer;

/// Create a copy of TavilySearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TavilySearchResponseCopyWith<_TavilySearchResponse> get copyWith => __$TavilySearchResponseCopyWithImpl<_TavilySearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TavilySearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TavilySearchResponse&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.answer, answer) || other.answer == answer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_results),answer);

@override
String toString() {
  return 'TavilySearchResponse(query: $query, results: $results, answer: $answer)';
}


}

/// @nodoc
abstract mixin class _$TavilySearchResponseCopyWith<$Res> implements $TavilySearchResponseCopyWith<$Res> {
  factory _$TavilySearchResponseCopyWith(_TavilySearchResponse value, $Res Function(_TavilySearchResponse) _then) = __$TavilySearchResponseCopyWithImpl;
@override @useResult
$Res call({
 String query, List<TavilySearchResult> results, String answer
});




}
/// @nodoc
class __$TavilySearchResponseCopyWithImpl<$Res>
    implements _$TavilySearchResponseCopyWith<$Res> {
  __$TavilySearchResponseCopyWithImpl(this._self, this._then);

  final _TavilySearchResponse _self;
  final $Res Function(_TavilySearchResponse) _then;

/// Create a copy of TavilySearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? results = null,Object? answer = null,}) {
  return _then(_TavilySearchResponse(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<TavilySearchResult>,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TavilySearchResult {

 String get title; String get url; String get content; double get score;
/// Create a copy of TavilySearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TavilySearchResultCopyWith<TavilySearchResult> get copyWith => _$TavilySearchResultCopyWithImpl<TavilySearchResult>(this as TavilySearchResult, _$identity);

  /// Serializes this TavilySearchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TavilySearchResult&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.content, content) || other.content == content)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,url,content,score);

@override
String toString() {
  return 'TavilySearchResult(title: $title, url: $url, content: $content, score: $score)';
}


}

/// @nodoc
abstract mixin class $TavilySearchResultCopyWith<$Res>  {
  factory $TavilySearchResultCopyWith(TavilySearchResult value, $Res Function(TavilySearchResult) _then) = _$TavilySearchResultCopyWithImpl;
@useResult
$Res call({
 String title, String url, String content, double score
});




}
/// @nodoc
class _$TavilySearchResultCopyWithImpl<$Res>
    implements $TavilySearchResultCopyWith<$Res> {
  _$TavilySearchResultCopyWithImpl(this._self, this._then);

  final TavilySearchResult _self;
  final $Res Function(TavilySearchResult) _then;

/// Create a copy of TavilySearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? url = null,Object? content = null,Object? score = null,}) {
  return _then(TavilySearchResult(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TavilySearchResult].
extension TavilySearchResultPatterns on TavilySearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TavilySearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TavilySearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TavilySearchResult value)  $default,){
final _that = this;
switch (_that) {
case _TavilySearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TavilySearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _TavilySearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String url,  String content,  double score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TavilySearchResult() when $default != null:
return $default(_that.title,_that.url,_that.content,_that.score);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String url,  String content,  double score)  $default,) {final _that = this;
switch (_that) {
case _TavilySearchResult():
return $default(_that.title,_that.url,_that.content,_that.score);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String url,  String content,  double score)?  $default,) {final _that = this;
switch (_that) {
case _TavilySearchResult() when $default != null:
return $default(_that.title,_that.url,_that.content,_that.score);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TavilySearchResult implements TavilySearchResult {
  const _TavilySearchResult({required this.title, required this.url, required this.content, this.score = 0.0});
  factory _TavilySearchResult.fromJson(Map<String, dynamic> json) => _$TavilySearchResultFromJson(json);

@override final  String title;
@override final  String url;
@override final  String content;
@override@JsonKey() final  double score;

/// Create a copy of TavilySearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TavilySearchResultCopyWith<_TavilySearchResult> get copyWith => __$TavilySearchResultCopyWithImpl<_TavilySearchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TavilySearchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TavilySearchResult&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.content, content) || other.content == content)&&(identical(other.score, score) || other.score == score));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,url,content,score);

@override
String toString() {
  return 'TavilySearchResult(title: $title, url: $url, content: $content, score: $score)';
}


}

/// @nodoc
abstract mixin class _$TavilySearchResultCopyWith<$Res> implements $TavilySearchResultCopyWith<$Res> {
  factory _$TavilySearchResultCopyWith(_TavilySearchResult value, $Res Function(_TavilySearchResult) _then) = __$TavilySearchResultCopyWithImpl;
@override @useResult
$Res call({
 String title, String url, String content, double score
});




}
/// @nodoc
class __$TavilySearchResultCopyWithImpl<$Res>
    implements _$TavilySearchResultCopyWith<$Res> {
  __$TavilySearchResultCopyWithImpl(this._self, this._then);

  final _TavilySearchResult _self;
  final $Res Function(_TavilySearchResult) _then;

/// Create a copy of TavilySearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? url = null,Object? content = null,Object? score = null,}) {
  return _then(_TavilySearchResult(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
