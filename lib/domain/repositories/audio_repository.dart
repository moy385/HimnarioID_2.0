import '../entities/pista_audio.dart';

/// Repositorio de audio.
/// Define el contrato para la reproducción de pistas de audio asociadas a himnos.
abstract class AudioRepository {
  /// Obtiene las pistas de audio de un himno.
  Future<List<PistaAudio>> getByHimno(int himnoId);

  /// Inicia la reproducción de una pista.
  Future<void> play(int pistaId);

  /// Detiene la reproducción actual.
  Future<void> stop();
}
