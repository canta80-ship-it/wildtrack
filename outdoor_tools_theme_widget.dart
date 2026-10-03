import 'package:flutter/material.dart';
import '../premium_ui.dart';

/// Shares WildTrack's editorial palette and controls across the field tools.
class OutdoorToolsTheme extends StatelessWidget {
  const OutdoorToolsTheme({super.key,required this.child});
  final Widget child;
  @override Widget build(BuildContext context) {
    final base=Theme.of(context);
    return Theme(data:base.copyWith(
      scaffoldBackgroundColor:WildColors.ivory,
      colorScheme:base.colorScheme.copyWith(primary:WildColors.forest,secondary:WildColors.earth,surface:WildColors.ivory,onSurface:WildColors.ink),
      appBarTheme:const AppBarTheme(backgroundColor:WildColors.ivory,foregroundColor:WildColors.forest,elevation:0),
      cardTheme:CardThemeData(color:Colors.white,elevation:0,margin:const EdgeInsets.symmetric(vertical:5),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22),side:const BorderSide(color:WildColors.cream))),
      inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:16),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:const BorderSide(color:WildColors.sage)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:const BorderSide(color:WildColors.sage))),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:WildColors.forest,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(horizontal:18,vertical:16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)))),
      outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(foregroundColor:WildColors.forest,padding:const EdgeInsets.symmetric(horizontal:18,vertical:16),side:const BorderSide(color:WildColors.sage),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)))),
      progressIndicatorTheme:const ProgressIndicatorThemeData(color:WildColors.forest,linearTrackColor:WildColors.sage),
    ),child:child);
  }
}
