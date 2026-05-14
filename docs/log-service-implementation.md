# Log Service Implementation Guide

## Where to put it

**Use `lib/core/services/log_service.dart`** — not a feature module.

Logging is a **cross-cutting concern**: it has no UI, no state, no Cubit, and every feature writes to it. Putting it under `lib/features/logs/` would imply it's a self-contained feature (with its own pages/widgets/logic), which it isn't. A dedicated service in `lib/core/` matches how `InternetConnectionService` is handled.

**Do not** scatter a `LogUseCase` across features — the overhead of an abstract repository + impl + use case is unnecessary for a fire-and-forget Firestore write.

---

## File structure

```
lib/
├── core/
│   └── services/
│       └── log_service.dart        ← new
├── features/
│   └── logs/
│       └── data/
│           └── model/
│               └── log_model.dart  ← new (Freezed + json_serializable)
```

> The `logs` feature folder is kept only for the **data model**. No logic/, presentation/, or domain/ needed.

---

## 1. Log model

`lib/features/logs/data/model/log_model.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'log_model.freezed.dart';
part 'log_model.g.dart';

@freezed
class LogModel with _$LogModel {
  const factory LogModel({
    String? docId,
    String? customerId,
    String? page,
    String? category,
    String? severityLevel,
    String? action,
    String? notes,
    DateTime? time,
  }) = _LogModel;

  factory LogModel.fromJson(Map<String, dynamic> json) =>
      _$LogModelFromJson(json);
}
```

Run codegen after creating this:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 2. Getting `customerId` and `appVersion` — do NOT inject Cubits

A natural instinct is to inject `AuthCubit` (for the current user) and `AppCubit` (for the app version) into `LogService`. **Don't do this.**

Cubits sit *above* services in the dependency graph — they depend on repositories and services, not the other way around. Injecting a Cubit into a service creates a layering violation and risks circular dependencies in GetIt.

Both values are available at a lower level without touching any Cubit:

| Need | Solution |
|---|---|
| `customerId` | `FirebaseAuth.instance.currentUser?.uid` — Firebase Auth is a singleton, always reflects the live session |
| `appVersion` | `PackageInfo.fromPlatform()` — same package `AppCubit` uses, called directly and cached |

`LogService` auto-fills both on every `write()` call, so callers never have to pass them manually.

---

## 3. LogService

`lib/core/services/log_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffix_app/domain/firestore_service.dart';
import 'package:coffix_app/features/logs/data/log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LogService {
  final FirebaseFirestore _firestore = FirestoreService.instance;
  String? _appVersion;

  Future<String> _getAppVersion() async {
    _appVersion ??= await PackageInfo.fromPlatform().then(
      (info) => '${info.version}+${info.buildNumber}',
    );
    return _appVersion!;
  }

  Future<void> write(Log log) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final appVersion = await _getAppVersion();

      final data = log.toJson()
        ..remove('docId')
        ..['customerId'] ??= uid
        ..['appVersion'] = appVersion
        ..['time'] = FieldValue.serverTimestamp();

      await _firestore.collection('logs').add(data);
    } catch (_) {
      // Never let a log failure crash the app.
    }
  }
}
```

Key points:
- `customerId` is filled automatically from `FirebaseAuth` — callers can still override it by passing it in the `Log` object (the `??=` preserves an explicit value).
- `appVersion` is resolved once and cached in `_appVersion` for subsequent writes.
- `FieldValue.serverTimestamp()` is used instead of a client-side timestamp.
- Errors are swallowed — a log failure must never crash the main flow.

---

## 4. Register in GetIt

`lib/core/di/service_locator.dart`

```dart
getIt.registerLazySingleton<LogService>(() => LogService());
```

Add this near the top of `setupServiceLocator`, before the Cubits.

---

## 5. Using LogService in a Cubit

Inject `LogService` via the constructor, then call `write()` after the action completes. You do **not** need to pass `customerId` or `appVersion` — `LogService` fills them automatically.

```dart
class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _paymentRepository;
  final LogService _logService;

  PaymentCubit({
    required PaymentRepository paymentRepository,
    required LogService logService,
  })  : _paymentRepository = paymentRepository,
        _logService = logService,
        super(PaymentInitial());

  Future<void> payWithCredit(String orderId, double amount) async {
    try {
      await _paymentRepository.payWithCredit(orderId, amount);

      await _logService.write(Log(
        page: 'payment_options',
        category: 'purchase',
        severityLevel: 'major',
        action: 'payment_successful',
        notes: 'Paid \$$amount for order $orderId via Coffix Credit',
      ));
    } catch (e) {
      await _logService.write(Log(
        page: 'payment_options',
        category: 'purchase',
        severityLevel: 'major',
        action: 'payment_failed',
        notes: e.toString(),
      ));
      // emit error state...
    }
  }
}
```

Update `service_locator.dart` to pass `LogService` when registering the Cubit:

```dart
getIt.registerLazySingleton<PaymentCubit>(
  () => PaymentCubit(
    paymentRepository: getIt<PaymentRepository>(),
    logService: getIt<LogService>(),
  ),
);
```

---

## 6. Severity / category reference

See [`logs-feature.md`](./logs-feature.md) for the full list of severity levels, categories, and the implementation checklist.

---

## Summary

| Question | Answer |
|---|---|
| Feature module? | No — logging is cross-cutting, not a user-facing feature |
| Use case class? | No — `LogService.write()` is sufficient |
| Abstract repository? | No — only one implementation (Firestore), no need to mock |
| Where to place? | `lib/core/services/log_service.dart` |
| Model location? | `lib/features/logs/data/log.dart` |
| DI pattern? | Lazy singleton via GetIt, injected into each Cubit |
| Inject AuthCubit? | No — use `FirebaseAuth.instance.currentUser?.uid` directly |
| Inject AppCubit? | No — use `PackageInfo.fromPlatform()` directly, cached after first call |
