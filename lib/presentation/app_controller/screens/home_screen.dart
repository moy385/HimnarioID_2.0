import 'package:flutter/material.dart';
import '../../shared_widgets/search_bar.dart';
import '../../shared_widgets/hymn_card.dart';

/// Tipos de filtro para himnos
enum HymnFilter {
  todos,
  oficiales,
  inspiradas,
  porCategoria,
}

/// Pantalla de inicio / Dashboard del Controlador
/// Incluye buscador, filtros y lista de himnos
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  HymnFilter _selectedFilter = HymnFilter.todos;
  bool _isConnected = false; // Estado de conexión (placeholder)
  String _searchQuery = '';

  // Lista de himnos de ejemplo (placeholder)
  final List<HymnModel> _himnos = const [
    HymnModel(
      id: 1,
      numero: '001',
      titulo: 'Santo, Santo, Santo',
      categoria: 'Adoración',
      primeraLinea: 'Santo, Santo, Santo, Dios de cielos...',
      esOficial: true,
    ),
    HymnModel(
      id: 2,
      numero: '002',
      titulo: 'Jesús Me Ama',
      categoria: 'Infantil',
      primeraLinea: 'Jesús me ama, lo sé muy bien...',
      esOficial: true,
    ),
    HymnModel(
      id: 3,
      numero: '003',
      titulo: 'Grande es Tu Fidelidad',
      categoria: 'Gratitud',
      primeraLinea: 'Tu amor es más fuerte que la muerte...',
      esOficial: true,
    ),
    HymnModel(
      id: 4,
      numero: '004',
      titulo: 'Cuán Grande Es',
      categoria: 'Alabanza',
      primeraLinea: 'Cuán grande es mi Dios, mayor que todo...',
      esOficial: true,
    ),
    HymnModel(
      id: 5,
      numero: '101',
      titulo: 'En Tu Luz',
      categoria: 'Inspirada',
      primeraLinea: 'En tu luz veo luz y en tu amor...',
      esOficial: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Lista filtrada de himnos según búsqueda y filtro seleccionado
  List<HymnModel> get _filteredHimnos {
    return _himnos.where((himno) {
      // Filtrar por texto de búsqueda
      final matchesSearch = _searchQuery.isEmpty ||
          himno.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          himno.numero.contains(_searchQuery);

      // Filtrar por categoría
      bool matchesFilter = true;
      switch (_selectedFilter) {
        case HymnFilter.oficiales:
          matchesFilter = himno.esOficial;
          break;
        case HymnFilter.inspiradas:
          matchesFilter = !himno.esOficial;
          break;
        case HymnFilter.todos:
        case HymnFilter.porCategoria:
          matchesFilter = true;
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HimnarioID'),
        actions: [
          // Indicador de conexión
          IconButton(
            onPressed: () {
              setState(() {
                _isConnected = !_isConnected;
              });
            },
            icon: Icon(
              _isConnected
                  ? Icons.cast_connected_rounded
                  : Icons.cast_rounded,
              color: _isConnected ? Colors.green : colorScheme.error,
            ),
            tooltip: _isConnected
                ? 'Conectado a Pantalla Principal'
                : 'Sin conexión',
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
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Por Categoría',
                  HymnFilter.porCategoria,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de himnos
          Expanded(
            child: _filteredHimnos.isEmpty
                ? Center(
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
                          'No se encontraron himnos',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredHimnos.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final himno = _filteredHimnos[index];
                      return HymnCard(
                        himno: himno,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/hymn-detail',
                            arguments: himno,
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

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    HymnFilter filter,
  ) {
    final isSelected = _selectedFilter == filter;
    final colorScheme = Theme.of(context).colorScheme;

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
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}