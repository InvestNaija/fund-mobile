import 'package:chd_funds/business_logic/data/response/customer_response_model.dart';

abstract class LocalStorageRepository{
  Future<bool> saveToken(String token);
  String getToken();
  Future<bool> saveCustomer(CustomerResponseModel customer);
  Future<bool> setLoggedInStatus(bool isLoggedIn);
  bool getLoggedInStatus();
  Future<bool> setHideBalance(bool shouldHide);
  bool getHideBalance();
  Future<bool> clear();
  CustomerResponseModel getCustomer();
}