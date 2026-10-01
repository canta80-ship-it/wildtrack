import 'package:flutter/material.dart';
import 'premium_ui.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key, required this.home, this.register = false});
  final Widget home;
  final bool register;

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  late bool register = widget.register;
  final identity = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;

  @override
  void dispose() {
    identity.dispose();
    password.dispose();
    super.dispose();
  }

  void unavailable() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: WildColors.ivory,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const WildLogo(compact: true),
          const SizedBox(height: 18),
          Text(register ? 'Registrazione sicura' : 'Accesso sicuro', style: WildText.h1),
          const SizedBox(height: 10),
          const Text('La schermata è già pronta, ma l’account reale e le passkey verranno attivati solo insieme al backend privacy-first. In questa preview non inviamo credenziali a nessun server.'),
          const SizedBox(height: 18),
          WildPrimaryButton(label: 'Continua come ospite', icon: Icons.arrow_forward, onPressed: () {
            Navigator.pop(context);
            Navigator.of(this.context).pushReplacement(MaterialPageRoute<void>(builder: (_) => widget.home));
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WildColors.ivory,
    body: SafeArea(
      child: ListView(children: [
        SizedBox(
          height: 285,
          child: Stack(fit: StackFit.expand, children: [
            const WildLandscape(height: 285),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: .03), Colors.transparent, WildColors.ivory]))),
            const Positioned(top: 32, left: 0, right: 0, child: Column(children: [
              WildLogo(),
              SizedBox(height: 9),
              Text('N A T U R A   •   S C O P E R T A   •   C O N S E R V A Z I O N E', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: WildColors.forest)),
            ])),
          ]),
        ),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .97), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, 8))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                height: 56,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: WildColors.cream, borderRadius: BorderRadius.circular(19)),
                child: Row(children: [
                  Expanded(child: _Tab(label: 'Accedi', active: !register, onTap: () => setState(() => register = false))),
                  Expanded(child: _Tab(label: 'Registrati', active: register, onTap: () => setState(() => register = true))),
                ]),
              ),
              const SizedBox(height: 24),
              Text(register ? 'Crea il tuo account' : 'Bentornato su WildTrack', style: WildText.h1),
              const SizedBox(height: 5),
              Text(register ? 'Un’identità pseudonima, senza profilazione.' : 'Continua la tua esplorazione', style: const TextStyle(color: WildColors.muted, fontSize: 16)),
              const SizedBox(height: 22),
              TextField(controller: identity, decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline), hintText: 'Email o nickname')),
              const SizedBox(height: 12),
              TextField(controller: password, obscureText: hidden, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline), hintText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden), icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
              const SizedBox(height: 15),
              WildPrimaryButton(label: register ? 'Registrati con passkey' : 'Accedi con passkey', icon: Icons.key, onPressed: unavailable),
              const SizedBox(height: 12),
              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('oppure', style: TextStyle(color: WildColors.muted))), Expanded(child: Divider())]),
              const SizedBox(height: 12),
              WildPrimaryButton(label: register ? 'Registrati' : 'Accedi', icon: Icons.arrow_forward, onPressed: unavailable),
              const SizedBox(height: 12),
              WildOutlineButton(label: register ? 'Ho già un account' : 'Registrati', onPressed: () => setState(() => register = !register)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(20)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.eco_outlined, color: WildColors.forest),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('La tua privacy è importante', style: TextStyle(fontWeight: FontWeight.w800, color: WildColors.forest)),
                    SizedBox(height: 3),
                    Text('Raccogliamo solo i dati minimi necessari. Nessuna pubblicità comportamentale e nessuna vendita dei dati.', style: TextStyle(fontSize: 12, color: WildColors.muted)),
                  ])),
                  Icon(Icons.shield_outlined, color: WildColors.forest),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(15),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: active ? WildColors.forest : Colors.transparent, borderRadius: BorderRadius.circular(15)),
      child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: active ? Colors.white : WildColors.ink)),
    ),
  );
}
