import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../theme.dart';
import '../services/otp_service.dart';
import '../services/photo_fx_service.dart';
import 'camera_capture_screen.dart';

class SignupScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final ThemeType themeType;
  final ValueChanged<ThemeType> onThemeChanged;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final Color accentColor;
  final ValueChanged<Color> onAccentColorChanged;

  const SignupScreen({
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
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _picker = ImagePicker();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _error;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Profile photo
  File? _photoFile;
  String? _selectedAvatar;
  String _selectedFrame = 'none';
  String _selectedFilter = 'none';
  String _selectedBg = 'none';
  int _rotation = 0;
  bool _flipped = false;

  // Extra profile fields (web signup parity)
  String _countryCode = '+91';
  int _countryDigits = 10;
  String _dobISO = '';
  String _gender = 'Male';
  final Set<String> _selectedSports = <String>{};

  // Email OTP (same EmailJS account as web)
  String? _otp;
  int _otpSendCount = 0;
  bool _otpSending = false;
  bool _emailVerified = false;
  String? _otpStatus;
  bool _otpStatusOk = false;
  Timer? _otpExpiryTimer;
  Timer? _otpCooldownTimer;
  int _otpCooldownLeft = 0;

  // Terms
  bool _termsAccepted = false;

  // Real-time validation (web parity)
  String? _nameMsg; bool _nameOk = false;
  String? _usernameMsg; bool _usernameOk = false; bool _usernameChecking = false;
  String? _emailMsg; bool _emailOk = false; bool _emailRegistered = false; bool _emailChecking = false;
  String? _mobileMsg; bool _mobileOk = false; bool _mobileChecking = false;
  String? _passMsg; bool _passOk = false;
  String? _confirmMsg; bool _confirmOk = false;
  Timer? _usernameDbTimer;
  Timer? _emailDbTimer;
  Timer? _mobileDbTimer;

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

  static const List<Map<String, Object>> _countryCodes = [
    {'code': '+91', 'digits': 10, 'flag': '🇮🇳'},
    {'code': '+1', 'digits': 10, 'flag': '🇺🇸'},
    {'code': '+44', 'digits': 10, 'flag': '🇬🇧'},
    {'code': '+61', 'digits': 9, 'flag': '🇦🇺'},
    {'code': '+971', 'digits': 9, 'flag': '🇦🇪'},
    {'code': '+92', 'digits': 10, 'flag': '🇵🇰'},
    {'code': '+880', 'digits': 10, 'flag': '🇧🇩'},
    {'code': '+977', 'digits': 10, 'flag': '🇳🇵'},
    {'code': '+94', 'digits': 9, 'flag': '🇱🇰'},
    {'code': '+27', 'digits': 9, 'flag': '🇿🇦'},
    {'code': '+65', 'digits': 8, 'flag': '🇸🇬'},
    {'code': '+966', 'digits': 9, 'flag': '🇸🇦'},
  ];

  static const List<Map<String, String>> _sportOptions = [
    {'value': 'cricket', 'label': '🏏 Cricket'},
    {'value': 'football', 'label': '⚽ Football'},
    {'value': 'basketball', 'label': '🏀 Basketball'},
    {'value': 'tennis', 'label': '🎾 Tennis'},
    {'value': 'baseball', 'label': '⚾ Baseball'},
    {'value': 'hockey', 'label': '🏑 Hockey'},
    {'value': 'esports', 'label': '🎮 E-Sports'},
    {'value': 'kabaddi', 'label': '🤼 Kabaddi'},
    {'value': 'tabletennis', 'label': '🏓 Table Tennis'},
    {'value': 'volleyball', 'label': '🏐 Volleyball'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _otpCtrl.dispose();
    _otpExpiryTimer?.cancel();
    _otpCooldownTimer?.cancel();
    _usernameDbTimer?.cancel();
    _emailDbTimer?.cancel();
    _mobileDbTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (f != null) {
      final cropped = await _cropIfNeeded(File(f.path));
      if (cropped != null) setState(() { _photoFile = cropped; _selectedAvatar = null; });
    }
  }

  Future<void> _pickFromCamera() async {
    final res = await Navigator.of(context).push<CameraCaptureResult>(
      MaterialPageRoute(builder: (_) => CameraCaptureScreen(isDark: widget.isDark, accentColor: widget.accentColor)),
    );
    if (res != null) {
      setState(() {
        _photoFile = File(res.filePath);
        _selectedAvatar = null;
        _selectedFilter = 'none';
        _selectedBg = 'none';
        _rotation = 0;
        _flipped = false;
      });
    }
  }

  Future<File?> _cropIfNeeded(File file) async {
    try {
      final tmpDir = Directory.systemTemp.createTempSync('fc_crop');
      final copy = File('${tmpDir.path}/input.jpg');
      await copy.writeAsBytes(await file.readAsBytes());
      final cropped = await ImageCropper().cropImage(
        sourcePath: copy.path,
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
      try { tmpDir.deleteSync(recursive: true); } catch (_) {}
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
      final paint = Paint()..shader = _bgGradient(_selectedBg).createShader(Rect.fromLTWH(0, 0, 400, 400));
      canvas.drawRect(Rect.fromLTWH(0, 0, 400, 400), paint);
    } else if (_photoFile != null) {
      final bytes = await _photoFile!.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      var img = frame.image;

      if (_rotation != 0) {
        final rotated = await _rotateImage(img, _rotation);
        img = rotated;
      }

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

      // MLKit person cut-out onto the selected sports background
      if (_selectedBg != 'none') {
        final selBg = kSportBackgrounds.firstWhere((b) => b.key == _selectedBg, orElse: () => kSportBackgrounds.last);
        final cut = await PhotoFxService.cutoutToGradient(
          photoBytes: await _imgToBytes(img),
          bg: selBg,
          filterMatrix: _filters[_selectedFilter] ?? _filters['none']!,
        );
        if (cut != null) {
          if (_selectedFrame == 'none') return cut;
          return _applyFrameToBytes(cut, _selectedFrame);
        }
      }

      if (_selectedBg != 'none') {
        final paint = Paint()..shader = _bgGradient(_selectedBg).createShader(Rect.fromLTWH(0, 0, 400, 400));
        canvas.drawRect(Rect.fromLTWH(0, 0, 400, 400), paint);
      }

      final srcSize = Size(img.width.toDouble(), img.height.toDouble());
      final scale = max(size.width / srcSize.width, size.height / srcSize.height);
      final dstSize = srcSize * scale;
      final offset = Offset((size.width - dstSize.width) / 2, (size.height - dstSize.height) / 2);
      final filter = _filters[_selectedFilter]!;
      final colorFilter = ColorFilter.matrix(filter);
      final paint = Paint()..colorFilter = colorFilter;
      canvas.drawImageRect(img, Offset.zero & srcSize, offset & dstSize, paint);
    } else {
      final paint = Paint()..shader = _bgGradient(_selectedBg).createShader(Rect.fromLTWH(0, 0, 400, 400));
      canvas.drawRect(Rect.fromLTWH(0, 0, 400, 400), paint);
    }

    _drawFrame(canvas, _selectedFrame);

    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 400);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes?.buffer.asUint8List();
  }

  void _drawFrame(Canvas canvas, String frameId) {
    if (frameId == 'none') return;
    final frame = _frames.firstWhere((f) => f.id == frameId);
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

  Future<Uint8List> _imgToBytes(ui.Image img) async {
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<Uint8List> _applyFrameToBytes(Uint8List png, String frameId) async {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));
    canvas.drawImageRect(img, const Offset(0, 0) & const Size(400, 400), const Offset(0, 0) & const Size(400, 400), Paint());
    _drawFrame(canvas, frameId);
    final picture = recorder.endRecording();
    final out = await picture.toImage(400, 400);
    final bd = await out.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  LinearGradient _bgGradient(String key) {
    return kSportBackgrounds.firstWhere((b) => b.key == key, orElse: () => kSportBackgrounds.first).gradient;
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

  // ── Email OTP (same EmailJS account as the web signup) ──
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !_emailRe.hasMatch(email)) {
      setState(() { _otpStatus = 'Please enter a valid email address first.'; _otpStatusOk = false; });
      return;
    }
    if (_emailRegistered) {
      setState(() { _otpStatus = 'This email is already registered. Please log in instead.'; _otpStatusOk = false; });
      return;
    }
    final username = _usernameCtrl.text.trim();
    if (username.isNotEmpty && (!_usernameOk || _usernameChecking)) {
      setState(() { _otpStatus = _usernameChecking ? 'Checking username availability...' : 'Username is not available. Choose another.'; _otpStatusOk = false; });
      return;
    }
    if (_otpSendCount >= 3) {
      setState(() { _otpStatus = 'Maximum OTP limit reached (3 per session). Try again later.'; _otpStatusOk = false; });
      return;
    }

    setState(() { _otpSending = true; _otpStatus = 'Sending...'; _otpStatusOk = false; });
    final otp = OtpService.generate();
    final err = await OtpService.send(email, otp);
    if (!mounted) return;
    setState(() => _otpSending = false);

    if (err != null) {
      setState(() { _otpStatus = err; _otpStatusOk = false; });
      return;
    }

    _otpSendCount++;
    _otp = otp;
    _emailVerified = false;
    setState(() { _otpStatus = 'OTP sent to $email'; _otpStatusOk = true; });

    _otpExpiryTimer?.cancel();
    _otpExpiryTimer = Timer(const Duration(minutes: 5), () {
      if (!mounted) return;
      setState(() { _otp = null; _otpStatus = 'OTP expired. Request a new one.'; _otpStatusOk = false; });
    });

    _startCooldown();
  }

  void _startCooldown() {
    _otpCooldownTimer?.cancel();
    setState(() => _otpCooldownLeft = 120);
    _otpCooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _otpCooldownLeft--;
        if (_otpCooldownLeft <= 0) { t.cancel(); _otpCooldownLeft = 0; }
      });
    });
  }

  void _verifyOtp() {
    final entered = _otpCtrl.text.trim();
    if (_otp == null) {
      setState(() { _otpStatus = 'No OTP sent or OTP expired. Request a new one.'; _otpStatusOk = false; });
      return;
    }
    if (entered.length < 4) {
      setState(() { _otpStatus = 'Please enter the OTP sent to your email.'; _otpStatusOk = false; });
      return;
    }
    if (entered != _otp) {
      setState(() { _otpStatus = 'Invalid OTP. Try again.'; _otpStatusOk = false; });
      return;
    }
    _otpExpiryTimer?.cancel();
    _otpCooldownTimer?.cancel();
    setState(() { _emailVerified = true; _otpStatus = 'Email verified!'; _otpStatusOk = true; });
  }

  // ── DOB ──
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final sixYearsAgo = DateTime(now.year - 6, now.month, now.day);
    final initial = _dobISO.isNotEmpty ? DateTime.tryParse(_dobISO) : DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? sixYearsAgo,
      firstDate: DateTime(now.year - 100),
      lastDate: sixYearsAgo,
      helpText: 'Select Date of Birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: widget.accentColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dobISO = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  String? _dobError() {
    if (_dobISO.isEmpty) return 'Date of birth is required';
    final parts = _dobISO.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((p) => p == null)) return 'Invalid date';
    final y = parts[0]!, m = parts[1]!, d = parts[2]!;
    final bd = DateTime(y, m, d);
    final now = DateTime.now();
    if (bd.isAfter(now)) return 'Cannot be in the future';
    var age = now.year - y;
    if (now.month < m || (now.month == m && now.day < d)) age--;
    if (age < 13) return 'Must be 13+';
    return null;
  }

  // ── Real-time validation (web parity) ──
  static final RegExp _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _usernameRe = RegExp(r'^[a-z0-9_]{3,20}$');
  static final RegExp _seqRe = RegExp(
    r'(?:012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)',
    caseSensitive: false,
  );

  void _validateName(String v) {
    final ok = v.trim().isNotEmpty;
    setState(() { _nameMsg = ok ? '' : 'Name is required'; _nameOk = ok; });
  }

  void _validateUsername(String v) {
    final val = v.trim().toLowerCase();
    _usernameDbTimer?.cancel();
    if (val.isEmpty) {
      setState(() { _usernameMsg = 'Optional — auto-generated if blank'; _usernameOk = true; _usernameChecking = false; });
      return;
    }
    if (!_usernameRe.hasMatch(val)) {
      setState(() { _usernameMsg = '3–20 letters, numbers or underscores only'; _usernameOk = false; _usernameChecking = false; });
      return;
    }
    setState(() { _usernameMsg = 'Checking…'; _usernameChecking = true; });
    _usernameDbTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final snap = await FirebaseFirestore.instance.collection('usernames').doc(val).get();
        if (!mounted) return;
        setState(() {
          if (snap.exists) { _usernameMsg = 'Username taken'; _usernameOk = false; }
          else { _usernameMsg = 'Available'; _usernameOk = true; }
          _usernameChecking = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() { _usernameMsg = 'Available'; _usernameOk = true; _usernameChecking = false; });
      }
    });
  }

  Future<void> _validateEmail(String v, {bool force = false}) async {
    final val = v.trim();
    _emailDbTimer?.cancel();
    // Reset OTP verification when the email changes
    if (_emailVerified && !force) {
      setState(() {
        _emailVerified = false;
        _otp = null;
        _otpStatus = 'Email changed — re-verify required';
        _otpStatusOk = false;
        _otpCtrl.clear();
      });
    }
    if (val.isEmpty) {
      setState(() { _emailMsg = ''; _emailOk = false; _emailRegistered = false; _emailChecking = false; });
      return;
    }
    if (!_emailRe.hasMatch(val)) {
      setState(() { _emailMsg = 'Invalid email format'; _emailOk = false; _emailRegistered = false; _emailChecking = false; });
      return;
    }
    setState(() { _emailMsg = 'Valid format'; _emailOk = true; _emailChecking = true; });
    _emailDbTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        // ignore: deprecated_member_use
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(val);
        if (!mounted) return;
        setState(() {
          if (methods.isNotEmpty) {
            _emailMsg = 'Already registered — cannot send OTP';
            _emailOk = false;
            _emailRegistered = true;
          } else {
            _emailMsg = 'Available';
            _emailOk = true;
            _emailRegistered = false;
          }
          _emailChecking = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() { _emailMsg = 'Check failed'; _emailOk = false; _emailChecking = false; });
      }
    });
  }

  void _validateMobile(String v) {
    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
    _mobileDbTimer?.cancel();
    if (digits.isEmpty) {
      setState(() { _mobileMsg = ''; _mobileOk = false; _mobileChecking = false; });
      return;
    }
    if (digits.length != _countryDigits) {
      setState(() { _mobileMsg = 'Enter exactly $_countryDigits digits'; _mobileOk = false; _mobileChecking = false; });
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(digits)) {
      setState(() { _mobileMsg = 'Digits only'; _mobileOk = false; _mobileChecking = false; });
      return;
    }
    setState(() { _mobileMsg = 'Valid format'; _mobileOk = true; _mobileChecking = true; });
    final full = _countryCode + digits;
    _mobileDbTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final snap = await FirebaseFirestore.instance.collection('mobiles').doc(full).get();
        if (!mounted) return;
        setState(() {
          if (snap.exists) { _mobileMsg = 'Already registered'; _mobileOk = false; }
          else { _mobileMsg = 'Available'; _mobileOk = true; }
          _mobileChecking = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() { _mobileMsg = 'Check failed'; _mobileOk = false; _mobileChecking = false; });
      }
    });
  }

  void _validatePassword(String v) {
    final fails = <String>[];
    if (v.length < 8) fails.add('8+ chars');
    if (!RegExp(r'[A-Z]').hasMatch(v)) fails.add('A-Z');
    if (!RegExp(r'[a-z]').hasMatch(v)) fails.add('a-z');
    if (!RegExp(r'[@#_]').hasMatch(v)) fails.add('@ # _');
    if (_seqRe.hasMatch(v)) fails.add('no seq (123, abc)');
    final ok = fails.isEmpty;
    setState(() {
      _passMsg = v.isEmpty ? '' : (ok ? 'Strong password' : 'Missing: ${fails.join(', ')}');
      _passOk = ok;
    });
    if (_confirmCtrl.text.isNotEmpty) _validateConfirm(_confirmCtrl.text);
  }

  void _validateConfirm(String v) {
    final ok = v.isNotEmpty && v == _passCtrl.text;
    setState(() { _confirmMsg = v.isEmpty ? '' : (ok ? 'Passwords match' : 'Passwords do not match'); _confirmOk = ok; });
  }

  Widget _liveMsg(String? msg, bool ok, bool checking) {
    if (msg == null || msg.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 5),
      child: Row(
        children: [
          if (checking) const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)),
          if (checking) const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ok ? const Color(0xFF00855B) : (widget.isDark ? const Color(0xFFF87171) : AppColors.liveRed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit ──
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_emailVerified) {
      setState(() => _error = 'Please verify your email via OTP before signing up.');
      return;
    }
    if (!_termsAccepted) {
      setState(() => _error = 'Please agree to the Terms of Service.');
      return;
    }
    final dobErr = _dobError();
    if (dobErr != null) { setState(() => _error = dobErr); return; }

    setState(() => _error = null);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final fullName = _nameCtrl.text.trim();
    final mobileLocal = _mobileCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    final mobile = _countryCode + mobileLocal;

    final rawUsername = _usernameCtrl.text.trim().toLowerCase();
    final finalUsername = rawUsername.isNotEmpty
        ? rawUsername
        : (fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') + Random().nextInt(10000).toString());

    setState(() => _loading = true);
    try {
      // 1. Username duplicate check
      final usernameRef = FirebaseFirestore.instance.collection('usernames').doc(finalUsername);
      if ((await usernameRef.get()).exists) {
        throw FirebaseAuthException(code: 'username-taken', message: 'Username is already taken. Please choose another one.');
      }

      // 2. Create user (throws email-already-in-use if registered)
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      final user = cred.user;
      if (user == null) throw FirebaseAuthException(code: 'unknown', message: 'Could not create account.');
      await user.updateDisplayName(fullName);

      // 3. Mobile duplicate check
      final mobileRef = FirebaseFirestore.instance.collection('mobiles').doc(mobile);
      if ((await mobileRef.get()).exists) {
        await user.delete();
        throw FirebaseAuthException(code: 'mobile-taken', message: 'This mobile number is already registered. Please login.');
      }

      // 4. Upload photo / avatar
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

      // 5. Store user doc
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await ref.set({
        'uid': user.uid,
        'email': email,
        'username': finalUsername,
        'fullName': fullName,
        'mobile': mobile,
        'dob': _dobISO,
        'gender': _gender,
        'photoURL': photoUrl ?? '',
        'frame': _selectedFrame,
        'emailVerified': true,
        'provider': 'email',
        'coins': 100,
        'level': 1,
        'xp': 0,
        'selectedSports': _selectedSports.isNotEmpty ? _selectedSports.toList() : ['cricket'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 6. Reserve username + mobile
      await mobileRef.set({'uid': user.uid});
      await usernameRef.set({'uid': user.uid});

      if (mounted) Navigator.pop(context, true);
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
      case 'username-taken': return 'Username is already taken. Please choose another one.';
      case 'mobile-taken': return 'This mobile number is already registered.';
      default: return e.message ?? 'Registration failed.';
    }
  }

  // ── Build ──
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
                        // Brand (real logo)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/fancoin/fanconnactlogo.png',
                            width: 64, height: 64, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.shield_outlined, size: 32, color: accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text('Join the Stadium! 🏟️', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
                        const SizedBox(height: 4),
                        Text('Create your account to start winning.', style: TextStyle(color: hintColor, fontSize: 13)),
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

                        // Full Name
                        _buildField(
                          controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                          textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                          onChanged: _validateName,
                        ),
                        _liveMsg(_nameMsg, _nameOk, false),
                        const SizedBox(height: 14),

                        // Username
                        _buildField(
                          controller: _usernameCtrl, label: 'Username', icon: Icons.alternate_email_outlined,
                          hint: 'Leave blank for auto-generate',
                          textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                          onChanged: _validateUsername,
                        ),
                        _liveMsg(_usernameMsg, _usernameOk, _usernameChecking),
                        const SizedBox(height: 14),

                        // Email
                        _buildField(
                          controller: _emailCtrl, label: 'Email Address', icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!_emailRe.hasMatch(v.trim())) return 'Invalid email';
                            return null;
                          },
                          textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                          onChanged: (v) => _validateEmail(v),
                        ),
                        _liveMsg(_emailMsg, _emailOk, _emailChecking),
                        const SizedBox(height: 10),

                        // Email OTP row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _otpCtrl,
                                enabled: _otp != null && !_emailVerified,
                                maxLength: 6,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 4),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '••••••',
                                  hintStyle: TextStyle(color: hintColor.withValues(alpha: 0.5), fontSize: 13),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0E1116) : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _emailVerified
                                    ? null
                                    : (_otpSending || _otpCooldownLeft > 0 || !_emailOk || _emailRegistered || _emailChecking || _usernameChecking || (_usernameCtrl.text.trim().isNotEmpty && !_usernameOk) ? null : _sendOtp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: accent.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: _otpSending
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(_otpCooldownLeft > 0 ? 'Resend ${_otpCooldownLeft}s' : (_otpSendCount >= 3 ? 'No sends' : 'Send OTP'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _emailVerified || _otp == null ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _emailVerified ? const Color(0xFF00855B) : accent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: accent.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                ),
                                child: Text(_emailVerified ? '✓' : 'Verify', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                        if (_otpStatus != null) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _otpStatus!,
                              style: TextStyle(fontSize: 12, fontWeight: _otpStatusOk ? FontWeight.w700 : FontWeight.w500,
                                color: _otpStatusOk ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF00855B))
                                    : (isDark ? const Color(0xFFF87171) : AppColors.liveRed)),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Mobile
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                                  child: Text('Country', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hintColor)),
                                ),
                                Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0E1116) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _countryCode,
                                    underline: const SizedBox.shrink(),
                                    isDense: true,
                                    style: TextStyle(color: textColor, fontSize: 13),
                                    borderRadius: BorderRadius.circular(12),
                                    items: _countryCodes.map((c) {
                                      return DropdownMenuItem(
                                        value: c['code'] as String,
                                        child: Text('${c['flag']} ${c['code']}', style: const TextStyle(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() {
                                        _countryCode = v;
                                        final match = _countryCodes.firstWhere((c) => c['code'] == v);
                                        _countryDigits = (match['digits'] as num).toInt();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildField(
                                controller: _mobileCtrl, label: 'Mobile Number', icon: Icons.call_outlined,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_countryDigits)],
                                validator: (v) {
                                  final digits = (v ?? '').trim().replaceAll(RegExp(r'\D'), '');
                                  if (digits.isEmpty) return 'Mobile number is required';
                                  if (digits.length != _countryDigits) return 'Must be $_countryDigits digits';
                                  return null;
                                },
                                textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                                onChanged: _validateMobile,
                              ),
                            ),
                          ],
                        ),
                        _liveMsg(_mobileMsg, _mobileOk, _mobileChecking),
                        const SizedBox(height: 14),

                        // DOB
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 6),
                              child: Text('Date of Birth', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hintColor)),
                            ),
                            InkWell(
                              onTap: _pickDob,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.calendar_month_outlined, size: 18, color: hintColor),
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
                                ),
                                child: Text(
                                  _dobISO.isEmpty ? 'Select date' : _dobISO,
                                  style: TextStyle(color: _dobISO.isEmpty ? hintColor.withValues(alpha: 0.6) : textColor, fontSize: 14),
                                ),
                              ),
                            ),
                            if (_dobISO.isNotEmpty && _dobError() != null) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(_dobError()!, style: TextStyle(fontSize: 12, color: AppColors.liveRed)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _buildField(
                          controller: _passCtrl, label: 'Create Password', icon: Icons.lock_outline,
                          obscure: _obscurePass,
                          hint: '8+ chars, A-Z, a-z, @ # _',
                          validator: (v) {
                            final val = v ?? '';
                            if (val.isEmpty) return 'Enter a password';
                            if (val.length < 8) return 'At least 8 characters';
                            if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Add an uppercase letter (A-Z)';
                            if (!RegExp(r'[a-z]').hasMatch(val)) return 'Add a lowercase letter (a-z)';
                            if (!RegExp(r'[@#_]').hasMatch(val)) return 'Add @ # or _';
                            if (RegExp(r'(?:012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)', caseSensitive: false).hasMatch(val)) {
                              return 'No sequences (123, abc)';
                            }
                            return null;
                          },
                          textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                          onChanged: _validatePassword,
                          suffix: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: hintColor),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        _liveMsg(_passMsg, _passOk, false),
                        const SizedBox(height: 14),

                        // Confirm
                        _buildField(
                          controller: _confirmCtrl, label: 'Confirm Password', icon: Icons.lock_outline,
                          obscure: _obscureConfirm,
                          validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                          textColor: textColor, hintColor: hintColor, accent: accent, isDark: isDark,
                          onChanged: _validateConfirm,
                          suffix: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: hintColor),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        _liveMsg(_confirmMsg, _confirmOk, false),
                        const SizedBox(height: 14),

                        // Gender
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 6),
                              child: Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hintColor)),
                            ),
                            Row(
                              children: [
                                _genderOption('Male', isDark, accent, textColor),
                                const SizedBox(width: 8),
                                _genderOption('Female', isDark, accent, textColor),
                                const SizedBox(width: 8),
                                _genderOption('Other', isDark, accent, textColor),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Favorite Sports
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 6),
                              child: Text('Favorite Sports', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hintColor)),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _sportOptions.map((s) {
                                final value = s['value']!;
                                final selected = _selectedSports.contains(value);
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    if (selected) { _selectedSports.remove(value); } else { _selectedSports.add(value); }
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected ? accent : (isDark ? Colors.white10 : accent.withValues(alpha: 0.05)),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: selected ? accent : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08))),
                                    ),
                                    child: Text(s['label']!,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                            color: selected ? Colors.white : textColor)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Terms
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 22, width: 22,
                              child: Checkbox(
                                value: _termsAccepted,
                                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                                activeColor: accent,
                                side: BorderSide(color: hintColor.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('I agree to the ', style: TextStyle(color: hintColor, fontSize: 12)),
                                  GestureDetector(
                                    onTap: () => _showTerms(context),
                                    child: Text('Terms of Service', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12, decoration: TextDecoration.underline)),
                                  ),
                                  Text(' and ', style: TextStyle(color: hintColor, fontSize: 12)),
                                  GestureDetector(
                                    onTap: () => _showTerms(context, privacy: true),
                                    child: Text('Privacy Policy', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12, decoration: TextDecoration.underline)),
                                  ),
                                  Text('.', style: TextStyle(color: hintColor, fontSize: 12)),
                                ],
                              ),
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

                        // Theme preset picker (web parity)
                        Text('Theme', style: TextStyle(fontSize: 11, color: hintColor, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: themeConfigs.map((cfg) {
                              final selected = widget.themeType == cfg.type;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(cfg.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : textColor)),
                                  selected: selected,
                                  selectedColor: accent,
                                  backgroundColor: isDark ? Colors.white10 : accent.withValues(alpha: 0.05),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onSelected: (_) => widget.onThemeChanged(cfg.type),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Night/dark quick toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${isDark ? 'Night' : 'Day'} mode', style: TextStyle(fontSize: 11, color: hintColor)),
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

  Widget _genderOption(String value, bool isDark, Color accent, Color textColor) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent : (isDark ? Colors.white10 : accent.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? accent : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08))),
          ),
          child: Text(value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : textColor)),
        ),
      ),
    );
  }

  void _showTerms(BuildContext context, {bool privacy = false}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 480),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(privacy ? 'Privacy Policy' : 'Terms of Service',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    privacy ? _privacyText : _termsText,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _termsText = '''
Welcome to FanConnact! By creating an account you agree to the following terms:

1. You must be at least 13 years old to use FanConnact.
2. You are responsible for keeping your login credentials safe.
3. FanCoins earned through predictions, missions and rewards have no real-world monetary value and cannot be exchanged for cash.
4. Predictions and contests are for entertainment only. Fantasy results are based on official match outcomes.
5. Do not post abusive, hateful, or illegal content in communities, chats or profiles.
6. One account per person. Duplicate accounts may be suspended.
7. We may suspend accounts that violate these terms or misuse the platform.
8. We may update these terms at any time; continued use means you accept the updated terms.

For full details, please also read the Privacy Policy.
''';

  static const String _privacyText = '''
At FanConnact we respect your privacy.

1. We collect your name, email, mobile, date of birth and favorite sports to create and personalize your account.
2. Your profile photo, username and public stats may be visible to other fans.
3. We use Firebase (Google) to store your account securely.
4. We never sell your personal data.
5. You can delete your account at any time — contact support through the app.
6. Emails/OTPs are sent through our email service provider for verification.
7. We may collect anonymous usage data to improve the app.

Questions? Reach out to support from the Settings page.
''';

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
                onTap: () => setState(() { _selectedAvatar = seed; _photoFile = null; }),
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
                      errorBuilder: (_, _, _) => Container(color: accent.withValues(alpha: 0.2), child: Icon(Icons.person, color: accent, size: 20)),
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
            ..scaleByDouble(_flipped ? -1 : 1, 1, 1, 1),
          child: Image.file(_photoFile!, fit: BoxFit.cover),
        ),
      );
    }
    if (_selectedAvatar != null) {
      return Image.network(
        'https://api.dicebear.com/7.x/avataaars/png?seed=$_selectedAvatar',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: accent.withValues(alpha: 0.2), child: Icon(Icons.person, color: accent, size: 40)),
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
            children: kSportBackgrounds.map((b) {
              final selected = _selectedBg == b.key;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(b.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54))),
                  selected: selected,
                  selectedColor: accent,
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (v) => setState(() => _selectedBg = b.key),
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffix,
    String? hint,
    ValueChanged<String>? onChanged,
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
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: hintColor),
            suffixIcon: suffix,
            hintText: hint ?? 'Enter your ${label.toLowerCase()}',
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
