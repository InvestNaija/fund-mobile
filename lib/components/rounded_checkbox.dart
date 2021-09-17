import 'package:flutter/material.dart';
import 'package:invest_naija/constants.dart';

class RoundedCheckBox extends StatelessWidget {
  final String name;
  final bool selected;
  final ValueChanged<bool> onChanged;
  const RoundedCheckBox({Key key, this.name, this.onChanged, this.selected = false}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: Checkbox(
            value: selected,
            onChanged:onChanged,
            shape: CircleBorder(), fillColor: MaterialStateProperty.all(Constants.primaryColor),),
        ),
        SizedBox(width: 10,),
        Expanded(child: Text(this.name,  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Constants.blackColor),))
      ],);
  }
}