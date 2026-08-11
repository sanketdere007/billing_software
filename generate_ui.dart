import 'dart:io';

void main() async {
  final baseDir = 'd:\\FlutterProject\\billing_software\\lib\\screens';
  final cityListPath = '$baseDir\\cities\\city_list_screen.dart';
  final cityMasterPath = '$baseDir\\cities\\city_master_screen.dart';

  final listTemplate = await File(cityListPath).readAsString();
  final masterTemplate = await File(cityMasterPath).readAsString();

  final mappings = [
    {
      "name": "categories",
      "file_prefix": "category",
      "replacements": {
        "CityListItem": "CategoryListItem",
        "CityUpsertRequest": "CategoryUpsertRequest",
        "CityMaster": "Category Master",
        "City Master": "Category Master",
        "City": "Category",
        "city": "category",
        "Cities": "Categories",
        "cities": "categories",
        "cityName": "catName",
        "cityIsActive": "catIsActive",
        "cityId": "catId",
      },
    },
    {
      "name": "subcategories",
      "file_prefix": "subcategory",
      "replacements": {
        "CityListItem": "SubCategoryListItem",
        "CityUpsertRequest": "SubCategoryUpsertRequest",
        "CityMaster": "SubCategory Master",
        "City Master": "SubCategory Master",
        "City": "SubCategory",
        "city": "subcategory",
        "Cities": "SubCategories",
        "cities": "subcategories",
        "cityName": "subCatName",
        "cityIsActive": "subCatIsActive",
        "cityId": "subCatId",
      },
    },
    {
      "name": "brands",
      "file_prefix": "brand",
      "replacements": {
        "CityListItem": "BrandListItem",
        "CityUpsertRequest": "BrandUpsertRequest",
        "CityMaster": "Brand Master",
        "City Master": "Brand Master",
        "City": "Brand",
        "city": "brand",
        "Cities": "Brands",
        "cities": "brands",
        "cityName": "brandName",
        "cityIsActive": "brandIsActive",
        "cityId": "brandId",
      },
    },
    {
      "name": "units",
      "file_prefix": "unit",
      "replacements": {
        "CityListItem": "UnitListItem",
        "CityUpsertRequest": "UnitUpsertRequest",
        "CityMaster": "Unit Master",
        "City Master": "Unit Master",
        "City": "Unit",
        "city": "unit",
        "Cities": "Units",
        "cities": "units",
        "cityName": "unitName",
        "cityIsActive": "unitIsActive",
        "cityId": "unitId",
      },
    },
  ];

  for (var mapping in mappings) {
    final outDir = Directory('$baseDir\\${mapping["name"]}');
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    String listContent = listTemplate;
    (mapping["replacements"] as Map<String, String>?)?.forEach((k, v) {
      listContent = listContent.replaceAll(k.toString(), v.toString());
    });

    final listOut = File(
      '${outDir.path}\\${mapping["file_prefix"]}_list_screen.dart',
    );
    await listOut.writeAsString(listContent);

    String masterContent = masterTemplate;
    (mapping["replacements"] as Map<String, String>?)?.forEach((k, v) {
      masterContent = masterContent.replaceAll(k.toString(), v.toString());
    });

    final masterOut = File(
      '${outDir.path}\\${mapping["file_prefix"]}_master_screen.dart',
    );
    await masterOut.writeAsString(masterContent);

    print('Generated ${mapping["name"]} screens');
  }
}
