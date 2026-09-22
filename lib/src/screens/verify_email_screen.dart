import "dart:async";
import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter_animate/flutter_animate.dart";


class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  String? _message;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerified(silent: true);
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isSending = true;
      _message = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() => _message = "Verification email sent again.");
    } catch (e) {
      setState(() => _message = "Couldn't resend right now, try again shortly.");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (!silent) setState(() => _isChecking = true);
    await FirebaseAuth.instance.currentUser?.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (refreshedUser != null && refreshedUser.emailVerified) {
      _autoCheckTimer?.cancel();
      // AuthGate's StreamBuilder will pick this up automatically once
      // the user object updates, but reload() alone doesn't emit a new
      // stream event, so we force it by briefly re-signing state.
      setState(() {});
    }
    if (!silent && mounted) {
      setState(() {
        _isChecking = false;
        if (refreshedUser == null || !refreshedUser.emailVerified) {
          _message = "Still not verified - check your inbox (and spam folder).";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "your email";

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_unread,
                    size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  "Verify your email",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "We sent a verification link to $email. Click it, then come back here.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_message != null) ...[
                  Text(_message!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _isChecking ? null : () => _checkVerified(),
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("I've verified - refresh"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isSending ? null : _resendEmail,
                  child: Text(_isSending ? "Sending..." : "Resend email"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text("Sign out"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
