import 'dart:io';

void main() {
  final dir = Directory('d:\\FlutterProject\\billing_software\\lib\\screens');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_screen.dart'))
      .toList();

  int processedCount = 0;

  for (final file in files) {
    if (file.path.contains('payment_screen') ||
        file.path.contains('receipt_entry_screen') ||
        file.path.contains('add_sales_entry_screen') ||
        file.path.contains('add_sales_return_screen') ||
        file.path.contains('add_purchase_entry_screen')) {
      continue; // Handled manually
    }

    String content = file.readAsStringSync();

    // Check if it's a form screen that likely uses SaveClearShortcuts
    if (!content.contains('Cancel')) continue;
    if (content.contains('Clear (F10)')) continue; // Already processed

    // Regex to find Cancel button and prepend Clear button
    // We match: OutlinedButton(\n [any whitespace] onPressed: [anything],\n [any whitespace] [optional style]\n [any whitespace] child: const Text('Cancel'),\n [any whitespace]),
    final cancelRegex = RegExp(
        r'([ \t]*)OutlinedButton\(\s*onPressed:\s*([^,]+),\s*(style:\s*[^,]+,\s*)?child:\s*const\s*Text\(\x27Cancel\x27\),\s*\)');

    bool modified = false;
    content = content.replaceAllMapped(cancelRegex, (match) {
      modified = true;
      final indent = match.group(1) ?? '';
      final onPressed = match.group(2) ?? '';
      final style = match.group(3) ?? '';

      return '''$indent// Injected Clear Button
${indent}OutlinedButton(
$indent  onPressed: $onPressed == null ? null : () => SaveClearShortcuts.invokeClear(context),
$indent  ${style}child: const Text('Clear (F10)'),
$indent),
${indent}const SizedBox(width: 12, height: 10),
${indent}OutlinedButton(
$indent  onPressed: $onPressed,
$indent  ${style}child: const Text('Cancel'),
$indent)''';
    });

    if (modified) {
      file.writeAsStringSync(content);
      processedCount++;
      print('Updated: \${file.path}');
    }
  }

  print('Successfully processed \$processedCount files.');
}
