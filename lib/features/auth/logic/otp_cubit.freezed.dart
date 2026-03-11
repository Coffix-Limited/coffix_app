// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OtpState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpState()';
}


}

/// @nodoc
class $OtpStateCopyWith<$Res>  {
$OtpStateCopyWith(OtpState _, $Res Function(OtpState) __);
}


/// Adds pattern-matching-related methods to [OtpState].
extension OtpStatePatterns on OtpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Sending value)?  sending,TResult Function( _Error value)?  error,TResult Function( _OtpSent value)?  otpSent,TResult Function( _Verifying value)?  verifying,TResult Function( _Verified value)?  verified,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Sending() when sending != null:
return sending(_that);case _Error() when error != null:
return error(_that);case _OtpSent() when otpSent != null:
return otpSent(_that);case _Verifying() when verifying != null:
return verifying(_that);case _Verified() when verified != null:
return verified(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Sending value)  sending,required TResult Function( _Error value)  error,required TResult Function( _OtpSent value)  otpSent,required TResult Function( _Verifying value)  verifying,required TResult Function( _Verified value)  verified,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Sending():
return sending(_that);case _Error():
return error(_that);case _OtpSent():
return otpSent(_that);case _Verifying():
return verifying(_that);case _Verified():
return verified(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Sending value)?  sending,TResult? Function( _Error value)?  error,TResult? Function( _OtpSent value)?  otpSent,TResult? Function( _Verifying value)?  verifying,TResult? Function( _Verified value)?  verified,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Sending() when sending != null:
return sending(_that);case _Error() when error != null:
return error(_that);case _OtpSent() when otpSent != null:
return otpSent(_that);case _Verifying() when verifying != null:
return verifying(_that);case _Verified() when verified != null:
return verified(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  sending,TResult Function( String message)?  error,TResult Function( String email)?  otpSent,TResult Function()?  verifying,TResult Function()?  verified,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Sending() when sending != null:
return sending();case _Error() when error != null:
return error(_that.message);case _OtpSent() when otpSent != null:
return otpSent(_that.email);case _Verifying() when verifying != null:
return verifying();case _Verified() when verified != null:
return verified();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  sending,required TResult Function( String message)  error,required TResult Function( String email)  otpSent,required TResult Function()  verifying,required TResult Function()  verified,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Sending():
return sending();case _Error():
return error(_that.message);case _OtpSent():
return otpSent(_that.email);case _Verifying():
return verifying();case _Verified():
return verified();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  sending,TResult? Function( String message)?  error,TResult? Function( String email)?  otpSent,TResult? Function()?  verifying,TResult? Function()?  verified,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Sending() when sending != null:
return sending();case _Error() when error != null:
return error(_that.message);case _OtpSent() when otpSent != null:
return otpSent(_that.email);case _Verifying() when verifying != null:
return verifying();case _Verified() when verified != null:
return verified();case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements OtpState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpState.initial()';
}


}




/// @nodoc


class _Sending implements OtpState {
  const _Sending();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpState.sending()';
}


}




/// @nodoc


class _Error implements OtpState {
  const _Error({required this.message});
  

 final  String message;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'OtpState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $OtpStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _OtpSent implements OtpState {
  const _OtpSent({required this.email});
  

 final  String email;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpSentCopyWith<_OtpSent> get copyWith => __$OtpSentCopyWithImpl<_OtpSent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpSent&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'OtpState.otpSent(email: $email)';
}


}

/// @nodoc
abstract mixin class _$OtpSentCopyWith<$Res> implements $OtpStateCopyWith<$Res> {
  factory _$OtpSentCopyWith(_OtpSent value, $Res Function(_OtpSent) _then) = __$OtpSentCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class __$OtpSentCopyWithImpl<$Res>
    implements _$OtpSentCopyWith<$Res> {
  __$OtpSentCopyWithImpl(this._self, this._then);

  final _OtpSent _self;
  final $Res Function(_OtpSent) _then;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(_OtpSent(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Verifying implements OtpState {
  const _Verifying();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Verifying);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpState.verifying()';
}


}




/// @nodoc


class _Verified implements OtpState {
  const _Verified();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Verified);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpState.verified()';
}


}




// dart format on
