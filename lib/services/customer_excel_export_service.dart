import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../utils/platform_helper.dart';

/// Result object containing outcome of an Excel export operation
class CustomerExcelExportResult {
  final bool success;
  final String message;
  final String? filePath;
  final int recordCount;
  final List<int>? fileBytes;

  const CustomerExcelExportResult({
    required this.success,
    required this.message,
    this.filePath,
    required this.recordCount,
    this.fileBytes,
  });
}

/// Helper service for exporting Customer Master data to formatted Excel (.xlsx) files
class CustomerExcelExportService {
  /// Defines column definitions for the Customer Export sheet
  static const List<String> _headers = [
    'Sr. No.',
    'Customer Code',
    'Customer Name',
    'Company Name',
    'Mobile No.',
    'Alternate Mobile',
    'Email',
    'GST No.',
    'PAN No.',
    'Address',
    'Area',
    'City',
    'State',
    'Pincode',
    'Country',
    'Status',
    'Created Date',
    'Modified Date',
  ];

  /// Generates the .xlsx file bytes for the given customer list
  static List<int> generateCustomerExcelBytes(List<CustomerListItem> customers) {
    final archive = Archive();

    // 1. [Content_Types].xml
    final contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

    // 2. _rels/.rels
    final relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)));

    // 3. xl/_rels/workbook.xml.rels
    final workbookRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('xl/_rels/workbook.xml.rels', workbookRelsXml.length, utf8.encode(workbookRelsXml)));

    // 4. xl/workbook.xml
    final workbookXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <bookViews>
    <workbookView xWindow="0" yWindow="0" windowWidth="20480" windowHeight="10240"/>
  </bookViews>
  <sheets>
    <sheet name="Customers" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''';
    archive.addFile(ArchiveFile('xl/workbook.xml', workbookXml.length, utf8.encode(workbookXml)));

    // 5. xl/styles.xml
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
    <!-- 0: Default Normal -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <!-- 1: Header (Bold, White on #1E3A8A Dark Navy fill, Thin border, Centered) -->
    <xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center" wrapText="0"/>
    </xf>
    <!-- 2: Regular text data (Thin border, Left-aligned, Vertical center) -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="left" vertical="center"/>
    </xf>
    <!-- 3: Centered data (Sr. No., Code, Status, Dates) -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
    <!-- 4: Right-aligned numeric data -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="right" vertical="center"/>
    </xf>
  </cellXfs>
</styleSheet>''';
    archive.addFile(ArchiveFile('xl/styles.xml', stylesXml.length, utf8.encode(stylesXml)));

    // 6. xl/worksheets/sheet1.xml
    final sheet1Xml = _buildSheet1Xml(customers);
    archive.addFile(ArchiveFile('xl/worksheets/sheet1.xml', sheet1Xml.length, utf8.encode(sheet1Xml)));

    // Encode to ZIP (.xlsx)
    final zipEncoder = ZipEncoder();
    return zipEncoder.encode(archive);
  }

  /// Builds worksheet XML including frozen first row, auto-fit column widths, and customer rows
  static String _buildSheet1Xml(List<CustomerListItem> customers) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');

    // Freeze First Row (pane ySplit="1", topLeftCell="A2")
    buffer.writeln('  <sheetViews>');
    buffer.writeln('    <sheetView tabSelected="1" workbookViewId="0">');
    buffer.writeln('      <pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>');
    buffer.writeln('    </sheetView>');
    buffer.writeln('  </sheetViews>');

    buffer.writeln('  <sheetFormatPr defaultRowHeight="20" customHeight="1"/>');

    // Calculate auto-fit column widths
    final colWidths = List<double>.generate(_headers.length, (i) => _headers[i].length.toDouble());

    // Extract all rows to calculate widths
    final rowsData = <List<String>>[];
    for (int i = 0; i < customers.length; i++) {
      final c = customers[i];
      final row = [
        (i + 1).toString(), // Sr. No.
        c.custCode.isNotEmpty ? c.custCode : 'C-${c.custId}',
        c.custName,
        c.custCompanyName,
        c.custMobileNo,
        c.custAlternateMobileNo,
        c.custEmail,
        c.custGSTNo,
        c.custPANNo,
        c.custAddress,
        c.custArea,
        c.custCity,
        c.custState,
        c.custPincode,
        c.custCountry.isNotEmpty ? c.custCountry : 'India',
        c.custIsActive ? 'Active' : 'Inactive',
        _formatDate(c.custCreatedDate),
        _formatDate(c.custModifiedDate),
      ];
      rowsData.add(row);

      for (int j = 0; j < row.length; j++) {
        if (row[j].length > colWidths[j]) {
          colWidths[j] = row[j].length.toDouble();
        }
      }
    }

    // Output <cols> for auto-fit column widths (clamped between 10.0 and 48.0 + padding)
    buffer.writeln('  <cols>');
    for (int i = 0; i < colWidths.length; i++) {
      final colIndex = i + 1;
      final autoWidth = (colWidths[i] + 4.5).clamp(11.0, 48.0);
      buffer.writeln('    <col min="$colIndex" max="$colIndex" width="${autoWidth.toStringAsFixed(2)}" customWidth="1"/>');
    }
    buffer.writeln('  </cols>');

    // Output <sheetData>
    buffer.writeln('  <sheetData>');

    // Header Row (Row 1, style s="1")
    buffer.writeln('    <row r="1" ht="26" customHeight="1">');
    for (int i = 0; i < _headers.length; i++) {
      final cellRef = '${_columnToLetter(i + 1)}1';
      final headerTitle = _escapeXml(_headers[i]);
      buffer.writeln('      <c r="$cellRef" s="1" t="inlineStr"><is><t>$headerTitle</t></is></c>');
    }
    buffer.writeln('    </row>');

    // Data Rows (Row 2 .. N+1)
    for (int rowIndex = 0; rowIndex < rowsData.length; rowIndex++) {
      final rowNum = rowIndex + 2;
      final row = rowsData[rowIndex];
      buffer.writeln('    <row r="$rowNum" ht="20" customHeight="1">');

      for (int colIndex = 0; colIndex < row.length; colIndex++) {
        final cellRef = '${_columnToLetter(colIndex + 1)}$rowNum';
        final val = row[colIndex];

        if (colIndex == 0) {
          // Sr. No. -> Numeric cell (style 3: centered)
          buffer.writeln('      <c r="$cellRef" s="3" t="n"><v>$val</v></c>');
        } else if (colIndex == 1 || colIndex == 4 || colIndex == 5 || colIndex == 13 || colIndex == 15 || colIndex == 16 || colIndex == 17) {
          // Centered text fields: Code, Mobile, Pincode, Status, Dates (style 3)
          final escaped = _escapeXml(val);
          buffer.writeln('      <c r="$cellRef" s="3" t="inlineStr"><is><t>$escaped</t></is></c>');
        } else {
          // Left-aligned regular text fields (style 2)
          final escaped = _escapeXml(val);
          buffer.writeln('      <c r="$cellRef" s="2" t="inlineStr"><is><t>$escaped</t></is></c>');
        }
      }

      buffer.writeln('    </row>');
    }

    buffer.writeln('  </sheetData>');
    buffer.writeln('</worksheet>');

    return buffer.toString();
  }

  /// Converts 1-indexed column number to Excel letter (1 -> A, 2 -> B, 27 -> AA)
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

  /// XML character escaper
  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Format date string for user-friendly display
  static String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '-';
    try {
      final parsed = DateTime.tryParse(rawDate.trim());
      if (parsed != null) {
        return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
      }
    } catch (_) {}
    return rawDate.trim();
  }

  /// Exports the given customer list to an Excel (.xlsx) file and saves it on the system.
  static Future<CustomerExcelExportResult> exportCustomers({
    required List<CustomerListItem> customers,
  }) async {
    if (customers.isEmpty) {
      return const CustomerExcelExportResult(
        success: false,
        message: 'No customer records available to export.',
        recordCount: 0,
      );
    }

    try {
      final bytes = generateCustomerExcelBytes(customers);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Customers_Export_$timestamp.xlsx';

      if (kIsWeb) {
        // Web: trigger browser download via base64 data URI
        final base64Data = base64Encode(bytes);
        final uri = Uri.parse('data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Data');
        await launchUrl(uri);
        return CustomerExcelExportResult(
          success: true,
          message: 'Exported ${customers.length} customers to $fileName',
          filePath: fileName,
          recordCount: customers.length,
          fileBytes: bytes,
        );
      }

      // Windows / Desktop / Native platform file saving
      String? savedPath;

      if (PlatformHelper.isWindowsDesktop) {
        // Preferred: User's Downloads or Documents folder
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
        // Other native platforms (Linux, macOS, Mobile fallback)
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        savedPath = file.path;
      }

      return CustomerExcelExportResult(
        success: true,
        message: 'Successfully exported ${customers.length} ${customers.length == 1 ? 'customer' : 'customers'} to $fileName',
        filePath: savedPath,
        recordCount: customers.length,
        fileBytes: bytes,
      );
    } catch (e) {
      return CustomerExcelExportResult(
        success: false,
        message: 'Failed to export customer records: $e',
        recordCount: customers.length,
      );
    }
  }

  /// Opens the exported Excel file in the default system viewer (e.g. Microsoft Excel)
  static Future<bool> openExportedFile(String filePath) async {
    try {
      if (kIsWeb) return false;

      if (PlatformHelper.isWindowsDesktop) {
        // Launch using Windows start command
        final result = await Process.run('cmd.exe', ['/c', 'start', '""', filePath], runInShell: true);
        return result.exitCode == 0;
      } else {
        final uri = Uri.file(filePath);
        return await launchUrl(uri);
      }
    } catch (_) {
      return false;
    }
  }

  /// Reveals the exported file in Windows File Explorer
  static Future<bool> revealInFileExplorer(String filePath) async {
    try {
      if (PlatformHelper.isWindowsDesktop) {
        final result = await Process.run('explorer.exe', ['/select,', filePath]);
        return result.exitCode == 0;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
