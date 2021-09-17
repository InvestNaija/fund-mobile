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
import 'package:invest_naija/components/rounded_checkbox.dart';
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
  bool reinvest = true;
  TextEditingController amountController;
  GlobalKey<FormState> formKey;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
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
                        String assetId = widget.asset.id;
                        double amount = double.parse(amountController.text);
                        var expressInterestResponse = await assetsProvider.payNow(assetId : assetId, units : 99, amount: amount);
                        if(expressInterestResponse.error != null){
                          showSnackBar(context, 'Unable to express interest', expressInterestResponse.error.message);
                          return;
                        }
                        var response = await paymentProvider.getPaymentUrl(reservationId: expressInterestResponse.data.reservation.id, gateway: 'flutterwave');
                        if(response.error != null){
                          showSnackBar(context, 'Payment Error', response.error.message);
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
                  onPressed: () async{
                    showDirectDepositDialog(
                        context: context,
                        title: 'Make payment with direct deposits',
                        onClose: (){
                          //changePage(context,2);
                          //Navigator.pushNamed(context,'/dashboard');
                        }
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
}
