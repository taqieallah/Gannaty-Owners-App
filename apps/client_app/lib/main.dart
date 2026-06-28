import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase backend (replaces the two Firebase apps). Owner accounts and
  // compound data are read from the shared Supabase project.
  await SupaConfig.initialize();
  runApp(const ProviderScope(child: ClientApp()));
}
