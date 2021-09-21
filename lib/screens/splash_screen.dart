import 'package:flutter/material.dart';
import 'package:chd_funds/business_logic/repository/local/local_storage.dart';
import 'package:chd_funds/constants.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_){
      Navigator.of(context).pushNamed(appLocalStorage.getLoggedInStatus() ?? false ? '/dashboard' : '/on-boarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.whiteColor,
    );
  }
}
