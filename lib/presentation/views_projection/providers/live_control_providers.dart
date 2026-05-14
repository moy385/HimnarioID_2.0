import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';

/// Provider del himno activo actualmente en proyección.
final activeHymnProvider = StateProvider<Himno?>((ref) => null);

/// Provider de la lista completa de estrofas del himno activo.
final estrofasProvider = StateProvider<List<Estrofa>>((ref) => []);

/// Provider del índice de la estrofa actual en la proyección.
final currentStanzaIndexProvider = StateProvider<int>((ref) => 0);

/// Provider que indica si la pantalla está en modo blackout.
final isBlackoutProvider = StateProvider<bool>((ref) => false);

/// Provider que retorna la estrofa actual.
final currentStanzaProvider = Provider<Estrofa?>((ref) {
  final estrofas = ref.watch(estrofasProvider);
  final index = ref.watch(currentStanzaIndexProvider);
  if (index < 0 || index >= estrofas.length) return null;
  return estrofas[index];
});

/// Provider que retorna la siguiente estrofa (si existe).
final nextStanzaProvider = Provider<Estrofa?>((ref) {
  final estrofas = ref.watch(estrofasProvider);
  final index = ref.watch(currentStanzaIndexProvider);
  final nextIndex = index + 1;
  if (nextIndex >= estrofas.length) return null;
  return estrofas[nextIndex];
});

/// Provider que retorna true si hay una estrofa siguiente.
final hasNextStanzaProvider = Provider<bool>((ref) {
  final estrofas = ref.watch(estrofasProvider);
  final index = ref.watch(currentStanzaIndexProvider);
  return index < estrofas.length - 1;
});

/// Provider que retorna true si hay una estrofa anterior.
final hasPrevStanzaProvider = Provider<bool>((ref) {
  return ref.watch(currentStanzaIndexProvider) > 0;
});

/// Notifier para controlar la navegación entre estrofas.
final liveControlProvider =
    StateNotifierProvider<LiveControlNotifier, LiveControlState>((ref) {
  return LiveControlNotifier();
});

/// Estado completo del control en vivo.
class LiveControlState {
  final Himno? hymn;
  final List<Estrofa> estrofas;
  final int currentIndex;
  final bool isBlackout;
  final int? versionPaisId;

  const LiveControlState({
    this.hymn,
    this.estrofas = const [],
    this.currentIndex = 0,
    this.isBlackout = false,
    this.versionPaisId,
  });

  bool get hasNext => currentIndex < estrofas.length - 1;
  bool get hasPrev => currentIndex > 0;

  Estrofa? get currentStanza =>
      estrofas.isNotEmpty && currentIndex < estrofas.length
          ? estrofas[currentIndex]
          : null;

  Estrofa? get nextStanza => hasNext ? estrofas[currentIndex + 1] : null;

  LiveControlState copyWith({
    Himno? hymn,
    List<Estrofa>? estrofas,
    int? currentIndex,
    bool? isBlackout,
    int? versionPaisId,
  }) {
    return LiveControlState(
      hymn: hymn ?? this.hymn,
      estrofas: estrofas ?? this.estrofas,
      currentIndex: currentIndex ?? this.currentIndex,
      isBlackout: isBlackout ?? this.isBlackout,
      versionPaisId: versionPaisId ?? this.versionPaisId,
    );
  }
}

/// Notifier que maneja la navegación en vivo.
class LiveControlNotifier extends StateNotifier<LiveControlState> {
  LiveControlNotifier() : super(const LiveControlState());

  /// Carga un himno para proyección.
  void loadHymn(Himno hymn, List<Estrofa> stanzas, {int? versionPaisId}) {
    state = LiveControlState(
      hymn: hymn,
      estrofas: stanzas,
      currentIndex: 0,
      isBlackout: false,
      versionPaisId: versionPaisId ?? hymn.primaryVersionPaisId,
    );
  }

  /// Avanza a la siguiente estrofa.
  void nextStanza() {
    if (state.hasNext) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isBlackout: false,
      );
    }
  }

  /// Retrocede a la estrofa anterior.
  void prevStanza() {
    if (state.hasPrev) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        isBlackout: false,
      );
    }
  }

  /// Va al primer coro disponible.
  void goToChorus() {
    final chorusIndex = state.estrofas.indexWhere((e) => e.isChorus);
    if (chorusIndex != -1) {
      state = state.copyWith(
        currentIndex: chorusIndex,
        isBlackout: false,
      );
    }
  }

  /// Va a una estrofa específica por índice.
  void goToStanza(int index) {
    if (index >= 0 && index < state.estrofas.length) {
      state = state.copyWith(
        currentIndex: index,
        isBlackout: false,
      );
    }
  }

  /// Va al inicio (estrofa 0).
  void goToStart() {
    state = state.copyWith(
      currentIndex: 0,
      isBlackout: false,
    );
  }

  /// Activa/desactiva el modo blackout.
  void toggleBlackout() {
    state = state.copyWith(isBlackout: !state.isBlackout);
  }

  /// Apaga la pantalla.
  void blackout() {
    state = state.copyWith(isBlackout: true);
  }

  /// Actualiza el estado completo desde una fuente externa (p.ej. servidor gRPC).
  void updateFromServer(LiveControlState newState) {
    state = newState;
  }
}
