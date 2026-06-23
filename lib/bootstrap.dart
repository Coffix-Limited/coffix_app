// ignore_for_file: library_prefixes

import 'dart:async';

import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/core/flavors/flavor_config.dart';
import 'package:coffix_app/data/notification_service.dart';
import 'package:coffix_app/firebase_options_dev.dart' as devConfig;
import 'package:coffix_app/firebase_options_prod.dart' as prodConfig;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    debugPrint(
      '${bloc.runtimeType} | ${change.currentState} -> ${change.nextState}',
    );
    super.onChange(bloc, change);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} | ERROR: $error');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(Widget Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enlarge the in-memory image cache so decoded thumbnails survive a quick
  // background -> foreground round-trip instead of being re-decoded (which
  // re-triggers the loading shimmer). Flutter still clears the cache on a real
  // low-memory signal.
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200 MB

  FirebaseOptions? firebaseOptions;
  if (FlavorConfig.isDev()) {
    debugPrint('Dev flavor');
    firebaseOptions = devConfig.DefaultFirebaseOptions.currentPlatform;
  } else if (FlavorConfig.isProd()) {
    debugPrint('Prod flavor');
    firebaseOptions = prodConfig.DefaultFirebaseOptions.currentPlatform;
  }

  if (firebaseOptions != null) {
    final hasDefaultApp = Firebase.apps.any((app) => app.name == '[DEFAULT]');
    if (!hasDefaultApp) {
      await Firebase.initializeApp(
        // name: FlavorConfig.instance.name,
        options: firebaseOptions,
      );
    }
  }

  // init notifications
  await NotificationService().initialize();

  tz.initializeTimeZones();
  final location = tz.getLocation('Pacific/Auckland');
  tz.setLocalLocation(location);

  Bloc.observer = const AppBlocObserver();

  // Add cross-flavor configuration here
  await setupServiceLocator();

  debugPrint('Firebase apps: ${Firebase.apps.map((e) => e.name).toList()}');
  debugPrint('Current flavor: ${FlavorConfig.instance.name}');
  debugPrint('Firebase projectId: ${Firebase.app().options.projectId}');
  debugPrint('Firebase apiKey: ${Firebase.app().options.apiKey}');

  runApp(builder());
}
