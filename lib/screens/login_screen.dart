import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme.dart';
import '../l10n.dart';
import '../firebase_options.dart';

// Login / Signup screen shown on first app open (mirrors the web login.html).
class LoginScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  const LoginScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.locale,
    required this.onLocaleChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignup = false;
  bool _loading = false;
  String? _error;

  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();

  final _google = GoogleSignIn(
    clientId: DefaultFirebaseOptions.webClientId,
    scopes: ['email', 'profile'],
  );

  Future<void> _submit() async {
    setState(() => _error = null);
    final email = _email.text.trim();
    final pass = _pass.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }
    if (_isSignup && _name.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a display name.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isSignup) {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: pass);
        await cred.user?.updateDisplayName(_name.text.trim());
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: pass);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Authentication failed.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _error = null);
    setState(() => _loading = true);
    try {
      final account = await _google.signIn();
      if (account == null) return; // user cancelled
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Google sign-in failed.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/fancoin/fanconnactlogo.png',
                    height: 72, errorBuilder: (_, __, ___) =>
                        const Icon(Icons.sports, size: 64, color: AppColors.brandBlue)),
                const SizedBox(height: 12),
                Text('Fanconnact',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandBlue)),
                const SizedBox(height: 4),
                Text(_isSignup ? 'Create your account' : 'Welcome back',
                    style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 24),
                if (_isSignup)
                  _field(_name, 'Display Name', Icons.person),
                _field(_email, 'Email', Icons.email),
                _field(_pass, 'Password', Icons.lock, obscure: true),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.liveRed, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isSignup ? 'Sign Up' : 'Log In',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _googleSignIn,
                    icon: const Icon(Icons.g_mobiledata, color: AppColors.brandBlue),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isSignup = !_isSignup),
                  child: Text(
                    _isSignup
                        ? 'Already have an account? Log in'
                        : 'New here? Create an account',
                    style: const TextStyle(color: AppColors.brandBlue),
                  ),
                ),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: widget.onToggleTheme,
                  tooltip: 'Toggle theme',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.brandBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : Colors.white,
        ),
      ),
    );
  }
}
