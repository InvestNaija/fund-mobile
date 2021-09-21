import 'package:flutter/foundation.dart';
import 'package:chd_funds/business_logic/data/response/transaction_list_response_model.dart';
import 'package:chd_funds/business_logic/data/response/transaction_response_model.dart';
import 'package:chd_funds/business_logic/repository/transactions_repository.dart';

class TransactionProvider extends ChangeNotifier{
  bool loading = true;
  Map<String, double> portfolioAmount = Map();

  bool loadingRecentTransaction = true;
  List<TransactionResponseModel> recentTransactions = [];
  List<TransactionResponseModel> transactions = [];
  List<TransactionResponseModel> reservoir = [];

  Future<bool> refreshTransactions() async{
    loadingRecentTransaction = true;
    notifyListeners();
    getRecentTransactions();
    return true;
  }

  void filterTransactionByStatus(String status){
      if(status.isEmpty || status.toLowerCase() == 'all'){
        transactions = reservoir;
      }else {
        transactions = reservoir.where((trnx) => trnx.status == status.toLowerCase()).toList();
      }
      notifyListeners();
  }

  void refreshRecentTransactions() async{
    loadingRecentTransaction = true;
    notifyListeners();
    getRecentTransactions();
  }

  void getRecentTransactions() async{
    TransactionListResponseModel transactionsResponse = await TransactionRepository().getTransactions();
    if(transactionsResponse.error == null){
      var tempTransactions = transactionsResponse.data.where((element) => element.asset.type != 'ipo').toList();
      recentTransactions = tempTransactions.getRange(0,5).toList();
      transactions = tempTransactions;
      reservoir = tempTransactions;
      calculateCumulativeEIpoInvestmentAmount(transactionsResponse.data);
    }
    loadingRecentTransaction = false;
    notifyListeners();
  }

  void calculateCumulativeEIpoInvestmentAmount(List<TransactionResponseModel> transactions){
     Map<String, double> currencyValue = Map();
     for(TransactionResponseModel transaction in transactions){
       String currency = transaction.asset.currency;
       if(!currencyValue.containsKey(currency)){
          currencyValue[currency] = transaction.amount;
       }else{
         currencyValue[currency] = transaction.amount + currencyValue[currency];
       }
     }
     portfolioAmount = currencyValue;
  }
}