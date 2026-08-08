import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../theme.dart';

class SignupScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final Color accentColor;
  final ValueChanged<Color> onAccentColorChanged;

  const SignupScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.locale,
    required this.onLocaleChanged,
    required this.accentColor,
    required this.onAccentColorChanged,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _picker = ImagePicker();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _error;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  File? _photoFile;
  String? _photoPath;
  String? _selectedAvatar;
  String _selectedFrame = 'none';
  String _selectedFilter = 'none';
  String _selectedBg = 'none';
  int _rotation = 0;
  bool _flipped = false;

  static const List<String> _defaultAvatars = [
    'Felix', 'Aneka', 'George', 'Spooky', 'Max', 'Ruby', 'Leo', 'Zoe',
  ];

  static const List<_FrameOption> _frames = [
    _FrameOption('none', 'None', null, null),
    _FrameOption('gold', 'Gold', Colors.amber, Color(0x66FFD700)),
    _FrameOption('emerald', 'Emerald', Color(0xFF10B981), Color(0x6610B981)),
    _FrameOption('diamond', 'Diamond', Color(0xFF22D3EE), Color(0x6622D3EE)),
    _FrameOption('ruby', 'Ruby', Color(0xFFEF4444), Color(0x66EF4444)),
    _FrameOption('sapphire', 'Sapphire', Color(0xFF6366F1), Color(0x666366F1)),
  ];

  static const Map<String, List<double>> _filters = {
    'none': [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0],
    'vivid': [1.5,0,0,0,0, 0,1.5,0,0,0, 0,0,1.5,0,0, 0,0,0,1,0],
    'warm': [1.0,0,0,0,0, 0,1.0,0,0,0, 0,0,0.8,0,0, 0,0,0,1,0],
    'cool': [1.0,0,0,0,0, 0,0.9,0,0,0, 0,0,1.2,0,0, 0,0,0,1,0],
    'noir': [0.21,0.72,0.07,0,0, 0.21,0.72,0.07,0,0, 0.21,0.72,0.07,0,0, 0,0,0,1,0],
    'retro': [0.6,0.2,0.1,0,0, 0.1,0.7,0.1,0,0, 0.05,0.05,0.5,0,0, 0,0,0,1,0],
    'dramatic': [1.5,0,0,0,-30, 0,1.5,0,0,-30, 0,0,1.5,0,-30, 0,0,0,1,0],
  };

  static const Map<String, LinearGradient> _bgGradients = {
    'none': LinearGradient(colors: [Colors.transparent, Colors.transparent]),
    'stadium': LinearGradient(colors: [Color(0xFF1a472a), Color(0xFF2d5a3e)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    'cricket': LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF16213e)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    'football': LinearGradient(colors: [Color(0xFF0d5520), Color(0xFF1a7a30)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    'basketball': LinearGradient(colors: [Color(0xFFc4721a), Color(0xFFe8902e)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    'tennis': LinearGradient(colors: [Color(0xFF1a6e3a), Color(0xFF2a9e5a)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (f != null) {
      final cropped = await _cropIfNeeded(File(f.path));
      if (cropped != null) setState(() { _photoFile = cropped; _photoPath = cropped.path; _selectedAvatar = null; });
    }
  }

  Future<void> _pickFromCamera() async {
    final f = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1024);
    if (f != null) {
      final cropped = await _cropIfNeeded(File(f.path));
      if (cropped != null) setState(() { _photoFile = cropped; _photoPath = cropped.path; _selectedAvatar = null; });
    }
  }

  Future<File?> _cropIfNeeded(File file) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: widget.isDark ? const Color(0xFF161B22) : Colors.white,
            toolbarWidgetColor: widget.isDark ? Colors.white : const Color(0xFF0F172A),
            backgroundColor: widget.isDark ? const Color(0xFF02060C) : const Color(0xFFF8F9FF),
            activeControlsWidgetColor: widget.accentColor,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop', aspectRatioLockEnabled: true),
        ],
      );
      return cropped == null ? null : File(cropped.path);
    } catch (_) {
      return file;
    }
  }

  Future<Uint8List?> _processPhoto() async {
    if (_photoFile == null && _selectedAvatar == null) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 400, 400));
    final size = Size(400, 400);

    if (_selectedAvatar != null) {
      final img = await NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=${_selectedAvatar}');
      // Draw gradient background
      final paint = Paint()..shader = _bgGradients[_selectedBg]!.createShader(Rect.fromLTWH(0, 0, 400, 400));
      canvas.drawRect(Rect.fromLTWH(0, 0, 400, 400), paint);
    } else if (_photoFile != null) {
      final bytes = await _photoFile!.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      var img = frame.image;

      // Apply rotation
      if (_rotation != 0) {
        final rotated = await _rotateImage(img, _rotation);
        img = rotated;
      }

      // Apply horizontal flip
      if (_flipped) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()));
        canvas.save();
        canvas.translate(img.width.toDouble(), 0);
        canvas.scale(-1, 1);
        canvas.drawImage(img, Offset.zero, Paint());
        canvas.restore();
        final picture = recorder.endRecording();
        img = await picture.toImage(img.width, img.height);
      }

      // Draw background
      if (_selectedBg != 'none') {
        final paint = Paint()..shader = _bgGradients[_selectedBg]!.createShader(Rect.fromLTWH(0, 0, 400, 400));
        canvas.drawRect(Rect.fromLTWH(0, 0, 400, 400), paint);
      }

      // Draw image
      final srcSize = Size(img.width.toDouble(), img.height.toDouble());
      final scale = max(size.width / srcSize.width, size.height / srcSize.height);
      final dstSize = srcSize * scale;
      final offset = Offset((size.width - dstSize.width) / 2, (size.height - dstSize.height) / 2);
      final filter = _filters[_selectedFilter]!;
      final colorFilter = ColorFilter.matrix(filter);
      final paint = Paint()..colorFilter = colorFilter;
      canvas.drawImageRect(img, Offset.zero & srcSize, offset & dstSize, paint);
    } else {
      // No photo, draw default gradient
      final paint = Paint()..shader = _bgGradients[_selectedBg]!.createShader(Rect.fromLTWH(0, 0, 400, 400));
      canvas.drawRect(Rect.fromLTWH(0, 0, 400, 400), paint);
    }

    // Draw frame
    if (_selectedFrame != 'none') {
      final frame = _frames.firstWhere((f) => f.id == _selectedFrame);
      final borderPaint = Paint()
        ..color = frame.color!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;
      final glowPaint = Paint()
        ..color = frame.glowColor!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(const Offset(200, 200), 190, glowPaint);
      canvas.drawCircle(const Offset(200, 200), 190, borderPaint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 400);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes?.buffer.asUint8List();
  }

  Future<ui.Image> _rotateImage(ui.Image img, int deg) async {
    final angle = deg * pi / 180;
    final cosA = cos(angle).abs();
    final sinA = sin(angle).abs();
    final newW = (img.height * sinA + img.width * cosA).ceil();
    final newH = (img.height * cosA + img.width * sinA).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, newW.toDouble(), newH.toDouble()));
    canvas.translate(newW / 2, newH / 2);
    canvas.rotate(angle);
    canvas.drawImage(img, Offset(-img.width / 2, -img.height / 2), Paint());
    final picture = recorder.endRecording();
    final rotated = await picture.toImage(newW, newH);
    return rotated;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      final user = cred.user;
      if (user != null) {
        await user.updateDisplayName(_nameCtrl.text.trim());

        // Upload processed photo (camera/gallery) or use dicebear avatar.
        String? photoUrl;
        if (_photoFile != null) {
          final bytes = await _processPhoto();
          if (bytes != null) {
            final ref = FirebaseStorage.instance.ref('avatars/${user.uid}.png');
            await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
            photoUrl = await ref.getDownloadURL();
          }
        } else if (_selectedAvatar != null) {
          photoUrl = 'https://api.dicebear.com/7.x/avataaars/png?seed=$_selectedAvatar';
        }

        // Create user doc
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await ref.set({
          'email': user.email,
          'username': email.split('@')[0],
          'fullName': _nameCtrl.text.trim(),
          'photoURL': photoUrl ?? '',
          'frame': _selectedFrame,
          'coins': 100,
          'level': 1,
          'xp': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authError(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'This email is already registered.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default: return e.message ?? 'Registration failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = widget.accentColor;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
    final cardBg = isDark ? const Color(0xFF161B22) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(colors: [Color(0xFF02060C), Color(0xFF0A1628), Color(0xFF02060C)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : LinearGradient(colors: [const Color(0xFFF8F9FF), accent.withValues(alpha: 0.05), const Color(0xFFF8F9FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                        // Brand
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.shield_outlined, size: 24, color: accent),
                            ),
                            const SizedBox(width: 10),
                            Text('Fan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: accent)),
                            Text('connact', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
                        const SizedBox(height: 4),
                        Text('Join the Stadium!', style: TextStyle(color: hintColor, fontSize: 13)),
                        const SizedBox(height: 24),

                        // Profile Photo
                        _buildPhotoSection(isDark, accent, textColor, hintColor),

                        const SizedBox(height: 24),

                        // Filters (when photo is selected)
                        if (_photoFile != null) ...[
                          _buildFilterChips(isDark, accent),
                          const SizedBox(height: 16),
                        ],

                        // Background
                        _buildBackgroundChips(isDark, accent),
                        const SizedBox(height: 20),

                        // Name
                        _buildField(
                          controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                          textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                        ),
                        const SizedBox(height: 14),

                        // Email
                        _buildField(
                          controller: _emailCtrl, label: 'Email Address', icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter your email';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                          textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _buildField(
                          controller: _passCtrl, label: 'Password', icon: Icons.lock_outline,
                          obscure: _obscurePass,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter a password';
                            if (v.length < 6) return 'At least 6 characters';
                            return null;
                          },
                          textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                          suffix: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: hintColor),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Confirm
                        _buildField(
                          controller: _confirmCtrl, label: 'Confirm Password', icon: Icons.lock_outline,
                          obscure: _obscureConfirm,
                          validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                          textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                          suffix: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: hintColor),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
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
                                : const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sign in link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ', style: TextStyle(color: hintColor, fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text('Sign In', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(bool isDark, Color accent, Color textColor, Color hintColor) {
    return Column(
      children: [
        // Avatar preview
        GestureDetector(
          onTap: _pickFromGallery,
          child: Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedFrame == 'none' ? (accent.withValues(alpha: 0.3)) : _frames.firstWhere((f) => f.id == _selectedFrame).color!,
                width: _selectedFrame == 'none' ? 2 : 4,
              ),
              boxShadow: _selectedFrame != 'none'
                  ? [BoxShadow(color: _frames.firstWhere((f) => f.id == _selectedFrame).glowColor!, blurRadius: 12)]
                  : null,
            ),
            child: ClipOval(
              child: _avatarContent(isDark, accent),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionBtn(Icons.photo_library_outlined, 'Gallery', _pickFromGallery, isDark, accent),
            const SizedBox(width: 10),
            _actionBtn(Icons.camera_alt_outlined, 'Camera', _pickFromCamera, isDark, accent),
          ],
        ),
        const SizedBox(height: 12),

        // Default avatars
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: _defaultAvatars.map((seed) {
              final selected = _selectedAvatar == seed;
              return GestureDetector(
                onTap: () => setState(() { _selectedAvatar = seed; _photoFile = null; _photoPath = null; }),
                child: Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? accent : Colors.transparent, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://api.dicebear.com/7.x/avataaars/png?seed=$seed',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: accent.withValues(alpha: 0.2), child: Icon(Icons.person, color: accent, size: 20)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Frames
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: _frames.map((f) {
              final selected = _selectedFrame == f.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedFrame = f.id),
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: f.id == 'none' ? hintColor.withValues(alpha: 0.2) : Colors.transparent,
                    border: Border.all(color: f.color ?? hintColor.withValues(alpha: 0.3), width: selected ? 3 : 2),
                    boxShadow: f.glowColor != null && selected
                        ? [BoxShadow(color: f.glowColor!, blurRadius: 6)]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: f.id == 'none'
                      ? Icon(Icons.close, size: 14, color: hintColor.withValues(alpha: 0.5))
                      : null,
                ),
              );
            }).toList(),
          ),
        ),

        // Rotation controls (when photo is selected)
        if (_photoFile != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBtn(Icons.rotate_left, 'Rotate Left', () => setState(() => _rotation = (_rotation - 90) % 360), hintColor),
              const SizedBox(width: 16),
              _iconBtn(Icons.rotate_right, 'Rotate Right', () => setState(() => _rotation = (_rotation + 90) % 360), hintColor),
              const SizedBox(width: 16),
              _iconBtn(Icons.flip, 'Flip', () => setState(() => _flipped = !_flipped), hintColor),
            ],
          ),
        ],
      ],
    );
  }

  Widget _avatarContent(bool isDark, Color accent) {
    final hintColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
    if (_photoFile != null) {
      final filter = _filters[_selectedFilter] ?? _filters['none']!;
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(filter),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationZ(_rotation * pi / 180)
            ..scale(_flipped ? -1 : 1, 1),
          child: Image.file(_photoFile!, fit: BoxFit.cover),
        ),
      );
    }
    if (_selectedAvatar != null) {
      return Image.network(
        'https://api.dicebear.com/7.x/avataaars/png?seed=$_selectedAvatar',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: accent.withValues(alpha: 0.2), child: Icon(Icons.person, color: accent, size: 40)),
      );
    }
    return Container(
      color: accent.withValues(alpha: 0.08),
      child: Icon(Icons.add_a_photo, color: hintColor, size: 32),
    );
  }

  Widget _buildFilterChips(bool isDark, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filters', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _filters.keys.map((key) {
              final selected = _selectedFilter == key;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(key[0].toUpperCase() + key.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54))),
                  selected: selected,
                  selectedColor: accent,
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (v) => setState(() => _selectedFilter = key),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundChips(bool isDark, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Background', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _bgGradients.keys.map((key) {
              final selected = _selectedBg == key;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(key[0].toUpperCase() + key.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54))),
                  selected: selected,
                  selectedColor: accent,
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (v) => setState(() => _selectedBg = key),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, bool isDark, Color accent) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: accent),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : accent.withValues(alpha: 0.05),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap, Color hintColor) {
    return IconButton(
      icon: Icon(icon, size: 20, color: hintColor),
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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

class _FrameOption {
  final String id;
  final String label;
  final Color? color;
  final Color? glowColor;
  const _FrameOption(this.id, this.label, this.color, this.glowColor);
}
