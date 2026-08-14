import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/otp_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final ThemeType themeType;
  final ValueChanged<ThemeType> onThemeChanged;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final Color accentColor;
  final ValueChanged<Color> onAccentColorChanged;

  const LoginScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.themeType,
    required this.onThemeChanged,
    required this.locale,
    required this.onLocaleChanged,
    required this.accentColor,
    required this.onAccentColorChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  bool _obscurePass = true;
  bool _rememberMe = false;

  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _google = GoogleSignIn(scopes: ['email', 'profile']);
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_slideController);
    _loadRememberMe();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('savedEmail') ?? '';
    if (saved.isNotEmpty && mounted) {
      setState(() {
        _email.text = saved;
        _rememberMe = true;
      });
    }
  }

  Future<void> _navigateSignup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SignupScreen(
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          themeType: widget.themeType,
          onThemeChanged: widget.onThemeChanged,
          locale: widget.locale,
          onLocaleChanged: widget.onLocaleChanged,
          accentColor: widget.accentColor,
          onAccentColorChanged: widget.onAccentColorChanged,
        ),
      ),
    );
    if (result == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'username': (user.email ?? '').split('@')[0],
        'fullName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'coins': 100,
        'level': 1,
        'xp': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> _twoFactorEnabled(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return snap.data()?['twoFactorEnabled'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final email = _email.text.trim();
    final pass = _pass.text.trim();

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      if (cred.user != null) {
        await _ensureUserDoc(cred.user!);
        // Two-Factor: if enabled for this account, require the email OTP.
        if (await _twoFactorEnabled(cred.user!.uid)) {
          final ok = await OtpService.verifyDialog(
            context,
            email: email,
            title: 'Two-Factor Authentication',
            message: 'A 6-digit code was sent to $email. Enter it to continue.',
          );
          if (ok != true) {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = 'Two-factor verification failed. Please try again.';
            });
            return;
          }
        }
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('savedEmail', email);
        }
        if (mounted) Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authErrorMessage(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _error = null; _loading = true; });
    try {
      final account = await _google.signIn();
      if (account == null) { setState(() => _loading = false); return; }
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCred.user != null) {
        await _ensureUserDoc(userCred.user!);
        if (mounted) Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authErrorMessage(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _facebookSignIn() async {
    setState(() { _error = null; _loading = true; });
    try {
      final result = await FacebookAuth.instance.login(permissions: ['email', 'public_profile']);
      if (result.status != LoginStatus.success) { setState(() => _loading = false); return; }
      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null) { setState(() => _loading = false); return; }
      final credential = FacebookAuthProvider.credential(accessToken);
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCred.user != null) {
        await _ensureUserDoc(userCred.user!);
        if (mounted) Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authErrorMessage(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleSignIn() async {
    setState(() { _error = null; _loading = true; });
    try {
      final credential = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
      final oauthCredential = OAuthProvider('apple.com').credential(idToken: credential.identityToken, accessToken: credential.authorizationCode);
      final userCred = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      if (userCred.user != null) {
        await _ensureUserDoc(userCred.user!);
        if (mounted) Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authErrorMessage(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Email Sent', style: TextStyle(fontWeight: FontWeight.w800)),
            content: Text('Password reset link sent to $email'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': case 'invalid-credential': return 'Incorrect password.';
      case 'invalid-email': return 'Please enter a valid email.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      case 'email-already-in-use': return 'This email is already registered.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'account-exists-with-different-credential': return 'An account already exists with a different sign-in method.';
      default: return e.message ?? 'Authentication failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = widget.accentColor;
    final bgGradient = isDark
        ? const LinearGradient(colors: [Color(0xFF02060C), Color(0xFF0A1628), Color(0xFF02060C)], begin: Alignment.topLeft, end: Alignment.bottomRight)
        : LinearGradient(colors: [const Color(0xFFF8F9FF), accent.withValues(alpha: 0.05), const Color(0xFFF8F9FF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    final cardBg = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AnimatedBuilder(
                  animation: _slideController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/fancoin/fanconnactlogo.png',
                                  width: 56, height: 56, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(Icons.sports, size: 32, color: accent),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Welcome Back',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to continue',
                              style: TextStyle(color: hintColor, fontSize: 14),
                            ),
                            const SizedBox(height: 28),

                            _buildField(
                              controller: _email,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter your email';
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              },
                              textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                            ),
                            const SizedBox(height: 14),

                            _buildField(
                              controller: _pass,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscure: _obscurePass,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter a password';
                                return null;
                              },
                              textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                              suffix: IconButton(
                                icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: hintColor),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 20, width: 20,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                          activeColor: accent,
                                          side: BorderSide(color: hintColor.withValues(alpha: 0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Remember me', style: TextStyle(fontSize: 13, color: hintColor)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _resetPassword,
                                  child: Text('Forgot Password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
                                ),
                              ],
                            ),

                            // Error
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.liveRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.liveRed, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.liveRed, fontSize: 12))),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Submit
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: _loading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: accent.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              ),
                            ),

                            // Divider
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR CONTINUE WITH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: hintColor, letterSpacing: 1.2)),
                                ),
                                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Social buttons
                            Row(
                              children: [
                                Expanded(child: _socialBtn('Google', Icons.g_mobiledata, const Color(0xFF4285F4), _googleSignIn, isDark)),
                                const SizedBox(width: 10),
                                Expanded(child: _socialBtn('Facebook', Icons.facebook, const Color(0xFF1877F2), _facebookSignIn, isDark)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _socialBtn(
                                    'Apple', Icons.apple, isDark ? Colors.white : Colors.black, _appleSignIn, isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _socialBtn(
                                    'Twitter/X', Icons.alternate_email, isDark ? Colors.white : const Color(0xFF1DA1F2), _twitterSignIn, isDark,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Sign Up
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ", style: TextStyle(color: hintColor, fontSize: 13)),
                                GestureDetector(
                                  onTap: _navigateSignup,
                                  child: Text('Sign Up', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Theme toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${isDark ? 'Dark' : 'Light'} mode', style: TextStyle(fontSize: 11, color: hintColor)),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: hintColor, size: 18),
                                  onPressed: widget.onToggleTheme,
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Toggle theme',
                                ),
                              ],
                            ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _twitterSignIn() {
    setState(() => _error = 'Twitter login coming soon. Use Google or email instead.');
  }

  Widget _socialBtn(String label, IconData icon, Color iconColor, VoidCallback onTap, bool isDark) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: _loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1C2230) : Colors.white,
          side: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color hintColor,
    required Color accent,
    required bool isDark,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hintColor)),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: hintColor),
            suffixIcon: suffix,
            hintText: 'Enter your ${label.toLowerCase()}',
            hintStyle: TextStyle(color: hintColor.withValues(alpha: 0.5), fontSize: 13),
            filled: true,
            fillColor: isDark ? const Color(0xFF0E1116) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.liveRed, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
