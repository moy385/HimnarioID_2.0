import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/himno_tipo.dart';
import '../../../core/network/connection_state.dart';
import '../../../core/window_manager/window_providers.dart';
import '../../../domain/entities/himno.dart';
import '../../dual_mode_wrapper/dual_mode_providers.dart';
import '../../shared_widgets/search_bar.dart';
import '../../shared_widgets/hymn_card.dart';
import '../../views_projection/controller/widgets/discover_display_sheet.dart'
    show DiscoverDisplaySheet;
import '../../views_projection/display/receptor_binding.dart';
import '../../views_projection/providers/connection_providers.dart';
import '../../views_projection/providers/live_control_providers.dart';
import '../../views_projection/providers/presentation_providers.dart';
import '../../views_admin/login/login_screen.dart';
import '../../views_admin/admin_panel_screen.dart';
import '../../views_admin/providers/auth_providers.dart'
    show isAuthenticatedProvider;
import '../providers/hymn_providers.dart';
import 'connected_dashboard.dart';
import 'present_button.dart';

/// Tipos de filtro para himnos.
enum HymnFilter {
  todos,
  oficiales,
  inspiradas,
}

/// Pantalla de inicio / Dashboard del Controlador.
///
/// Según el rol de conexión ([connectionRoleProvider]):
/// - [ConnectionRole.receiver] → [StandbyScreen] envuelto en [ReceptorBinding]
/// - [ConnectionRole.emitter] → [ConnectedDashboard]
/// - [ConnectionRole.none] → Interfaz normal con buscador, filtros y lista
///
/// En modo Desktop con presentación activa ([isPresentingProvider] es `true`),
/// muestra un [PresentControlBar] como overlay en la parte inferior y oculta
/// el FAB "Presentar".
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  HymnFilter _selectedFilter = HymnFilter.todos;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Carga un himno en el provider de control en vivo sin navegar.
  ///
  /// Se ejecuta cuando [isPresentingProvider] es `true` y se toca un himno.
  /// Proyecta el himno en la ventana secundaria (a través del provider) y
  /// actualiza el [PresentControlBar] con el título. No se navega a otra
  /// pantalla — el control permanece como overlay en HomeScreen.
  ///
  /// También envía el himno completo a la segunda ventana de proyección
  /// vía [WindowService.sendMessage] usando el protocolo JSON stdin/stdout.
  Future<void> _selectHymnForProjection(
    BuildContext context,
    WidgetRef ref,
    Himno himno,
  ) async {
    try {
      final repo = ref.read(hymnRepositoryProvider);
      final himnoCompleto = await repo.getHymnById(himno.id);
      final versionPaisId = himnoCompleto.primaryVersionPaisId;
      final estrofas = await repo.getStanzas(versionPaisId);

      // 1. Cargar en liveControlProvider local (actualiza PresentControlBar)
      ref.read(liveControlProvider.notifier).loadHymn(
            himnoCompleto,
            estrofas,
            versionPaisId: versionPaisId,
          );

      // 2. Enviar a la 2da ventana vía WindowService.sendMessage()
      final windowService = ref.read(windowServiceProvider);
      await windowService.sendMessage({
        'type': 'LOAD_HYMN',
        'himno_id': himnoCompleto.id,
        'titulo': himnoCompleto.titulo,
        'numero': himnoCompleto.numero,
        'tipo': himnoCompleto.tipo.name,
        'estrofas': estrofas.map((e) => {
          'id': e.id,
          'version_pais_id': e.versionPaisId,
          'tipo': e.tipo.name,
          'orden': e.orden,
          'contenido': e.contenido,
        }).toList(), // ignore: require_trailing_commas
        'currentIndex': 0,
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar himno: $e')),
        );
      }
    }
  }

  /// Obtiene el valor [HimnoTipo] según el filtro seleccionado.
  HimnoTipo? _filterToTipo() {
    switch (_selectedFilter) {
      case HymnFilter.oficiales:
        return HimnoTipo.oficial;
      case HymnFilter.inspiradas:
        return HimnoTipo.inspirada;
      case HymnFilter.todos:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final role = ref.watch(connectionRoleProvider);

    // ── Modo Receptor: StandbyScreen ↔ LiveProjectionScreen según himno ──
    if (role == ConnectionRole.receiver) {
      final display = ref.watch(receptorDisplayProvider);
      return ReceptorBinding(child: display);
    }

    // ── Modo Emisor: ConnectedDashboard ──
    if (role == ConnectionRole.emitter) {
      return const ConnectedDashboard();
    }

    // ── Modo normal (sin rol de conexión) ──
    final connectionState = ref.watch(connectionStateProvider);
    final isConnected = connectionState is Connected;

    // Escuchar el provider de himnos con los parámetros actuales
    final hymnQuery = HymnQueryParam(
      text: _searchQuery,
      tipo: _filterToTipo(),
    );
    final hymnsAsync = ref.watch(hymnListProvider(hymnQuery));

    final isDesktop = ref.watch(isDesktopModeProvider);
    final isPresenting = ref.watch(isPresentingProvider);

    return Scaffold(
      floatingActionButton:
          isDesktop && !isPresenting ? const PresentButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: const Text('HimnarioID'),
        leading: IconButton(
          icon: Icon(
            ref.watch(isAuthenticatedProvider)
                ? Icons.lock_rounded
                : Icons.lock_open_rounded,
          ),
          onPressed: () {
            final isAuth = ref.read(isAuthenticatedProvider);
            if (isAuth) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminPanelScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
          tooltip: 'Administraci\u00f3n',
        ),
        actions: [
          // Botón de conexión: abre el DiscoverDisplaySheet
          IconButton(
            onPressed: () => _openDiscoverySheet(context),
            icon: Icon(
              connectionState is Connected
                  ? Icons.cast_connected_rounded
                  : Icons.cast_rounded,
              color: connectionState is ConnectionError
                  ? colorScheme.error
                  : isConnected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
            ),
            tooltip: switch (connectionState) {
              final Connected c => 'Conectado a ${c.device.name}',
              ConnectionError _ => 'Error de conexi\u00f3n',
              _ => 'Conectar display',
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: HymnSearchBar(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),

          // Chips de filtrado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  'Todos',
                  HymnFilter.todos,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Oficiales',
                  HymnFilter.oficiales,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Inspiradas',
                  HymnFilter.inspiradas,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de himnos con manejo de estados async
          Expanded(
            child: hymnsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar himnos',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        // Forzar recarga invalidando el provider
                        ref.invalidate(hymnListProvider(hymnQuery));
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (himnos) {
                if (himnos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No se encontraron himnos para "$_searchQuery"'
                              : 'No hay himnos disponibles',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: himnos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final himno = himnos[index];
                    return HymnCard(
                      himno: himno,
                      onTap: () {
                        if (isPresenting && isDesktop) {
                          _selectHymnForProjection(
                            context,
                            ref,
                            himno,
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/hymn-detail',
                            arguments: himno,
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Abre el BottomSheet de descubrimiento y conexión de displays.
  void _openDiscoverySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const DiscoverDisplaySheet(),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    HymnFilter filter,
  ) {
    final isSelected = _selectedFilter == filter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: textTheme.labelMedium?.copyWith(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
