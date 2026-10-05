import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'preferences_service.dart';
import 'community_service.dart';

class NearbyGroupsService extends ChangeNotifier {
  static final instance = NearbyGroupsService();
  final List<Map<String, dynamic>> groups = [];
  bool loaded = false, syncing = false;
  Future<void> writes = Future.value();
  String get identity => sha256.convert(utf8.encode(PreferencesService.instance.token)).toString();
  File get file => File('${PreferencesService.instance.file.parent.path}/wildtrack_nearby_groups.json');
  Future<void> load() async {
    if (loaded) return;
    try { groups.addAll((jsonDecode(await file.readAsString()) as List).map((e) => Map<String,dynamic>.from(e as Map))); } catch (_) {}
    loaded = true;
  }
  Future<void> save() {
    final snapshot = jsonEncode(groups);
    final task = writes.then((_) async { final tmp = File('${file.path}.tmp'); await tmp.writeAsString(snapshot, flush:true); await tmp.rename(file.path); });
    writes = task.catchError((Object _) {});
    notifyListeners();
    return task;
  }
  Future<Map<String,dynamic>> create(String name) async {
    await load();
    if (name.trim().length < 2 || name.length > 60) throw const FormatException('Nome da 2 a 60 caratteri');
    final group = <String,dynamic>{'id': const Uuid().v4(), 'name': name.trim(), 'owner':identity, 'mine':1, 'members':<Map<String,dynamic>>[], 'synced':false};
    groups.add(group); await save(); return group;
  }
  Future<void> receive(Map<String,dynamic> group) async {
    await load();
    if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch('${group['id']}') || '${group['name']}'.length > 60 || !RegExp(r'^[a-f0-9]{64}$').hasMatch('${group['owner']}')) throw const FormatException('Invito non valido');
    if (!groups.any((g) => g['id'] == group['id'])) {
      groups.add({'id':group['id'], 'name':group['name'], 'owner':group['owner'], 'mine':0, 'synced':false});
      await save();
    }
  }
  Future<void> addMember(Map<String,dynamic> group, Map<String,dynamic> member) async {
    if (group['owner'] != identity) throw const FormatException('Gruppo non tuo');
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch('${member['id']}') || '${member['nickname']}'.isEmpty || '${member['nickname']}'.length > 40) throw const FormatException('Membro non valido');
    final members = group['members'] as List;
    if (members.length >= 30) throw const FormatException('Massimo 30 partecipanti');
    if (!members.any((m) => m['id'] == member['id'])) members.add(member);
    group['synced'] = false;
    await save();
  }
  Future<void> sync() async {
    await load(); if (syncing) return; syncing=true;
    try {
      for (final group in groups.where((g) => g['owner'] == identity && g['synced'] != true)) {
        await CommunityService.instance.api('maps', method:'POST',body:{'action':'offlineCreate','mapId':group['id'],'name':group['name'],'members':group['members']});
        group['synced'] = true; await save();
      }
    } finally { syncing=false; }
  }
}
