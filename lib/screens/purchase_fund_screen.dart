import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invest_naija/business_logic/data/response/express_interest_response_model.dart';
import 'package:invest_naija/business_logic/data/response/payment_url_response.dart';
import 'package:invest_naija/business_logic/data/response/shares_response_model.dart';
import 'package:invest_naija/business_logic/providers/assets_provider.dart';
import 'package:invest_naija/business_logic/providers/customer_provider.dart';
import 'package:invest_naija/business_logic/providers/payment_provider.dart';
import 'package:invest_naija/components/custom_button.dart';
import 'package:invest_naija/components/custom_lead_icon.dart';
import 'package:invest_naija/components/custom_textfield.dart';
import 'package:invest_naija/components/filter_checkbox.dart';
import 'package:invest_naija/components/rounded_checkbox.dart';
import 'package:invest_naija/mixins/application_mixin.dart';
import 'package:invest_naija/mixins/dialog_mixin.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import 'payment_web_screen.dart';

class PurchaseFundScreen extends StatefulWidget {

  final SharesResponseModel asset;

  const PurchaseFundScreen({Key key, this.asset}) : super(key: key);

  @override
  _PurchaseFundScreenState createState() => _PurchaseFundScreenState();
}

class _PurchaseFundScreenState extends State<PurchaseFundScreen> with DialogMixins, ApplicationMixin{
  TextEditingController unitQuantityTextEditingController = TextEditingController();
  TextEditingController estimatedAmountTextEditingController = TextEditingController();

  bool makeSpecifiedUnitReadOnly = false;
  bool makeEstimatedAmountReadOnly = false;
  bool reinvest = true;
  GlobalKey<FormState> formKey;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    makeSpecifiedUnitReadOnly = widget.asset.sharePrice == 0;
    makeEstimatedAmountReadOnly = widget.asset.sharePrice != 0;
    unitQuantityTextEditingController.text = '0' ;
    Provider.of<CustomerProvider>(context, listen: false).getCustomerDetailsSilently();
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 20,),
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
                  controller: TextEditingController(text: widget.asset.type == 'ipo' ? 'Public offer' : widget.asset.type),
                ),
                const  SizedBox(height: 25,),
                CustomTextField(
                  readOnly: true,
                  label: "Purchase Price",
                  controller: TextEditingController(text: widget.asset.sharePrice == 0 ? 'Pending price discovery' : widget.asset.sharePrice.toString()),
                ),
                const SizedBox(height: 25,),
                CustomTextField(
                  readOnly: makeSpecifiedUnitReadOnly,
                  label: "Specified Units",
                  controller: unitQuantityTextEditingController,
                  keyboardType : TextInputType.number,
                  onChange: (value){
                      var digit = value.isEmpty ? 0 : int.parse(value);
                      estimatedAmountTextEditingController.text = (digit * widget.asset.sharePrice).toString();
                  },
                ),
                const SizedBox(height: 25,),
                CustomTextField(
                  readOnly: makeEstimatedAmountReadOnly,
                  label: "Estimated Amount",
                  controller: estimatedAmountTextEditingController,
                  keyboardType: TextInputType.number,
                  onChange: (value){
                     if(widget.asset.sharePrice != 0.0){
                       var digit = int.parse(value);
                       var digitTwo = int.parse(unitQuantityTextEditingController.text);
                       unitQuantityTextEditingController.text = (digit * digitTwo).toString();
                     }
                  },
                ),
                const SizedBox(height: 20,),
                RoundedCheckBox(
                  name: 'Scrip (Reinvest your dividends/distributions and compound your returns)',
                  selected: reinvest,
                  onChanged: (value){
                    setState(()=> reinvest = true);
                  },
                ),
                const SizedBox(height: 10,),
                RoundedCheckBox(
                  name: 'Cash distribution (Collect your dividend)',
                  selected: !reinvest,
                  onChanged: (value){
                    setState(()=> reinvest = false);
                  },
                ),
                const SizedBox(height: 20,),
                Consumer3<AssetsProvider, CustomerProvider, PaymentProvider>(
                  builder: (context, assetsProvider, customerProvider, paymentProvider, child) {
                    return CustomButton(
                      data: "Proceed to make payment",
                      isLoading: assetsProvider.isMakingReservation || paymentProvider.isFetchingPaymentLink,
                      textColor: Constants.whiteColor,
                      color: Constants.primaryColor,
                      onPressed: () async{
                        if(!formKey.currentState.validate()) return;
                        int unit = int.parse(unitQuantityTextEditingController.text);
                        double amount = double.parse(estimatedAmountTextEditingController.text);
                        var expressInterestResponse = await assetsProvider.payNow(assetId : widget.asset.id, units : unit, amount: amount, reinvest: reinvest);
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
                Consumer<AssetsProvider>(
                  builder: (context, assetsProvider, child) {
                    return CustomButton(
                      data: "Pay directly to bank",
                      isLoading: assetsProvider.isSavingReservation,
                      textColor: Constants.whiteColor,
                      color: Constants.innerBorderColor,
                      onPressed: () async{
                        if(!formKey.currentState.validate()){
                          return;
                        }
                        showDirectDepositDialog(
                            context: context,
                            title: 'Make payment with direct deposits',
                            onClose: (){
                              //changePage(context,2);
                              //Navigator.pushNamed(context,'/dashboard');
                            }
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('it is at dispose');
    super.dispose();
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
