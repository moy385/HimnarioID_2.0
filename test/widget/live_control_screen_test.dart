import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/enums/estrofa_tipo.dart';
import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/domain/entities/categoria.dart';
import 'package:himnario_id_2/domain/entities/estrofa.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/domain/entities/version_pais.dart';
import 'package:himnario_id_2/domain/repositories/control_repository.dart';
import 'package:himnario_id_2/presentation/views_projection/controller/live_control_screen.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/connection_providers.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/live_control_providers.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/projection_providers.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ─────────────────────────────────────────────────────

class MockControlRepository extends Mock implements ControlRepository {}

// ─── Helpers ───────────────────────────────────────────────────

Himno _createTestHimno({
  int id = 1,
  String titulo = 'Santo, Santo, Santo',
  int? numero = 1,
}) {
  return Himno(
    id: id,
    titulo: titulo,
    numero: numero,
    tipo: HimnoTipo.oficial,
    versiones: [
      VersionPais(id: 1, himnoId: id, paisId: 0, paisNombre: 'Honduras', paisCodigo: 'HN', tonalidadOriginal: 'G'),
    ],
    categorias: [
      const Categoria(id: 1, nombre: 'Alabanza'),
    ],
  );
}

List<Estrofa> _createTestStanzas() {
  return [
    const Estrofa(
      id: 1,
      versionPaisId: 1,
      tipo: EstrofaTipo.estrofa,
      orden: 1,
      contenido: 'Primera estrofa del himno',
    ),
    const Estrofa(
      id: 2,
      versionPaisId: 1,
      tipo: EstrofaTipo.coro,
      orden: 2,
      contenido: 'Coro del himno',
    ),
    const Estrofa(
      id: 3,
      versionPaisId: 1,
      tipo: EstrofaTipo.estrofa,
      orden: 3,
      contenido: 'Segunda estrofa del himno',
    ),
  ];
}

// ─── Provider Overrides ───────────────────────────────────────

/// LiveControlNotifier con estado inicial que tiene un himno cargado.
LiveControlNotifier _createLoadedNotifier() {
  final notifier = LiveControlNotifier();
  notifier.loadHymn(
    _createTestHimno(),
    _createTestStanzas(),
  );
  return notifier;
}

/// Override para liveControlProvider con estado precargado.
final _liveControlLoadedOverride = liveControlProvider.overrideWith(
  (ref) => _createLoadedNotifier(),
);

/// Override para isConnectedProvider (false = modo offline).
final _isConnectedOverride = isConnectedProvider.overrideWith(
  (ref) => false,
);

/// Override para controlRepositoryProvider.
final _controlRepoOverride = controlRepositoryProvider.overrideWith(
  (ref) => MockControlRepository(),
);

/// Override para projectionConfigProvider.
final _projectionConfigOverride = projectionConfigProvider.overrideWith(
  (ref) {
    final repo = ref.read(controlRepositoryProvider);
    return ProjectionConfigNotifier(repo);
  },
);

Widget _buildTestApp({
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      _liveControlLoadedOverride,
      _isConnectedOverride,
      _controlRepoOverride,
      _projectionConfigOverride,
      ...overrides,
    ],
    child: const MaterialApp(
      home: LiveControlScreen(),
    ),
  );
}

// ─── Tests ─────────────────────────────────────────────────────

void main() {
  group('LiveControlScreen', () {
    testWidgets('Muestra el título del himno en el AppBar', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // El AppBar debe mostrar el título del himno
      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
    });

    testWidgets('Botón SIGUIENTE funciona', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verificar que el botón SIGUIENTE está presente
      expect(find.text('SIGUIENTE'), findsOneWidget);

      // Hacer tap en SIGUIENTE
      await tester.tap(find.text('SIGUIENTE'));
      await tester.pumpAndSettle();

      // La estrofa actual debería cambiar al coro (índice 1)
      // El preview panel muestra "Coro" (tipo.value) y el badge "EstrofaTipo.coro"
      expect(find.text('Coro'), findsOneWidget);
    });

    testWidgets('Botón Anterior funciona', (tester) async {
      // Crear un notifier que comience en el índice 1 (CORO)
      final notifier = LiveControlNotifier();
      notifier.loadHymn(
        _createTestHimno(),
        _createTestStanzas(),
      );
      // Avanzar una vez para estar en índice 1
      notifier.nextStanza();

      final override = liveControlProvider.overrideWith(
        (ref) => notifier,
      );

      await tester.pumpWidget(
        _buildTestApp(overrides: [override]),
      );
      await tester.pumpAndSettle();

      // Verificar que estamos en Coro (el preview panel muestra tipo.value = 'Coro')
      expect(find.text('Coro'), findsOneWidget);

      // Hacer tap en Anterior
      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();

      // Debería retroceder a la primera estrofa
      // La vista previa muestra "Actual: Estrofa" (tipo.value = 'Estrofa')
      expect(find.text('Estrofa'), findsOneWidget);
    });

    testWidgets('Botón Apagar activa modo blackout', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Buscar el botón "Apagar"
      expect(find.text('Apagar'), findsOneWidget);

      // Hacer tap en Apagar
      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();

      // Después del blackout, el botón cambia a "Encender"
      expect(find.text('Encender'), findsOneWidget);
    });

    testWidgets('Boton Encender desactiva modo blackout', (tester) async {
      // Crear notifier en blackout
      final notifier = LiveControlNotifier();
      notifier.loadHymn(
        _createTestHimno(),
        _createTestStanzas(),
      );
      notifier.toggleBlackout(); // activar blackout

      final override = liveControlProvider.overrideWith(
        (ref) => notifier,
      );

      await tester.pumpWidget(
        _buildTestApp(overrides: [override]),
      );
      await tester.pumpAndSettle();

      // Debe mostrar "Encender"
      expect(find.text('Encender'), findsOneWidget);

      // Hacer tap para salir del blackout
      await tester.tap(find.text('Encender'));
      await tester.pumpAndSettle();

      // Ahora debe mostrar "Apagar"
      expect(find.text('Apagar'), findsOneWidget);
    });

    testWidgets('Botones de acceso rápido están presentes', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verificar botones de acceso rápido
      expect(find.text('Ir al Coro'), findsOneWidget);
      expect(find.text('Ir al Inicio'), findsOneWidget);

      // SIGUIENTE (botón gigante) está presente
      expect(find.text('SIGUIENTE'), findsOneWidget);

      // Anterior está presente
      expect(find.text('Anterior'), findsOneWidget);
    });

    testWidgets('Indicador de conexión se muestra', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Cuando no hay conexión, se muestra el icono cast normal
      expect(find.byIcon(Icons.cast_rounded), findsOneWidget);
    });

    testWidgets('Vista previa muestra estrofa actual y siguiente',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // El panel de vista previa tiene "Actual" y "Siguiente"
      expect(find.text('Actual'), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);

      // La estrofa actual (índice 0) muestra "Estrofa" (tipo.value) y
      // la siguiente (índice 1) muestra "Coro"
      expect(find.text('Estrofa'), findsOneWidget);
      expect(find.text('Coro'), findsOneWidget);
    });
  });
}
