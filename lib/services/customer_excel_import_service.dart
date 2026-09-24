import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';

class CustomerExcelImportService {
  static Future<List<Map<String, dynamic>>?> pickAndParseExcel() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Excel',
        extensions: <String>['xlsx', 'xls'],
      );
      
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      if (file == null) {
        return null; // User canceled
      }

      final bytes = await file.readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      List<Map<String, dynamic>> parsedData = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;
        
        bool isHeader = true;
        List<String> headers = [];

        for (var row in sheet.rows) {
          if (isHeader) {
            for (var cell in row) {
              headers.add(cell?.value?.toString().trim().toLowerCase() ?? '');
            }
            isHeader = false;
            continue;
          }

          // If the row is empty, skip
          if (row.every((cell) => cell == null || cell.value == null || cell.value.toString().trim().isEmpty)) {
            continue;
          }

          Map<String, dynamic> rowData = {
            "srNo": _getIntValue(row, headers, ["sr no.", "sr", "srno", "sr.no", "sr. no"]) ?? 0,
            "name": _getStringValue(row, headers, ["name", "customer name", "farmer name", "customer"]),
            "number": _getStringValue(row, headers, ["number", "mobile", "mobile no.", "phone"]),
            "email": _getStringValue(row, headers, ["email", "e-mail", "email id"]),
            "address": _getStringValue(row, headers, ["address", "add"]),
            "village": _getStringValue(row, headers, ["village", "area"]),
            "taluka": _getStringValue(row, headers, ["taluka", "city", "tehsil"]),
            "district": _getStringValue(row, headers, ["district", "dist"]),
            "state": _getStringValue(row, headers, ["state"]),
            "pinCode": _getStringValue(row, headers, ["pincode", "pin", "pin code", "zip"]),
            "farmerType": _getStringValue(row, headers, ["farmer type", "farmertype"]),
            "animalType": _getStringValue(row, headers, ["animal type", "animaltype"]),
            "animalCount": _getIntValue(row, headers, ["animal count", "animalcount"]) ?? 0,
            "birdType": _getStringValue(row, headers, ["bird type", "birdtype"]),
            "birdCount": _getIntValue(row, headers, ["bird count", "birdcount"]) ?? 0,
          };

          parsedData.add(rowData);
        }
        break; // Only read the first sheet
      }
      return parsedData;
    } catch (e) {
      debugPrint("Error parsing excel: $e");
      rethrow;
    }
  }

  static String _getStringValue(List<dynamic> row, List<String> headers, List<String> possibleNames) {
    int index = -1;
    for (String name in possibleNames) {
      index = headers.indexOf(name);
      if (index != -1) break;
    }

    if (index != -1 && index < row.length) {
      return _getCellValueString(row[index]).trim();
    }
    return "";
  }

  static String _getCellValueString(dynamic cell) {
    if (cell == null) return "";
    var value = cell.value;
    if (value == null) return "";
    
    // Handle excel ^4.x CellValue types if present
    String valStr = value.toString();
    if (valStr.startsWith('TextCellValue(')) {
      return valStr.substring(14, valStr.length - 1);
    } else if (valStr.startsWith('IntCellValue(')) {
      return valStr.substring(13, valStr.length - 1);
    } else if (valStr.startsWith('DoubleCellValue(')) {
      return valStr.substring(16, valStr.length - 1);
    } else if (valStr.startsWith('BoolCellValue(')) {
      return valStr.substring(14, valStr.length - 1);
    }
    return valStr;
  }

  static int? _getIntValue(List<dynamic> row, List<String> headers, List<String> possibleNames) {
    String strVal = _getStringValue(row, headers, possibleNames);
    if (strVal.isNotEmpty) {
      return int.tryParse(strVal.split('.').first); // Handle floats like 1.0
    }
    return null;
  }
}
