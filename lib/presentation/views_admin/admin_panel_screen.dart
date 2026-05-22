import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'crud_hymns/hymn_list_screen.dart';
import 'crud_catalogs/catalog_panel_screen.dart';
import '../views_personal/dashboard/home_screen.dart';

/// Pantalla principal del panel de configuración con navegación tipo Drawer.
///
/// Muestra un [NavigationDrawer] estilo hamburger menu con las opciones:
/// - Administrar Himnos
/// - Catálogos
///
/// El cuerpo cambia según la opción seleccionada en el drawer.
/// Cuando no hay ninguna opción seleccionada (estado inicial) se muestra
/// una pantalla de bienvenida.
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  /// -1 = bienvenida, 0 = Himnos, 1 = Catálogos
  int _selectedDrawerIndex = -1;

  static const _titles = <String>[
    'Panel de Configuración',
    'Administrar Himnos',
    'Catálogos',
  ];

  String get _title => _titles[_selectedDrawerIndex + 1];

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: _selectedDrawerIndex != -1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedDrawerIndex = -1),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Ir al inicio',
            onPressed: _goHome,
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedDrawerIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedDrawerIndex = index);
          Navigator.of(context).pop();
        },
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.admin_panel_settings,
                  size: 40,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'MQ App',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Admin',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: Text('Administrar Himnos'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: Text('Catálogos'),
          ),
          const Divider(),
        ],
      ),
      body: _selectedDrawerIndex == -1 ? _buildWelcome(theme, colorScheme) : _buildScreen(),
    );
  }

  Widget _buildWelcome(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.admin_panel_settings,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Bienvenido, Admin',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona una opción del menú',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_selectedDrawerIndex) {
      case 0:
        return const HymnListScreen();
      case 1:
        return const CatalogPanelScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
