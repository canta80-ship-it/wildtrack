import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildtrack_mvp/services/did_you_know_service.dart';

void main() {
  test('Failed and hanging news sources do not discard a healthy source', () async {
    final item=DidYouKnowItem(id:'ok',category:'EVENTI',title:'Festival montagna',body:'',asset:'',source:'healthy',publishedAt:DateTime.now(),isLive:true);
    final rows=await DidYouKnowService.collectSources([
      () async => [item],
      () async => throw const SocketException('offline'),
      () => Completer<List<DidYouKnowItem>>().future,
    ],timeout:const Duration(milliseconds:20));
    expect(rows.expand((batch)=>batch).map((e)=>e.id),['ok']);
  });

  test('RSS sources parse titles, category context and publication dates independently', () {
    final service = DidYouKnowService();
    final items = service.parseRss('<rss><channel><item><guid>1</guid><title>Mostra fotografica delle Dolomiti</title><description>Incontro dedicato alla montagna</description><link>https://example.org/evento</link><pubDate>Tue, 06 Oct 2026 08:00:00 GMT</pubDate><category>Eventi</category></item></channel></rss>', 'test', 'Fonte test');
    expect(items.single.source,'Fonte test');
    expect(items.single.category,'EVENTI');
    expect(DidYouKnowService.mountainEvents(items),hasLength(1));
    expect(items.single.publishedAt,DateTime.utc(2026,10,6,8));
    expect(() => service.parseRss('not xml','broken','Fonte'),throwsA(isA<Exception>()));
  });

  test('Community events require both an event and a mountain topic', () {
    DidYouKnowItem item(String title, String body, {bool live = true}) =>
        DidYouKnowItem(id: title, category: 'FOTOGRAFIA', title: title,
            body: body, asset: '', source: 'test', publishedAt: DateTime.now(),
            isLive: live);
    final items = [
      item('Festival della montagna', 'Incontri con gli alpinisti'),
      item('Mostra fotografica', 'Paesaggi delle Dolomiti'),
      item('Raduno CAI', 'Escursioni e arrampicata'),
      item('Fiera della tecnologia', 'Nuove fotocamere'),
      item('Festival del cinema', 'Proiezioni in città'),
      item('Consigli per il trekking', 'Come scegliere lo zaino'),
      item('Evento montagna salvato', '', live: false),
    ];
    expect(DidYouKnowService.mountainEvents(items).map((e) => e.title), [
      'Festival della montagna', 'Mostra fotografica', 'Raduno CAI',
    ]);
  });
  test('Manual refresh bypasses fresh cache and failure preserves real last update', () async {
    final dir=await Directory.systemTemp.createTemp('wildtrack-feed-');
    addTearDown(() => dir.delete(recursive:true));
    final file=File('${dir.path}/feed.json');
    final now=DateTime.now();
    DidYouKnowItem item(String id, {bool live=true}) => DidYouKnowItem(id:id,category:'FAUNA',title:id,body:'text',asset:'',source:'test',publishedAt:now,isLive:live);
    await file.writeAsString(jsonEncode({'updatedAt':now.toIso8601String(),'items':[item('cached').toJson()]}));
    var calls=0, fail=false;
    final service=DidYouKnowService(cacheFile:file,clock:()=>now,newsLoader:() async { calls++; if(fail) throw const SocketException('offline'); return [item('new')]; });
    expect((await service.load()).items.first.id,'cached'); expect(calls,0);
    final fresh=await service.load(force:true); expect(fresh.items.first.id,'new'); expect(fresh.fromCache,false); expect(calls,1);
    fail=true;
    final offline=await service.load(force:true); expect(offline.items.any((e)=>e.id=='new'),true); expect(offline.fromCache,true); expect(offline.updatedAt,now); expect(offline.warning,isNotNull);
  });
  test('Guide rotation changes first saved card without fabricating or shuffling news', () {
    final now=DateTime.now();
    DidYouKnowItem item(String id,bool live) => DidYouKnowItem(id:id,category:'FAUNA',title:id,body:'text',asset:'',source:'test',publishedAt:now,isLive:live);
    final items=[item('news',true),item('a',false),item('b',false),item('c',false)];
    final rotated=DidYouKnowService.rotateGuides(items,1);
    expect(rotated.first.id,'news'); expect(rotated.where((e)=>!e.isLive).map((e)=>e.id),['b','c','a']);
    expect(rotated.map((e)=>e.id).toSet(),items.map((e)=>e.id).toSet()); expect(rotated.every((e)=>e.publishedAt==now),true);
  });
}
