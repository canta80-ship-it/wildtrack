import 'package:flutter/material.dart';

import 'auth_service.dart';
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
  final username = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    final user = username.text.trim();
    final pass = password.text;
    if (user.isEmpty || pass.isEmpty) {
      setState(() => error = 'Inserisci nome utente e password.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      if (register) {
        await AuthService.instance.register(user, pass);
      } else {
        await AuthService.instance.signIn(user, pass);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => widget.home));
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void guest() => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => widget.home));

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
                  Expanded(child: _Tab(label: 'Accedi', active: !register, onTap: () => setState(() { register = false; error = null; }))),
                  Expanded(child: _Tab(label: 'Registrati', active: register, onTap: () => setState(() { register = true; error = null; }))),
                ]),
              ),
              const SizedBox(height: 24),
              Text(register ? 'Crea il tuo account' : 'Bentornato su WildTrack', style: WildText.h1),
              const SizedBox(height: 5),
              Text(register ? 'Ti basta un nome utente. Nessuna email obbligatoria.' : 'Continua la tua esplorazione', style: const TextStyle(color: WildColors.muted, fontSize: 16)),
              const SizedBox(height: 22),
              TextField(
                controller: username,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), hintText: 'Nome utente'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: hidden,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline), hintText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden), icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined))),
              ),
              if (register) ...[
                const SizedBox(height: 8),
                const Text('Minimo 8 caratteri. Il nome utente deve essere unico.', style: TextStyle(fontSize: 11, color: WildColors.muted)),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFE8E1), borderRadius: BorderRadius.circular(16)),
                  child: Text(error!, style: const TextStyle(color: Color(0xFF7A2E25), fontSize: 12)),
                ),
              ],
              const SizedBox(height: 16),
              WildPrimaryButton(label: busy ? 'Attendi…' : register ? 'Crea account' : 'Accedi', icon: register ? Icons.person_add_alt_1 : Icons.login, onPressed: busy ? null : submit),
              const SizedBox(height: 12),
              WildOutlineButton(label: register ? 'Ho già un account' : 'Registrati', onPressed: busy ? null : () => setState(() { register = !register; error = null; })),
              const SizedBox(height: 12),
              TextButton(onPressed: busy ? null : guest, child: const Center(child: Text('Continua come ospite', style: TextStyle(color: WildColors.forest, fontWeight: FontWeight.w700)))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: WildColors.sageSoft, borderRadius: BorderRadius.circular(20)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.eco_outlined, color: WildColors.forest),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('La tua privacy è importante', style: TextStyle(fontWeight: FontWeight.w800, color: WildColors.forest)),
                    SizedBox(height: 3),
                    Text('Usiamo un identificativo tecnico interno per l’account. Non chiediamo il tuo indirizzo email per registrarti.', style: TextStyle(fontSize: 12, color: WildColors.muted)),
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
