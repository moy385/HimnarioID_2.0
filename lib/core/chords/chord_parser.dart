import 'chord_line.dart';

/// Expresión regular para extraer acordes en formato ChordPro: `[G]`, `[Am7]`, `[C#m]`, `[G/B]`.
///
/// Captura el contenido dentro de corchetes excluyendo los corchetes.
/// Soporta: raíz (A-G), alteraciones (#/b), sufijos (m, 7, sus, dim, aug, Maj, maj),
/// números, y acordes con bajo separados por `/`.
const String chordPatternRaw = r'\[([A-G][#b]?[a-zA-Z0-9+#b]*(?:/[A-G][#b]?)?)\]';

/// [RegExp] compilado a partir de [chordPatternRaw] para usar en parseo y transposición.
final RegExp chordRegex = RegExp(chordPatternRaw);

/// Parsea una línea de texto en formato ChordPro y devuelve una lista de
/// segmentos [ChordLine].
///
/// Cada acorde encontrado inicia un nuevo segmento: el [chord] es el contenido
/// de los corchetes y [text] es el texto que le sigue hasta el próximo acorde
/// o el fin de línea.
///
/// Reglas:
/// - Si la línea no contiene acordes, retorna `[ChordLine(chord: null, text: line)]`.
/// - Un acorde al final de la línea genera texto vacío en el último segmento.
/// - Texto antes del primer acorde se emite como segmento sin acorde.
///
/// Ejemplos:
/// ```dart
/// parseChordProLine('[C]Santo [G]Dios')
///   → [{chord:"C", text:"Santo "}, {chord:"G", text:"Dios"}]
///
/// parseChordProLine('[C]Santo [G]')
///   → [{chord:"C", text:"Santo "}, {chord:"G", text:""}]
///
/// parseChordProLine('Santo Dios')
///   → [{chord:null, text:"Santo Dios"}]
/// ```
List<ChordLine> parseChordProLine(String line) {
  if (line.isEmpty) {
    return [const ChordLine(text: '')];
  }

  final matches = chordRegex.allMatches(line).toList();

  // ── Sin acordes: un solo segmento de texto ──
  if (matches.isEmpty) {
    return [ChordLine(chord: null, text: line)];
  }

  final result = <ChordLine>[];
  int lastEnd = 0;

  for (final match in matches) {
    // Texto antes del acorde (desde el final del acorde anterior o inicio)
    if (match.start > lastEnd) {
      result.add(ChordLine(text: line.substring(lastEnd, match.start)));
    }

    final chord = match.group(1)!;

    // El texto después del acorde empieza inmediatamente después de `]`
    final textStart = match.end;

    // Buscar el siguiente acorde para delimitar el texto de este
    final nextMatch = chordRegex.firstMatch(line.substring(textStart));
    final textEnd = nextMatch != null
        ? textStart + nextMatch.start
        : line.length;

    result.add(ChordLine(
      chord: chord,
      text: line.substring(textStart, textEnd),
    ),);

    lastEnd = textEnd;
  }

  return result;
}

/// Elimina todos los marcadores de acordes ChordPro del texto.
///
/// Ejemplo: `stripChords('[G]Dios es [C]amor')` → `'Dios es amor'`
String stripChords(String text) {
  return text.replaceAll(chordRegex, '');
}
