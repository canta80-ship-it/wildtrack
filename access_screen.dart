import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../premium_ui.dart';
import 'book_widget.dart';

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
    setState(() {
      busy = true;
      error = null;
    });
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

  void _switchMode(bool value) {
    setState(() {
      register = value;
      error = null;
    });
  }

  void _passkeyInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AuthService.instance.usesCloudAccounts
            ? 'La passkey verrà attivata in una release dedicata.'
            : 'Per ora l’accesso locale usa nome utente e password. La passkey richiede l’account cloud.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WildColors.ivory,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            BookHero(
              asset: 'intro_cervo.jpg',
              height: 315,
              alignment: Alignment.topCenter,
              bottomStrength: .18,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    const WildLogo(),
                    const SizedBox(height: 8),
                    const Text(
                      'N A T U R A   •   S C O P E R T A   •   C O N S E R V A Z I O N E',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                        color: WildColors.forest,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFEFA),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Color(0x18000000), blurRadius: 30, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 58,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EEE5),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _Tab(label: 'Accedi', active: !register, onTap: () => _switchMode(false))),
                          Expanded(child: _Tab(label: 'Registrati', active: register, onTap: () => _switchMode(true))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      register ? 'Crea il tuo account' : 'Bentornato su WildTrack',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: WildColors.ink,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      register ? 'Crea il tuo profilo e continua la tua esplorazione.' : 'Continua la tua esplorazione',
                      style: const TextStyle(color: WildColors.muted, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: username,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        prefixIcon: Icon(register ? Icons.person_outline : Icons.mail_outline),
                        hintText: register ? 'Nickname' : 'Email o nickname',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: hidden,
                      onSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        ),
                      ),
                    ),
                    if (!register) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Recupero password disponibile con account cloud.')),
                          ),
                          child: const Text('Hai dimenticato la password?', style: TextStyle(color: WildColors.forest)),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text('Minimo 8 caratteri. Il nickname deve avere almeno 3 caratteri.', style: TextStyle(fontSize: 11, color: WildColors.muted)),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFE8E1), borderRadius: BorderRadius.circular(16)),
                        child: Text(error!, style: const TextStyle(color: Color(0xFF7A2E25), fontSize: 12)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (!register) ...[
                      _GreenButton(
                        label: 'Accedi con passkey',
                        icon: Icons.key_rounded,
                        onPressed: busy ? null : _passkeyInfo,
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text('oppure', style: TextStyle(color: WildColors.muted)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    _GreenButton(
                      label: busy ? 'Attendi…' : register ? 'Crea account' : 'Accedi',
                      icon: register ? Icons.person_add_alt_1 : Icons.login_rounded,
                      onPressed: busy ? null : submit,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton(
                        onPressed: busy ? null : () => _switchMode(!register),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: WildColors.forest, width: 1.4),
                          foregroundColor: WildColors.forest,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                register ? 'Ho già un account' : 'Registrati',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    BookCard(
                      tint: const Color(0xFFEEF3E9),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.eco_outlined, color: WildColors.forest),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('La tua privacy è importante', style: TextStyle(fontWeight: FontWeight.w800, color: WildColors.forest)),
                                SizedBox(height: 4),
                                Text(
                                  'Raccogliamo solo i dati minimi necessari per offrirti un’esperienza sicura e personalizzata.',
                                  style: TextStyle(fontSize: 12, height: 1.35, color: WildColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.shield_outlined, color: WildColors.forest),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          duration: const Duration(milliseconds: 170),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active ? const LinearGradient(colors: [Color(0xFF244F38), Color(0xFF173F2B)]) : null,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: active ? Colors.white : WildColors.ink),
          ),
        ),
      );
}

class _GreenButton extends StatelessWidget {
  const _GreenButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 60,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: WildColors.forest,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      );
}
