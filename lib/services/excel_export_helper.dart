import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/platform_helper.dart';

enum ExcelCellAlign { left, center, right }

enum ExcelCellType { text, number }

class ExcelColumn {
  final String header;
  final ExcelCellAlign align;
  final ExcelCellType type;

  const ExcelColumn(
    this.header, {
    this.align = ExcelCellAlign.left,
    this.type = ExcelCellType.text,
  });
}

class ExcelExportResult {
  final bool success;
  final String message;
  final String? filePath;
  final int recordCount;
  final List<int>? fileBytes;

  const ExcelExportResult({
    required this.success,
    required this.message,
    this.filePath,
    required this.recordCount,
    this.fileBytes,
  });
}

/// Shared .xlsx builder and file saver used by report exports.
class ExcelExportHelper {
  static List<int> generateBytes({
    required String sheetName,
    required List<ExcelColumn> columns,
    required List<List<String>> rows,
  }) {
    final archive = Archive();

    final contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';
    archive.addFile(ArchiveFile(
      '[Content_Types].xml',
      contentTypesXml.length,
      utf8.encode(contentTypesXml),
    ));

    final relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)));

    final workbookRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile(
      'xl/_rels/workbook.xml.rels',
      workbookRelsXml.length,
      utf8.encode(workbookRelsXml),
    ));

    final safeSheetName = _escapeXml(_sanitizeSheetName(sheetName));
    final workbookXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <bookViews>
    <workbookView xWindow="0" yWindow="0" windowWidth="20480" windowHeight="10240"/>
  </bookViews>
  <sheets>
    <sheet name="$safeSheetName" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''';
    archive.addFile(ArchiveFile('xl/workbook.xml', workbookXml.length, utf8.encode(workbookXml)));

    final stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2">
    <font>
      <sz val="11"/>
      <color theme="1"/>
      <name val="Calibri"/>
      <family val="2"/>
    </font>
    <font>
      <b val="1"/>
      <sz val="11"/>
      <color rgb="FFFFFFFF"/>
      <name val="Calibri"/>
      <family val="2"/>
    </font>
  </fonts>
  <fills count="3">
    <fill>
      <patternFill patternType="none"/>
    </fill>
    <fill>
      <patternFill patternType="gray125"/>
    </fill>
    <fill>
      <patternFill patternType="solid">
        <fgColor rgb="FF1E3A8A"/>
      </patternFill>
    </fill>
  </fills>
  <borders count="2">
    <border>
      <left/><right/><top/><bottom/><diagonal/>
    </border>
    <border>
      <left style="thin"><color rgb="FFD1D5DB"/></left>
      <right style="thin"><color rgb="FFD1D5DB"/></right>
      <top style="thin"><color rgb="FFD1D5DB"/></top>
      <bottom style="thin"><color rgb="FFD1D5DB"/></bottom>
    </border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="5">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center" wrapText="0"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="left" vertical="center"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="right" vertical="center"/>
    </xf>
  </cellXfs>
</styleSheet>''';
    archive.addFile(ArchiveFile('xl/styles.xml', stylesXml.length, utf8.encode(stylesXml)));

    final sheet1Xml = _buildSheetXml(columns: columns, rows: rows);
    archive.addFile(ArchiveFile(
      'xl/worksheets/sheet1.xml',
      sheet1Xml.length,
      utf8.encode(sheet1Xml),
    ));

    return ZipEncoder().encode(archive);
  }

  static Future<ExcelExportResult> exportSheet({
    required String filePrefix,
    required String sheetName,
    required List<ExcelColumn> columns,
    required List<List<String>> rows,
    required String emptyMessage,
  }) async {
    if (rows.isEmpty) {
      return ExcelExportResult(
        success: false,
        message: emptyMessage,
        recordCount: 0,
      );
    }

    try {
      final bytes = generateBytes(
        sheetName: sheetName,
        columns: columns,
        rows: rows,
      );
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${filePrefix}_$timestamp.xlsx';

      if (kIsWeb) {
        final base64Data = base64Encode(bytes);
        final uri = Uri.parse(
          'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Data',
        );
        await launchUrl(uri);
        return ExcelExportResult(
          success: true,
          message: 'Exported ${rows.length} records to $fileName',
          filePath: fileName,
          recordCount: rows.length,
          fileBytes: bytes,
        );
      }

      String? savedPath;
      if (PlatformHelper.isWindowsDesktop) {
        final userProfile = Platform.environment['USERPROFILE'];
        String targetDir = Directory.current.path;

        if (userProfile != null && userProfile.isNotEmpty) {
          final downloadsDir = Directory('$userProfile\\Downloads');
          if (downloadsDir.existsSync()) {
            targetDir = downloadsDir.path;
          } else {
            final docsDir = Directory('$userProfile\\Documents');
            if (docsDir.existsSync()) {
              targetDir = docsDir.path;
            }
          }
        }

        final file = File('$targetDir\\$fileName');
        await file.writeAsBytes(bytes);
        savedPath = file.path;
      } else {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        savedPath = file.path;
      }

      return ExcelExportResult(
        success: true,
        message:
            'Successfully exported ${rows.length} ${rows.length == 1 ? 'record' : 'records'} to $fileName',
        filePath: savedPath,
        recordCount: rows.length,
        fileBytes: bytes,
      );
    } catch (e) {
      return ExcelExportResult(
        success: false,
        message: 'Failed to export records: $e',
        recordCount: rows.length,
      );
    }
  }

  static Future<bool> openExportedFile(String filePath) async {
    try {
      if (kIsWeb) return false;

      if (PlatformHelper.isWindowsDesktop) {
        final result = await Process.run(
          'cmd.exe',
          ['/c', 'start', '""', filePath],
          runInShell: true,
        );
        return result.exitCode == 0;
      }

      return await launchUrl(Uri.file(filePath));
    } catch (_) {
      return false;
    }
  }

  static String formatAmount(double value) => value.toStringAsFixed(2);

  static String formatDate(DateTime? value, {String pattern = 'dd-MM-yyyy'}) {
    if (value == null) return '';
    return DateFormat(pattern).format(value);
  }

  static String _buildSheetXml({
    required List<ExcelColumn> columns,
    required List<List<String>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    buffer.writeln('  <sheetViews>');
    buffer.writeln('    <sheetView tabSelected="1" workbookViewId="0">');
    buffer.writeln('      <pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>');
    buffer.writeln('    </sheetView>');
    buffer.writeln('  </sheetViews>');
    buffer.writeln('  <sheetFormatPr defaultRowHeight="20" customHeight="1"/>');

    final colWidths = List<double>.generate(
      columns.length,
      (i) => columns[i].header.length.toDouble(),
    );
    for (final row in rows) {
      for (int j = 0; j < columns.length && j < row.length; j++) {
        if (row[j].length > colWidths[j]) {
          colWidths[j] = row[j].length.toDouble();
        }
      }
    }

    buffer.writeln('  <cols>');
    for (int i = 0; i < colWidths.length; i++) {
      final colIndex = i + 1;
      final autoWidth = (colWidths[i] + 4.5).clamp(11.0, 48.0);
      buffer.writeln(
        '    <col min="$colIndex" max="$colIndex" width="${autoWidth.toStringAsFixed(2)}" customWidth="1"/>',
      );
    }
    buffer.writeln('  </cols>');
    buffer.writeln('  <sheetData>');

    buffer.writeln('    <row r="1" ht="26" customHeight="1">');
    for (int i = 0; i < columns.length; i++) {
      final cellRef = '${_columnToLetter(i + 1)}1';
      final headerTitle = _escapeXml(columns[i].header);
      buffer.writeln(
        '      <c r="$cellRef" s="1" t="inlineStr"><is><t>$headerTitle</t></is></c>',
      );
    }
    buffer.writeln('    </row>');

    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final rowNum = rowIndex + 2;
      final row = rows[rowIndex];
      buffer.writeln('    <row r="$rowNum" ht="20" customHeight="1">');

      for (int colIndex = 0; colIndex < columns.length; colIndex++) {
        final cellRef = '${_columnToLetter(colIndex + 1)}$rowNum';
        final val = colIndex < row.length ? row[colIndex] : '';
        final column = columns[colIndex];
        final style = _styleFor(column.align);

        if (column.type == ExcelCellType.number && val.isNotEmpty) {
          buffer.writeln('      <c r="$cellRef" s="$style" t="n"><v>$val</v></c>');
        } else {
          final escaped = _escapeXml(val);
          buffer.writeln(
            '      <c r="$cellRef" s="$style" t="inlineStr"><is><t>$escaped</t></is></c>',
          );
        }
      }

      buffer.writeln('    </row>');
    }

    buffer.writeln('  </sheetData>');
    buffer.writeln('</worksheet>');
    return buffer.toString();
  }

  static int _styleFor(ExcelCellAlign align) {
    switch (align) {
      case ExcelCellAlign.center:
        return 3;
      case ExcelCellAlign.right:
        return 4;
      case ExcelCellAlign.left:
        return 2;
    }
  }

  static String _columnToLetter(int colIndex) {
    String result = '';
    int col = colIndex;
    while (col > 0) {
      final remainder = (col - 1) % 26;
      result = String.fromCharCode(65 + remainder) + result;
      col = (col - 1) ~/ 26;
    }
    return result;
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _sanitizeSheetName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/*?:\[\]]'), ' ').trim();
    if (cleaned.isEmpty) return 'Sheet1';
    return cleaned.length > 31 ? cleaned.substring(0, 31) : cleaned;
  }
}
