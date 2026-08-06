import 'package:flutter/services.dart';

/// A [TextInputFormatter] that capitalizes the first letter of each word
/// (i.e. at the beginning of the text or immediately following whitespace or separators).
class CapitalizeWordsInputFormatter extends TextInputFormatter {
  const CapitalizeWordsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final StringBuffer buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ' ' ||
          char == '\t' ||
          char == '\n' ||
          char == '-' ||
          char == '.' ||
          char == '/' ||
          char == '(') {
        buffer.write(char);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
      }
    }

    final capitalizedText = buffer.toString();
    if (capitalizedText == text) {
      return newValue;
    }

    return newValue.copyWith(
      text: capitalizedText,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}
