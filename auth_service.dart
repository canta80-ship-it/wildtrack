import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'preferences_service.dart';

const _firebaseApiKey = String.fromEnvironment('WILDTRACK_FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('WILDTRACK_FIREBASE_APP_ID');
const _firebaseProjectId = String.fromEnvironment('WILDTRACK_FIREBASE_PROJECT_ID');
const _firebaseSenderId = String.fromEnvironment('WILDTRACK_FIREBASE_SENDER_ID');

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  FirebaseOptions? get _options {
    if (_firebaseApiKey.isEmpty || _firebaseAppId.isEmpty || _firebaseProjectId.isEmpty || _firebaseSenderId.isEmpty) return null;
    return const FirebaseOptions(
      apiKey: _firebaseApiKey,
      appId: _firebaseAppId,
      messagingSenderId: _firebaseSenderId,
      projectId: _firebaseProjectId,
    );
  }

  Future<FirebaseAuth> _auth() async {
    final options = _options;
    if (options == null) throw Exception('Servizio account non configurato. Mancano i parametri Firebase del progetto.');
    if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
    return FirebaseAuth.instance;
  }

  String normalizeUsername(String value) {
    final v = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    if (v.length < 3) throw Exception('Il nome utente deve avere almeno 3 caratteri.');
    if (v.length > 30) throw Exception('Il nome utente può avere al massimo 30 caratteri.');
    return v;
  }

  String _syntheticEmail(String username) => '${normalizeUsername(username)}@users.wildtrack.app';

  Future<String> register(String username, String password) async {
    final normalized = normalizeUsername(username);
    if (password.length < 8) throw Exception('La password deve avere almeno 8 caratteri.');
    final auth = await _auth();
    try {
      await auth.createUserWithEmailAndPassword(email: _syntheticEmail(normalized), password: password);
      await auth.currentUser?.updateDisplayName(normalized);
      PreferencesService.instance.nickname = normalized;
      await PreferencesService.instance.save();
      return normalized;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') throw Exception('Nome utente già utilizzato.');
      if (e.code == 'weak-password') throw Exception('Password troppo semplice.');
      throw Exception(e.message ?? 'Registrazione non riuscita.');
    }
  }

  Future<String> signIn(String username, String password) async {
    final normalized = normalizeUsername(username);
    final auth = await _auth();
    try {
      await auth.signInWithEmailAndPassword(email: _syntheticEmail(normalized), password: password);
      PreferencesService.instance.nickname = normalized;
      await PreferencesService.instance.save();
      return normalized;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw Exception('Nome utente o password non corretti.');
      }
      throw Exception(e.message ?? 'Accesso non riuscito.');
    }
  }

  Future<void> signOut() async {
    final auth = await _auth();
    await auth.signOut();
  }

  Future<String?> currentUsername() async {
    try {
      final auth = await _auth();
      final user = auth.currentUser;
      if (user == null) return null;
      return user.displayName ?? user.email?.split('@').first;
    } catch (_) {
      return null;
    }
  }
}
