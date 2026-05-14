import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/enums/estrofa_tipo.dart';
import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/domain/entities/estrofa.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/domain/entities/version_pais.dart';
import 'package:himnario_id_2/presentation/views_personal/providers/hymn_providers.dart';
import 'package:himnario_id_2/presentation/views_projection/display/simple_projection_view.dart';

/// Crea un himno de prueba con la versionPaisId especificada.
Himno _createTestHimno({
  int id = 1,
  String titulo = 'Santo, Santo, Santo',
  int? numero = 1,
  HimnoTipo tipo = HimnoTipo.oficial,
  int versionPaisId = 1,
}) {
  return Himno(
    id: id,
    titulo: titulo,
    numero: numero,
    tipo: tipo,
    versiones: [
      VersionPais(
        id: versionPaisId,
        himnoId: id,
        pais: 'HN',
        tonalidadOriginal: 'C',
      ),
    ],
    categorias: [],
  );
}

/// Crea una lista de estrofas de prueba.
List<Estrofa> _createTestStrofas() {
  return const [
    Estrofa(
      id: 1,
      versionPaisId: 1,
      tipo: EstrofaTipo.estrofa,
      orden: 1,
      contenido: 'Primera estrofa de prueba',
    ),
    Estrofa(
      id: 2,
      versionPaisId: 1,
      tipo: EstrofaTipo.coro,
      orden: 2,
      contenido: 'Coro de prueba',
    ),
    Estrofa(
      id: 3,
      versionPaisId: 1,
      tipo: EstrofaTipo.estrofa,
      orden: 3,
      contenido: 'Segunda estrofa de prueba',
    ),
  ];
}

/// Variables compartidas para controlar el comportamiento del mock.
List<Estrofa> _mockStanzas = [];
bool _mockStanzasError = false;
int _mockStanzasErrorVersionId = -1;

final _stanzasProviderOverride = stanzasProvider.overrideWith(
  (ref, int versionId) async {
    if (_mockStanzasError && _mockStanzasErrorVersionId == versionId) {
      throw Exception('Error de prueba al cargar estrofas');
    }
    return _mockStanzas;
  },
);

Widget _buildTestApp(Himno himno) {
  return ProviderScope(
    overrides: [
      _stanzasProviderOverride,
    ],
    child: MaterialApp(
      home: SimpleProjectionView(himno: himno),
    ),
  );
}

void main() {
  setUp(() {
    _mockStanzas = [];
    _mockStanzasError = false;
    _mockStanzasErrorVersionId = -1;
  });

  group('SimpleProjectionView', () {
    testWidgets('Renderiza título del himno', (tester) async {
      _mockStanzas = _createTestStrofas();
      final himno = _createTestHimno();

      await tester.pumpWidget(_buildTestApp(himno));
      await tester.pumpAndSettle();

      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
    });

    testWidgets('Muestra loading mientras carga estrofas', (tester) async {
      final completer = Completer<List<Estrofa>>();
      final loadingOverride = stanzasProvider.overrideWith(
        (ref, int versionId) => completer.future,
      );
      final himno = _createTestHimno();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [loadingOverride],
          child: MaterialApp(
            home: SimpleProjectionView(himno: himno),
          ),
        ),
      );
      await tester.pump();

      // Debe mostrar el CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete([]);
    });

    testWidgets('Muestra "sin versiones" cuando versionId < 0',
        (tester) async {
      // Himno sin versiones (primaryVersionPaisId será -1)
      const himno = Himno(
        id: 1,
        titulo: 'Test Sin Versiones',
        tipo: HimnoTipo.oficial,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SimpleProjectionView(himno: himno),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Este himno no tiene versiones disponibles'),
        findsOneWidget,
      );
    });

    testWidgets('Muestra navegación prev/next cuando hay estrofas',
        (tester) async {
      _mockStanzas = _createTestStrofas();
      final himno = _createTestHimno();

      await tester.pumpWidget(_buildTestApp(himno));
      await tester.pumpAndSettle();

      // Debe mostrar los botones de navegación
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });

    testWidgets('Botón siguiente avanza a siguiente estrofa',
        (tester) async {
      _mockStanzas = _createTestStrofas();
      final himno = _createTestHimno();

      await tester.pumpWidget(_buildTestApp(himno));
      await tester.pumpAndSettle();

      // Verificar que muestra la primera estrofa
      expect(find.text('Primera estrofa de prueba'), findsOneWidget);

      // Tocar el botón Siguiente
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pumpAndSettle();

      // Ahora debe mostrar la segunda estrofa (coro)
      expect(find.text('Coro de prueba'), findsOneWidget);
      expect(find.text('Primera estrofa de prueba'), findsNothing);
    });

    testWidgets('Botón anterior retrocede a estrofa anterior',
        (tester) async {
      _mockStanzas = _createTestStrofas();
      final himno = _createTestHimno();

      await tester.pumpWidget(_buildTestApp(himno));
      await tester.pumpAndSettle();

      // Avanzar dos estrofas
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pumpAndSettle();

      // Debe mostrar la tercera estrofa
      expect(find.text('Segunda estrofa de prueba'), findsOneWidget);

      // Retroceder una
      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      await tester.pumpAndSettle();

      // Ahora debe mostrar la segunda estrofa (coro)
      expect(find.text('Coro de prueba'), findsOneWidget);
      expect(find.text('Segunda estrofa de prueba'), findsNothing);
    });

    testWidgets('Muestra error cuando provider falla', (tester) async {
      _mockStanzasError = true;
      _mockStanzasErrorVersionId = 1;
      final himno = _createTestHimno();

      await tester.pumpWidget(_buildTestApp(himno));
      await tester.pumpAndSettle();

      // Debe mostrar el mensaje de error y botón reintentar
      expect(find.text('Error al cargar las estrofas'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
