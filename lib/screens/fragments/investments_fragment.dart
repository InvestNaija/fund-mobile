import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:invest_naija/business_logic/providers/assets_provider.dart';
import 'package:invest_naija/components/investment_product_card.dart';
import 'package:invest_naija/constants.dart';
import 'package:provider/provider.dart';

class InvestmentsFragment extends StatefulWidget {
  @override
  _InvestmentsFragmentState createState() => _InvestmentsFragmentState();
}

class _InvestmentsFragmentState extends State<InvestmentsFragment> {

  @override
  void initState() {
    Provider.of<AssetsProvider>(context, listen: false).getEIpoAssets();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30,),
          const Text("Investments", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Constants.blackColor),),
          const SizedBox(height: 5,),
          const Text(
            "Choose from any of our investments to maximize your earnings and secure your future",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Constants.neutralColor),),
          const SizedBox(height: 30,),
          Expanded(
            child: ListView(
              children: [
                Row(
                  children: [
                    SvgPicture.asset("assets/images/explore.svg"),
                    const SizedBox(width: 10,),
                    const Text("Explore Bonds", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Constants.blackColor),),
                  ],
                ),
                const SizedBox(height: 10,),
                Consumer<AssetsProvider>(
                  builder: (context, assetsProvider, child) {
                    var bonds = assetsProvider.eIpoAssets.where((asset) => asset.type == 'bond').toList();
                    return GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 4.0,
                          maxCrossAxisExtent: 200,
                        ),
                        itemCount: assetsProvider.isLoadingEIpoAssets ? 5 : bonds.length,
                        itemBuilder: (context, index) {
                          return assetsProvider.isLoadingEIpoAssets? LoadingInvestmentProductCard() :
                          InvestmentProductCard(
                            asset: bonds[index],
                            onTap: ()=> Navigator.pushNamed(context, '/bond-detail', arguments: bonds[index]),
                          );
                        });
                  },
                ),
                const SizedBox(height: 25,),
                Row(
                  children: [
                    SvgPicture.asset("assets/images/explore.svg"),
                    const SizedBox(width: 10,),
                    const Text("Explore Funds", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Constants.blackColor),),
                  ],
                ),
                const SizedBox(height: 10,),
                Consumer<AssetsProvider>(
                  builder: (context, assetsProvider, child) {
                    var funds = assetsProvider.eIpoAssets.where((asset) => asset.type == 'fund').toList();
                    return GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 4.0,
                          maxCrossAxisExtent: 200,
                        ),
                        itemCount: assetsProvider.isLoadingEIpoAssets ? 5 : funds.length,
                        itemBuilder: (context, index) {
                          return assetsProvider.isLoadingEIpoAssets? LoadingInvestmentProductCard() :
                          InvestmentProductCard(
                            asset: funds[index],
                            onTap: ()=> Navigator.pushNamed(context, '/fund-detail', arguments: funds[index]),
                          );
                        });
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
