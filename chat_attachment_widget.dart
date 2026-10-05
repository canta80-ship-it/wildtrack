import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/community_service.dart';
import '../services/media_storage_service.dart';
class ChatAttachment extends StatefulWidget {
  const ChatAttachment({super.key, required this.id, required this.metadata});
  final String id;
  final Map<String,dynamic> metadata;
  @override State<ChatAttachment> createState() => _ChatAttachmentState();
}
class _ChatAttachmentState extends State<ChatAttachment> {
  Uint8List? bytes; String? error; bool busy=false;
  bool get image => (widget.metadata['mime'] as String? ?? '').startsWith('image/');
  @override void initState(){super.initState(); if(image) load();}
  Future<void> load() async {
    if(busy || bytes != null) return;
    setState(() {busy=true; error=null;});
    try {final data=await CommunityService.instance.api('messages?attachment=${Uri.encodeComponent(widget.id)}'); if(mounted) setState(() => bytes=base64Decode(data['data'] as String));}
    catch(_){if(mounted) setState(() => error='Allegato non disponibile. Tocca per riprovare.');}
    finally{if(mounted) setState(() => busy=false);}
  }
  Future<void> open() async {
    await load(); if(bytes==null || !mounted) return;
    try {
      final dir=await MediaStorageService.instance.mediaDirectory;
      final name=(widget.metadata['name'] as String? ?? 'allegato').replaceAll(RegExp(r'[/\\\x00-\x1f]'),'_');
      final file=File('${dir.path}/${widget.id}_$name'); await file.writeAsBytes(bytes!);
      await SharePlus.instance.share(ShareParams(files:[XFile(file.path, name:name)], text:name));
    }catch(e){if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}
  }
  @override Widget build(BuildContext context) => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(image && bytes!=null) GestureDetector(onTap:()=>showDialog<void>(context:context,builder:(_)=>Dialog(child:InteractiveViewer(child:Image.memory(bytes!)))), child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.memory(bytes!,width:260,height:200,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Text('Foto non leggibile')))),
    TextButton.icon(style:TextButton.styleFrom(foregroundColor:const Color(0xff183b29)),onPressed:busy?null:open,icon:Icon(image?Icons.photo_outlined:Icons.attach_file),label:Text(busy?'Caricamento…':(widget.metadata['name'] as String? ?? 'Apri allegato'), maxLines:2,overflow:TextOverflow.ellipsis)),
    if(error!=null) Text(error!,style:const TextStyle(fontSize:12)),
  ]);
}
