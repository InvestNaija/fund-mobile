import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invest_naija/business_logic/data/response/shares_response_model.dart';
import 'package:invest_naija/business_logic/providers/assets_provider.dart';
import 'package:invest_naija/business_logic/providers/customer_provider.dart';
import 'package:invest_naija/business_logic/providers/payment_provider.dart';
import 'package:invest_naija/components/custom_button.dart';
import 'package:invest_naija/components/custom_lead_icon.dart';
import 'package:invest_naija/components/custom_textfield.dart';
import 'package:invest_naija/mixins/application_mixin.dart';
import 'package:invest_naija/mixins/dialog_mixin.dart';
import 'package:provider/provider.dart';
import '../constants.dart';

class PurchaseBondScreen extends StatefulWidget {

  final SharesResponseModel asset;

  const PurchaseBondScreen({Key key, this.asset}) : super(key: key);

  @override
  _PurchaseBondScreenState createState() => _PurchaseBondScreenState();
}

class _PurchaseBondScreenState extends State<PurchaseBondScreen> with DialogMixins, ApplicationMixin{
  TextEditingController amountController = TextEditingController();

  GlobalKey<FormState> formKey;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    Provider.of<CustomerProvider>(context, listen: false).getCustomerDetailsSilently();
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: Platform.localeName, name: widget.asset.currency);
    String minAmount = formatCurrency.format(widget.asset.anticipatedMinPrice);
    String sharePrice = widget.asset.sharePrice == 0 ? 'Pending Price Discovery' : '${formatCurrency.format(widget.asset.sharePrice)}';
    print(sharePrice);

    return Scaffold(
      backgroundColor: Constants.dashboardBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 60),
        child: Transform.translate(
          offset: Offset(0, 20),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Row(
              children: [
                const SizedBox(width: 25,),
                Image.network(widget.asset.image, width: 24, height: 24,),
                const SizedBox(width: 13,),
                Text(widget.asset.name ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Constants.blackColor),),
              ],
            ),
            leading: Transform.translate(offset: Offset(22,0), child: CustomLeadIcon(),),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 50,),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: const Text("Enter your transaction details",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Constants.blackColor)),
                ),
                const SizedBox(height: 35,),
                CustomTextField(
                  readOnly: true,
                  label: "Offering Type",
                  controller: TextEditingController(text: widget.asset.type.toUpperCase()),
                ),
                const SizedBox(height: 25,),
                CustomTextField(
                  readOnly: false,
                  label: "Estimated Amount",
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  onChange: (value){},
                ),
                const SizedBox(height: 25,),
                Divider(),
                const Align(
                  alignment: Alignment.centerRight,
                  child: const Text("Total",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Constants.gray7Color)),
                ),
                ValueListenableBuilder<TextEditingValue>(
                    valueListenable: amountController,
                    builder: (context, value, child){
                      var text = '';
                      try{
                        text = formatCurrency.format(double.parse(value.text.isEmpty? 0 : value.text));
                      }catch(ex){
                        text = formatCurrency.format(0);
                      }
                      print(text);
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Text(text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Constants.blackColor)),
                      );
                    },
                ),
                Divider(),
                const SizedBox(height: 40,),
                Consumer3<AssetsProvider, CustomerProvider, PaymentProvider>(
                  builder: (context, assetsProvider, customerProvider, paymentProvider, child) {
                    return CustomButton(
                      data: "Proceed to make payment",
                      isLoading: assetsProvider.isMakingReservation || paymentProvider.isFetchingPaymentLink,
                      textColor: Constants.whiteColor,
                      color: Constants.primaryColor,
                      onPressed: () async{
                        if(!formKey.currentState.validate()) return;

                        bool hasCscs = await customerProvider.hasCscs();
                        if(!hasCscs){
                          showCscsDialog();
                          return;
                        }
                        bool hasNuban = await customerProvider.hasNuban();
                        if(!hasNuban){
                          showBankDetailDialog();
                          return;
                        }
                        String assetId = widget.asset.id;
                        double amount = double.parse(amountController.text);
                        var expressInterestResponse = await assetsProvider.payNow(assetId : assetId, units : 99, amount: amount);
                        if(expressInterestResponse.error != null){
                          showSnackBar('Unable to express interest', expressInterestResponse.error.message);
                          return;
                        }
                        var response = await paymentProvider.getPaymentUrl(reservationId: expressInterestResponse.data.reservation.id, gateway: 'flutterwave');
                        if(response.error != null){
                          showSnackBar('Payment Error', response.error.message);
                          return;
                        }
                        Navigator.pushNamed(context, '/payment-web', arguments: response.data.authorizationUrl);
                      },
                    );
                  },
                ),
                const SizedBox(height: 20,),
                CustomButton(
                  data: "Pay directly to bank",
                  textColor: Constants.whiteColor,
                  color: Constants.innerBorderColor,
                  onPressed: () async{},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showCreateCscsModal(){
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('A CSCS account number would be created for you', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Your CSCS number is mandatory/required to complete your application', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Proceed', style: TextStyle(color: Constants.blackColor),),
              onPressed: () {
                Navigator.popAndPushNamed(context, '/create-cscs', arguments: true);
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Constants.yellowColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showCscsDialog(){
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cscs Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('To make payment for this asset, you should have a CSCS Number. Do you have a CSCS Number?', style: TextStyle(fontSize: 14,)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Constants.blackColor),),
              onPressed: () {
                Navigator.popAndPushNamed(context, '/enter-cscs', arguments: true);
              },
            ),
            TextButton(
              child: const Text('No, I don\'t', style: TextStyle(color: Constants.yellowColor)),
              onPressed: () {
                Navigator.of(context).pop();
                showCreateCscsModal();
              },
            ),
          ],
        );
      },
    );
  }

  void showBankDetailDialog(){
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bank Information'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Please update your Bank detail to continue'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Update Bank Detail', style: TextStyle(color: Constants.blackColor),),
              onPressed: () {
                Navigator.popAndPushNamed(context, '/enter-bank-detail', arguments: true);
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Constants.blackColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void showSnackBar(String title, String msg){
    final snackBar = SnackBar(
      content: Container(
        height: 70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),),
            SizedBox(height: 15,),
            Text(msg),
          ],
        ),
      ),);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
