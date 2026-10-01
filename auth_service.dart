import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite/sqflite.dart';

import 'preferences_service.dart';

const _firebaseApiKey = String.fromEnvironment('WILDTRACK_FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('WILDTRACK_FIREBASE_APP_ID');
const _firebaseProjectId = String.fromEnvironment(
  'WILDTRACK_FIREBASE_PROJECT_ID',
);
const _firebaseSenderId = String.fromEnvironment(
  'WILDTRACK_FIREBASE_SENDER_ID',
);

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  FirebaseOptions? get _options {
    if (_firebaseApiKey.isEmpty ||
        _firebaseAppId.isEmpty ||
        _firebaseProjectId.isEmpty ||
        _firebaseSenderId.isEmpty)
      return null;
    return const FirebaseOptions(
      apiKey: _firebaseApiKey,
      appId: _firebaseAppId,
      messagingSenderId: _firebaseSenderId,
      projectId: _firebaseProjectId,
    );
  }

  bool get usesCloudAccounts => _options != null;

  Future<FirebaseAuth> _auth() async {
    final options = _options;
    if (options == null) throw Exception('Cloud account non configurato.');
    if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
    return FirebaseAuth.instance;
  }

  String normalizeUsername(String value) {
    final v = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '',
    );
    if (v.length < 3)
      throw Exception('Il nome utente deve avere almeno 3 caratteri.');
    if (v.length > 30)
      throw Exception('Il nome utente può avere al massimo 30 caratteri.');
    return v;
  }

  String _cloudEmail(String value) =>
      value.contains('@') ? value.trim().toLowerCase() : _syntheticEmail(value);

  String _syntheticEmail(String username) =>
      '${normalizeUsername(username)}@users.wildtrack.app';

  Future<File> _localAuthFile() async {
    final dir = Directory(await getDatabasesPath());
    await dir.create(recursive: true);
    return File('${dir.path}/wildtrack_local_account.json');
  }

  String _makeSalt() {
    final r = Random.secure();
    return List.generate(
      24,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  String _hash(String username, String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$username:$password')).toString();

  Future<Map<String, dynamic>?> _readLocalAccount() async {
    try {
      final file = await _localAuthFile();
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocalAccount(String username, String password) async {
    final salt = _makeSalt();
    final file = await _localAuthFile();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'username': username,
        'salt': salt,
        'hash': _hash(username, password, salt),
        'signedIn': true,
      }),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  Future<void> _writeLocalAccount(Map<String, dynamic> account) async {
    final file = await _localAuthFile();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(account), flush: true);
    await tmp.rename(file.path);
  }

  Future<String> register(String username, String password) async {
    final normalized = normalizeUsername(username);
    if (password.length < 8)
      throw Exception('La password deve avere almeno 8 caratteri.');

    if (!usesCloudAccounts) {
      final existing = await _readLocalAccount();
      if (existing != null) {
        throw Exception('Su questo dispositivo esiste già un account locale.');
      }
      await _saveLocalAccount(normalized, password);
      PreferencesService.instance.nickname = normalized;
      await PreferencesService.instance.save();
      return normalized;
    }

    final auth = await _auth();
    try {
      await auth.createUserWithEmailAndPassword(
        email: _cloudEmail(username),
        password: password,
      );
      await auth.currentUser?.updateDisplayName(normalized);
      PreferencesService.instance.nickname = normalized;
      await PreferencesService.instance.save();
      return normalized;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use')
        throw Exception('Nome utente già utilizzato.');
      if (e.code == 'weak-password')
        throw Exception('Password troppo semplice.');
      throw Exception(e.message ?? 'Registrazione non riuscita.');
    }
  }

  Future<String> signIn(String username, String password) async {
    final normalized = normalizeUsername(username);

    if (!usesCloudAccounts) {
      final account = await _readLocalAccount();
      if (account == null)
        throw Exception(
          'Nessun account locale trovato. Registrati prima su questo dispositivo.',
        );
      final savedUser = account['username'] as String? ?? '';
      final salt = account['salt'] as String? ?? '';
      final savedHash = account['hash'] as String? ?? '';
      if (savedUser != normalized ||
          salt.isEmpty ||
          savedHash != _hash(normalized, password, salt)) {
        throw Exception('Nome utente o password non corretti.');
      }
      account['signedIn'] = true;
      await _writeLocalAccount(account);
      PreferencesService.instance.nickname = normalized;
      await PreferencesService.instance.save();
      return normalized;
    }

    final auth = await _auth();
    try {
      await auth.signInWithEmailAndPassword(
        email: _cloudEmail(username),
        password: password,
      );
      PreferencesService.instance.nickname = normalized;
      await PreferencesService.instance.save();
      return normalized;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        throw Exception('Nome utente o password non corretti.');
      }
      throw Exception(e.message ?? 'Accesso non riuscito.');
    }
  }

  Future<bool> hasRecoveryCode() async =>
      (await _readLocalAccount())?['recoveryHash'] != null;

  Future<String> createRecoveryCode() async {
    if (usesCloudAccounts) throw StateError('Usa il recupero tramite email.');
    final account = await _readLocalAccount();
    if (account == null || account['signedIn'] == false)
      throw StateError('Accedi prima di generare il codice.');
    final code = _makeSalt();
    final salt = _makeSalt();
    account['recoverySalt'] = salt;
    account['recoveryHash'] = _hash(account['username'] as String, code, salt);
    await _writeLocalAccount(account);
    return code;
  }

  Future<void> recoverPassword(
    String username,
    String code,
    String newPassword,
  ) async {
    if (usesCloudAccounts) {
      final email = username.trim();
      if (!email.contains('@') || email.endsWith('@users.wildtrack.app')) {
        throw StateError('Inserisci l’email reale associata all’account.');
      }
      final auth = await _auth();
      await auth.sendPasswordResetEmail(email: email);
      return;
    }
    if (newPassword.length < 8)
      throw StateError('La password deve avere almeno 8 caratteri.');
    final normalized = normalizeUsername(username);
    final account = await _readLocalAccount();
    final salt = account?['recoverySalt'] as String? ?? '';
    if (account == null ||
        account['username'] != normalized ||
        salt.isEmpty ||
        account['recoveryHash'] != _hash(normalized, code.trim(), salt)) {
      throw StateError('Nickname o codice di recupero non valido.');
    }
    final passwordSalt = _makeSalt();
    account['salt'] = passwordSalt;
    account['hash'] = _hash(normalized, newPassword, passwordSalt);
    account['signedIn'] = false;
    await _writeLocalAccount(account);
  }

  Future<void> signOut() async {
    if (!usesCloudAccounts) {
      final account = await _readLocalAccount();
      if (account != null) {
        account['signedIn'] = false;
        await _writeLocalAccount(account);
      }
      return;
    }
    final auth = await _auth();
    await auth.signOut();
  }

  Future<String?> currentUsername() async {
    if (!usesCloudAccounts) {
      final account = await _readLocalAccount();
      return account == null || account['signedIn'] == false
          ? null
          : account['username'] as String?;
    }
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
