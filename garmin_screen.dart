import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../premium_ui.dart';

class GarminScreen extends StatelessWidget {
  const GarminScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:WildColors.ivory,
    appBar:AppBar(title:const Text('Garmin Connect')),body:ListView(padding:const EdgeInsets.all(24),children:[
      const Icon(Icons.watch_outlined,size:64,color:WildColors.forest),const SizedBox(height:20),
      const Text('Le tue uscite, collegate',style:WildText.h1),const SizedBox(height:15),
      const Text('Il collegamento automatico dell’account sarà disponibile dopo l’attivazione dell’integrazione ufficiale Garmin per WildTrack.',style:TextStyle(height:1.5)),
      const SizedBox(height:16),
      const ListTile(leading:Icon(Icons.hourglass_top),title:Text('Account non collegato'),subtitle:Text('Integrazione in attesa di attivazione')),
      const SizedBox(height:16),
      OutlinedButton.icon(onPressed:()=>launchUrl(Uri.parse('https://connect.garmin.com/'),mode:LaunchMode.externalApplication),icon:const Icon(Icons.open_in_new),label:const Text('Apri Garmin Connect')),
    ]));
}
