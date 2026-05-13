import '../constants/musical_constants.dart';

// ExpReg para extraer acordes de formato ChordPro: [G] [Am7] [C#m]
final _chordPattern = RegExp(r'\[([A-G][#b]?[A-Ga-g0-9]*)\]');

/// Transpone acordes en contenido ChordPro.
///
/// [content] - texto con formato ChordPro (ej: "[G]Dios es [C]amor")
/// [semitones] - número de semitonos a mover (positivo = subir, negativo = bajar)
///
/// Retorna el contenido con acordes transpuestos.
String transposeChordPro(String content, int semitones) {
  if (semitones == 0) return content;

  return content.replaceAllMapped(_chordPattern, (match) {
    final chord = match.group(1)!;
    final transposed = _transposeChord(chord, semitones);
    return '[$transposed]';
  });
}

/// Transpone una nota individual aplicando el sufijo del acorde.
///
/// [chord] - raíz del acorde con posible sufijo (ej: "Am7", "G", "C#m")
/// [semitones] - semitonos a mover
String _transposeChord(String chord, int semitones) {
  // Extraer raíz (primera letra mayúscula + posible # o b)
  final rootMatch = RegExp(r'^([A-G][#b]?)').firstMatch(chord);
  if (rootMatch == null) return chord;

  final root = rootMatch.group(1)!;
  final suffix = chord.substring(root.length);

  final transposedRoot = _transposeRoot(root, semitones);
  return '$transposedRoot$suffix';
}

/// Transpone la raíz del acorde en la escala cromática.
String _transposeRoot(String root, int semitones) {
  // Normalizar bemoles a sostenidos para búsqueda
  final normalizedRoot = _normalizeToSharp(root);
  final index = MusicalConstants.chromaticScale.indexOf(normalizedRoot);
  if (index == -1) return root;

  // Calcular nuevo índice con wrapping (escala circular)
  final newIndex = (index + semitones) % 12;
  final adjustedIndex = newIndex < 0 ? newIndex + 12 : newIndex;

  return MusicalConstants.chromaticScale[adjustedIndex];
}

/// Normaliza bemoles a sostenidos equivalentes.
String _normalizeToSharp(String root) {
  const flatToSharp = {
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };
  return flatToSharp[root] ?? root;
}