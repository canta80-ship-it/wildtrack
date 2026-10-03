import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../services/wildtrack_intelligence_service.dart';
import '../premium_ui.dart';

class CameraAssistantCard extends StatelessWidget {
  const CameraAssistantCard({super.key, required this.snapshot});
  final IntelligenceSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final p = PreferencesService.instance;
    final target = snapshot?.species.firstOrNull;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CameraAssistantScreen(snapshot: snapshot),
        ),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2E8D7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const WildIconDisc(
              Icons.camera_alt_outlined,
              size: 52,
              background: WildColors.earth,
              foreground: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.cameraLabel.isEmpty
                        ? 'Assistente fotocamera'
                        : p.cameraLabel,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${p.cameraMode} · ${p.cameraShutter} · ${p.cameraAperture} · ${p.cameraFocus}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: WildColors.muted,
                    ),
                  ),
                  if (target != null)
                    Text(
                      'Suggerimenti contestuali: ${target.name} · condizioni ${target.conditions.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: WildColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.tune, color: WildColors.forest),
          ],
        ),
      ),
    );
  }
}

class CameraAssistantScreen extends StatefulWidget {
  const CameraAssistantScreen({super.key, this.snapshot});
  final IntelligenceSnapshot? snapshot;

  @override
  State<CameraAssistantScreen> createState() => _CameraAssistantScreenState();
}

class _CameraAssistantScreenState extends State<CameraAssistantScreen> {
  late final TextEditingController label;
  late String mode;
  late String shutter;
  late String aperture;
  late bool autoIso;
  late int iso;
  late int maxIso;
  late String focus;
  late String afArea;
  late String subject;
  late String drive;
  late bool stabilization;
  late bool raw;
  late double focal;
  bool saving = false;

  static const modes = ['M', 'A / Av', 'S / Tv', 'P'];
  static const shutters = [
    '1/250',
    '1/500',
    '1/800',
    '1/1000',
    '1/1250',
    '1/1600',
    '1/2000',
    '1/2500',
    '1/3200',
  ];
  static const apertures = ['f/2.8', 'f/4', 'f/5.6', 'f/6.3', 'f/8', 'f/11'];
  static const focuses = ['AF-S', 'AF-C', 'MF'];
  static const afAreas = [
    'Ampia',
    'Zona',
    'Spot',
    'Tracking / Zona',
    'Tracking / Spot',
  ];
  static const subjects = [
    'Auto',
    'Animale / Uccello',
    'Animale',
    'Uccello',
    'Nessuno',
  ];
  static const drives = [
    'Singolo',
    'Raffica bassa',
    'Raffica media',
    'Raffica alta',
  ];
  static const isos = [100, 200, 400, 800, 1600, 3200, 6400, 12800];

  @override
  void initState() {
    super.initState();
    final p = PreferencesService.instance;
    label = TextEditingController(text: p.cameraLabel);
    mode = p.cameraMode;
    shutter = p.cameraShutter;
    aperture = p.cameraAperture;
    autoIso = p.cameraAutoIso;
    iso = p.cameraIso;
    maxIso = p.cameraAutoIsoMax;
    focus = p.cameraFocus;
    afArea = p.cameraAfArea;
    subject = p.cameraSubject;
    drive = p.cameraDrive;
    stabilization = p.cameraStabilization;
    raw = p.cameraRaw;
    focal = p.cameraFocalMm.toDouble().clamp(16, 800);
  }

  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  void _applySuggested() {
    final target = widget.snapshot?.species.firstOrNull;
    final name = target?.name.toLowerCase() ?? '';
    final bird = RegExp(
      r'poiana|aquila|falco|gufo|picchio|airone|germano|uccell',
    ).hasMatch(name);
    final fast = bird || RegExp(r'volpe|lupo|lepre').hasMatch(name);
    setState(() {
      mode = 'M';
      shutter = bird
          ? '1/2000'
          : fast
          ? '1/1600'
          : '1/1000';
      aperture = focal >= 250 ? 'f/6.3' : 'f/5.6';
      autoIso = true;
      maxIso = 6400;
      focus = 'AF-C';
      afArea = bird ? 'Tracking / Zona' : 'Tracking / Spot';
      subject = bird ? 'Uccello' : 'Animale';
      drive = fast ? 'Raffica alta' : 'Raffica media';
      stabilization = true;
      raw = true;
    });
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    final p = PreferencesService.instance;
    p.cameraLabel = label.text.trim();
    p.cameraMode = mode;
    p.cameraShutter = shutter;
    p.cameraAperture = aperture;
    p.cameraAutoIso = autoIso;
    p.cameraIso = iso;
    p.cameraAutoIsoMax = maxIso;
    p.cameraFocus = focus;
    p.cameraAfArea = afArea;
    p.cameraSubject = subject;
    p.cameraDrive = drive;
    p.cameraStabilization = stabilization;
    p.cameraRaw = raw;
    p.cameraFocalMm = focal.round();
    try {
      await p.save();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilo fotocamera salvato.')),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilo non salvato. Riprova.')),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.snapshot?.species.firstOrNull;
    return Scaffold(
      backgroundColor: WildColors.ivory,
      appBar: AppBar(title: const Text('Assistente fotocamera')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: WildPrimaryButton(
          label: saving ? 'Salvataggio…' : 'Salva profilo',
          icon: Icons.save_outlined,
          onPressed: saving ? null : _save,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: WildColors.forest,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                const WildIconDisc(
                  Icons.camera_alt_outlined,
                  size: 58,
                  background: Color(0x22FFFFFF),
                  foreground: Colors.white,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Controlli generici',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Funziona come guida con qualsiasi fotocamera. I nomi dei menu possono variare tra Sony, Canon, Nikon, Fujifilm, OM System, Panasonic e altri corpi.',
                        style: TextStyle(
                          color: Color(0xFFD9E6DC),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                      if (target != null) ...[
                        const SizedBox(height: 7),
                        Text(
                          'Specie suggerita: ${target.name} · condizioni ${target.conditions.toLowerCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Profilo opzionale',
            child: TextField(
              controller: label,
              decoration: const InputDecoration(
                labelText: 'Fotocamera / obiettivo',
                hintText: 'Es. mirrorless + 100–500 mm',
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Section(
            title: 'Esposizione',
            child: Column(
              children: [
                _Dropdown(
                  label: 'Modalità',
                  value: mode,
                  values: modes,
                  onChanged: (v) => setState(() => mode = v),
                ),
                const SizedBox(height: 9),
                _Dropdown(
                  label: 'Tempo',
                  value: shutter,
                  values: shutters,
                  onChanged: (v) => setState(() => shutter = v),
                ),
                const SizedBox(height: 9),
                _Dropdown(
                  label: 'Diaframma',
                  value: aperture,
                  values: apertures,
                  onChanged: (v) => setState(() => aperture = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: autoIso,
                  onChanged: (v) => setState(() => autoIso = v),
                  title: const Text(
                    'Auto ISO',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (autoIso)
                  _Dropdown(
                    label: 'ISO massimo',
                    value: '$maxIso',
                    values: isos.map((e) => '$e').toList(),
                    onChanged: (v) => setState(() => maxIso = int.parse(v)),
                  )
                else
                  _Dropdown(
                    label: 'ISO',
                    value: '$iso',
                    values: isos.map((e) => '$e').toList(),
                    onChanged: (v) => setState(() => iso = int.parse(v)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Section(
            title: 'Messa a fuoco',
            child: Column(
              children: [
                _Dropdown(
                  label: 'AF',
                  value: focus,
                  values: focuses,
                  onChanged: (v) => setState(() => focus = v),
                ),
                const SizedBox(height: 9),
                _Dropdown(
                  label: 'Area AF',
                  value: afArea,
                  values: afAreas,
                  onChanged: (v) => setState(() => afArea = v),
                ),
                const SizedBox(height: 9),
                _Dropdown(
                  label: 'Rilevamento soggetto',
                  value: subject,
                  values: subjects,
                  onChanged: (v) => setState(() => subject = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Section(
            title: 'Scatto e obiettivo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Dropdown(
                  label: 'Avanzamento',
                  value: drive,
                  values: drives,
                  onChanged: (v) => setState(() => drive = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Focale',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      '${focal.round()} mm',
                      style: const TextStyle(
                        color: WildColors.forest,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: focal,
                  min: 16,
                  max: 800,
                  divisions: 98,
                  onChanged: (v) => setState(() => focal = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: stabilization,
                  onChanged: (v) => setState(() => stabilization = v),
                  title: const Text(
                    'Stabilizzazione',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: raw,
                  onChanged: (v) => setState(() => raw = v),
                  title: const Text(
                    'RAW / RAW+JPEG',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (target != null)
            WildOutlineButton(
              label: 'Applica impostazioni suggerite per ${target.name}',
              icon: Icons.auto_awesome,
              onPressed: _applySuggested,
            ),
          const SizedBox(height: 10),
          const SizedBox(height: 12),
          const Text(
            'WildTrack modifica il proprio profilo di assistenza, non i comandi fisici della fotocamera. Il controllo remoto diretto richiederebbe protocolli specifici del produttore.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              color: WildColors.muted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: WildText.h2),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: values.contains(value) ? value : values.first,
    decoration: InputDecoration(labelText: label),
    items: values
        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

