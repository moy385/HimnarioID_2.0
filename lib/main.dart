import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios asíncronos (BD, mDNS, etc.)
  await AppInitializer.initialize();

  runApp(
    const ProviderScope(
      child: HimnarioApp(),
    ),
  );
}
