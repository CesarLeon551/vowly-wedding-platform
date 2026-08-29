import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'data/firebase/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Necesario antes de usar DateFormat/NumberFormat con locale 'es_MX'
  // (CreateWeddingScreen, DashboardScreen).
  await initializeDateFormatting('es_MX');

  runApp(const ProviderScope(child: BodaApp()));
}
