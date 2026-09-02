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

 CardBrief? get brief; CardData? get cardData; bool get isExtracting; String? get extractionError; CardTemplate get selectedTemplate; CardRatio get selectedRatio; AppFont get selectedFont; double get headlineScale; ImagePosition get imagePosition; PhotoFilter get photoFilter; bool get templateCompact; String? get activePanel; String? get focusedField; File? get backgroundImage; double get scrimOpacity; bool get useVignette; bool get useAutoPalette; List<Color>? get extractedPalette; Set<String> get rewritingFields; String? get rewriteError; Set<String> get missingFields; String? get watermarkText; bool get showWatermark; File? get watermarkImage; double get watermarkSize; Offset get watermarkOffset; String? get brandName; String? get brandHandle; bool get showBrandFooter; double get imageOpacity; double get backgroundBlurRadius; String? get badgeText; Color? get accentColor; double get previewScale; BackgroundType get backgroundType; PresetBackground? get presetBackground; double get textShadowRadius; Color? get textShadowColor; bool get isGlowEnabled; Offset get headlineOffset; Offset get subtextOffset; Offset get microStatOffset; List<CardConfigSnapshot> get undoStack; List<CardConfigSnapshot> get redoStack;
/// Create a copy of CardGeneratorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardGeneratorStateCopyWith<CardGeneratorState> get copyWith => _$CardGeneratorStateCopyWithImpl<CardGeneratorState>(this as CardGeneratorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardGeneratorState&&(identical(other.brief, brief) || other.brief == brief)&&(identical(other.cardData, cardData) || other.cardData == cardData)&&(identical(other.isExtracting, isExtracting) || other.isExtracting == isExtracting)&&(identical(other.extractionError, extractionError) || other.extractionError == extractionError)&&(identical(other.selectedTemplate, selectedTemplate) || other.selectedTemplate == selectedTemplate)&&(identical(other.selectedRatio, selectedRatio) || other.selectedRatio == selectedRatio)&&(identical(other.selectedFont, selectedFont) || other.selectedFont == selectedFont)&&(identical(other.headlineScale, headlineScale) || other.headlineScale == headlineScale)&&(identical(other.imagePosition, imagePosition) || other.imagePosition == imagePosition)&&(identical(other.photoFilter, photoFilter) || other.photoFilter == photoFilter)&&(identical(other.templateCompact, templateCompact) || other.templateCompact == templateCompact)&&(identical(other.activePanel, activePanel) || other.activePanel == activePanel)&&(identical(other.focusedField, focusedField) || other.focusedField == focusedField)&&(identical(other.backgroundImage, backgroundImage) || other.backgroundImage == backgroundImage)&&(identical(other.scrimOpacity, scrimOpacity) || other.scrimOpacity == scrimOpacity)&&(identical(other.useVignette, useVignette) || other.useVignette == useVignette)&&(identical(other.useAutoPalette, useAutoPalette) || other.useAutoPalette == useAutoPalette)&&const DeepCollectionEquality().equals(other.extractedPalette, extractedPalette)&&const DeepCollectionEquality().equals(other.rewritingFields, rewritingFields)&&(identical(other.rewriteError, rewriteError) || other.rewriteError == rewriteError)&&const DeepCollectionEquality().equals(other.missingFields, missingFields)&&(identical(other.watermarkText, watermarkText) || other.watermarkText == watermarkText)&&(identical(other.showWatermark, showWatermark) || other.showWatermark == showWatermark)&&(identical(other.watermarkImage, watermarkImage) || other.watermarkImage == watermarkImage)&&(identical(other.watermarkSize, watermarkSize) || other.watermarkSize == watermarkSize)&&(identical(other.watermarkOffset, watermarkOffset) || other.watermarkOffset == watermarkOffset)&&(identical(other.brandName, brandName) || other.brandName == brandName)&&(identical(other.brandHandle, brandHandle) || other.brandHandle == brandHandle)&&(identical(other.showBrandFooter, showBrandFooter) || other.showBrandFooter == showBrandFooter)&&(identical(other.imageOpacity, imageOpacity) || other.imageOpacity == imageOpacity)&&(identical(other.backgroundBlurRadius, backgroundBlurRadius) || other.backgroundBlurRadius == backgroundBlurRadius)&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor)&&(identical(other.previewScale, previewScale) || other.previewScale == previewScale)&&(identical(other.backgroundType, backgroundType) || other.backgroundType == backgroundType)&&(identical(other.presetBackground, presetBackground) || other.presetBackground == presetBackground)&&(identical(other.textShadowRadius, textShadowRadius) || other.textShadowRadius == textShadowRadius)&&(identical(other.textShadowColor, textShadowColor) || other.textShadowColor == textShadowColor)&&(identical(other.isGlowEnabled, isGlowEnabled) || other.isGlowEnabled == isGlowEnabled)&&(identical(other.headlineOffset, headlineOffset) || other.headlineOffset == headlineOffset)&&(identical(other.subtextOffset, subtextOffset) || other.subtextOffset == subtextOffset)&&(identical(other.microStatOffset, microStatOffset) || other.microStatOffset == microStatOffset)&&const DeepCollectionEquality().equals(other.undoStack, undoStack)&&const DeepCollectionEquality().equals(other.redoStack, redoStack));
}


@override
int get hashCode => Object.hashAll([runtimeType,brief,cardData,isExtracting,extractionError,selectedTemplate,selectedRatio,selectedFont,headlineScale,imagePosition,photoFilter,templateCompact,activePanel,focusedField,backgroundImage,scrimOpacity,useVignette,useAutoPalette,const DeepCollectionEquality().hash(extractedPalette),const DeepCollectionEquality().hash(rewritingFields),rewriteError,const DeepCollectionEquality().hash(missingFields),watermarkText,showWatermark,watermarkImage,watermarkSize,watermarkOffset,brandName,brandHandle,showBrandFooter,imageOpacity,backgroundBlurRadius,badgeText,accentColor,previewScale,backgroundType,presetBackground,textShadowRadius,textShadowColor,isGlowEnabled,headlineOffset,subtextOffset,microStatOffset,const DeepCollectionEquality().hash(undoStack),const DeepCollectionEquality().hash(redoStack)]);

@override
String toString() {
  return 'CardGeneratorState(brief: $brief, cardData: $cardData, isExtracting: $isExtracting, extractionError: $extractionError, selectedTemplate: $selectedTemplate, selectedRatio: $selectedRatio, selectedFont: $selectedFont, headlineScale: $headlineScale, imagePosition: $imagePosition, photoFilter: $photoFilter, templateCompact: $templateCompact, activePanel: $activePanel, focusedField: $focusedField, backgroundImage: $backgroundImage, scrimOpacity: $scrimOpacity, useVignette: $useVignette, useAutoPalette: $useAutoPalette, extractedPalette: $extractedPalette, rewritingFields: $rewritingFields, rewriteError: $rewriteError, missingFields: $missingFields, watermarkText: $watermarkText, showWatermark: $showWatermark, watermarkImage: $watermarkImage, watermarkSize: $watermarkSize, watermarkOffset: $watermarkOffset, brandName: $brandName, brandHandle: $brandHandle, showBrandFooter: $showBrandFooter, imageOpacity: $imageOpacity, backgroundBlurRadius: $backgroundBlurRadius, badgeText: $badgeText, accentColor: $accentColor, previewScale: $previewScale, backgroundType: $backgroundType, presetBackground: $presetBackground, textShadowRadius: $textShadowRadius, textShadowColor: $textShadowColor, isGlowEnabled: $isGlowEnabled, headlineOffset: $headlineOffset, subtextOffset: $subtextOffset, microStatOffset: $microStatOffset, undoStack: $undoStack, redoStack: $redoStack)';
}


}

/// @nodoc
abstract mixin class $CardGeneratorStateCopyWith<$Res>  {
  factory $CardGeneratorStateCopyWith(CardGeneratorState value, $Res Function(CardGeneratorState) _then) = _$CardGeneratorStateCopyWithImpl;
@useResult
$Res call({
 CardBrief? brief, CardData? cardData, bool isExtracting, String? extractionError, CardTemplate selectedTemplate, CardRatio selectedRatio, AppFont selectedFont, double headlineScale, ImagePosition imagePosition, PhotoFilter photoFilter, bool templateCompact, String? activePanel, String? focusedField, File? backgroundImage, double scrimOpacity, bool useVignette, bool useAutoPalette, List<Color>? extractedPalette, Set<String> rewritingFields, String? rewriteError, Set<String> missingFields, String? watermarkText, bool showWatermark, File? watermarkImage, double watermarkSize, Offset watermarkOffset, String? brandName, String? brandHandle, bool showBrandFooter, double imageOpacity, double backgroundBlurRadius, String? badgeText, Color? accentColor, double previewScale, BackgroundType backgroundType, PresetBackground? presetBackground, double textShadowRadius, Color? textShadowColor, bool isGlowEnabled, Offset headlineOffset, Offset subtextOffset, Offset microStatOffset, List<CardConfigSnapshot> undoStack, List<CardConfigSnapshot> redoStack
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
@pragma('vm:prefer-inline') @override $Res call({Object? brief = freezed,Object? cardData = freezed,Object? isExtracting = null,Object? extractionError = freezed,Object? selectedTemplate = null,Object? selectedRatio = null,Object? selectedFont = null,Object? headlineScale = null,Object? imagePosition = null,Object? photoFilter = null,Object? templateCompact = null,Object? activePanel = freezed,Object? focusedField = freezed,Object? backgroundImage = freezed,Object? scrimOpacity = null,Object? useVignette = null,Object? useAutoPalette = null,Object? extractedPalette = freezed,Object? rewritingFields = null,Object? rewriteError = freezed,Object? missingFields = null,Object? watermarkText = freezed,Object? showWatermark = null,Object? watermarkImage = freezed,Object? watermarkSize = null,Object? watermarkOffset = null,Object? brandName = freezed,Object? brandHandle = freezed,Object? showBrandFooter = null,Object? imageOpacity = null,Object? backgroundBlurRadius = null,Object? badgeText = freezed,Object? accentColor = freezed,Object? previewScale = null,Object? backgroundType = null,Object? presetBackground = freezed,Object? textShadowRadius = null,Object? textShadowColor = freezed,Object? isGlowEnabled = null,Object? headlineOffset = null,Object? subtextOffset = null,Object? microStatOffset = null,Object? undoStack = null,Object? redoStack = null,}) {
  return _then(CardGeneratorState(
brief: freezed == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as CardBrief?,cardData: freezed == cardData ? _self.cardData : cardData // ignore: cast_nullable_to_non_nullable
as CardData?,isExtracting: null == isExtracting ? _self.isExtracting : isExtracting // ignore: cast_nullable_to_non_nullable
as bool,extractionError: freezed == extractionError ? _self.extractionError : extractionError // ignore: cast_nullable_to_non_nullable
as String?,selectedTemplate: null == selectedTemplate ? _self.selectedTemplate : selectedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate,selectedRatio: null == selectedRatio ? _self.selectedRatio : selectedRatio // ignore: cast_nullable_to_non_nullable
as CardRatio,selectedFont: null == selectedFont ? _self.selectedFont : selectedFont // ignore: cast_nullable_to_non_nullable
as AppFont,headlineScale: null == headlineScale ? _self.headlineScale : headlineScale // ignore: cast_nullable_to_non_nullable
as double,imagePosition: null == imagePosition ? _self.imagePosition : imagePosition // ignore: cast_nullable_to_non_nullable
as ImagePosition,photoFilter: null == photoFilter ? _self.photoFilter : photoFilter // ignore: cast_nullable_to_non_nullable
as PhotoFilter,templateCompact: null == templateCompact ? _self.templateCompact : templateCompact // ignore: cast_nullable_to_non_nullable
as bool,activePanel: freezed == activePanel ? _self.activePanel : activePanel // ignore: cast_nullable_to_non_nullable
as String?,focusedField: freezed == focusedField ? _self.focusedField : focusedField // ignore: cast_nullable_to_non_nullable
as String?,backgroundImage: freezed == backgroundImage ? _self.backgroundImage : backgroundImage // ignore: cast_nullable_to_non_nullable
as File?,scrimOpacity: null == scrimOpacity ? _self.scrimOpacity : scrimOpacity // ignore: cast_nullable_to_non_nullable
as double,useVignette: null == useVignette ? _self.useVignette : useVignette // ignore: cast_nullable_to_non_nullable
as bool,useAutoPalette: null == useAutoPalette ? _self.useAutoPalette : useAutoPalette // ignore: cast_nullable_to_non_nullable
as bool,extractedPalette: freezed == extractedPalette ? _self.extractedPalette : extractedPalette // ignore: cast_nullable_to_non_nullable
as List<Color>?,rewritingFields: null == rewritingFields ? _self.rewritingFields : rewritingFields // ignore: cast_nullable_to_non_nullable
as Set<String>,rewriteError: freezed == rewriteError ? _self.rewriteError : rewriteError // ignore: cast_nullable_to_non_nullable
as String?,missingFields: null == missingFields ? _self.missingFields : missingFields // ignore: cast_nullable_to_non_nullable
as Set<String>,watermarkText: freezed == watermarkText ? _self.watermarkText : watermarkText // ignore: cast_nullable_to_non_nullable
as String?,showWatermark: null == showWatermark ? _self.showWatermark : showWatermark // ignore: cast_nullable_to_non_nullable
as bool,watermarkImage: freezed == watermarkImage ? _self.watermarkImage : watermarkImage // ignore: cast_nullable_to_non_nullable
as File?,watermarkSize: null == watermarkSize ? _self.watermarkSize : watermarkSize // ignore: cast_nullable_to_non_nullable
as double,watermarkOffset: null == watermarkOffset ? _self.watermarkOffset : watermarkOffset // ignore: cast_nullable_to_non_nullable
as Offset,brandName: freezed == brandName ? _self.brandName : brandName // ignore: cast_nullable_to_non_nullable
as String?,brandHandle: freezed == brandHandle ? _self.brandHandle : brandHandle // ignore: cast_nullable_to_non_nullable
as String?,showBrandFooter: null == showBrandFooter ? _self.showBrandFooter : showBrandFooter // ignore: cast_nullable_to_non_nullable
as bool,imageOpacity: null == imageOpacity ? _self.imageOpacity : imageOpacity // ignore: cast_nullable_to_non_nullable
as double,backgroundBlurRadius: null == backgroundBlurRadius ? _self.backgroundBlurRadius : backgroundBlurRadius // ignore: cast_nullable_to_non_nullable
as double,badgeText: freezed == badgeText ? _self.badgeText : badgeText // ignore: cast_nullable_to_non_nullable
as String?,accentColor: freezed == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as Color?,previewScale: null == previewScale ? _self.previewScale : previewScale // ignore: cast_nullable_to_non_nullable
as double,backgroundType: null == backgroundType ? _self.backgroundType : backgroundType // ignore: cast_nullable_to_non_nullable
as BackgroundType,presetBackground: freezed == presetBackground ? _self.presetBackground : presetBackground // ignore: cast_nullable_to_non_nullable
as PresetBackground?,textShadowRadius: null == textShadowRadius ? _self.textShadowRadius : textShadowRadius // ignore: cast_nullable_to_non_nullable
as double,textShadowColor: freezed == textShadowColor ? _self.textShadowColor : textShadowColor // ignore: cast_nullable_to_non_nullable
as Color?,isGlowEnabled: null == isGlowEnabled ? _self.isGlowEnabled : isGlowEnabled // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CardBrief? brief,  CardData? cardData,  bool isExtracting,  String? extractionError,  CardTemplate selectedTemplate,  CardRatio selectedRatio,  AppFont selectedFont,  double headlineScale,  ImagePosition imagePosition,  PhotoFilter photoFilter,  bool templateCompact,  String? activePanel,  String? focusedField,  File? backgroundImage,  double scrimOpacity,  bool useVignette,  bool useAutoPalette,  List<Color>? extractedPalette,  Set<String> rewritingFields,  String? rewriteError,  Set<String> missingFields,  String? watermarkText,  bool showWatermark,  File? watermarkImage,  double watermarkSize,  Offset watermarkOffset,  String? brandName,  String? brandHandle,  bool showBrandFooter,  double imageOpacity,  double backgroundBlurRadius,  String? badgeText,  Color? accentColor,  double previewScale,  BackgroundType backgroundType,  PresetBackground? presetBackground,  double textShadowRadius,  Color? textShadowColor,  bool isGlowEnabled,  Offset headlineOffset,  Offset subtextOffset,  Offset microStatOffset,  List<CardConfigSnapshot> undoStack,  List<CardConfigSnapshot> redoStack)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardGeneratorState() when $default != null:
return $default(_that.brief,_that.cardData,_that.isExtracting,_that.extractionError,_that.selectedTemplate,_that.selectedRatio,_that.selectedFont,_that.headlineScale,_that.imagePosition,_that.photoFilter,_that.templateCompact,_that.activePanel,_that.focusedField,_that.backgroundImage,_that.scrimOpacity,_that.useVignette,_that.useAutoPalette,_that.extractedPalette,_that.rewritingFields,_that.rewriteError,_that.missingFields,_that.watermarkText,_that.showWatermark,_that.watermarkImage,_that.watermarkSize,_that.watermarkOffset,_that.brandName,_that.brandHandle,_that.showBrandFooter,_that.imageOpacity,_that.backgroundBlurRadius,_that.badgeText,_that.accentColor,_that.previewScale,_that.backgroundType,_that.presetBackground,_that.textShadowRadius,_that.textShadowColor,_that.isGlowEnabled,_that.headlineOffset,_that.subtextOffset,_that.microStatOffset,_that.undoStack,_that.redoStack);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CardBrief? brief,  CardData? cardData,  bool isExtracting,  String? extractionError,  CardTemplate selectedTemplate,  CardRatio selectedRatio,  AppFont selectedFont,  double headlineScale,  ImagePosition imagePosition,  PhotoFilter photoFilter,  bool templateCompact,  String? activePanel,  String? focusedField,  File? backgroundImage,  double scrimOpacity,  bool useVignette,  bool useAutoPalette,  List<Color>? extractedPalette,  Set<String> rewritingFields,  String? rewriteError,  Set<String> missingFields,  String? watermarkText,  bool showWatermark,  File? watermarkImage,  double watermarkSize,  Offset watermarkOffset,  String? brandName,  String? brandHandle,  bool showBrandFooter,  double imageOpacity,  double backgroundBlurRadius,  String? badgeText,  Color? accentColor,  double previewScale,  BackgroundType backgroundType,  PresetBackground? presetBackground,  double textShadowRadius,  Color? textShadowColor,  bool isGlowEnabled,  Offset headlineOffset,  Offset subtextOffset,  Offset microStatOffset,  List<CardConfigSnapshot> undoStack,  List<CardConfigSnapshot> redoStack)  $default,) {final _that = this;
switch (_that) {
case _CardGeneratorState():
return $default(_that.brief,_that.cardData,_that.isExtracting,_that.extractionError,_that.selectedTemplate,_that.selectedRatio,_that.selectedFont,_that.headlineScale,_that.imagePosition,_that.photoFilter,_that.templateCompact,_that.activePanel,_that.focusedField,_that.backgroundImage,_that.scrimOpacity,_that.useVignette,_that.useAutoPalette,_that.extractedPalette,_that.rewritingFields,_that.rewriteError,_that.missingFields,_that.watermarkText,_that.showWatermark,_that.watermarkImage,_that.watermarkSize,_that.watermarkOffset,_that.brandName,_that.brandHandle,_that.showBrandFooter,_that.imageOpacity,_that.backgroundBlurRadius,_that.badgeText,_that.accentColor,_that.previewScale,_that.backgroundType,_that.presetBackground,_that.textShadowRadius,_that.textShadowColor,_that.isGlowEnabled,_that.headlineOffset,_that.subtextOffset,_that.microStatOffset,_that.undoStack,_that.redoStack);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CardBrief? brief,  CardData? cardData,  bool isExtracting,  String? extractionError,  CardTemplate selectedTemplate,  CardRatio selectedRatio,  AppFont selectedFont,  double headlineScale,  ImagePosition imagePosition,  PhotoFilter photoFilter,  bool templateCompact,  String? activePanel,  String? focusedField,  File? backgroundImage,  double scrimOpacity,  bool useVignette,  bool useAutoPalette,  List<Color>? extractedPalette,  Set<String> rewritingFields,  String? rewriteError,  Set<String> missingFields,  String? watermarkText,  bool showWatermark,  File? watermarkImage,  double watermarkSize,  Offset watermarkOffset,  String? brandName,  String? brandHandle,  bool showBrandFooter,  double imageOpacity,  double backgroundBlurRadius,  String? badgeText,  Color? accentColor,  double previewScale,  BackgroundType backgroundType,  PresetBackground? presetBackground,  double textShadowRadius,  Color? textShadowColor,  bool isGlowEnabled,  Offset headlineOffset,  Offset subtextOffset,  Offset microStatOffset,  List<CardConfigSnapshot> undoStack,  List<CardConfigSnapshot> redoStack)?  $default,) {final _that = this;
switch (_that) {
case _CardGeneratorState() when $default != null:
return $default(_that.brief,_that.cardData,_that.isExtracting,_that.extractionError,_that.selectedTemplate,_that.selectedRatio,_that.selectedFont,_that.headlineScale,_that.imagePosition,_that.photoFilter,_that.templateCompact,_that.activePanel,_that.focusedField,_that.backgroundImage,_that.scrimOpacity,_that.useVignette,_that.useAutoPalette,_that.extractedPalette,_that.rewritingFields,_that.rewriteError,_that.missingFields,_that.watermarkText,_that.showWatermark,_that.watermarkImage,_that.watermarkSize,_that.watermarkOffset,_that.brandName,_that.brandHandle,_that.showBrandFooter,_that.imageOpacity,_that.backgroundBlurRadius,_that.badgeText,_that.accentColor,_that.previewScale,_that.backgroundType,_that.presetBackground,_that.textShadowRadius,_that.textShadowColor,_that.isGlowEnabled,_that.headlineOffset,_that.subtextOffset,_that.microStatOffset,_that.undoStack,_that.redoStack);case _:
  return null;

}
}

}

/// @nodoc


class _CardGeneratorState extends CardGeneratorState {
  const _CardGeneratorState({this.brief, this.cardData, this.isExtracting = false, this.extractionError, this.selectedTemplate = CardTemplate.socialPost, this.selectedRatio = CardRatio.portrait45, this.selectedFont = AppFont.defaultFont, this.headlineScale = 1.0, this.imagePosition = ImagePosition.background, this.photoFilter = PhotoFilter.none, this.templateCompact = true, this.activePanel, this.focusedField, this.backgroundImage, this.scrimOpacity = 0.55, this.useVignette = false, this.useAutoPalette = false,  List<Color>? extractedPalette,  Set<String> rewritingFields = const {}, this.rewriteError,  Set<String> missingFields = const {}, this.watermarkText, this.showWatermark = false, this.watermarkImage, this.watermarkSize = 60.0, this.watermarkOffset = const Offset(0.85, 0.9), this.brandName, this.brandHandle, this.showBrandFooter = true, this.imageOpacity = 1.0, this.backgroundBlurRadius = 0.0, this.badgeText, this.accentColor, this.previewScale = 1.0, this.backgroundType = BackgroundType.gradient, this.presetBackground, this.textShadowRadius = 0.0, this.textShadowColor, this.isGlowEnabled = false, this.headlineOffset = const Offset(0.5, 0.2), this.subtextOffset = const Offset(0.5, 0.5), this.microStatOffset = const Offset(0.5, 0.8),  List<CardConfigSnapshot> undoStack = const [],  List<CardConfigSnapshot> redoStack = const []}): _extractedPalette = extractedPalette,_rewritingFields = rewritingFields,_missingFields = missingFields,_undoStack = undoStack,_redoStack = redoStack,super._();
  

@override final  CardBrief? brief;
@override final  CardData? cardData;
@override@JsonKey() final  bool isExtracting;
@override final  String? extractionError;
@override@JsonKey() final  CardTemplate selectedTemplate;
@override@JsonKey() final  CardRatio selectedRatio;
@override@JsonKey() final  AppFont selectedFont;
@override@JsonKey() final  double headlineScale;
@override@JsonKey() final  ImagePosition imagePosition;
@override@JsonKey() final  PhotoFilter photoFilter;
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
 final  Set<String> _missingFields;
@override@JsonKey() Set<String> get missingFields {
  if (_missingFields is EqualUnmodifiableSetView) return _missingFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_missingFields);
}

@override final  String? watermarkText;
@override@JsonKey() final  bool showWatermark;
@override final  File? watermarkImage;
@override@JsonKey() final  double watermarkSize;
@override@JsonKey() final  Offset watermarkOffset;
@override final  String? brandName;
@override final  String? brandHandle;
@override@JsonKey() final  bool showBrandFooter;
@override@JsonKey() final  double imageOpacity;
@override@JsonKey() final  double backgroundBlurRadius;
@override final  String? badgeText;
@override final  Color? accentColor;
@override@JsonKey() final  double previewScale;
@override@JsonKey() final  BackgroundType backgroundType;
@override final  PresetBackground? presetBackground;
@override@JsonKey() final  double textShadowRadius;
@override final  Color? textShadowColor;
@override@JsonKey() final  bool isGlowEnabled;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardGeneratorState&&(identical(other.brief, brief) || other.brief == brief)&&(identical(other.cardData, cardData) || other.cardData == cardData)&&(identical(other.isExtracting, isExtracting) || other.isExtracting == isExtracting)&&(identical(other.extractionError, extractionError) || other.extractionError == extractionError)&&(identical(other.selectedTemplate, selectedTemplate) || other.selectedTemplate == selectedTemplate)&&(identical(other.selectedRatio, selectedRatio) || other.selectedRatio == selectedRatio)&&(identical(other.selectedFont, selectedFont) || other.selectedFont == selectedFont)&&(identical(other.headlineScale, headlineScale) || other.headlineScale == headlineScale)&&(identical(other.imagePosition, imagePosition) || other.imagePosition == imagePosition)&&(identical(other.photoFilter, photoFilter) || other.photoFilter == photoFilter)&&(identical(other.templateCompact, templateCompact) || other.templateCompact == templateCompact)&&(identical(other.activePanel, activePanel) || other.activePanel == activePanel)&&(identical(other.focusedField, focusedField) || other.focusedField == focusedField)&&(identical(other.backgroundImage, backgroundImage) || other.backgroundImage == backgroundImage)&&(identical(other.scrimOpacity, scrimOpacity) || other.scrimOpacity == scrimOpacity)&&(identical(other.useVignette, useVignette) || other.useVignette == useVignette)&&(identical(other.useAutoPalette, useAutoPalette) || other.useAutoPalette == useAutoPalette)&&const DeepCollectionEquality().equals(other._extractedPalette, _extractedPalette)&&const DeepCollectionEquality().equals(other._rewritingFields, _rewritingFields)&&(identical(other.rewriteError, rewriteError) || other.rewriteError == rewriteError)&&const DeepCollectionEquality().equals(other._missingFields, _missingFields)&&(identical(other.watermarkText, watermarkText) || other.watermarkText == watermarkText)&&(identical(other.showWatermark, showWatermark) || other.showWatermark == showWatermark)&&(identical(other.watermarkImage, watermarkImage) || other.watermarkImage == watermarkImage)&&(identical(other.watermarkSize, watermarkSize) || other.watermarkSize == watermarkSize)&&(identical(other.watermarkOffset, watermarkOffset) || other.watermarkOffset == watermarkOffset)&&(identical(other.brandName, brandName) || other.brandName == brandName)&&(identical(other.brandHandle, brandHandle) || other.brandHandle == brandHandle)&&(identical(other.showBrandFooter, showBrandFooter) || other.showBrandFooter == showBrandFooter)&&(identical(other.imageOpacity, imageOpacity) || other.imageOpacity == imageOpacity)&&(identical(other.backgroundBlurRadius, backgroundBlurRadius) || other.backgroundBlurRadius == backgroundBlurRadius)&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor)&&(identical(other.previewScale, previewScale) || other.previewScale == previewScale)&&(identical(other.backgroundType, backgroundType) || other.backgroundType == backgroundType)&&(identical(other.presetBackground, presetBackground) || other.presetBackground == presetBackground)&&(identical(other.textShadowRadius, textShadowRadius) || other.textShadowRadius == textShadowRadius)&&(identical(other.textShadowColor, textShadowColor) || other.textShadowColor == textShadowColor)&&(identical(other.isGlowEnabled, isGlowEnabled) || other.isGlowEnabled == isGlowEnabled)&&(identical(other.headlineOffset, headlineOffset) || other.headlineOffset == headlineOffset)&&(identical(other.subtextOffset, subtextOffset) || other.subtextOffset == subtextOffset)&&(identical(other.microStatOffset, microStatOffset) || other.microStatOffset == microStatOffset)&&const DeepCollectionEquality().equals(other._undoStack, _undoStack)&&const DeepCollectionEquality().equals(other._redoStack, _redoStack));
}


@override
int get hashCode => Object.hashAll([runtimeType,brief,cardData,isExtracting,extractionError,selectedTemplate,selectedRatio,selectedFont,headlineScale,imagePosition,photoFilter,templateCompact,activePanel,focusedField,backgroundImage,scrimOpacity,useVignette,useAutoPalette,const DeepCollectionEquality().hash(_extractedPalette),const DeepCollectionEquality().hash(_rewritingFields),rewriteError,const DeepCollectionEquality().hash(_missingFields),watermarkText,showWatermark,watermarkImage,watermarkSize,watermarkOffset,brandName,brandHandle,showBrandFooter,imageOpacity,backgroundBlurRadius,badgeText,accentColor,previewScale,backgroundType,presetBackground,textShadowRadius,textShadowColor,isGlowEnabled,headlineOffset,subtextOffset,microStatOffset,const DeepCollectionEquality().hash(_undoStack),const DeepCollectionEquality().hash(_redoStack)]);

@override
String toString() {
  return 'CardGeneratorState(brief: $brief, cardData: $cardData, isExtracting: $isExtracting, extractionError: $extractionError, selectedTemplate: $selectedTemplate, selectedRatio: $selectedRatio, selectedFont: $selectedFont, headlineScale: $headlineScale, imagePosition: $imagePosition, photoFilter: $photoFilter, templateCompact: $templateCompact, activePanel: $activePanel, focusedField: $focusedField, backgroundImage: $backgroundImage, scrimOpacity: $scrimOpacity, useVignette: $useVignette, useAutoPalette: $useAutoPalette, extractedPalette: $extractedPalette, rewritingFields: $rewritingFields, rewriteError: $rewriteError, missingFields: $missingFields, watermarkText: $watermarkText, showWatermark: $showWatermark, watermarkImage: $watermarkImage, watermarkSize: $watermarkSize, watermarkOffset: $watermarkOffset, brandName: $brandName, brandHandle: $brandHandle, showBrandFooter: $showBrandFooter, imageOpacity: $imageOpacity, backgroundBlurRadius: $backgroundBlurRadius, badgeText: $badgeText, accentColor: $accentColor, previewScale: $previewScale, backgroundType: $backgroundType, presetBackground: $presetBackground, textShadowRadius: $textShadowRadius, textShadowColor: $textShadowColor, isGlowEnabled: $isGlowEnabled, headlineOffset: $headlineOffset, subtextOffset: $subtextOffset, microStatOffset: $microStatOffset, undoStack: $undoStack, redoStack: $redoStack)';
}


}

/// @nodoc
abstract mixin class _$CardGeneratorStateCopyWith<$Res> implements $CardGeneratorStateCopyWith<$Res> {
  factory _$CardGeneratorStateCopyWith(_CardGeneratorState value, $Res Function(_CardGeneratorState) _then) = __$CardGeneratorStateCopyWithImpl;
@override @useResult
$Res call({
 CardBrief? brief, CardData? cardData, bool isExtracting, String? extractionError, CardTemplate selectedTemplate, CardRatio selectedRatio, AppFont selectedFont, double headlineScale, ImagePosition imagePosition, PhotoFilter photoFilter, bool templateCompact, String? activePanel, String? focusedField, File? backgroundImage, double scrimOpacity, bool useVignette, bool useAutoPalette, List<Color>? extractedPalette, Set<String> rewritingFields, String? rewriteError, Set<String> missingFields, String? watermarkText, bool showWatermark, File? watermarkImage, double watermarkSize, Offset watermarkOffset, String? brandName, String? brandHandle, bool showBrandFooter, double imageOpacity, double backgroundBlurRadius, String? badgeText, Color? accentColor, double previewScale, BackgroundType backgroundType, PresetBackground? presetBackground, double textShadowRadius, Color? textShadowColor, bool isGlowEnabled, Offset headlineOffset, Offset subtextOffset, Offset microStatOffset, List<CardConfigSnapshot> undoStack, List<CardConfigSnapshot> redoStack
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
@override @pragma('vm:prefer-inline') $Res call({Object? brief = freezed,Object? cardData = freezed,Object? isExtracting = null,Object? extractionError = freezed,Object? selectedTemplate = null,Object? selectedRatio = null,Object? selectedFont = null,Object? headlineScale = null,Object? imagePosition = null,Object? photoFilter = null,Object? templateCompact = null,Object? activePanel = freezed,Object? focusedField = freezed,Object? backgroundImage = freezed,Object? scrimOpacity = null,Object? useVignette = null,Object? useAutoPalette = null,Object? extractedPalette = freezed,Object? rewritingFields = null,Object? rewriteError = freezed,Object? missingFields = null,Object? watermarkText = freezed,Object? showWatermark = null,Object? watermarkImage = freezed,Object? watermarkSize = null,Object? watermarkOffset = null,Object? brandName = freezed,Object? brandHandle = freezed,Object? showBrandFooter = null,Object? imageOpacity = null,Object? backgroundBlurRadius = null,Object? badgeText = freezed,Object? accentColor = freezed,Object? previewScale = null,Object? backgroundType = null,Object? presetBackground = freezed,Object? textShadowRadius = null,Object? textShadowColor = freezed,Object? isGlowEnabled = null,Object? headlineOffset = null,Object? subtextOffset = null,Object? microStatOffset = null,Object? undoStack = null,Object? redoStack = null,}) {
  return _then(_CardGeneratorState(
brief: freezed == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as CardBrief?,cardData: freezed == cardData ? _self.cardData : cardData // ignore: cast_nullable_to_non_nullable
as CardData?,isExtracting: null == isExtracting ? _self.isExtracting : isExtracting // ignore: cast_nullable_to_non_nullable
as bool,extractionError: freezed == extractionError ? _self.extractionError : extractionError // ignore: cast_nullable_to_non_nullable
as String?,selectedTemplate: null == selectedTemplate ? _self.selectedTemplate : selectedTemplate // ignore: cast_nullable_to_non_nullable
as CardTemplate,selectedRatio: null == selectedRatio ? _self.selectedRatio : selectedRatio // ignore: cast_nullable_to_non_nullable
as CardRatio,selectedFont: null == selectedFont ? _self.selectedFont : selectedFont // ignore: cast_nullable_to_non_nullable
as AppFont,headlineScale: null == headlineScale ? _self.headlineScale : headlineScale // ignore: cast_nullable_to_non_nullable
as double,imagePosition: null == imagePosition ? _self.imagePosition : imagePosition // ignore: cast_nullable_to_non_nullable
as ImagePosition,photoFilter: null == photoFilter ? _self.photoFilter : photoFilter // ignore: cast_nullable_to_non_nullable
as PhotoFilter,templateCompact: null == templateCompact ? _self.templateCompact : templateCompact // ignore: cast_nullable_to_non_nullable
as bool,activePanel: freezed == activePanel ? _self.activePanel : activePanel // ignore: cast_nullable_to_non_nullable
as String?,focusedField: freezed == focusedField ? _self.focusedField : focusedField // ignore: cast_nullable_to_non_nullable
as String?,backgroundImage: freezed == backgroundImage ? _self.backgroundImage : backgroundImage // ignore: cast_nullable_to_non_nullable
as File?,scrimOpacity: null == scrimOpacity ? _self.scrimOpacity : scrimOpacity // ignore: cast_nullable_to_non_nullable
as double,useVignette: null == useVignette ? _self.useVignette : useVignette // ignore: cast_nullable_to_non_nullable
as bool,useAutoPalette: null == useAutoPalette ? _self.useAutoPalette : useAutoPalette // ignore: cast_nullable_to_non_nullable
as bool,extractedPalette: freezed == extractedPalette ? _self._extractedPalette : extractedPalette // ignore: cast_nullable_to_non_nullable
as List<Color>?,rewritingFields: null == rewritingFields ? _self._rewritingFields : rewritingFields // ignore: cast_nullable_to_non_nullable
as Set<String>,rewriteError: freezed == rewriteError ? _self.rewriteError : rewriteError // ignore: cast_nullable_to_non_nullable
as String?,missingFields: null == missingFields ? _self._missingFields : missingFields // ignore: cast_nullable_to_non_nullable
as Set<String>,watermarkText: freezed == watermarkText ? _self.watermarkText : watermarkText // ignore: cast_nullable_to_non_nullable
as String?,showWatermark: null == showWatermark ? _self.showWatermark : showWatermark // ignore: cast_nullable_to_non_nullable
as bool,watermarkImage: freezed == watermarkImage ? _self.watermarkImage : watermarkImage // ignore: cast_nullable_to_non_nullable
as File?,watermarkSize: null == watermarkSize ? _self.watermarkSize : watermarkSize // ignore: cast_nullable_to_non_nullable
as double,watermarkOffset: null == watermarkOffset ? _self.watermarkOffset : watermarkOffset // ignore: cast_nullable_to_non_nullable
as Offset,brandName: freezed == brandName ? _self.brandName : brandName // ignore: cast_nullable_to_non_nullable
as String?,brandHandle: freezed == brandHandle ? _self.brandHandle : brandHandle // ignore: cast_nullable_to_non_nullable
as String?,showBrandFooter: null == showBrandFooter ? _self.showBrandFooter : showBrandFooter // ignore: cast_nullable_to_non_nullable
as bool,imageOpacity: null == imageOpacity ? _self.imageOpacity : imageOpacity // ignore: cast_nullable_to_non_nullable
as double,backgroundBlurRadius: null == backgroundBlurRadius ? _self.backgroundBlurRadius : backgroundBlurRadius // ignore: cast_nullable_to_non_nullable
as double,badgeText: freezed == badgeText ? _self.badgeText : badgeText // ignore: cast_nullable_to_non_nullable
as String?,accentColor: freezed == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as Color?,previewScale: null == previewScale ? _self.previewScale : previewScale // ignore: cast_nullable_to_non_nullable
as double,backgroundType: null == backgroundType ? _self.backgroundType : backgroundType // ignore: cast_nullable_to_non_nullable
as BackgroundType,presetBackground: freezed == presetBackground ? _self.presetBackground : presetBackground // ignore: cast_nullable_to_non_nullable
as PresetBackground?,textShadowRadius: null == textShadowRadius ? _self.textShadowRadius : textShadowRadius // ignore: cast_nullable_to_non_nullable
as double,textShadowColor: freezed == textShadowColor ? _self.textShadowColor : textShadowColor // ignore: cast_nullable_to_non_nullable
as Color?,isGlowEnabled: null == isGlowEnabled ? _self.isGlowEnabled : isGlowEnabled // ignore: cast_nullable_to_non_nullable
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
