import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'categoria_tab.dart';
import 'pais_tab.dart';
import 'pista_tab.dart';
import 'fondo_tab.dart';
import 'usuario_tab.dart';

/// Panel principal de administración de catálogos.
///
/// Contiene un [TabBar] con 5 secciones: Categorías, Países, Pistas, Fondos
/// y Usuarios. Cada sección está implementada en su propio widget tab.
class CatalogPanelScreen extends ConsumerStatefulWidget {
  const CatalogPanelScreen({super.key});

  @override
  ConsumerState<CatalogPanelScreen> createState() => _CatalogPanelScreenState();
}

class _CatalogPanelScreenState extends ConsumerState<CatalogPanelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Material(
          color: colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Categorías'),
              Tab(text: 'Países'),
              Tab(text: 'Pistas'),
              Tab(text: 'Fondos'),
              Tab(text: 'Usuarios'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CategoriaTab(),
              PaisTab(),
              PistaTab(),
              FondoTab(),
              UsuarioTab(),
            ],
          ),
        ),
      ],
    );
  }
}
