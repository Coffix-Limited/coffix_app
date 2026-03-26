// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draft_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DraftState {

 List<Draft> get drafts;
/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftStateCopyWith<DraftState> get copyWith => _$DraftStateCopyWithImpl<DraftState>(this as DraftState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftState&&const DeepCollectionEquality().equals(other.drafts, drafts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(drafts));

@override
String toString() {
  return 'DraftState(drafts: $drafts)';
}


}

/// @nodoc
abstract mixin class $DraftStateCopyWith<$Res>  {
  factory $DraftStateCopyWith(DraftState value, $Res Function(DraftState) _then) = _$DraftStateCopyWithImpl;
@useResult
$Res call({
 List<Draft> drafts
});




}
/// @nodoc
class _$DraftStateCopyWithImpl<$Res>
    implements $DraftStateCopyWith<$Res> {
  _$DraftStateCopyWithImpl(this._self, this._then);

  final DraftState _self;
  final $Res Function(DraftState) _then;

/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? drafts = null,}) {
  return _then(_self.copyWith(
drafts: null == drafts ? _self.drafts : drafts // ignore: cast_nullable_to_non_nullable
as List<Draft>,
  ));
}

}


/// Adds pattern-matching-related methods to [DraftState].
extension DraftStatePatterns on DraftState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _Error():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<Draft> drafts)?  initial,TResult Function( List<Draft> drafts)?  loading,TResult Function( List<Draft> drafts)?  loaded,TResult Function( String message,  List<Draft> drafts)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that.drafts);case _Loading() when loading != null:
return loading(_that.drafts);case _Loaded() when loaded != null:
return loaded(_that.drafts);case _Error() when error != null:
return error(_that.message,_that.drafts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<Draft> drafts)  initial,required TResult Function( List<Draft> drafts)  loading,required TResult Function( List<Draft> drafts)  loaded,required TResult Function( String message,  List<Draft> drafts)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial(_that.drafts);case _Loading():
return loading(_that.drafts);case _Loaded():
return loaded(_that.drafts);case _Error():
return error(_that.message,_that.drafts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<Draft> drafts)?  initial,TResult? Function( List<Draft> drafts)?  loading,TResult? Function( List<Draft> drafts)?  loaded,TResult? Function( String message,  List<Draft> drafts)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that.drafts);case _Loading() when loading != null:
return loading(_that.drafts);case _Loaded() when loaded != null:
return loaded(_that.drafts);case _Error() when error != null:
return error(_that.message,_that.drafts);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements DraftState {
  const _Initial({final  List<Draft> drafts = const []}): _drafts = drafts;
  

 final  List<Draft> _drafts;
@override@JsonKey() List<Draft> get drafts {
  if (_drafts is EqualUnmodifiableListView) return _drafts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_drafts);
}


/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InitialCopyWith<_Initial> get copyWith => __$InitialCopyWithImpl<_Initial>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial&&const DeepCollectionEquality().equals(other._drafts, _drafts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_drafts));

@override
String toString() {
  return 'DraftState.initial(drafts: $drafts)';
}


}

/// @nodoc
abstract mixin class _$InitialCopyWith<$Res> implements $DraftStateCopyWith<$Res> {
  factory _$InitialCopyWith(_Initial value, $Res Function(_Initial) _then) = __$InitialCopyWithImpl;
@override @useResult
$Res call({
 List<Draft> drafts
});




}
/// @nodoc
class __$InitialCopyWithImpl<$Res>
    implements _$InitialCopyWith<$Res> {
  __$InitialCopyWithImpl(this._self, this._then);

  final _Initial _self;
  final $Res Function(_Initial) _then;

/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? drafts = null,}) {
  return _then(_Initial(
drafts: null == drafts ? _self._drafts : drafts // ignore: cast_nullable_to_non_nullable
as List<Draft>,
  ));
}


}

/// @nodoc


class _Loading implements DraftState {
  const _Loading({final  List<Draft> drafts = const []}): _drafts = drafts;
  

 final  List<Draft> _drafts;
@override@JsonKey() List<Draft> get drafts {
  if (_drafts is EqualUnmodifiableListView) return _drafts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_drafts);
}


/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadingCopyWith<_Loading> get copyWith => __$LoadingCopyWithImpl<_Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading&&const DeepCollectionEquality().equals(other._drafts, _drafts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_drafts));

@override
String toString() {
  return 'DraftState.loading(drafts: $drafts)';
}


}

/// @nodoc
abstract mixin class _$LoadingCopyWith<$Res> implements $DraftStateCopyWith<$Res> {
  factory _$LoadingCopyWith(_Loading value, $Res Function(_Loading) _then) = __$LoadingCopyWithImpl;
@override @useResult
$Res call({
 List<Draft> drafts
});




}
/// @nodoc
class __$LoadingCopyWithImpl<$Res>
    implements _$LoadingCopyWith<$Res> {
  __$LoadingCopyWithImpl(this._self, this._then);

  final _Loading _self;
  final $Res Function(_Loading) _then;

/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? drafts = null,}) {
  return _then(_Loading(
drafts: null == drafts ? _self._drafts : drafts // ignore: cast_nullable_to_non_nullable
as List<Draft>,
  ));
}


}

/// @nodoc


class _Loaded implements DraftState {
  const _Loaded({final  List<Draft> drafts = const []}): _drafts = drafts;
  

 final  List<Draft> _drafts;
@override@JsonKey() List<Draft> get drafts {
  if (_drafts is EqualUnmodifiableListView) return _drafts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_drafts);
}


/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._drafts, _drafts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_drafts));

@override
String toString() {
  return 'DraftState.loaded(drafts: $drafts)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $DraftStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@override @useResult
$Res call({
 List<Draft> drafts
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? drafts = null,}) {
  return _then(_Loaded(
drafts: null == drafts ? _self._drafts : drafts // ignore: cast_nullable_to_non_nullable
as List<Draft>,
  ));
}


}

/// @nodoc


class _Error implements DraftState {
  const _Error({required this.message, final  List<Draft> drafts = const []}): _drafts = drafts;
  

 final  String message;
 final  List<Draft> _drafts;
@override@JsonKey() List<Draft> get drafts {
  if (_drafts is EqualUnmodifiableListView) return _drafts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_drafts);
}


/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._drafts, _drafts));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(_drafts));

@override
String toString() {
  return 'DraftState.error(message: $message, drafts: $drafts)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $DraftStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@override @useResult
$Res call({
 String message, List<Draft> drafts
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of DraftState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? drafts = null,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,drafts: null == drafts ? _self._drafts : drafts // ignore: cast_nullable_to_non_nullable
as List<Draft>,
  ));
}


}

// dart format on
