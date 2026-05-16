import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/domain/repositories/control_repository.dart';
import 'package:himnario_id_2/presentation/views_projection/display/projection_app.dart';
import 'package:himnario_id_2/presentation/views_projection/display/receptor_binding.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/connection_providers.dart';

// ═══════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════

class MockControlRepository extends Mock implements ControlRepository {}

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════

/// Construye el widget de prueba con [ProjectionApp] y overrides
/// para los providers que dependen de servicios externos.
Widget _buildTestApp({Stream<String>? stdinOverride}) {
  return ProviderScope(
    overrides: [
      // controlRepositoryProvider → mock
      controlRepositoryProvider.overrideWithProvider(
        Provider<ControlRepository>((ref) => MockControlRepository()),
      ),
      // receptorInfoProvider → valor fijo (no necesita servidor gRPC real)
      receptorInfoProvider.overrideWithProvider(
        Provider<ReceptorInfo>(
          (ref) => const ReceptorInfo(
            isRunning: false,
            port: 50051,
            displayName: 'Test',
          ),
        ),
      ),
    ],
    child: MaterialApp(
      home: ProjectionApp(stdinOverride: stdinOverride),
    ),
  );
}

/// Crea un mensaje LOAD_HYMN con un himno de prueba y sus estrofas.
Map<String, dynamic> _loadHymnMessage({
  int id = 1,
  String titulo = 'Santo, Santo, Santo',
  int? numero = 1,
  String tipo = 'oficial',
  int stanzaCount = 3,
}) {
  return {
    'type': 'LOAD_HYMN',
    'himno_id': id,
    'titulo': titulo,
    'numero': numero,
    'tipo': tipo,
    'estrofas': List.generate(stanzaCount, (i) {
      return {
        'id': i + 1,
        'version_pais_id': 1,
        'tipo': i == 1 ? 'coro' : 'estrofa',
        'orden': i + 1,
        'contenido': 'Estrofa ${i + 1} de prueba',
      };
    }),
    'currentIndex': 0,
  };
}

// ═══════════════════════════════════════════════════════════════
// Test suite
// ═══════════════════════════════════════════════════════════════

void main() {
  group('ProjectionApp', () {
    testWidgets('1. Estado inicial — "Esperando proyección..."',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Esperando proyección...'), findsOneWidget);
    });

    testWidgets('2. LOAD_HYMN — muestra el himno cargado', (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Enviar mensaje LOAD_HYMN
      stdinCtrl.add(jsonEncode(_loadHymnMessage()));
      await tester.pumpAndSettle();

      // Verificar que el himno se muestra
      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
      expect(find.text('Estrofa 1 de prueba'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('3. NEXT_STANZA — avanza a la siguiente estrofa',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cargar himno con 3 estrofas
      stdinCtrl.add(jsonEncode(_loadHymnMessage(stanzaCount: 3)));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 1 de prueba'), findsOneWidget);

      // Avanzar
      stdinCtrl.add(jsonEncode({'type': 'NEXT_STANZA'}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 2 de prueba'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('4. PREV_STANZA — retrocede a la estrofa anterior',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cargar himno con 3 estrofas
      stdinCtrl.add(jsonEncode(_loadHymnMessage(stanzaCount: 3)));
      await tester.pumpAndSettle();

      // Avanzar 2 veces
      stdinCtrl.add(jsonEncode({'type': 'NEXT_STANZA'}));
      await tester.pumpAndSettle();
      stdinCtrl.add(jsonEncode({'type': 'NEXT_STANZA'}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 3 de prueba'), findsOneWidget);

      // Retroceder 1
      stdinCtrl.add(jsonEncode({'type': 'PREV_STANZA'}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 2 de prueba'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('5. GO_TO_STANZA — va a un índice específico',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cargar himno con 3 estrofas
      stdinCtrl.add(jsonEncode(_loadHymnMessage(stanzaCount: 3)));
      await tester.pumpAndSettle();

      // Ir directamente a la estrofa 3 (índice 2)
      stdinCtrl.add(jsonEncode({'type': 'GO_TO_STANZA', 'index': 2}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 3 de prueba'), findsOneWidget);

      // Volver a la estrofa 1 (índice 0)
      stdinCtrl.add(jsonEncode({'type': 'GO_TO_STANZA', 'index': 0}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 1 de prueba'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('6. BLACKOUT — activa/desactiva pantalla negra',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cargar himno primero
      stdinCtrl.add(jsonEncode(_loadHymnMessage()));
      await tester.pumpAndSettle();

      // Activar blackout
      stdinCtrl.add(jsonEncode({'type': 'BLACKOUT', 'enabled': true}));
      await tester.pumpAndSettle();

      // Con blackout activado, el texto del himno NO debe mostrarse
      expect(find.text('Santo, Santo, Santo'), findsNothing);

      // Desactivar blackout
      stdinCtrl.add(jsonEncode({'type': 'BLACKOUT', 'enabled': false}));
      await tester.pumpAndSettle();

      // El himno debe volver a mostrarse
      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('7. Mensaje mal formado — no crashea', (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Enviar texto no-JSON
      stdinCtrl.add('esto no es json');
      await tester.pumpAndSettle();

      // La app debe seguir mostrando el estado inicial
      expect(find.text('Esperando proyección...'), findsOneWidget);

      // Enviar tipo de mensaje desconocido (JSON válido, pero no handler)
      stdinCtrl.add('{"type": "UNKNOWN"}');
      await tester.pumpAndSettle();

      // Sigue mostrando estado inicial
      expect(find.text('Esperando proyección...'), findsOneWidget);

      // Después del malformed, un mensaje válido debe seguir funcionando
      stdinCtrl.add(jsonEncode(_loadHymnMessage()));
      await tester.pumpAndSettle();

      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
      await stdinCtrl.close();
    });
  });
}
