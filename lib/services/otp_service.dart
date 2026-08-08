import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';

// Free email-OTP service built on EmailJS (same account the web app uses).
// Sends a 6-digit code to the user's inbox; the app verifies it locally.
class OtpService {
  static const _serviceId = 'service_ntkex4p';
  static const _templateId = 'template_0d6nbzt';
  static const _userId = '64zTCXrsJZHB9u2tY';
  static const _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  static String generate() {
    final r = Random.secure();
    return (100000 + r.nextInt(900000)).toString();
  }

  // Returns null on success, or a human-readable error message on failure.
  static Future<String?> send(String email, String otp) async {
    final expiry = DateTime.now().add(const Duration(minutes: 5));
    final time =
        '${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}';
    try {
      final res = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_id': _serviceId,
              'template_id': _templateId,
              'user_id': _userId,
              'template_params': {
                'to_email': email,
                'passcode': otp,
                'time': time,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return null;
      if (res.statusCode == 403) {
        return 'Email service needs "API access from non-browser environments" enabled in the EmailJS dashboard (Account > Security).';
      }
      return 'Email service returned an error (${res.statusCode}). Try again.';
    } catch (_) {
      return 'Could not reach the email service. Check your internet and try again.';
    }
  }

  // Shows a dialog that auto-sends a code, verifies the user's entry and
  // pops with `true` only when the code matches.
  static Future<bool> verifyDialog(
    BuildContext context, {
    required String email,
    String title = 'Email Verification',
    String message = '',
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtpVerifyDialog(
        email: email,
        title: title,
        message: message,
      ),
    );
    return ok == true;
  }
}

class _OtpVerifyDialog extends StatefulWidget {
  final String email;
  final String title;
  final String message;
  const _OtpVerifyDialog({
    required this.email,
    required this.title,
    required this.message,
  });

  @override
  State<_OtpVerifyDialog> createState() => _OtpVerifyDialogState();
}

class _OtpVerifyDialogState extends State<_OtpVerifyDialog> {
  final _controller = TextEditingController();
  String? _otp;
  bool _sending = true;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final otp = OtpService.generate();
    final err = await OtpService.send(widget.email, otp);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (err == null) {
        _otp = otp;
        _sent = true;
      } else {
        _error = err;
      }
    });
  }

  void _verify() {
    final entered = _controller.text.trim();
    if (_otp == null || entered.isEmpty) {
      setState(() => _error = 'Enter the 6-digit code sent to your email.');
      return;
    }
    if (entered != _otp) {
      setState(() => _error = 'Incorrect code. Please try again.');
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message.isNotEmpty
                ? widget.message
                : 'We sent a 6-digit code to ${widget.email}.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 6),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _verify(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.liveRed, fontSize: 12)),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              if (_sending)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              else if (_sent)
                const Text('✓ Code sent', style: TextStyle(color: Color(0xFF00855b), fontSize: 12)),
              const Spacer(),
              if (_sent)
                TextButton(
                  onPressed: _sending ? null : _send,
                  child: const Text('Resend code'),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _verify,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
