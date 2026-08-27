class ApiConstants {
  // Base API URL
  static const String baseUrl = 'http://billingapi.local:3032';

  // Auth Endpoints
  static const String loginEndpoint = '/api/Auth/Login';

  // City Endpoints
  static const String getAllCitiesEndpoint = '/api/City/GetAllCities';
  static const String insertOrUpdateCityEndpoint =
      '/api/City/InsertorUpdateCity';

  // GST Tax Endpoints
  static const String getAllGSTTaxesEndpoint = '/api/GSTTax/GetAllGSTTaxes';
  static const String insertOrUpdateGSTTaxEndpoint =
      '/api/GSTTax/InsertOrUpdateGSTTax';

  // Supplier Endpoints
  static const String getAllSuppliersEndpoint = '/api/Supplier/GetAllSuppliers';
  static const String insertOrUpdateSupplierEndpoint =
      '/api/Supplier/InsertorUpdateSupplier';
  static const String getSupplierOutstandingReportEndpoint =
      '/api/Supplier/GetSupplierOutstandingReport';
  static const String getSupplierPendingInvoiceEndpoint =
      '/api/Supplier/GetSupplierPendingInvoice';

  // Category Endpoints
  static const String getAllCategoriesEndpoint =
      '/api/Category/GetAllCategories';
  static const String insertOrUpdateCategoryEndpoint =
      '/api/Category/InsertorUpdateCategory';

  // SubCategory Endpoints
  static const String getAllSubCategoriesEndpoint =
      '/api/SubCategory/GetAllSubCategories';
  static const String insertOrUpdateSubCategoryEndpoint =
      '/api/SubCategory/InsertorUpdateSubCategory';

  // Brand Endpoints
  static const String getAllBrandsEndpoint = '/api/Brand/GetAllBrands';
  static const String insertOrUpdateBrandEndpoint =
      '/api/Brand/InsertorUpdateBrand';

  // Unit Endpoints
  static const String getAllUnitsEndpoint = '/api/Unit/GetAllUnits';
  static const String insertOrUpdateUnitEndpoint =
      '/api/Unit/InsertorUpdateUnit';

  // Area Endpoints
  static const String getAllAreasEndpoint = '/api/Area/GetAllAreas';
  static const String insertOrUpdateAreaEndpoint =
      '/api/Area/InsertorUpdateArea';

  // State Endpoints
  static const String getAllStatesEndpoint = '/api/State/GetAllStates';

  // Customer Endpoints
  static const String getAllCustomersEndpoint = '/api/Customer/GetAllCustomers';
  static const String getCustomerByIdEndpoint = '/api/Customer/GetCustomerById';
  static const String insertOrUpdateCustomerEndpoint =
      '/api/Customer/InsertorUpdateCustomer';

  // Product Endpoints
  static const String getAllProductsEndpoint = '/api/Product/GetAllProducts';
  static const String insertOrUpdateProductEndpoint =
      '/api/Product/InsertOrUpdateProduct';

  // Database Backup Endpoints
  static const String createDatabaseBackupEndpoint =
      '/api/DatabaseBackup/CreateDatabaseBackup';

  // Company Endpoints
  static const String getAllCompaniesEndpoint = '/api/Company/GetAllCompanies';

  // Branch Endpoints
  static const String getAllBranchesEndpoint = '/api/Branch/GetAllBranches';

  // Purchase Entry Endpoints
  static const String insertOrUpdatePurchaseEntryEndpoint =
      '/api/PurchaseEntry/InsertOrUpdatePurchaseEntry';

  // Payment Endpoints
  static const String insertOrUpdatePaymentEndpoint =
      '/api/Payment/InsertOrUpdatePayment';

  // Email Endpoints
  static const String sendEmailEndpoint = '/api/Email/send';

  // Default JSON Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Authenticated Headers with JWT Bearer Token
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  // Network Timeout Duration
  static const Duration timeoutDuration = Duration(seconds: 15);
}
