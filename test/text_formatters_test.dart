import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/utils/text_formatters.dart';

void main() {
  group('CapitalizeWordsInputFormatter', () {
    const formatter = CapitalizeWordsInputFormatter();

    TextEditingValue format(String oldText, String newText, {int? selectionOffset}) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldText.length),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selectionOffset ?? newText.length,
          ),
        ),
      );
    }

    test('capitalizes first letter when starting to type', () {
      final result = format('', 's');
      expect(result.text, 'S');
      expect(result.selection.baseOffset, 1);
    });

    test('continues typing word in lowercase after first letter', () {
      final result = format('S', 'Sa');
      expect(result.text, 'Sa');
      expect(result.selection.baseOffset, 2);
    });

    test('capitalizes next word after space is pressed', () {
      final result = format('Sanket ', 'Sanket d');
      expect(result.text, 'Sanket D');
      expect(result.selection.baseOffset, 8);
    });

    test('handles multiple words and spaces', () {
      final result = format('', 'sanket suresh dere');
      expect(result.text, 'Sanket Suresh Dere');
    });

    test('handles multiple consecutive spaces correctly', () {
      final result = format('Sanket  ', 'Sanket  d');
      expect(result.text, 'Sanket  D');
    });

    test('handles punctuation separators like dot and hyphen', () {
      final result = format('', 'mr. john-doe');
      expect(result.text, 'Mr. John-Doe');
    });

    test('handles empty text gracefully', () {
      final result = format('S', '');
      expect(result.text, '');
    });

    test('preserves cursor selection offset', () {
      final result = format('Sanket Dere', 'Sanket aDere', selectionOffset: 8);
      expect(result.text, 'Sanket aDere');
      expect(result.selection.baseOffset, 8);
    });
  });
}
