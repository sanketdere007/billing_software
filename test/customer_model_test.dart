import 'package:flutter_test/flutter_test.dart';
import 'package:billing_software/models/customer.dart';

void main() {
  group('Customer Model - GetAllCustomer & GetCustomerById API Response tests', () {
    test('CustomerListItem parses Cust_AreaName, Cust_CityName, and Cust_StateName correctly', () {
      final json = {
        'cust_Id': 101,
        'cust_Code': 'CUST-001',
        'cust_Name': 'John Doe',
        'cust_CompanyName': 'Acme Corp',
        'cust_MobileNo': '9876543210',
        'cust_AlternateMobileNo': '9123456780',
        'cust_Email': 'john@example.com',
        'cust_GSTNo': '27ABCDE1234F1Z5',
        'cust_PANNo': 'ABCDE1234F',
        'cust_Address': '123 Main Street',
        'cust_Areaid': 5,
        'Cust_AreaName': 'Kothrud',
        'cust_Cityid': 12,
        'Cust_CityName': 'Pune',
        'cust_Stateid': 27,
        'Cust_StateName': 'Maharashtra',
        'cust_Pincode': '411038',
        'cust_Country': 'India',
        'cust_BranchId': 1,
        'cust_CompId': 1,
        'cust_IsActive': true,
        'cust_CreatedBy': 1,
        'cust_CreatedDate': '2026-01-01T10:00:00Z',
      };

      final customer = CustomerListItem.fromJson(json);

      expect(customer.custId, 101);
      expect(customer.custName, 'John Doe');
      expect(customer.custAreaName, 'Kothrud');
      expect(customer.custCityName, 'Pune');
      expect(customer.custStateName, 'Maharashtra');
      expect(customer.custArea, 'Kothrud');
      expect(customer.custCity, 'Pune');
      expect(customer.custState, 'Maharashtra');
      expect(customer.areaName, 'Kothrud');
      expect(customer.cityName, 'Pune');
      expect(customer.stateName, 'Maharashtra');
      expect(customer.fullAddress, contains('Kothrud'));
      expect(customer.fullAddress, contains('Pune'));
      expect(customer.fullAddress, contains('Maharashtra'));
    });

    test('CustomerListResponse parses GetAllCustomers API response with Cust_AreaName, Cust_CityName, Cust_StateName', () {
      final getAllCustomersResponseJson = {
        'status': true,
        'message': 'Customers fetched successfully',
        'data': [
          {
            'cust_Id': 201,
            'cust_Code': 'CUST-201',
            'cust_Name': 'Rahul Sharma',
            'cust_MobileNo': '9800000001',
            'cust_Address': 'Shop 4, Market Yard',
            'Cust_AreaName': 'Gultekdi',
            'Cust_CityName': 'Pune',
            'Cust_StateName': 'Maharashtra',
            'cust_Pincode': '411037',
          },
          {
            'cust_Id': 202,
            'cust_Code': 'CUST-202',
            'cust_Name': 'Amit Patel',
            'cust_MobileNo': '9800000002',
            'cust_Address': '10 Navrangpura',
            'Cust_AreaName': 'Navrangpura',
            'Cust_CityName': 'Ahmedabad',
            'Cust_StateName': 'Gujarat',
            'cust_Pincode': '380009',
          }
        ]
      };

      final response = CustomerListResponse.fromJson(getAllCustomersResponseJson);

      expect(response.status, isTrue);
      expect(response.data.length, 2);

      final cust1 = response.data[0];
      expect(cust1.custId, 201);
      expect(cust1.custName, 'Rahul Sharma');
      expect(cust1.custAreaName, 'Gultekdi');
      expect(cust1.custCityName, 'Pune');
      expect(cust1.custStateName, 'Maharashtra');

      final cust2 = response.data[1];
      expect(cust2.custId, 202);
      expect(cust2.custName, 'Amit Patel');
      expect(cust2.custAreaName, 'Navrangpura');
      expect(cust2.custCityName, 'Ahmedabad');
      expect(cust2.custStateName, 'Gujarat');
    });

    test('CustomerDetailResponse parses GetCustomerById API response with Cust_AreaName, Cust_CityName, Cust_StateName', () {
      final getCustomerByIdResponseJson = {
        'status': true,
        'message': 'Customer details found',
        'data': {
          'cust_Id': 301,
          'cust_Code': 'CUST-301',
          'cust_Name': 'Sneha Rao',
          'cust_MobileNo': '9800000003',
          'cust_Address': 'Flat 202, Green Glen Layout',
          'Cust_AreaName': 'Bellandur',
          'Cust_CityName': 'Bengaluru',
          'Cust_StateName': 'Karnataka',
          'cust_Pincode': '560103',
          'cust_IsActive': true,
        }
      };

      final response = CustomerDetailResponse.fromJson(getCustomerByIdResponseJson);

      expect(response.status, isTrue);
      expect(response.data, isNotNull);
      final cust = response.data!;
      expect(cust.custId, 301);
      expect(cust.custName, 'Sneha Rao');
      expect(cust.custAreaName, 'Bellandur');
      expect(cust.custCityName, 'Bengaluru');
      expect(cust.custStateName, 'Karnataka');
      expect(cust.areaName, 'Bellandur');
      expect(cust.cityName, 'Bengaluru');
      expect(cust.stateName, 'Karnataka');
    });

    test('CustomerListItem.toJson serializes Cust_AreaName, Cust_CityName, and Cust_StateName', () {
      final customer = CustomerListItem(
        custId: 401,
        custCode: 'CUST-401',
        custName: 'Priya Verma',
        custMobileNo: '9900000004',
        custAreaName: 'Bandra West',
        custCityName: 'Mumbai',
        custStateName: 'Maharashtra',
      );

      final json = customer.toJson();

      expect(json['Cust_AreaName'], 'Bandra West');
      expect(json['cust_AreaName'], 'Bandra West');
      expect(json['Cust_CityName'], 'Mumbai');
      expect(json['cust_CityName'], 'Mumbai');
      expect(json['Cust_StateName'], 'Maharashtra');
      expect(json['cust_StateName'], 'Maharashtra');
    });

    test('CustomerListItem.copyWith preserves and updates Cust_AreaName, Cust_CityName, Cust_StateName', () {
      final customer = CustomerListItem(
        custId: 501,
        custCode: 'CUST-501',
        custName: 'Vijay Kumar',
        custMobileNo: '9900000005',
        custAreaName: 'Indiranagar',
        custCityName: 'Bengaluru',
        custStateName: 'Karnataka',
      );

      final updated = customer.copyWith(
        custAreaName: 'Whitefield',
        custCityName: 'Bengaluru',
        custStateName: 'Karnataka',
      );

      expect(updated.custAreaName, 'Whitefield');
      expect(updated.custArea, 'Whitefield');
      expect(updated.custCityName, 'Bengaluru');
      expect(updated.custStateName, 'Karnataka');
    });
  });
}
