import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../premium_ui.dart';

class LensAssistantScreen extends StatefulWidget {
  const LensAssistantScreen({super.key});

  @override
  State<LensAssistantScreen> createState() => _LensAssistantScreenState();
}

class _LensAssistantScreenState extends State<LensAssistantScreen> {
  String evidence = 'Impronta';
  String size = 'Media';
  String shape = 'Non so';
  String habitat = 'Bosco';
  String? photo;

  static const evidenceTypes = ['Impronta', 'Fatta', 'Penna', 'Pelo', 'Sfregamento / segno'];
  static const sizes = ['Piccola', 'Media', 'Grande'];
  static const habitats = ['Bosco', 'Prato / radura', 'Montagna', 'Acqua / zona umida', 'Agricolo'];

  List<String> get shapes => switch (evidence) {
    'Impronta' => ['Non so', 'Zoccolo diviso', '4 dita', '5 dita', 'Uccello'],
    'Fatta' => ['Non so', 'Palline', 'Cilindrica', 'Ammasso', 'Con peli / semi'],
    'Penna' => ['Non so', 'Chiara', 'Scura', 'Barrata / maculata', 'Molto grande'],
    'Pelo' => ['Non so', 'Corto', 'Lungo', 'Lanoso', 'Rigido / setola'],
    _ => ['Non so', 'Corteccia graffiata', 'Fango / sfregamento', 'Palco / corna', 'Scavo'],
  };

  Future<void> _pick(ImageSource source) async {
    final f = await ImagePicker().pickImage(source: source, maxWidth: 1800, imageQuality: 90);
    if (f != null && mounted) setState(() => photo = f.path);
  }

  List<_Candidate> _candidates() {
    final rows = <_Candidate>[];
    void add(String name, int score, String why) => rows.add(_Candidate(name, score.clamp(1, 99), why));

    if (evidence == 'Impronta') {
      if (shape == 'Zoccolo diviso') {
        add('Cervo', size == 'Grande' ? 88 : 72, 'Zoccolo diviso; dimensione e habitat compatibili.');
        add('Capriolo', size == 'Piccola' || size == 'Media' ? 84 : 55, 'Zoccolo più piccolo e appuntito.');
        add('Cinghiale', size == 'Media' || size == 'Grande' ? 76 : 50, 'Zoccolo diviso più tondeggiante, spesso con speroni visibili.');
        if (habitat == 'Montagna') add('Camoscio', 72, 'Zoccolo compatto e contesto montano compatibile.');
      } else if (shape == '4 dita') {
        add('Lupo', size == 'Grande' ? 82 : 67, 'Quattro dita, cuscinetto canide e passo generalmente diretto.');
        add('Volpe', size == 'Piccola' || size == 'Media' ? 80 : 48, 'Impronta canide più piccola e stretta.');
      } else if (shape == '5 dita') {
        add('Orso bruno', size == 'Grande' ? 90 : 55, 'Cinque dita e dimensione elevata.');
        add('Tasso', size == 'Media' ? 77 : 58, 'Cinque dita con unghie spesso evidenti.');
        add('Martora / faina', size == 'Piccola' ? 74 : 48, 'Cinque dita, impronta più piccola e compatta.');
      } else if (shape == 'Uccello') {
        add('Airone cenerino', size == 'Grande' && habitat == 'Acqua / zona umida' ? 86 : 58, 'Dita molto lunghe e habitat umido.');
        add('Rapace', size == 'Media' || size == 'Grande' ? 62 : 45, 'Impronta tridattila con artigli marcati.');
      }
    } else if (evidence == 'Fatta') {
      if (shape == 'Palline') {
        add('Cervo', size != 'Piccola' ? 82 : 65, 'Palline ovali, spesso raccolte in gruppi.');
        add('Capriolo', size == 'Piccola' ? 80 : 60, 'Palline più piccole e appuntite.');
        if (habitat == 'Montagna') add('Camoscio', 70, 'Deposizioni a palline compatibili con ungulati montani.');
      } else if (shape == 'Cilindrica' || shape == 'Con peli / semi') {
        add('Volpe', size != 'Grande' ? 73 : 48, 'Forma allungata, spesso con peli, semi o resti alimentari.');
        add('Lupo', size == 'Grande' ? 78 : 60, 'Forma cilindrica e dimensioni maggiori, spesso con peli.');
      } else if (shape == 'Ammasso') {
        add('Cinghiale', 66, 'Deposizioni variabili in ammassi, da confrontare con contesto e dimensione.');
      }
    } else if (evidence == 'Pelo') {
      if (shape == 'Rigido / setola') add('Cinghiale', 84, 'Setole rigide e scure sono un indizio caratteristico.');
      if (shape == 'Lanoso') { add('Cervo', 65, 'Sottopelo e peli stagionali possono apparire lanosi.'); add('Camoscio', habitat == 'Montagna' ? 73 : 55, 'Pelo fitto compatibile con ambiente montano.'); }
      if (shape == 'Lungo') { add('Volpe', 62, 'Peli di guardia lunghi e morbidi.'); add('Lupo', 61, 'Peli di guardia lunghi; serve confronto microscopico per certezza.'); }
    } else if (evidence == 'Sfregamento / segno') {
      if (shape == 'Corteccia graffiata' || shape == 'Palco / corna') {
        add('Cervo', 81, 'Sfregamenti su tronchi e arbusti sono frequenti nel periodo riproduttivo.');
        add('Capriolo', size != 'Grande' ? 72 : 50, 'Sfregamenti più bassi e su fusti sottili.');
      }
      if (shape == 'Fango / sfregamento') add('Cinghiale', 78, 'Insogli e sfregamenti fangosi su tronchi sono tipici.');
      if (shape == 'Scavo') { add('Cinghiale', 76, 'Grufolate diffuse nel terreno.'); add('Tasso', 58, 'Scavi localizzati e latrine possono essere compatibili.'); }
    } else if (evidence == 'Penna') {
      add('Rapace / altro uccello', shape == 'Molto grande' ? 70 : 55, 'La sola descrizione non basta per una specie affidabile; servono forma, rachide, pattern e misura.');
      if (shape == 'Barrata / maculata') add('Gufo / rapace notturno', 58, 'Pattern barrato compatibile, ma non diagnostico da solo.');
    }

    if (rows.isEmpty) {
      add('Identificazione incerta', 35, 'Servono più dettagli: fotografia con scala, forma completa e contesto ambientale.');
      add('Confronto manuale necessario', 25, 'Usa la scheda specie e confronta più segni, non un solo indizio.');
    }
    rows.sort((a, b) => b.score.compareTo(a.score));
    return rows.take(4).toList();
  }

  Future<void> _showResults() async {
    final rows = _candidates();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: WildColors.ivory,
      builder: (sheet) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          minChildSize: .45,
          maxChildSize: .9,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const Text('Possibili corrispondenze', style: WildText.h1),
              const SizedBox(height: 5),
              const Text('Confidenza euristica basata sui criteri inseriti. Non è una conferma scientifica della specie.', style: TextStyle(color: WildColors.muted, height: 1.3)),
              const SizedBox(height: 14),
              for (final r in rows) Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  WildAnimalIllustration(r.name, size: 62),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(r.name, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800))), Text('${r.score}%', style: const TextStyle(fontWeight: FontWeight.w900, color: WildColors.forest))]),
                    const SizedBox(height: 5),
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: r.score / 100, minHeight: 7, color: WildColors.forest, backgroundColor: WildColors.sageSoft)),
                    const SizedBox(height: 6),
                    Text(r.why, style: const TextStyle(fontSize: 10.5, color: WildColors.muted, height: 1.3)),
                  ])),
                ]),
              ),
              const SizedBox(height: 5),
              const Text('Per specie sensibili o dubbi importanti, confronta più segni e affidati a una guida naturalistica o a personale qualificato.', style: TextStyle(fontSize: 10, color: WildColors.muted)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    appBar: AppBar(title: const Text('WildTrack Lens')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: WildColors.forest, borderRadius: BorderRadius.circular(26)),
          child: const Row(children: [
            WildIconDisc(Icons.auto_awesome_outlined, size: 56, background: Color(0x22FFFFFF), foreground: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Assistente tracce', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Combina foto e caratteristiche osservate per restringere le alternative senza inventare una certezza.', style: TextStyle(color: Color(0xFFD9E6DC), fontSize: 11, height: 1.3)),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        if (photo != null) ...[
          ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.file(File(photo!), height: 210, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 8),
        ],
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(photo == null ? 'Scatta foto' : 'Nuova foto'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galleria'))),
        ]),
        const SizedBox(height: 14),
        _Choice(label: 'Tipo di segno', value: evidence, values: evidenceTypes, onChanged: (v) => setState(() { evidence = v; shape = 'Non so'; })),
        const SizedBox(height: 9),
        _Choice(label: 'Dimensione indicativa', value: size, values: sizes, onChanged: (v) => setState(() => size = v)),
        const SizedBox(height: 9),
        _Choice(label: 'Caratteristica', value: shape, values: shapes, onChanged: (v) => setState(() => shape = v)),
        const SizedBox(height: 9),
        _Choice(label: 'Ambiente', value: habitat, values: habitats, onChanged: (v) => setState(() => habitat = v)),
        const SizedBox(height: 16),
        WildPrimaryButton(label: 'Analizza gli indizi', icon: Icons.manage_search, onPressed: _showResults),
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.value, required this.values, required this.onChanged});
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: values.contains(value) ? value : values.first,
    decoration: InputDecoration(labelText: label),
    items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
    onChanged: (v) { if (v != null) onChanged(v); },
  );
}

class _Candidate {
  const _Candidate(this.name, this.score, this.why);
  final String name;
  final int score;
  final String why;
}
