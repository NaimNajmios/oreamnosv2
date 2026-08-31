// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'generate_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GenerateUiState {

 PromptLength get promptLength; GenerateState get status; GeneratingStep get generatingStep; CuratedPost? get curatedPost; List<String> get historyStack; List<String> get recentInputs; String? get errorMessage; AiProvider? get suggestedFallbackProvider; String? get validationMessage; String? get pendingInput; bool get isResearchModeEnabled; List<String> get searchSources; bool get showTitle; bool get showHashtags; bool get showSource; String? get twitterExtractionUrl; bool get isExtractingImage; bool get keepStructure;
/// Create a copy of GenerateUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenerateUiStateCopyWith<GenerateUiState> get copyWith => _$GenerateUiStateCopyWithImpl<GenerateUiState>(this as GenerateUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenerateUiState&&(identical(other.promptLength, promptLength) || other.promptLength == promptLength)&&(identical(other.status, status) || other.status == status)&&(identical(other.generatingStep, generatingStep) || other.generatingStep == generatingStep)&&(identical(other.curatedPost, curatedPost) || other.curatedPost == curatedPost)&&const DeepCollectionEquality().equals(other.historyStack, historyStack)&&const DeepCollectionEquality().equals(other.recentInputs, recentInputs)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.suggestedFallbackProvider, suggestedFallbackProvider) || other.suggestedFallbackProvider == suggestedFallbackProvider)&&(identical(other.validationMessage, validationMessage) || other.validationMessage == validationMessage)&&(identical(other.pendingInput, pendingInput) || other.pendingInput == pendingInput)&&(identical(other.isResearchModeEnabled, isResearchModeEnabled) || other.isResearchModeEnabled == isResearchModeEnabled)&&const DeepCollectionEquality().equals(other.searchSources, searchSources)&&(identical(other.showTitle, showTitle) || other.showTitle == showTitle)&&(identical(other.showHashtags, showHashtags) || other.showHashtags == showHashtags)&&(identical(other.showSource, showSource) || other.showSource == showSource)&&(identical(other.twitterExtractionUrl, twitterExtractionUrl) || other.twitterExtractionUrl == twitterExtractionUrl)&&(identical(other.isExtractingImage, isExtractingImage) || other.isExtractingImage == isExtractingImage)&&(identical(other.keepStructure, keepStructure) || other.keepStructure == keepStructure));
}


@override
int get hashCode => Object.hash(runtimeType,promptLength,status,generatingStep,curatedPost,const DeepCollectionEquality().hash(historyStack),const DeepCollectionEquality().hash(recentInputs),errorMessage,suggestedFallbackProvider,validationMessage,pendingInput,isResearchModeEnabled,const DeepCollectionEquality().hash(searchSources),showTitle,showHashtags,showSource,twitterExtractionUrl,isExtractingImage,keepStructure);

@override
String toString() {
  return 'GenerateUiState(promptLength: $promptLength, status: $status, generatingStep: $generatingStep, curatedPost: $curatedPost, historyStack: $historyStack, recentInputs: $recentInputs, errorMessage: $errorMessage, suggestedFallbackProvider: $suggestedFallbackProvider, validationMessage: $validationMessage, pendingInput: $pendingInput, isResearchModeEnabled: $isResearchModeEnabled, searchSources: $searchSources, showTitle: $showTitle, showHashtags: $showHashtags, showSource: $showSource, twitterExtractionUrl: $twitterExtractionUrl, isExtractingImage: $isExtractingImage, keepStructure: $keepStructure)';
}


}

/// @nodoc
abstract mixin class $GenerateUiStateCopyWith<$Res>  {
  factory $GenerateUiStateCopyWith(GenerateUiState value, $Res Function(GenerateUiState) _then) = _$GenerateUiStateCopyWithImpl;
@useResult
$Res call({
 PromptLength promptLength, GenerateState status, GeneratingStep generatingStep, CuratedPost? curatedPost, List<String> historyStack, List<String> recentInputs, String? errorMessage, AiProvider? suggestedFallbackProvider, String? validationMessage, String? pendingInput, bool isResearchModeEnabled, List<String> searchSources, bool showTitle, bool showHashtags, bool showSource, String? twitterExtractionUrl, bool isExtractingImage, bool keepStructure
});




}
/// @nodoc
class _$GenerateUiStateCopyWithImpl<$Res>
    implements $GenerateUiStateCopyWith<$Res> {
  _$GenerateUiStateCopyWithImpl(this._self, this._then);

  final GenerateUiState _self;
  final $Res Function(GenerateUiState) _then;

/// Create a copy of GenerateUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? promptLength = null,Object? status = null,Object? generatingStep = null,Object? curatedPost = freezed,Object? historyStack = null,Object? recentInputs = null,Object? errorMessage = freezed,Object? suggestedFallbackProvider = freezed,Object? validationMessage = freezed,Object? pendingInput = freezed,Object? isResearchModeEnabled = null,Object? searchSources = null,Object? showTitle = null,Object? showHashtags = null,Object? showSource = null,Object? twitterExtractionUrl = freezed,Object? isExtractingImage = null,Object? keepStructure = null,}) {
  return _then(GenerateUiState(
promptLength: null == promptLength ? _self.promptLength : promptLength // ignore: cast_nullable_to_non_nullable
as PromptLength,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GenerateState,generatingStep: null == generatingStep ? _self.generatingStep : generatingStep // ignore: cast_nullable_to_non_nullable
as GeneratingStep,curatedPost: freezed == curatedPost ? _self.curatedPost : curatedPost // ignore: cast_nullable_to_non_nullable
as CuratedPost?,historyStack: null == historyStack ? _self.historyStack : historyStack // ignore: cast_nullable_to_non_nullable
as List<String>,recentInputs: null == recentInputs ? _self.recentInputs : recentInputs // ignore: cast_nullable_to_non_nullable
as List<String>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,suggestedFallbackProvider: freezed == suggestedFallbackProvider ? _self.suggestedFallbackProvider : suggestedFallbackProvider // ignore: cast_nullable_to_non_nullable
as AiProvider?,validationMessage: freezed == validationMessage ? _self.validationMessage : validationMessage // ignore: cast_nullable_to_non_nullable
as String?,pendingInput: freezed == pendingInput ? _self.pendingInput : pendingInput // ignore: cast_nullable_to_non_nullable
as String?,isResearchModeEnabled: null == isResearchModeEnabled ? _self.isResearchModeEnabled : isResearchModeEnabled // ignore: cast_nullable_to_non_nullable
as bool,searchSources: null == searchSources ? _self.searchSources : searchSources // ignore: cast_nullable_to_non_nullable
as List<String>,showTitle: null == showTitle ? _self.showTitle : showTitle // ignore: cast_nullable_to_non_nullable
as bool,showHashtags: null == showHashtags ? _self.showHashtags : showHashtags // ignore: cast_nullable_to_non_nullable
as bool,showSource: null == showSource ? _self.showSource : showSource // ignore: cast_nullable_to_non_nullable
as bool,twitterExtractionUrl: freezed == twitterExtractionUrl ? _self.twitterExtractionUrl : twitterExtractionUrl // ignore: cast_nullable_to_non_nullable
as String?,isExtractingImage: null == isExtractingImage ? _self.isExtractingImage : isExtractingImage // ignore: cast_nullable_to_non_nullable
as bool,keepStructure: null == keepStructure ? _self.keepStructure : keepStructure // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GenerateUiState].
extension GenerateUiStatePatterns on GenerateUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GenerateUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GenerateUiState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GenerateUiState value)  $default,){
final _that = this;
switch (_that) {
case _GenerateUiState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GenerateUiState value)?  $default,){
final _that = this;
switch (_that) {
case _GenerateUiState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PromptLength promptLength,  GenerateState status,  GeneratingStep generatingStep,  CuratedPost? curatedPost,  List<String> historyStack,  List<String> recentInputs,  String? errorMessage,  AiProvider? suggestedFallbackProvider,  String? validationMessage,  String? pendingInput,  bool isResearchModeEnabled,  List<String> searchSources,  bool showTitle,  bool showHashtags,  bool showSource,  String? twitterExtractionUrl,  bool isExtractingImage,  bool keepStructure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GenerateUiState() when $default != null:
return $default(_that.promptLength,_that.status,_that.generatingStep,_that.curatedPost,_that.historyStack,_that.recentInputs,_that.errorMessage,_that.suggestedFallbackProvider,_that.validationMessage,_that.pendingInput,_that.isResearchModeEnabled,_that.searchSources,_that.showTitle,_that.showHashtags,_that.showSource,_that.twitterExtractionUrl,_that.isExtractingImage,_that.keepStructure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PromptLength promptLength,  GenerateState status,  GeneratingStep generatingStep,  CuratedPost? curatedPost,  List<String> historyStack,  List<String> recentInputs,  String? errorMessage,  AiProvider? suggestedFallbackProvider,  String? validationMessage,  String? pendingInput,  bool isResearchModeEnabled,  List<String> searchSources,  bool showTitle,  bool showHashtags,  bool showSource,  String? twitterExtractionUrl,  bool isExtractingImage,  bool keepStructure)  $default,) {final _that = this;
switch (_that) {
case _GenerateUiState():
return $default(_that.promptLength,_that.status,_that.generatingStep,_that.curatedPost,_that.historyStack,_that.recentInputs,_that.errorMessage,_that.suggestedFallbackProvider,_that.validationMessage,_that.pendingInput,_that.isResearchModeEnabled,_that.searchSources,_that.showTitle,_that.showHashtags,_that.showSource,_that.twitterExtractionUrl,_that.isExtractingImage,_that.keepStructure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PromptLength promptLength,  GenerateState status,  GeneratingStep generatingStep,  CuratedPost? curatedPost,  List<String> historyStack,  List<String> recentInputs,  String? errorMessage,  AiProvider? suggestedFallbackProvider,  String? validationMessage,  String? pendingInput,  bool isResearchModeEnabled,  List<String> searchSources,  bool showTitle,  bool showHashtags,  bool showSource,  String? twitterExtractionUrl,  bool isExtractingImage,  bool keepStructure)?  $default,) {final _that = this;
switch (_that) {
case _GenerateUiState() when $default != null:
return $default(_that.promptLength,_that.status,_that.generatingStep,_that.curatedPost,_that.historyStack,_that.recentInputs,_that.errorMessage,_that.suggestedFallbackProvider,_that.validationMessage,_that.pendingInput,_that.isResearchModeEnabled,_that.searchSources,_that.showTitle,_that.showHashtags,_that.showSource,_that.twitterExtractionUrl,_that.isExtractingImage,_that.keepStructure);case _:
  return null;

}
}

}

/// @nodoc


class _GenerateUiState extends GenerateUiState {
  const _GenerateUiState({this.promptLength = PromptLength.medium, this.status = GenerateState.idle, this.generatingStep = GeneratingStep.idle, this.curatedPost,  List<String> historyStack = const [],  List<String> recentInputs = const [], this.errorMessage, this.suggestedFallbackProvider, this.validationMessage, this.pendingInput, this.isResearchModeEnabled = false,  List<String> searchSources = const [], this.showTitle = true, this.showHashtags = true, this.showSource = true, this.twitterExtractionUrl, this.isExtractingImage = false, this.keepStructure = false}): _historyStack = historyStack,_recentInputs = recentInputs,_searchSources = searchSources,super._();
  

@override@JsonKey() final  PromptLength promptLength;
@override@JsonKey() final  GenerateState status;
@override@JsonKey() final  GeneratingStep generatingStep;
@override final  CuratedPost? curatedPost;
 final  List<String> _historyStack;
@override@JsonKey() List<String> get historyStack {
  if (_historyStack is EqualUnmodifiableListView) return _historyStack;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_historyStack);
}

 final  List<String> _recentInputs;
@override@JsonKey() List<String> get recentInputs {
  if (_recentInputs is EqualUnmodifiableListView) return _recentInputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentInputs);
}

@override final  String? errorMessage;
@override final  AiProvider? suggestedFallbackProvider;
@override final  String? validationMessage;
@override final  String? pendingInput;
@override@JsonKey() final  bool isResearchModeEnabled;
 final  List<String> _searchSources;
@override@JsonKey() List<String> get searchSources {
  if (_searchSources is EqualUnmodifiableListView) return _searchSources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchSources);
}

@override@JsonKey() final  bool showTitle;
@override@JsonKey() final  bool showHashtags;
@override@JsonKey() final  bool showSource;
@override final  String? twitterExtractionUrl;
@override@JsonKey() final  bool isExtractingImage;
@override@JsonKey() final  bool keepStructure;

/// Create a copy of GenerateUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenerateUiStateCopyWith<_GenerateUiState> get copyWith => __$GenerateUiStateCopyWithImpl<_GenerateUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GenerateUiState&&(identical(other.promptLength, promptLength) || other.promptLength == promptLength)&&(identical(other.status, status) || other.status == status)&&(identical(other.generatingStep, generatingStep) || other.generatingStep == generatingStep)&&(identical(other.curatedPost, curatedPost) || other.curatedPost == curatedPost)&&const DeepCollectionEquality().equals(other._historyStack, _historyStack)&&const DeepCollectionEquality().equals(other._recentInputs, _recentInputs)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.suggestedFallbackProvider, suggestedFallbackProvider) || other.suggestedFallbackProvider == suggestedFallbackProvider)&&(identical(other.validationMessage, validationMessage) || other.validationMessage == validationMessage)&&(identical(other.pendingInput, pendingInput) || other.pendingInput == pendingInput)&&(identical(other.isResearchModeEnabled, isResearchModeEnabled) || other.isResearchModeEnabled == isResearchModeEnabled)&&const DeepCollectionEquality().equals(other._searchSources, _searchSources)&&(identical(other.showTitle, showTitle) || other.showTitle == showTitle)&&(identical(other.showHashtags, showHashtags) || other.showHashtags == showHashtags)&&(identical(other.showSource, showSource) || other.showSource == showSource)&&(identical(other.twitterExtractionUrl, twitterExtractionUrl) || other.twitterExtractionUrl == twitterExtractionUrl)&&(identical(other.isExtractingImage, isExtractingImage) || other.isExtractingImage == isExtractingImage)&&(identical(other.keepStructure, keepStructure) || other.keepStructure == keepStructure));
}


@override
int get hashCode => Object.hash(runtimeType,promptLength,status,generatingStep,curatedPost,const DeepCollectionEquality().hash(_historyStack),const DeepCollectionEquality().hash(_recentInputs),errorMessage,suggestedFallbackProvider,validationMessage,pendingInput,isResearchModeEnabled,const DeepCollectionEquality().hash(_searchSources),showTitle,showHashtags,showSource,twitterExtractionUrl,isExtractingImage,keepStructure);

@override
String toString() {
  return 'GenerateUiState(promptLength: $promptLength, status: $status, generatingStep: $generatingStep, curatedPost: $curatedPost, historyStack: $historyStack, recentInputs: $recentInputs, errorMessage: $errorMessage, suggestedFallbackProvider: $suggestedFallbackProvider, validationMessage: $validationMessage, pendingInput: $pendingInput, isResearchModeEnabled: $isResearchModeEnabled, searchSources: $searchSources, showTitle: $showTitle, showHashtags: $showHashtags, showSource: $showSource, twitterExtractionUrl: $twitterExtractionUrl, isExtractingImage: $isExtractingImage, keepStructure: $keepStructure)';
}


}

/// @nodoc
abstract mixin class _$GenerateUiStateCopyWith<$Res> implements $GenerateUiStateCopyWith<$Res> {
  factory _$GenerateUiStateCopyWith(_GenerateUiState value, $Res Function(_GenerateUiState) _then) = __$GenerateUiStateCopyWithImpl;
@override @useResult
$Res call({
 PromptLength promptLength, GenerateState status, GeneratingStep generatingStep, CuratedPost? curatedPost, List<String> historyStack, List<String> recentInputs, String? errorMessage, AiProvider? suggestedFallbackProvider, String? validationMessage, String? pendingInput, bool isResearchModeEnabled, List<String> searchSources, bool showTitle, bool showHashtags, bool showSource, String? twitterExtractionUrl, bool isExtractingImage, bool keepStructure
});




}
/// @nodoc
class __$GenerateUiStateCopyWithImpl<$Res>
    implements _$GenerateUiStateCopyWith<$Res> {
  __$GenerateUiStateCopyWithImpl(this._self, this._then);

  final _GenerateUiState _self;
  final $Res Function(_GenerateUiState) _then;

/// Create a copy of GenerateUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? promptLength = null,Object? status = null,Object? generatingStep = null,Object? curatedPost = freezed,Object? historyStack = null,Object? recentInputs = null,Object? errorMessage = freezed,Object? suggestedFallbackProvider = freezed,Object? validationMessage = freezed,Object? pendingInput = freezed,Object? isResearchModeEnabled = null,Object? searchSources = null,Object? showTitle = null,Object? showHashtags = null,Object? showSource = null,Object? twitterExtractionUrl = freezed,Object? isExtractingImage = null,Object? keepStructure = null,}) {
  return _then(_GenerateUiState(
promptLength: null == promptLength ? _self.promptLength : promptLength // ignore: cast_nullable_to_non_nullable
as PromptLength,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GenerateState,generatingStep: null == generatingStep ? _self.generatingStep : generatingStep // ignore: cast_nullable_to_non_nullable
as GeneratingStep,curatedPost: freezed == curatedPost ? _self.curatedPost : curatedPost // ignore: cast_nullable_to_non_nullable
as CuratedPost?,historyStack: null == historyStack ? _self._historyStack : historyStack // ignore: cast_nullable_to_non_nullable
as List<String>,recentInputs: null == recentInputs ? _self._recentInputs : recentInputs // ignore: cast_nullable_to_non_nullable
as List<String>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,suggestedFallbackProvider: freezed == suggestedFallbackProvider ? _self.suggestedFallbackProvider : suggestedFallbackProvider // ignore: cast_nullable_to_non_nullable
as AiProvider?,validationMessage: freezed == validationMessage ? _self.validationMessage : validationMessage // ignore: cast_nullable_to_non_nullable
as String?,pendingInput: freezed == pendingInput ? _self.pendingInput : pendingInput // ignore: cast_nullable_to_non_nullable
as String?,isResearchModeEnabled: null == isResearchModeEnabled ? _self.isResearchModeEnabled : isResearchModeEnabled // ignore: cast_nullable_to_non_nullable
as bool,searchSources: null == searchSources ? _self._searchSources : searchSources // ignore: cast_nullable_to_non_nullable
as List<String>,showTitle: null == showTitle ? _self.showTitle : showTitle // ignore: cast_nullable_to_non_nullable
as bool,showHashtags: null == showHashtags ? _self.showHashtags : showHashtags // ignore: cast_nullable_to_non_nullable
as bool,showSource: null == showSource ? _self.showSource : showSource // ignore: cast_nullable_to_non_nullable
as bool,twitterExtractionUrl: freezed == twitterExtractionUrl ? _self.twitterExtractionUrl : twitterExtractionUrl // ignore: cast_nullable_to_non_nullable
as String?,isExtractingImage: null == isExtractingImage ? _self.isExtractingImage : isExtractingImage // ignore: cast_nullable_to_non_nullable
as bool,keepStructure: null == keepStructure ? _self.keepStructure : keepStructure // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
