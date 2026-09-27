import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'data/local/database_helper.dart';
import 'core/sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zixioneoyoouxsihlsph.supabase.co',
    publishableKey:
        'sb_publishable_nXykz3wmjlzLIaRU52Ag-Q_FDpCXPaP',
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      startLocale: const Locale('fr'),
      saveLocale: true,
      child: const OltenApp(),
    ),
  );

  unawaited(_initializeInBackground());
}

Future<void> _initializeInBackground() async {
  try {
    await DatabaseHelper.instance.database;

    await DatabaseHelper.instance.initializeProphetStories();

    await DatabaseHelper.instance.initializeQuizzes();

    SyncService.instance.start();

    unawaited(
      SyncService.instance.sync(),
    );
  } catch (e, stackTrace) {
    debugPrint(
      'Background initialization error: $e',
    );

    debugPrint(
      stackTrace.toString(),
    );
  }
}