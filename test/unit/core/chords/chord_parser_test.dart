import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/chords/chord_line.dart';
import 'package:himnario_id_2/core/chords/chord_parser.dart';

void main() {
  group('ChordParser - parseChordProLine', () {
    test('línea vacía retorna segmento vacío', () {
      final result = parseChordProLine('');
      expect(result, [const ChordLine(text: '')]);
    });

    test('línea sin acordes retorna un solo segmento', () {
      const text = 'Santo Dios';
      final result = parseChordProLine(text);
      expect(result, [ChordLine(chord: null, text: text)]);
    });

    test('texto sin acordes con múltiples palabras', () {
      const text = 'Esto es una línea sin acordes';
      final result = parseChordProLine(text);
      expect(result, [ChordLine(chord: null, text: text)]);
    });

    test('[C]Santo [G]Dios → 2 segmentos', () {
      final result = parseChordProLine('[C]Santo [G]Dios');
      expect(result.length, 2);
      expect(result[0], ChordLine(chord: 'C', text: 'Santo '));
      expect(result[1], ChordLine(chord: 'G', text: 'Dios'));
    });

    test('[C]Santo [G] → último segmento con texto vacío', () {
      final result = parseChordProLine('[C]Santo [G]');
      expect(result.length, 2);
      expect(result[0], ChordLine(chord: 'C', text: 'Santo '));
      expect(result[1], ChordLine(chord: 'G', text: ''));
    });

    test('[C]Santo → un solo segmento con acorde', () {
      final result = parseChordProLine('[C]Santo');
      expect(result.length, 1);
      expect(result[0], ChordLine(chord: 'C', text: 'Santo'));
    });

    test('[Am][G][F] → múltiples acordes adyacentes', () {
      final result = parseChordProLine('[Am][G][F]');
      expect(result.length, 3);
      expect(result[0], ChordLine(chord: 'Am', text: ''));
      expect(result[1], ChordLine(chord: 'G', text: ''));
      expect(result[2], ChordLine(chord: 'F', text: ''));
    });

    test('texto antes del primer acorde', () {
      final result = parseChordProLine('Intro [C]Santo');
      expect(result.length, 2);
      expect(result[0], ChordLine(text: 'Intro '));
      expect(result[1], ChordLine(chord: 'C', text: 'Santo'));
    });

    test('acorde con bajo G/B', () {
      final result = parseChordProLine('[G/B]Santo');
      expect(result.length, 1);
      expect(result[0], ChordLine(chord: 'G/B', text: 'Santo'));
    });

    test('acorde menor Am', () {
      final result = parseChordProLine('[Am]Santo');
      expect(result.length, 1);
      expect(result[0], ChordLine(chord: 'Am', text: 'Santo'));
    });

    test('acorde con séptima G7', () {
      final result = parseChordProLine('[G7]Santo');
      expect(result.length, 1);
      expect(result[0], ChordLine(chord: 'G7', text: 'Santo'));
    });
  });

  group('ChordParser - stripChords', () {
    test('elimina acordes de texto', () {
      expect(stripChords('[G]Dios es [C]amor'), 'Dios es amor');
    });

    test('texto sin acordes no se modifica', () {
      expect(stripChords('Dios es amor'), 'Dios es amor');
    });

    test('cadena vacía retorna vacío', () {
      expect(stripChords(''), '');
    });
  });

  group('ChordParser - chordRegex', () {
    test('captura acorde simple', () {
      final match = chordRegex.firstMatch('[G]');
      expect(match?.group(1), 'G');
    });

    test('captura acorde con sostenido', () {
      final match = chordRegex.firstMatch('[C#]');
      expect(match?.group(1), 'C#');
    });

    test('captura acorde con bemol', () {
      final match = chordRegex.firstMatch('[Bb]');
      expect(match?.group(1), 'Bb');
    });

    test('captura acorde con bajo', () {
      final match = chordRegex.firstMatch('[G/B]');
      expect(match?.group(1), 'G/B');
    });

    test('captura acorde menor con séptima', () {
      final match = chordRegex.firstMatch('[Dm7]');
      expect(match?.group(1), 'Dm7');
    });

    test('no captura corchetes vacíos', () {
      final match = chordRegex.firstMatch('[]');
      expect(match, isNull);
    });

    test('no captura acorde inválido H', () {
      final match = chordRegex.firstMatch('[H]');
      expect(match, isNull);
    });
  });
}
