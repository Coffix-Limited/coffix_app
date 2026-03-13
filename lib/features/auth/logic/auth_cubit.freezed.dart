// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState()';
}


}

/// @nodoc
class $AuthStateCopyWith<$Res>  {
$AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _EmailNotVerified value)?  emailNotVerified,TResult Function( _Authenticated value)?  authenticated,TResult Function( _HasAccount value)?  hasAccount,TResult Function( _Unauthenticated value)?  unauthenticated,TResult Function( _OtpSent value)?  otpSent,TResult Function( _Error value)?  error,TResult Function( _ForgotPassword value)?  forgotPassword,TResult Function( _PasswordResetEmailSent value)?  passwordResetEmailSent,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _EmailNotVerified() when emailNotVerified != null:
return emailNotVerified(_that);case _Authenticated() when authenticated != null:
return authenticated(_that);case _HasAccount() when hasAccount != null:
return hasAccount(_that);case _Unauthenticated() when unauthenticated != null:
return unauthenticated(_that);case _OtpSent() when otpSent != null:
return otpSent(_that);case _Error() when error != null:
return error(_that);case _ForgotPassword() when forgotPassword != null:
return forgotPassword(_that);case _PasswordResetEmailSent() when passwordResetEmailSent != null:
return passwordResetEmailSent(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _EmailNotVerified value)  emailNotVerified,required TResult Function( _Authenticated value)  authenticated,required TResult Function( _HasAccount value)  hasAccount,required TResult Function( _Unauthenticated value)  unauthenticated,required TResult Function( _OtpSent value)  otpSent,required TResult Function( _Error value)  error,required TResult Function( _ForgotPassword value)  forgotPassword,required TResult Function( _PasswordResetEmailSent value)  passwordResetEmailSent,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _EmailNotVerified():
return emailNotVerified(_that);case _Authenticated():
return authenticated(_that);case _HasAccount():
return hasAccount(_that);case _Unauthenticated():
return unauthenticated(_that);case _OtpSent():
return otpSent(_that);case _Error():
return error(_that);case _ForgotPassword():
return forgotPassword(_that);case _PasswordResetEmailSent():
return passwordResetEmailSent(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _EmailNotVerified value)?  emailNotVerified,TResult? Function( _Authenticated value)?  authenticated,TResult? Function( _HasAccount value)?  hasAccount,TResult? Function( _Unauthenticated value)?  unauthenticated,TResult? Function( _OtpSent value)?  otpSent,TResult? Function( _Error value)?  error,TResult? Function( _ForgotPassword value)?  forgotPassword,TResult? Function( _PasswordResetEmailSent value)?  passwordResetEmailSent,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _EmailNotVerified() when emailNotVerified != null:
return emailNotVerified(_that);case _Authenticated() when authenticated != null:
return authenticated(_that);case _HasAccount() when hasAccount != null:
return hasAccount(_that);case _Unauthenticated() when unauthenticated != null:
return unauthenticated(_that);case _OtpSent() when otpSent != null:
return otpSent(_that);case _Error() when error != null:
return error(_that);case _ForgotPassword() when forgotPassword != null:
return forgotPassword(_that);case _PasswordResetEmailSent() when passwordResetEmailSent != null:
return passwordResetEmailSent(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  emailNotVerified,TResult Function( AppUserWithStore userWithStore)?  authenticated,TResult Function( bool hasAccount)?  hasAccount,TResult Function()?  unauthenticated,TResult Function( String email)?  otpSent,TResult Function( String message)?  error,TResult Function()?  forgotPassword,TResult Function()?  passwordResetEmailSent,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _EmailNotVerified() when emailNotVerified != null:
return emailNotVerified();case _Authenticated() when authenticated != null:
return authenticated(_that.userWithStore);case _HasAccount() when hasAccount != null:
return hasAccount(_that.hasAccount);case _Unauthenticated() when unauthenticated != null:
return unauthenticated();case _OtpSent() when otpSent != null:
return otpSent(_that.email);case _Error() when error != null:
return error(_that.message);case _ForgotPassword() when forgotPassword != null:
return forgotPassword();case _PasswordResetEmailSent() when passwordResetEmailSent != null:
return passwordResetEmailSent();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  emailNotVerified,required TResult Function( AppUserWithStore userWithStore)  authenticated,required TResult Function( bool hasAccount)  hasAccount,required TResult Function()  unauthenticated,required TResult Function( String email)  otpSent,required TResult Function( String message)  error,required TResult Function()  forgotPassword,required TResult Function()  passwordResetEmailSent,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _EmailNotVerified():
return emailNotVerified();case _Authenticated():
return authenticated(_that.userWithStore);case _HasAccount():
return hasAccount(_that.hasAccount);case _Unauthenticated():
return unauthenticated();case _OtpSent():
return otpSent(_that.email);case _Error():
return error(_that.message);case _ForgotPassword():
return forgotPassword();case _PasswordResetEmailSent():
return passwordResetEmailSent();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  emailNotVerified,TResult? Function( AppUserWithStore userWithStore)?  authenticated,TResult? Function( bool hasAccount)?  hasAccount,TResult? Function()?  unauthenticated,TResult? Function( String email)?  otpSent,TResult? Function( String message)?  error,TResult? Function()?  forgotPassword,TResult? Function()?  passwordResetEmailSent,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _EmailNotVerified() when emailNotVerified != null:
return emailNotVerified();case _Authenticated() when authenticated != null:
return authenticated(_that.userWithStore);case _HasAccount() when hasAccount != null:
return hasAccount(_that.hasAccount);case _Unauthenticated() when unauthenticated != null:
return unauthenticated();case _OtpSent() when otpSent != null:
return otpSent(_that.email);case _Error() when error != null:
return error(_that.message);case _ForgotPassword() when forgotPassword != null:
return forgotPassword();case _PasswordResetEmailSent() when passwordResetEmailSent != null:
return passwordResetEmailSent();case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements AuthState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.initial()';
}


}




/// @nodoc


class _Loading implements AuthState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.loading()';
}


}




/// @nodoc


class _EmailNotVerified implements AuthState {
  const _EmailNotVerified();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmailNotVerified);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.emailNotVerified()';
}


}




/// @nodoc


class _Authenticated implements AuthState {
  const _Authenticated({required this.userWithStore});
  

 final  AppUserWithStore userWithStore;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthenticatedCopyWith<_Authenticated> get copyWith => __$AuthenticatedCopyWithImpl<_Authenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Authenticated&&(identical(other.userWithStore, userWithStore) || other.userWithStore == userWithStore));
}


@override
int get hashCode => Object.hash(runtimeType,userWithStore);

@override
String toString() {
  return 'AuthState.authenticated(userWithStore: $userWithStore)';
}


}

/// @nodoc
abstract mixin class _$AuthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$AuthenticatedCopyWith(_Authenticated value, $Res Function(_Authenticated) _then) = __$AuthenticatedCopyWithImpl;
@useResult
$Res call({
 AppUserWithStore userWithStore
});




}
/// @nodoc
class __$AuthenticatedCopyWithImpl<$Res>
    implements _$AuthenticatedCopyWith<$Res> {
  __$AuthenticatedCopyWithImpl(this._self, this._then);

  final _Authenticated _self;
  final $Res Function(_Authenticated) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? userWithStore = null,}) {
  return _then(_Authenticated(
userWithStore: null == userWithStore ? _self.userWithStore : userWithStore // ignore: cast_nullable_to_non_nullable
as AppUserWithStore,
  ));
}


}

/// @nodoc


class _HasAccount implements AuthState {
  const _HasAccount({required this.hasAccount});
  

 final  bool hasAccount;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HasAccountCopyWith<_HasAccount> get copyWith => __$HasAccountCopyWithImpl<_HasAccount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HasAccount&&(identical(other.hasAccount, hasAccount) || other.hasAccount == hasAccount));
}


@override
int get hashCode => Object.hash(runtimeType,hasAccount);

@override
String toString() {
  return 'AuthState.hasAccount(hasAccount: $hasAccount)';
}


}

/// @nodoc
abstract mixin class _$HasAccountCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$HasAccountCopyWith(_HasAccount value, $Res Function(_HasAccount) _then) = __$HasAccountCopyWithImpl;
@useResult
$Res call({
 bool hasAccount
});




}
/// @nodoc
class __$HasAccountCopyWithImpl<$Res>
    implements _$HasAccountCopyWith<$Res> {
  __$HasAccountCopyWithImpl(this._self, this._then);

  final _HasAccount _self;
  final $Res Function(_HasAccount) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hasAccount = null,}) {
  return _then(_HasAccount(
hasAccount: null == hasAccount ? _self.hasAccount : hasAccount // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _Unauthenticated implements AuthState {
  const _Unauthenticated();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.unauthenticated()';
}


}




/// @nodoc


class _OtpSent implements AuthState {
  const _OtpSent({required this.email});
  

 final  String email;

/// Create a copy of AuthState
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
  return 'AuthState.otpSent(email: $email)';
}


}

/// @nodoc
abstract mixin class _$OtpSentCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
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

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(_OtpSent(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Error implements AuthState {
  const _Error({required this.message});
  

 final  String message;

/// Create a copy of AuthState
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
  return 'AuthState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
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

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ForgotPassword implements AuthState {
  const _ForgotPassword();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ForgotPassword);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.forgotPassword()';
}


}




/// @nodoc


class _PasswordResetEmailSent implements AuthState {
  const _PasswordResetEmailSent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PasswordResetEmailSent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.passwordResetEmailSent()';
}


}




// dart format on
