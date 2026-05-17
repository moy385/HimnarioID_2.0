import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/himno_tipo.dart';
import '../../../core/network/connection_state.dart';
import '../../shared_widgets/hymn_card.dart';
import '../../shared_widgets/search_bar.dart';
import '../../views_projection/controller/minimal_control_screen.dart';
import '../../views_projection/providers/connection_providers.dart';
import '../providers/hymn_providers.dart';

/// Dashboard para modo Emisor (conectado a display remoto).
///
/// Incluye buscador, filtros y lista de himnos. Al seleccionar un himno
/// abre [MinimalControlScreen] en lugar del detalle con scroll.
///
/// El rol de Receptor ya no se maneja aquí — [HomeScreen] redirige al
/// [StandbyScreen] cuando [ConnectionRole] es [ConnectionRole.receiver].
class ConnectedDashboard extends ConsumerStatefulWidget {
  const ConnectedDashboard({super.key});

  @override
  ConsumerState<ConnectedDashboard> createState() =>
      _ConnectedDashboardState();
}

class _ConnectedDashboardState extends ConsumerState<ConnectedDashboard> {
  final TextEditingController _searchController = TextEditingController();
  HimnoTipo? _selectedFilter;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final connectionState = ref.watch(connectionStateProvider);
    final deviceName = connectionState is Connected
        ? connectionState.device.name
        : 'Display';

    // Provider de himnos con los parámetros actuales
    final hymnQuery = HymnQueryParam(
      text: _searchQuery,
      tipo: _selectedFilter,
    );
    final hymnsAsync = ref.watch(hymnListProvider(hymnQuery));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Modo Emisor'),
            Text(
              'Conectado a $deviceName',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(connectionStateProvider.notifier).disconnect();
            },
            icon: const Icon(Icons.close_rounded),
            label: const Text('Salir'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: HymnSearchBar(
              controller: _searchController,
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  if (mounted) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  }
                });
              },
              onClear: () {
                _debounce?.cancel();
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
                _buildFilterChip('Todos', null),
                const SizedBox(width: 8),
                _buildFilterChip('Oficiales', HimnoTipo.oficial),
                const SizedBox(width: 8),
                _buildFilterChip('Inspiradas', HimnoTipo.inspirada),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo informativo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Selecciona un himno para controlar la proyección',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Lista de himnos
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MinimalControlScreen(
                              hymnId: himno.id,
                            ),
                          ),
                        );
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

  Widget _buildFilterChip(String label, HimnoTipo? filterValue) {
    final isSelected = _selectedFilter == filterValue;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? filterValue : null;
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
