# 🤖 Prompt de Refactorización: Renderizador ChordPro Responsivo

## 🎯 Objetivo
Crear un renderizador de acordes personalizado en Flutter que mantenga cada acorde anclado a su sílaba correspondiente, soportando diseño responsivo total (ajuste automático de texto sin corromper la posición de los acordes) sin importar el tamaño de la fuente.

## 🛠️ Contexto del Problema
Las librerías estándar de ChordPro se rompen cuando se eliminan los saltos de línea (`\n`) para lograr un efecto responsivo en pantallas móviles con letras grandes, causando que los acordes se apilen al inicio del texto.

## 📋 Instrucciones de Implementación (La Solución 'Wrap')

**Paso 1: No usar paquetes externos de ChordPro para el renderizado final.**
Vamos a crear nuestro propio Widget llamado `ResponsiveChordLyric`.

**Paso 2: Lógica de Parseo (Regex)**
El objetivo es transformar un String con formato ChordPro (ej. `Alaba a [G]Dios`) en una lista de objetos que contengan `{chord: String?, lyric: String}`.

**Paso 3: Construcción del UI (El uso de Wrap)**
Implementa el siguiente código base. La clave del éxito es usar el widget `Wrap` para iterar sobre los bloques. El `Wrap` hará el salto de línea automático de forma nativa cuando se quede sin espacio horizontal, llevándose el acorde y la letra juntos.

```dart
import 'package:flutter/material.dart';

class ChordLyricBlock {
  final String? chord;
  final String lyric;
  ChordLyricBlock({this.chord, required this.lyric});
}

class ResponsiveChordLyric extends StatelessWidget {
  final String chordProText;
  final TextStyle lyricStyle;
  final TextStyle chordStyle;

  const ResponsiveChordLyric({
    Key? key,
    required this.chordProText,
    required this.lyricStyle,
    required this.chordStyle,
  }) : super(key: key);

  List<ChordLyricBlock> _parseChordPro(String text) {
    // 1. Reemplazamos los saltos de línea con un espacio para forzar el responsive puro
    // (Opcional: Si el usuario quiere respetar los \n poéticos, 
    // se manejan partiendo el texto en bloques y devolviendo múltiples Wraps).
    final cleanText = text.replaceAll('\n', ' ');
    
    List<ChordLyricBlock> blocks = [];
    
    // Regex que busca cosas entre corchetes [Acorde]
    final RegExp exp = RegExp(r'\[(.*?)\]');
    
    // Partimos el texto manteniendo los separadores (los acordes)
    final Iterable<Match> matches = exp.allMatches(cleanText);
    
    int lastMatchEnd = 0;
    
    for (Match match in matches) {
      // Texto antes del acorde
      if (match.start > lastMatchEnd) {
        String before = cleanText.substring(lastMatchEnd, match.start);
        // Dividimos por espacios para que el Wrap pueda hacer saltos de línea naturales palabra por palabra
        List<String> words = before.split(' ');
        for (int i = 0; i < words.length; i++) {
          if (words[i].isNotEmpty || i < words.length - 1) {
             blocks.add(ChordLyricBlock(lyric: words[i] + (i < words.length - 1 ? ' ' : '')));
          }
        }
      }
      
      // Extraemos el acorde y el texto inmediatamente posterior hasta el siguiente espacio o acorde
      String chord = match.group(1)!;
      lastMatchEnd = match.end;
      
      int nextSpace = cleanText.indexOf(' ', lastMatchEnd);
      int nextBracket = cleanText.indexOf('[', lastMatchEnd);
      
      int endOfLyric = cleanText.length;
      if (nextSpace != -1 && (nextBracket == -1 || nextSpace < nextBracket)) {
         endOfLyric = nextSpace + 1; // Incluir el espacio
      } else if (nextBracket != -1) {
         endOfLyric = nextBracket;
      }
      
      String lyricAfterChord = cleanText.substring(lastMatchEnd, endOfLyric);
      blocks.add(ChordLyricBlock(chord: chord, lyric: lyricAfterChord));
      lastMatchEnd = endOfLyric;
    }
    
    // Añadir el resto del texto
    if (lastMatchEnd < cleanText.length) {
      String remaining = cleanText.substring(lastMatchEnd);
      List<String> words = remaining.split(' ');
        for (int i = 0; i < words.length; i++) {
          if (words[i].isNotEmpty || i < words.length - 1) {
             blocks.add(ChordLyricBlock(lyric: words[i] + (i < words.length - 1 ? ' ' : '')));
          }
        }
    }
    
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _parseChordPro(chordProText);

    return Wrap(
      spacing: 0.0, // El espaciado ya está en los strings de las letras
      runSpacing: 10.0, // Espacio vertical entre las líneas que se van creando
      crossAxisAlignment: WrapCrossAlignment.end,
      children: blocks.map((block) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.chord != null)
              Text(
                block.chord!,
                style: chordStyle,
              )
            else
              // Espaciador invisible para mantener la misma altura de línea si no hay acorde
              Text('', style: chordStyle), 
            Text(
              block.lyric,
              style: lyricStyle,
            ),
          ],
        );
      }).toList(),
    );
  }
}