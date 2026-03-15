// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credit_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreditState {

 bool get showTopUpField;
/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditStateCopyWith<CreditState> get copyWith => _$CreditStateCopyWithImpl<CreditState>(this as CreditState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditState&&(identical(other.showTopUpField, showTopUpField) || other.showTopUpField == showTopUpField));
}


@override
int get hashCode => Object.hash(runtimeType,showTopUpField);

@override
String toString() {
  return 'CreditState(showTopUpField: $showTopUpField)';
}


}

/// @nodoc
abstract mixin class $CreditStateCopyWith<$Res>  {
  factory $CreditStateCopyWith(CreditState value, $Res Function(CreditState) _then) = _$CreditStateCopyWithImpl;
@useResult
$Res call({
 bool showTopUpField
});




}
/// @nodoc
class _$CreditStateCopyWithImpl<$Res>
    implements $CreditStateCopyWith<$Res> {
  _$CreditStateCopyWithImpl(this._self, this._then);

  final CreditState _self;
  final $Res Function(CreditState) _then;

/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showTopUpField = null,}) {
  return _then(_self.copyWith(
showTopUpField: null == showTopUpField ? _self.showTopUpField : showTopUpField // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CreditState].
extension CreditStatePatterns on CreditState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool showTopUpField)?  initial,TResult Function( bool showTopUpField)?  loading,TResult Function( String paymentSessionUrl,  bool showTopUpField)?  loaded,TResult Function( String message,  bool showTopUpField)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that.showTopUpField);case _Loading() when loading != null:
return loading(_that.showTopUpField);case _Loaded() when loaded != null:
return loaded(_that.paymentSessionUrl,_that.showTopUpField);case _Error() when error != null:
return error(_that.message,_that.showTopUpField);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool showTopUpField)  initial,required TResult Function( bool showTopUpField)  loading,required TResult Function( String paymentSessionUrl,  bool showTopUpField)  loaded,required TResult Function( String message,  bool showTopUpField)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial(_that.showTopUpField);case _Loading():
return loading(_that.showTopUpField);case _Loaded():
return loaded(_that.paymentSessionUrl,_that.showTopUpField);case _Error():
return error(_that.message,_that.showTopUpField);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool showTopUpField)?  initial,TResult? Function( bool showTopUpField)?  loading,TResult? Function( String paymentSessionUrl,  bool showTopUpField)?  loaded,TResult? Function( String message,  bool showTopUpField)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that.showTopUpField);case _Loading() when loading != null:
return loading(_that.showTopUpField);case _Loaded() when loaded != null:
return loaded(_that.paymentSessionUrl,_that.showTopUpField);case _Error() when error != null:
return error(_that.message,_that.showTopUpField);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements CreditState {
  const _Initial({this.showTopUpField = false});
  

@override@JsonKey() final  bool showTopUpField;

/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InitialCopyWith<_Initial> get copyWith => __$InitialCopyWithImpl<_Initial>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial&&(identical(other.showTopUpField, showTopUpField) || other.showTopUpField == showTopUpField));
}


@override
int get hashCode => Object.hash(runtimeType,showTopUpField);

@override
String toString() {
  return 'CreditState.initial(showTopUpField: $showTopUpField)';
}


}

/// @nodoc
abstract mixin class _$InitialCopyWith<$Res> implements $CreditStateCopyWith<$Res> {
  factory _$InitialCopyWith(_Initial value, $Res Function(_Initial) _then) = __$InitialCopyWithImpl;
@override @useResult
$Res call({
 bool showTopUpField
});




}
/// @nodoc
class __$InitialCopyWithImpl<$Res>
    implements _$InitialCopyWith<$Res> {
  __$InitialCopyWithImpl(this._self, this._then);

  final _Initial _self;
  final $Res Function(_Initial) _then;

/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? showTopUpField = null,}) {
  return _then(_Initial(
showTopUpField: null == showTopUpField ? _self.showTopUpField : showTopUpField // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _Loading implements CreditState {
  const _Loading({this.showTopUpField = false});
  

@override@JsonKey() final  bool showTopUpField;

/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadingCopyWith<_Loading> get copyWith => __$LoadingCopyWithImpl<_Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading&&(identical(other.showTopUpField, showTopUpField) || other.showTopUpField == showTopUpField));
}


@override
int get hashCode => Object.hash(runtimeType,showTopUpField);

@override
String toString() {
  return 'CreditState.loading(showTopUpField: $showTopUpField)';
}


}

/// @nodoc
abstract mixin class _$LoadingCopyWith<$Res> implements $CreditStateCopyWith<$Res> {
  factory _$LoadingCopyWith(_Loading value, $Res Function(_Loading) _then) = __$LoadingCopyWithImpl;
@override @useResult
$Res call({
 bool showTopUpField
});




}
/// @nodoc
class __$LoadingCopyWithImpl<$Res>
    implements _$LoadingCopyWith<$Res> {
  __$LoadingCopyWithImpl(this._self, this._then);

  final _Loading _self;
  final $Res Function(_Loading) _then;

/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? showTopUpField = null,}) {
  return _then(_Loading(
showTopUpField: null == showTopUpField ? _self.showTopUpField : showTopUpField // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _Loaded implements CreditState {
  const _Loaded({required this.paymentSessionUrl, this.showTopUpField = false});
  

 final  String paymentSessionUrl;
@override@JsonKey() final  bool showTopUpField;

/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.paymentSessionUrl, paymentSessionUrl) || other.paymentSessionUrl == paymentSessionUrl)&&(identical(other.showTopUpField, showTopUpField) || other.showTopUpField == showTopUpField));
}


@override
int get hashCode => Object.hash(runtimeType,paymentSessionUrl,showTopUpField);

@override
String toString() {
  return 'CreditState.loaded(paymentSessionUrl: $paymentSessionUrl, showTopUpField: $showTopUpField)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $CreditStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@override @useResult
$Res call({
 String paymentSessionUrl, bool showTopUpField
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paymentSessionUrl = null,Object? showTopUpField = null,}) {
  return _then(_Loaded(
paymentSessionUrl: null == paymentSessionUrl ? _self.paymentSessionUrl : paymentSessionUrl // ignore: cast_nullable_to_non_nullable
as String,showTopUpField: null == showTopUpField ? _self.showTopUpField : showTopUpField // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _Error implements CreditState {
  const _Error({required this.message, this.showTopUpField = false});
  

 final  String message;
@override@JsonKey() final  bool showTopUpField;

/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message)&&(identical(other.showTopUpField, showTopUpField) || other.showTopUpField == showTopUpField));
}


@override
int get hashCode => Object.hash(runtimeType,message,showTopUpField);

@override
String toString() {
  return 'CreditState.error(message: $message, showTopUpField: $showTopUpField)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $CreditStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@override @useResult
$Res call({
 String message, bool showTopUpField
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of CreditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? showTopUpField = null,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,showTopUpField: null == showTopUpField ? _self.showTopUpField : showTopUpField // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
