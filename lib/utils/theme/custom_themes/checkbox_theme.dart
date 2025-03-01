import 'package:flutter/material.dart';

class wawuCheckBoxTheme{
  wawuCheckBoxTheme._();
  
  //customizable light checkbox theme
 static CheckboxThemeData lightCheckBoxTheme = CheckboxThemeData(
   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
   checkColor: WidgetStateProperty.resolveWith((states){
     if (states.contains(WidgetState.selected)){
       return Colors.white;
     }else{
       return Colors.black;
     }
   }),
   fillColor: WidgetStateProperty.resolveWith((states){
     if(states.contains(WidgetState.selected)){
       return Colors.blue;
     }else{
       return Colors.transparent;
     }
   }),
 );

}