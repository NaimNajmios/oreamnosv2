// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_generator_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CardGeneratorState {

 CardBrief? get brief; CardData? get cardData; bool get isExtracting; String? get extractionError; CardTemplate get selectedTemplate; CardRatio get selectedRatio; AppFont get selectedFont; double get headlineScale; bool get templateCompact; String? get activePanel; String? get focusedField; File? get backgroundImage; double get scrimOpacity; bool get useVignette; bool get useAutoPalette; List<Color>? get extractedPalette; Set<String> get rewritingFields; String? get rewriteError; String? get watermarkText; bool get showWatermark; Offset get headlineOffset; Offset get subtextOffset; Offset get microStatOffset; List<CardConfigSnapshot> get undoStack; List<CardConfigSnapshot> get redoStack;
/// Create a copy of CardGeneratorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardGeneratorStateCopyWith<CardGeneratorState> get copyWith => _$CardGeneratorStateCopyWithImpl<CardGeneratorState>(this as CardGeneratorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardGeneratorState&&(identical(other.brief, brief) || other.brief == brief)&&(identical(other.cardData, cardData) || other.cardData == cardData)&&(identical(other.isExtracting, isExtracting) || other.isExtracting == isExtracting)&&(identical(other.extractionError, extractionError) || other.extractionError == extractionError)&&(identical(other.selectedTemplate, selectedTemplate) || other.selectedTemplate == selectedTemplate)&&(identical(other.selectedRatio, selectedRatio) || other.selectedRatio == selectedRatio)&&(identical(other.selectedFont, selectedFont) || other.selectedFont == selectedFont)&&(identical(other.headlineScale, headlineScale) || other.headlineScale == headlineScale)&&(identical(other.templateCompact, templateCompact) || other.templateCompact == templateCompact)&&(identical(other.activePanel, activePanel) || other.activePanel == activePanel)&&(identical(other.focusedField, focusedField) || other.focusedField == focusedField)&&(identical(other.backgroundImage, backgroundImage) || other.backgroundImage == backgroundImage)&&(identical(other.scrimOpacity, scrimOpacity) || other.scrimOpacity == scrimOpacity)&&(identical(other.useVignette, useVignette) || other.useVignette == useVignette)&&(identical(other.useAutoPalette, useAutoPalette) || other.useAutoPalette == useAutoPalette)&&const DeepCollectionEquality().equals(other.extractedPalette, extractedPalette)&&const DeepCollectionEquality().equals(other.rewritingFields, rewritingFields)&&(identical(other.rewriteError, rewriteError) || other.rewriteError == rewriteError)&&(identical(other.watermarkText, watermarkText) || other.watermarkText == watermarkText)&&(identical(other.showWatermark, showWatermark) || other.showWatermark == showWatermark)&&(identical(other.headlineOffset, headlineOffset) || other.headlineOffset == headlineOffset)&&(identical(other.subtextOffset, subtextOffset) || other.subtextOffset == subtextOffset)&&(identical(other.microStatOffset, microStatOffset) || other.microStatOffset == microStatOffset)&&const DeepCollectionEquality().equals(other.undoStack, undoStack)&&const DeepCollectionEquality().equals(other.redoStack, redoStack));
}


@override
int get hashCode => Object.hashAll([runtimeType,brief,cardData,isExtracting,extractionError,selectedTemplate,selectedRatio,selectedFont,headlineScale,templateCompact,activePanel,focusedField,backgroundImage,scrimOpacity,useVignette,useAutoPalette,const DeepCollectionEquality().hash(extractedPalette),const DeepCollectionEquality().hash(rewritingFields),rewriteError,watermarkText,showWatermark,headlineOffset,subtextOffset,microStatOffset,const DeepCollectionEquality().hash(undoStack),const DeepCollectionEquality().hash(redoStack)]);

@override
String toString() {
  return 'CardGeneratorState(brief: $brief, cardData: $cardData, isExtracting: $isExtracting, extractionError: $extractionError, selectedTemplate: $selectedTemplate, selectedRatio: $selectedRatio, selectedFont: $selectedFont, headlineScale: $headlineScale, templateCompact: $templateCompact, activePanel: $activePanel, focusedField: $focusedField, backgroundImage: $backgroundImage, scrimOpacity: $scrimOpacity, useVignette: $useVignette, useAutoPalette: $useAutoPalette, extractedPalette: $extractedPalette, rewritingFields: $rewritingFields, rewriteError: $rewriteError, watermarkText: $watermarkText, showWatermark: $showWatermark, headlineOffset: $headlineOffset, subtextOffset: $subtextOffset, microStatOffset: $microStatOffset, undoStack: $undoStack, redoStack: $redoStack)';
}


}

/// @nodoc
abstract mixin class $CardGeneratorStateCopyWith<$Res>  {
  factory $CardGeneratorStateCopyWith(CardGeneratorState value, $Res Function(CardGeneratorState) _then) = _$CardGeneratorStateCopyWithImpl;
@useResult
$Res call({
 CardBrief? brief, CardData? cardData, bool isExtracting, String? extractionError, CardTemplate selectedTemplate, CardRatio selectedRatio, AppFont selectedFont, double headlineScale, bool templateCompact, String? activePanel, String? focusedField, File? backgroundImage, double scrimOpacity, bool useVignette, bool useAutoPalette, List<Color>? extractedPalette, Set<String> rewritingFields, String? rewriteError, String? watermarkText, bool showWatermark, Offset headlineOffset, Offset subtextOffset, Offset microStatOffset, List<CardConfigSnapshot> undoStack, List<CardConfigSnapshot> redoStack
});


$CardDataCopyWith<$Res>? get cardData;

}
/// @nodoc
class _$CardGeneratorStateCopyWithImpl<$Res>
    implements $CardGeneratorStateCopyWith<$Res> {
  _$CardGeneratorStateCopyWithImpl(this._self, this._then);

  final CardGeneratorState _self;
  final $Res Function(CardGeneratorState) _then;

/// Create a copy of CardGeneratorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? brief = freezed,Object? cardData = freezed,Object? isExtracting = null,Object? extractionError = freezed,Object? selectedTemplate = null,Object? selectedRatio = null,Object? selectedFont = null,Object? headlineScale = null,Object? templateCompact = null,Object? activePanel = freezed,Object? focusedField = freezed,Object? backgroundImage = freezed,Object? scrimOpacity = null,Object? useVignette = null,Object? useAutoPalette = null,Object? extractedPalette = freezed,Object? rewritingFields = null,Object? rewriteError = freezed,Object? watermarkText = freezed,Object? showWatermark = null,Object? headlineOffset = null,Object? subtextOffset = null,Object? microStatOffset = null,Object? undoStack = null,Object? redoStack = null,}) {
  return _then(CardGeneratorState(
brief: freezed == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as CardBrief?,cardData: freezed == cardData ? _self.cardData : cardData // ignore: cast_nullable_to_non_nullable
as CardData?,isExtracting: null == isExtracting ? _self.isExtracting : isExtracting // ignore: cast_nullable_to_non_nullable
as bool,extractionError: freezed == extractionError ? _self.extractionError : extractionError // ignore: cast_nullable_to_non_nullable
as String?,selectedTemplate: null == selectedTemplate ? _self.selectedTemplate : selectedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate,selectedRatio: null == selectedRatio ? _self.selectedRatio : selectedRatio // ignore: cast_nullable_to_non_nullable
as CardRatio,selectedFont: null == selectedFont ? _self.selectedFont : selectedFont // ignore: cast_nullable_to_non_nullable
as AppFont,headlineScale: null == headlineScale ? _self.headlineScale : headlineScale // ignore: cast_nullable_to_non_nullable
as double,templateCompact: null == templateCompact ? _self.templateCompact : templateCompact // ignore: cast_nullable_to_non_nullable
as bool,activePanel: freezed == activePanel ? _self.activePanel : activePanel // ignore: cast_nullable_to_non_nullable
as String?,focusedField: freezed == focusedField ? _self.focusedField : focusedField // ignore: cast_nullable_to_non_nullable
as String?,backgroundImage: freezed == backgroundImage ? _self.backgroundImage : backgroundImage // ignore: cast_nullable_to_non_nullable
as File?,scrimOpacity: null == scrimOpacity ? _self.scrimOpacity : scrimOpacity // ignore: cast_nullable_to_non_nullable
as double,useVignette: null == useVignette ? _self.useVignette : useVignette // ignore: cast_nullable_to_non_nullable
as bool,useAutoPalette: null == useAutoPalette ? _self.useAutoPalette : useAutoPalette // ignore: cast_nullable_to_non_nullable
as bool,extractedPalette: freezed == extractedPalette ? _self.extractedPalette : extractedPalette // ignore: cast_nullable_to_non_nullable
as List<Color>?,rewritingFields: null == rewritingFields ? _self.rewritingFields : rewritingFields // ignore: cast_nullable_to_non_nullable
as Set<String>,rewriteError: freezed == rewriteError ? _self.rewriteError : rewriteError // ignore: cast_nullable_to_non_nullable
as String?,watermarkText: freezed == watermarkText ? _self.watermarkText : watermarkText // ignore: cast_nullable_to_non_nullable
as String?,showWatermark: null == showWatermark ? _self.showWatermark : showWatermark // ignore: cast_nullable_to_non_nullable
as bool,headlineOffset: null == headlineOffset ? _self.headlineOffset : headlineOffset // ignore: cast_nullable_to_non_nullable
as Offset,subtextOffset: null == subtextOffset ? _self.subtextOffset : subtextOffset // ignore: cast_nullable_to_non_nullable
as Offset,microStatOffset: null == microStatOffset ? _self.microStatOffset : microStatOffset // ignore: cast_nullable_to_non_nullable
as Offset,undoStack: null == undoStack ? _self.undoStack : undoStack // ignore: cast_nullable_to_non_nullable
as List<CardConfigSnapshot>,redoStack: null == redoStack ? _self.redoStack : redoStack // ignore: cast_nullable_to_non_nullable
as List<CardConfigSnapshot>,
  ));
}
/// Create a copy of CardGeneratorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardDataCopyWith<$Res>? get cardData {
    if (_self.cardData == null) {
    return null;
  }

  return $CardDataCopyWith<$Res>(_self.cardData!, (value) {
    return _then(_self.copyWith(cardData: value));
  });
}
}


/// Adds pattern-matching-related methods to [CardGeneratorState].
extension CardGeneratorStatePatterns on CardGeneratorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardGeneratorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardGeneratorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardGeneratorState value)  $default,){
final _that = this;
switch (_that) {
case _CardGeneratorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardGeneratorState value)?  $default,){
final _that = this;
switch (_that) {
case _CardGeneratorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CardBrief? brief,  CardData? cardData,  bool isExtracting,  String? extractionError,  CardTemplate selectedTemplate,  CardRatio selectedRatio,  AppFont selectedFont,  double headlineScale,  bool templateCompact,  String? activePanel,  String? focusedField,  File? backgroundImage,  double scrimOpacity,  bool useVignette,  bool useAutoPalette,  List<Color>? extractedPalette,  Set<String> rewritingFields,  String? rewriteError,  String? watermarkText,  bool showWatermark,  Offset headlineOffset,  Offset subtextOffset,  Offset microStatOffset,  List<CardConfigSnapshot> undoStack,  List<CardConfigSnapshot> redoStack)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardGeneratorState() when $default != null:
return $default(_that.brief,_that.cardData,_that.isExtracting,_that.extractionError,_that.selectedTemplate,_that.selectedRatio,_that.selectedFont,_that.headlineScale,_that.templateCompact,_that.activePanel,_that.focusedField,_that.backgroundImage,_that.scrimOpacity,_that.useVignette,_that.useAutoPalette,_that.extractedPalette,_that.rewritingFields,_that.rewriteError,_that.watermarkText,_that.showWatermark,_that.headlineOffset,_that.subtextOffset,_that.microStatOffset,_that.undoStack,_that.redoStack);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CardBrief? brief,  CardData? cardData,  bool isExtracting,  String? extractionError,  CardTemplate selectedTemplate,  CardRatio selectedRatio,  AppFont selectedFont,  double headlineScale,  bool templateCompact,  String? activePanel,  String? focusedField,  File? backgroundImage,  double scrimOpacity,  bool useVignette,  bool useAutoPalette,  List<Color>? extractedPalette,  Set<String> rewritingFields,  String? rewriteError,  String? watermarkText,  bool showWatermark,  Offset headlineOffset,  Offset subtextOffset,  Offset microStatOffset,  List<CardConfigSnapshot> undoStack,  List<CardConfigSnapshot> redoStack)  $default,) {final _that = this;
switch (_that) {
case _CardGeneratorState():
return $default(_that.brief,_that.cardData,_that.isExtracting,_that.extractionError,_that.selectedTemplate,_that.selectedRatio,_that.selectedFont,_that.headlineScale,_that.templateCompact,_that.activePanel,_that.focusedField,_that.backgroundImage,_that.scrimOpacity,_that.useVignette,_that.useAutoPalette,_that.extractedPalette,_that.rewritingFields,_that.rewriteError,_that.watermarkText,_that.showWatermark,_that.headlineOffset,_that.subtextOffset,_that.microStatOffset,_that.undoStack,_that.redoStack);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CardBrief? brief,  CardData? cardData,  bool isExtracting,  String? extractionError,  CardTemplate selectedTemplate,  CardRatio selectedRatio,  AppFont selectedFont,  double headlineScale,  bool templateCompact,  String? activePanel,  String? focusedField,  File? backgroundImage,  double scrimOpacity,  bool useVignette,  bool useAutoPalette,  List<Color>? extractedPalette,  Set<String> rewritingFields,  String? rewriteError,  String? watermarkText,  bool showWatermark,  Offset headlineOffset,  Offset subtextOffset,  Offset microStatOffset,  List<CardConfigSnapshot> undoStack,  List<CardConfigSnapshot> redoStack)?  $default,) {final _that = this;
switch (_that) {
case _CardGeneratorState() when $default != null:
return $default(_that.brief,_that.cardData,_that.isExtracting,_that.extractionError,_that.selectedTemplate,_that.selectedRatio,_that.selectedFont,_that.headlineScale,_that.templateCompact,_that.activePanel,_that.focusedField,_that.backgroundImage,_that.scrimOpacity,_that.useVignette,_that.useAutoPalette,_that.extractedPalette,_that.rewritingFields,_that.rewriteError,_that.watermarkText,_that.showWatermark,_that.headlineOffset,_that.subtextOffset,_that.microStatOffset,_that.undoStack,_that.redoStack);case _:
  return null;

}
}

}

/// @nodoc


class _CardGeneratorState extends CardGeneratorState {
  const _CardGeneratorState({this.brief, this.cardData, this.isExtracting = false, this.extractionError, this.selectedTemplate = CardTemplate.socialPost, this.selectedRatio = CardRatio.portrait45, this.selectedFont = AppFont.defaultFont, this.headlineScale = 1.0, this.templateCompact = true, this.activePanel, this.focusedField, this.backgroundImage, this.scrimOpacity = 0.55, this.useVignette = false, this.useAutoPalette = false,  List<Color>? extractedPalette,  Set<String> rewritingFields = const {}, this.rewriteError, this.watermarkText, this.showWatermark = false, this.headlineOffset = const Offset(0.5, 0.2), this.subtextOffset = const Offset(0.5, 0.5), this.microStatOffset = const Offset(0.5, 0.8),  List<CardConfigSnapshot> undoStack = const [],  List<CardConfigSnapshot> redoStack = const []}): _extractedPalette = extractedPalette,_rewritingFields = rewritingFields,_undoStack = undoStack,_redoStack = redoStack,super._();
  

@override final  CardBrief? brief;
@override final  CardData? cardData;
@override@JsonKey() final  bool isExtracting;
@override final  String? extractionError;
@override@JsonKey() final  CardTemplate selectedTemplate;
@override@JsonKey() final  CardRatio selectedRatio;
@override@JsonKey() final  AppFont selectedFont;
@override@JsonKey() final  double headlineScale;
@override@JsonKey() final  bool templateCompact;
@override final  String? activePanel;
@override final  String? focusedField;
@override final  File? backgroundImage;
@override@JsonKey() final  double scrimOpacity;
@override@JsonKey() final  bool useVignette;
@override@JsonKey() final  bool useAutoPalette;
 final  List<Color>? _extractedPalette;
@override List<Color>? get extractedPalette {
  final value = _extractedPalette;
  if (value == null) return null;
  if (_extractedPalette is EqualUnmodifiableListView) return _extractedPalette;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Set<String> _rewritingFields;
@override@JsonKey() Set<String> get rewritingFields {
  if (_rewritingFields is EqualUnmodifiableSetView) return _rewritingFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_rewritingFields);
}

@override final  String? rewriteError;
@override final  String? watermarkText;
@override@JsonKey() final  bool showWatermark;
@override@JsonKey() final  Offset headlineOffset;
@override@JsonKey() final  Offset subtextOffset;
@override@JsonKey() final  Offset microStatOffset;
 final  List<CardConfigSnapshot> _undoStack;
@override@JsonKey() List<CardConfigSnapshot> get undoStack {
  if (_undoStack is EqualUnmodifiableListView) return _undoStack;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_undoStack);
}

 final  List<CardConfigSnapshot> _redoStack;
@override@JsonKey() List<CardConfigSnapshot> get redoStack {
  if (_redoStack is EqualUnmodifiableListView) return _redoStack;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redoStack);
}


/// Create a copy of CardGeneratorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardGeneratorStateCopyWith<_CardGeneratorState> get copyWith => __$CardGeneratorStateCopyWithImpl<_CardGeneratorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardGeneratorState&&(identical(other.brief, brief) || other.brief == brief)&&(identical(other.cardData, cardData) || other.cardData == cardData)&&(identical(other.isExtracting, isExtracting) || other.isExtracting == isExtracting)&&(identical(other.extractionError, extractionError) || other.extractionError == extractionError)&&(identical(other.selectedTemplate, selectedTemplate) || other.selectedTemplate == selectedTemplate)&&(identical(other.selectedRatio, selectedRatio) || other.selectedRatio == selectedRatio)&&(identical(other.selectedFont, selectedFont) || other.selectedFont == selectedFont)&&(identical(other.headlineScale, headlineScale) || other.headlineScale == headlineScale)&&(identical(other.templateCompact, templateCompact) || other.templateCompact == templateCompact)&&(identical(other.activePanel, activePanel) || other.activePanel == activePanel)&&(identical(other.focusedField, focusedField) || other.focusedField == focusedField)&&(identical(other.backgroundImage, backgroundImage) || other.backgroundImage == backgroundImage)&&(identical(other.scrimOpacity, scrimOpacity) || other.scrimOpacity == scrimOpacity)&&(identical(other.useVignette, useVignette) || other.useVignette == useVignette)&&(identical(other.useAutoPalette, useAutoPalette) || other.useAutoPalette == useAutoPalette)&&const DeepCollectionEquality().equals(other._extractedPalette, _extractedPalette)&&const DeepCollectionEquality().equals(other._rewritingFields, _rewritingFields)&&(identical(other.rewriteError, rewriteError) || other.rewriteError == rewriteError)&&(identical(other.watermarkText, watermarkText) || other.watermarkText == watermarkText)&&(identical(other.showWatermark, showWatermark) || other.showWatermark == showWatermark)&&(identical(other.headlineOffset, headlineOffset) || other.headlineOffset == headlineOffset)&&(identical(other.subtextOffset, subtextOffset) || other.subtextOffset == subtextOffset)&&(identical(other.microStatOffset, microStatOffset) || other.microStatOffset == microStatOffset)&&const DeepCollectionEquality().equals(other._undoStack, _undoStack)&&const DeepCollectionEquality().equals(other._redoStack, _redoStack));
}


@override
int get hashCode => Object.hashAll([runtimeType,brief,cardData,isExtracting,extractionError,selectedTemplate,selectedRatio,selectedFont,headlineScale,templateCompact,activePanel,focusedField,backgroundImage,scrimOpacity,useVignette,useAutoPalette,const DeepCollectionEquality().hash(_extractedPalette),const DeepCollectionEquality().hash(_rewritingFields),rewriteError,watermarkText,showWatermark,headlineOffset,subtextOffset,microStatOffset,const DeepCollectionEquality().hash(_undoStack),const DeepCollectionEquality().hash(_redoStack)]);

@override
String toString() {
  return 'CardGeneratorState(brief: $brief, cardData: $cardData, isExtracting: $isExtracting, extractionError: $extractionError, selectedTemplate: $selectedTemplate, selectedRatio: $selectedRatio, selectedFont: $selectedFont, headlineScale: $headlineScale, templateCompact: $templateCompact, activePanel: $activePanel, focusedField: $focusedField, backgroundImage: $backgroundImage, scrimOpacity: $scrimOpacity, useVignette: $useVignette, useAutoPalette: $useAutoPalette, extractedPalette: $extractedPalette, rewritingFields: $rewritingFields, rewriteError: $rewriteError, watermarkText: $watermarkText, showWatermark: $showWatermark, headlineOffset: $headlineOffset, subtextOffset: $subtextOffset, microStatOffset: $microStatOffset, undoStack: $undoStack, redoStack: $redoStack)';
}


}

/// @nodoc
abstract mixin class _$CardGeneratorStateCopyWith<$Res> implements $CardGeneratorStateCopyWith<$Res> {
  factory _$CardGeneratorStateCopyWith(_CardGeneratorState value, $Res Function(_CardGeneratorState) _then) = __$CardGeneratorStateCopyWithImpl;
@override @useResult
$Res call({
 CardBrief? brief, CardData? cardData, bool isExtracting, String? extractionError, CardTemplate selectedTemplate, CardRatio selectedRatio, AppFont selectedFont, double headlineScale, bool templateCompact, String? activePanel, String? focusedField, File? backgroundImage, double scrimOpacity, bool useVignette, bool useAutoPalette, List<Color>? extractedPalette, Set<String> rewritingFields, String? rewriteError, String? watermarkText, bool showWatermark, Offset headlineOffset, Offset subtextOffset, Offset microStatOffset, List<CardConfigSnapshot> undoStack, List<CardConfigSnapshot> redoStack
});


@override $CardDataCopyWith<$Res>? get cardData;

}
/// @nodoc
class __$CardGeneratorStateCopyWithImpl<$Res>
    implements _$CardGeneratorStateCopyWith<$Res> {
  __$CardGeneratorStateCopyWithImpl(this._self, this._then);

  final _CardGeneratorState _self;
  final $Res Function(_CardGeneratorState) _then;

/// Create a copy of CardGeneratorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? brief = freezed,Object? cardData = freezed,Object? isExtracting = null,Object? extractionError = freezed,Object? selectedTemplate = null,Object? selectedRatio = null,Object? selectedFont = null,Object? headlineScale = null,Object? templateCompact = null,Object? activePanel = freezed,Object? focusedField = freezed,Object? backgroundImage = freezed,Object? scrimOpacity = null,Object? useVignette = null,Object? useAutoPalette = null,Object? extractedPalette = freezed,Object? rewritingFields = null,Object? rewriteError = freezed,Object? watermarkText = freezed,Object? showWatermark = null,Object? headlineOffset = null,Object? subtextOffset = null,Object? microStatOffset = null,Object? undoStack = null,Object? redoStack = null,}) {
  return _then(_CardGeneratorState(
brief: freezed == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as CardBrief?,cardData: freezed == cardData ? _self.cardData : cardData // ignore: cast_nullable_to_non_nullable
as CardData?,isExtracting: null == isExtracting ? _self.isExtracting : isExtracting // ignore: cast_nullable_to_non_nullable
as bool,extractionError: freezed == extractionError ? _self.extractionError : extractionError // ignore: cast_nullable_to_non_nullable
as String?,selectedTemplate: null == selectedTemplate ? _self.selectedTemplate : selectedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate,selectedRatio: null == selectedRatio ? _self.selectedRatio : selectedRatio // ignore: cast_nullable_to_non_nullable
as CardRatio,selectedFont: null == selectedFont ? _self.selectedFont : selectedFont // ignore: cast_nullable_to_non_nullable
as AppFont,headlineScale: null == headlineScale ? _self.headlineScale : headlineScale // ignore: cast_nullable_to_non_nullable
as double,templateCompact: null == templateCompact ? _self.templateCompact : templateCompact // ignore: cast_nullable_to_non_nullable
as bool,activePanel: freezed == activePanel ? _self.activePanel : activePanel // ignore: cast_nullable_to_non_nullable
as String?,focusedField: freezed == focusedField ? _self.focusedField : focusedField // ignore: cast_nullable_to_non_nullable
as String?,backgroundImage: freezed == backgroundImage ? _self.backgroundImage : backgroundImage // ignore: cast_nullable_to_non_nullable
as File?,scrimOpacity: null == scrimOpacity ? _self.scrimOpacity : scrimOpacity // ignore: cast_nullable_to_non_nullable
as double,useVignette: null == useVignette ? _self.useVignette : useVignette // ignore: cast_nullable_to_non_nullable
as bool,useAutoPalette: null == useAutoPalette ? _self.useAutoPalette : useAutoPalette // ignore: cast_nullable_to_non_nullable
as bool,extractedPalette: freezed == extractedPalette ? _self._extractedPalette : extractedPalette // ignore: cast_nullable_to_non_nullable
as List<Color>?,rewritingFields: null == rewritingFields ? _self._rewritingFields : rewritingFields // ignore: cast_nullable_to_non_nullable
as Set<String>,rewriteError: freezed == rewriteError ? _self.rewriteError : rewriteError // ignore: cast_nullable_to_non_nullable
as String?,watermarkText: freezed == watermarkText ? _self.watermarkText : watermarkText // ignore: cast_nullable_to_non_nullable
as String?,showWatermark: null == showWatermark ? _self.showWatermark : showWatermark // ignore: cast_nullable_to_non_nullable
as bool,headlineOffset: null == headlineOffset ? _self.headlineOffset : headlineOffset // ignore: cast_nullable_to_non_nullable
as Offset,subtextOffset: null == subtextOffset ? _self.subtextOffset : subtextOffset // ignore: cast_nullable_to_non_nullable
as Offset,microStatOffset: null == microStatOffset ? _self.microStatOffset : microStatOffset // ignore: cast_nullable_to_non_nullable
as Offset,undoStack: null == undoStack ? _self._undoStack : undoStack // ignore: cast_nullable_to_non_nullable
as List<CardConfigSnapshot>,redoStack: null == redoStack ? _self._redoStack : redoStack // ignore: cast_nullable_to_non_nullable
as List<CardConfigSnapshot>,
  ));
}

/// Create a copy of CardGeneratorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardDataCopyWith<$Res>? get cardData {
    if (_self.cardData == null) {
    return null;
  }

  return $CardDataCopyWith<$Res>(_self.cardData!, (value) {
    return _then(_self.copyWith(cardData: value));
  });
}
}

// dart format on
